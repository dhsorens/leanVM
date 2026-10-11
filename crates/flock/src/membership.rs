//! A zero-knowledge proof of one hash preimage and one Merkle path, 34 BLAKE2s compressions, as two sumchecks and
//! two plain evaluation claims. `crates/flock/membership.md` is the description; this is its prover and verifier.
//!
//! A wire is `local + 2^11 * slot + 2^16 * compression`: 64 compressions of 32 blocks of 2048 wires. A compression's
//! slots are one `S` block, twenty `H` blocks (half a round each) and one `F` block; the rest are empty.

use fiat_shamir::merkle::Hash;
use fiat_shamir::transcript::{Challenger, Proof, ProverState, Receiver, Transmitter, VerifierState};
use pcs::whir::INITIAL_FOLDING_FACTOR;
use primitives::field::{F64, F192};
use primitives::hash::{IV, PARAM_IV, SIGMA, hash};
use primitives::multilinear::{eq_eval, eq_table, poly_eval};

use crate::lincheck;
use crate::standalone::Claim;
use crate::zerocheck;

/// Levels of the Merkle tree.
pub const DEPTH: usize = 32;
/// Sumcheck variables: the wires' index bits.
pub const N_VARS: usize = LOG_BLOCK + LOG_SLOTS + LOG_COMPRESSIONS;
/// Variables of the committed local matrices: a row, a column, a block type, and `A` or `A + B`.
pub const INDEX_VARS: usize = 2 * LOG_BLOCK + 3;
/// Variables of the committed polynomial: the witness and three masks of its size.
pub const COMMITTED_VARS: usize = N_VARS + 2;

const LOG_BLOCK: usize = 11;
const LOG_SLOTS: usize = 5;
const LOG_COMPRESSIONS: usize = 6;
const BLOCK: usize = 1 << LOG_BLOCK;
const N_WIRES: usize = 1 << N_VARS;
/// The hash of `x` with each constant, then one compression a level.
const N_HASHES: usize = DEPTH + 2;
const F_SLOT: usize = 21;
const N_SLOTS: usize = F_SLOT + 1;
const N_KINDS: usize = 3;
/// The block types: the compression's input, half a round, its output.
const S: usize = 0;
const H: usize = 1;
const F: usize = 2;

// A block's regions, in 32-bit words. Every block's output is at `OUT`, where the next one reads it.
const OUT: usize = 0;
/// `H`, `F`: the sixteen state words read from the previous slot. `S`: the sixteen message words it outputs.
const STATE_IN: usize = 16;
/// `H`: its eight message words. `S`: the previous hash. `F`: `x`, a free input.
const AUX: usize = 32;
const SIB: usize = 40;
const SWAP: usize = 48;
/// `S`: the direction bit, then the wires hiding the zerocheck's evaluations, `w = u * v` on random `u`, `v`.
const DIRECTION: usize = 56 * 32;
const HIDING: [usize; 3] = [57 * 32, 58 * 32, 59 * 32];
const N_HIDING: usize = 6;
/// `S`: the zerocheck's mask, three limbs a coefficient. Compression 0's are free, in no row and on no row's
/// right-hand side (`C` is the identity but for them); the other compressions' are zero.
const MASK: usize = DIRECTION + 112;
/// The mask is `c + sum_i (g_i x_i + h_i x_i^2)`.
const MASK_COEFFS: usize = 2 * N_VARS + 1;
/// `H`: its carry products.
const PRODUCTS: usize = 40 * 32;
const CONST: usize = BLOCK - 1;

const CONSTANTS: [[u8; 32]; 2] = [[0x11; 32], [0x22; 32]];

fn kind(slot: usize) -> Option<usize> {
    match slot {
        0 => Some(S),
        1..F_SLOT => Some(H),
        F_SLOT => Some(F),
        _ => None,
    }
}

fn wire(compression: usize, slot: usize, local: usize) -> usize {
    local | slot << LOG_BLOCK | compression << (LOG_BLOCK + LOG_SLOTS)
}

/// A sum of wires of one block, as the set of their local indices.
type Form = [u64; BLOCK / 64];
const EMPTY: Form = [0; BLOCK / 64];

fn one(local: usize) -> Form {
    let mut form = EMPTY;
    form[local / 64] = 1 << (local % 64);
    form
}

fn xor(a: &Form, b: &Form) -> Form {
    std::array::from_fn(|i| a[i] ^ b[i])
}

fn parity(form: &Form, bits: &Form) -> bool {
    form.iter().zip(bits).fold(0, |acc, (f, b)| acc ^ (f & b).count_ones()) & 1 == 1
}

fn set_bits(form: &Form) -> impl Iterator<Item = usize> + '_ {
    form.iter().enumerate().flat_map(|(i, &word)| {
        std::iter::successors((word != 0).then_some(word), |w| Some(w & (w - 1)).filter(|&w| w != 0))
            .map(move |w| 64 * i + w.trailing_zeros() as usize)
    })
}

type Word = Vec<Form>;

fn word(base: usize, index: usize) -> Word {
    (0..32).map(|i| one(32 * (base + index) + i)).collect()
}

fn xor_words(a: &Word, b: &Word) -> Word {
    a.iter().zip(b).map(|(x, y)| xor(x, y)).collect()
}

fn rotr(a: &Word, by: usize) -> Word {
    (0..32).map(|i| a[(i + by) % 32]).collect()
}

/// One block type: row `l` says wire `l` is `(sum of a[l]) * (sum of b[l])`.
struct Block {
    a: Vec<Form>,
    b: Vec<Form>,
    /// Rows whose `a` is one wire of another block, [`source`].
    routed: Vec<bool>,
    /// The rows that compute a wire from earlier ones, in an order that respects it. The others are free inputs.
    order: Vec<usize>,
}

impl Block {
    fn new() -> Self {
        let mut block = Self {
            a: vec![EMPTY; BLOCK],
            b: vec![EMPTY; BLOCK],
            routed: vec![false; BLOCK],
            order: Vec::new(),
        };
        block.a[CONST] = one(CONST);
        block.b[CONST] = one(CONST);
        block
    }

    fn row(&mut self, local: usize, a: Form, b: Form) {
        (self.a[local], self.b[local]) = (a, b);
        self.order.push(local);
    }

    /// Wire `local` is `form`.
    fn linear(&mut self, local: usize, form: Form) {
        self.row(local, form, one(CONST));
    }

    /// The `words` words at `base` copy wires of other blocks.
    fn copies(&mut self, base: usize, words: usize) {
        for local in 32 * base..32 * (base + words) {
            self.routed[local] = true;
            self.linear(local, EMPTY);
        }
    }

    /// Free input bits, boolean by the row `z = z * z`.
    fn booleans(&mut self, locals: std::ops::Range<usize>) {
        for local in locals {
            (self.a[local], self.b[local]) = (one(local), one(local));
        }
    }

    /// `x + y` mod `2^32`, its carries at `next`: carry `i + 1` is `p_i + carry_i`, `p_i = (x_i + c_i) * (y_i + c_i)`.
    fn add(&mut self, next: &mut usize, x: &Word, y: &Word) -> Word {
        let mut carry = EMPTY;
        (0..32)
            .map(|i| {
                let sum = xor(&xor(&x[i], &y[i]), &carry);
                if i < 31 {
                    self.row(*next, xor(&x[i], &carry), xor(&y[i], &carry));
                    carry = xor(&carry, &one(*next));
                    *next += 1;
                }
                sum
            })
            .collect()
    }

    /// Half a round: G on each column of the sixteen state words, with message words `2j` and `2j + 1`.
    fn half_round() -> Self {
        let mut block = Self::new();
        block.copies(STATE_IN, 16 + 8);
        let mut state: Vec<Word> = (0..16).map(|k| word(STATE_IN, k)).collect();
        let mut next = PRODUCTS;
        for j in 0..4 {
            let [mut a, mut b, mut c, mut d] = [0, 4, 8, 12].map(|row| state[row + j].clone());
            for (m, [rot_d, rot_b]) in [(2 * j, [16, 12]), (2 * j + 1, [8, 7])] {
                let ab = block.add(&mut next, &a, &b);
                a = block.add(&mut next, &ab, &word(AUX, m));
                d = rotr(&xor_words(&d, &a), rot_d);
                c = block.add(&mut next, &c, &d);
                b = rotr(&xor_words(&b, &c), rot_b);
            }
            for (row, value) in [0, 4, 8, 12].into_iter().zip([a, b, c, d]) {
                state[row + j] = value;
            }
        }
        assert!(next <= CONST);
        for (k, value) in state.iter().enumerate() {
            for (i, &form) in value.iter().enumerate() {
                block.linear(32 * (OUT + k) + i, form);
            }
        }
        block
    }

    /// The compression's input: the initial state, and the message `swap(previous hash, sibling)`.
    fn start() -> Self {
        let mut block = Self::new();
        let mut state = [PARAM_IV, IV].concat();
        // One 64-byte block: counter 64, final flag set.
        state[12] ^= 64;
        state[14] = !state[14];
        for (k, value) in state.iter().enumerate() {
            for i in 0..32 {
                let form = if (value >> i) & 1 == 1 { one(CONST) } else { EMPTY };
                block.linear(32 * (OUT + k) + i, form);
            }
        }
        block.copies(AUX, 8);
        block.booleans(32 * SIB..32 * (SIB + 8));
        block.booleans(DIRECTION..DIRECTION + 1);
        for bit in 0..256 {
            let [previous, sibling, swap] = [AUX, SIB, SWAP].map(|base| 32 * base + bit);
            block.row(swap, xor(&one(previous), &one(sibling)), one(DIRECTION));
            block.linear(32 * STATE_IN + bit, xor(&one(previous), &one(swap)));
            block.linear(32 * (STATE_IN + 8) + bit, xor(&one(sibling), &one(swap)));
        }
        for i in 0..N_HIDING {
            let [u, v, w] = HIDING.map(|base| base + i);
            (block.a[u], block.b[u]) = (one(u), one(CONST));
            (block.a[v], block.b[v]) = (one(v), one(CONST));
            (block.a[w], block.b[w]) = (one(u), one(v));
        }
        block
    }

    /// The compression's output, `h + v_k + v_(k+8)`. `x` lives here too.
    fn finish() -> Self {
        let mut block = Self::new();
        block.copies(STATE_IN, 16);
        block.booleans(32 * AUX..32 * (AUX + 8));
        for k in 0..8 {
            for i in 0..32 {
                let [lo, hi] = [k, k + 8].map(|k| one(32 * (STATE_IN + k) + i));
                let constant = if (PARAM_IV[k] >> i) & 1 == 1 { one(CONST) } else { EMPTY };
                block.linear(32 * (OUT + k) + i, xor(&xor(&lo, &hi), &constant));
            }
        }
        block
    }
}

/// Which output word of the previous slot is state word `k` of slot `slot`: the diagonal step is the column step
/// on a state whose row `r` is rotated by `r`, so the words rotate one way into it and back out of it.
fn state_source(slot: usize, k: usize) -> usize {
    let (row, col) = (k / 4, k % 4);
    match slot - 1 {
        0 => k,
        half if half % 2 == 1 => 4 * row + (col + row) % 4,
        _ => 4 * row + (col + 4 - row) % 4,
    }
}

/// The message word half-round `slot` reads at position `p`.
fn message_source(slot: usize, p: usize) -> usize {
    SIGMA[(slot - 1) / 2][8 * ((slot - 1) % 2) + p]
}

/// Where compression `c` reads its previous hash: the one before it along the path, or `x`.
fn previous_source(c: usize) -> (usize, usize) {
    match c {
        2..N_HASHES => (c - 1, OUT),
        1 => (0, AUX),
        _ => (c, AUX),
    }
}

/// The wire a routed row copies.
fn source(c: usize, slot: usize, local: usize) -> usize {
    let (w, bit) = (local / 32, local % 32);
    if slot == 0 {
        let (from, base) = previous_source(c);
        wire(from, F_SLOT, 32 * (base + w - AUX) + bit)
    } else if w < AUX {
        wire(c, slot - 1, 32 * (OUT + state_source(slot, w - STATE_IN)) + bit)
    } else {
        wire(c, 0, 32 * (STATE_IN + message_source(slot, w - AUX)) + bit)
    }
}

fn bit_of(bytes: &[u8; 32], bit: usize) -> bool {
    (bytes[bit / 8] >> (bit % 8)) & 1 == 1
}

/// The public values.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Statement {
    pub y: [u8; 32],
    pub root: [u8; 32],
}

/// What the prover knows. Bit `i` of `directions` says the sibling is on the left at level `i`.
#[derive(Clone, Debug)]
pub struct Secret {
    pub x: [u8; 32],
    pub siblings: [[u8; 32]; DEPTH],
    pub directions: u32,
}

impl Secret {
    /// Compression `c`'s free inputs. Padding compressions hash zeros.
    fn inputs(&self, c: usize) -> Inputs {
        match c {
            0 => (CONSTANTS[0], false, self.x),
            1 => (CONSTANTS[1], false, [0; 32]),
            2..N_HASHES => (self.siblings[c - 2], (self.directions >> (c - 2)) & 1 == 1, [0; 32]),
            _ => ([0; 32], false, [0; 32]),
        }
    }

    /// The statement this secret proves, by hashing natively.
    pub fn statement(&self) -> Statement {
        let pair = |left: &[u8; 32], right: &[u8; 32]| hash(&[*left, *right].concat());
        let leaf = pair(&self.x, &CONSTANTS[1]);
        let root = self.siblings.iter().enumerate().fold(leaf, |node, (i, sibling)| {
            if (self.directions >> i) & 1 == 1 {
                pair(sibling, &node)
            } else {
                pair(&node, sibling)
            }
        });
        Statement {
            y: pair(&self.x, &CONSTANTS[0]),
            root,
        }
    }
}

/// The circuit: its three block types.
pub struct Circuit {
    blocks: [Block; N_KINDS],
}

/// A satisfying assignment, with `A z` and `B z`.
pub struct Witness {
    pub z: Vec<F64>,
    a: Vec<F64>,
    b: Vec<F64>,
    /// The zerocheck mask's coefficients, which `z` holds as wires.
    mask: Vec<F192>,
}

impl Witness {
    /// `C z`: `z` without the mask wires.
    fn c(&self) -> Vec<F192> {
        let mut c = lift(&self.z);
        c[mask_wires()].fill(F192::ZERO);
        c
    }

    fn satisfied(&self) -> bool {
        (0..N_WIRES).all(|i| {
            self.a[i] * self.b[i]
                == if mask_wires().contains(&i) {
                    F64::ZERO
                } else {
                    self.z[i]
                }
        })
    }
}

/// The wires holding the zerocheck's mask.
fn mask_wires() -> std::ops::Range<usize> {
    wire(0, 0, MASK)..wire(0, 0, MASK) + 3 * MASK_COEFFS
}

/// A compression's free inputs: its sibling, its direction bit, and `x`.
type Inputs = ([u8; 32], bool, [u8; 32]);

impl Default for Circuit {
    fn default() -> Self {
        Self::new()
    }
}

impl Circuit {
    pub fn new() -> Self {
        Self {
            blocks: [Block::start(), Block::half_round(), Block::finish()],
        }
    }

    /// The local matrices as one dense table, the only circuit data a verifier needs behind a commitment.
    ///
    /// Entry `row + 2^11 * col + 2^22 * kind + 2^24 * s` is `A_kind` at `s = 0` and `A_kind + B_kind` at `s = 1`,
    /// so its last coordinate at `alpha` gives `A + alpha * B`.
    pub fn index(&self) -> Vec<F64> {
        let mut table = vec![F64::ZERO; 1 << INDEX_VARS];
        let (a_half, ab_half) = table.split_at_mut(1 << (INDEX_VARS - 1));
        for (k, block) in self.blocks.iter().enumerate() {
            for row in 0..BLOCK {
                let at = |col: usize| row | col << LOG_BLOCK | k << (2 * LOG_BLOCK);
                for col in set_bits(&block.a[row]) {
                    a_half[at(col)] = F64::ONE;
                }
                for col in set_bits(&xor(&block.a[row], &block.b[row])) {
                    ab_half[at(col)] = F64::ONE;
                }
            }
        }
        table
    }

    /// Run the circuit on `secret`. `random` supplies the hiding wires and the zerocheck's mask.
    pub fn witness(&self, secret: &Secret, random: &mut dyn FnMut() -> u64) -> Witness {
        self.run(&|c| secret.inputs(c), random)
    }

    /// Run the circuit on each compression's free inputs.
    fn run(&self, inputs: &dyn Fn(usize) -> Inputs, random: &mut dyn FnMut() -> u64) -> Witness {
        let mut z = vec![F64::ZERO; N_WIRES];
        let mut a = vec![F64::ZERO; N_WIRES];
        let mut b = vec![F64::ZERO; N_WIRES];
        let mut mask = Vec::with_capacity(MASK_COEFFS);
        let bit = |v: bool| F64(v as u64);
        for c in 0..1 << LOG_COMPRESSIONS {
            let (sibling, direction, x) = inputs(c);
            // `S` reads `x` from the `F` block, which comes later.
            for i in 0..256 {
                z[wire(c, F_SLOT, 32 * AUX + i)] = bit(bit_of(&x, i));
            }
            for slot in 0..N_SLOTS {
                let k = kind(slot).expect("a used slot");
                let block = &self.blocks[k];
                let base = wire(c, slot, 0);
                let mut bits = one(CONST);
                let set = |bits: &mut Form, local: usize, v: bool| bits[local / 64] |= (v as u64) << (local % 64);
                for i in 0..256 {
                    if k == S {
                        set(&mut bits, 32 * SIB + i, bit_of(&sibling, i));
                    } else if k == F {
                        set(&mut bits, 32 * AUX + i, bit_of(&x, i));
                    }
                }
                if k == S {
                    set(&mut bits, DIRECTION, direction);
                }
                let row_a = |bits: &Form, z: &[F64], local: usize| {
                    if block.routed[local] {
                        z[source(c, slot, local)].0 & 1 == 1
                    } else {
                        parity(&block.a[local], bits)
                    }
                };
                for &local in &block.order {
                    let value = row_a(&bits, &z, local) && parity(&block.b[local], &bits);
                    set(&mut bits, local, value);
                }
                for local in 0..BLOCK {
                    a[base + local] = bit(row_a(&bits, &z, local));
                    b[base + local] = bit(parity(&block.b[local], &bits));
                    z[base + local] = bit((bits[local / 64] >> (local % 64)) & 1 == 1);
                }
                if k == S {
                    for i in 0..N_HIDING {
                        let [u, v, w] = HIDING.map(|at| base + at + i);
                        (z[u], z[v]) = (F64(random()), F64(random()));
                        z[w] = z[u] * z[v];
                        (a[u], a[v], a[w], b[w]) = (z[u], z[v], z[u], z[v]);
                    }
                }
                if k == S && c == 0 {
                    for j in 0..MASK_COEFFS {
                        let limbs: [u64; 3] = std::array::from_fn(|_| random());
                        for (limb, &value) in limbs.iter().enumerate() {
                            z[base + MASK + 3 * j + limb] = F64(value);
                        }
                        mask.push(F192::new(limbs[0], limbs[1], limbs[2]));
                    }
                }
            }
        }
        let witness = Witness { z, a, b, mask };
        debug_assert!(witness.satisfied());
        witness
    }
}

/// Variables of the table [`committed`] returns.
pub const HIDDEN_VARS: usize = COMMITTED_VARS + 2;
/// The top variable inside a lane of that table's commitment, which the lanes' variables follow.
const LANE_TOP: usize = HIDDEN_VARS - INITIAL_FOLDING_FACTOR - 1;

/// The committed polynomial `P = (z, m_0, m_1, m_2)`, laid out so that opening it at one point reveals one value.
///
/// Two variables of uniformly random values surround it, placed for this commitment's structure: a leaf holds each
/// lane at one position, so `P` takes the high half of every lane and the random low half hides the leaves; and
/// the first variable the opening folds pairs `P` with a random twin. [`hidden_point`] is where a claim lands.
pub fn committed(witness: &Witness, masks: &[Vec<F64>; 3], random: &mut dyn FnMut() -> u64) -> Vec<F64> {
    assert!(masks.iter().all(|m| m.len() == N_WIRES));
    let tables = [&witness.z, &masks[0], &masks[1], &masks[2]];
    (0..1usize << HIDDEN_VARS)
        .map(|at| {
            if (at >> LANE_TOP) & 0b11 == 0b01 {
                let i = at & ((1 << LANE_TOP) - 1) | at >> (LANE_TOP + 2) << LANE_TOP;
                tables[i >> N_VARS][i % N_WIRES]
            } else {
                F64(random())
            }
        })
        .collect()
}

/// A claim on `P` as a claim on what [`committed`] returns.
pub fn hidden_point(claim: &Claim) -> Claim {
    let (low, high) = claim.point.split_at(LANE_TOP);
    Claim {
        point: [low, &[F192::ONE, F192::ZERO], high].concat(),
        value: claim.value,
    }
}

/// What a proof leaves to the two commitments.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Claims {
    /// On `P`, [`COMMITTED_VARS`] variables.
    pub witness: Claim,
    /// On [`Circuit::index`].
    pub index: Claim,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum VerifyError {
    Zerocheck(zerocheck::VerifyError),
    Transcript(fiat_shamir::transcript::Error),
    /// A denominator of the final claim is zero.
    Degenerate,
}

fn eq_index(index: usize, point: &[F192]) -> F192 {
    point.iter().enumerate().fold(F192::ONE, |acc, (k, &x)| {
        acc * if (index >> k) & 1 == 1 { x } else { F192::ONE + x }
    })
}

/// The lincheck's batching challenges: `alpha` over its claims, `beta` and `pi` over the pinned wires.
struct Batching {
    alpha: [F192; 5],
    beta: F192,
    pi: Vec<F192>,
}

impl Batching {
    fn sample(ch: &mut impl Challenger) -> Self {
        let alpha = ch.sample();
        Self {
            alpha: std::array::from_fn(|i| (0..i).fold(F192::ONE, |acc, _| acc * alpha)),
            beta: ch.sample(),
            pi: ch.sample_vec(8),
        }
    }
}

/// The wires with public values: each constant, `y`, `root` (256 bits from the wire given), and two direction bits.
fn pins(statement: &Statement) -> Vec<(usize, Vec<bool>)> {
    let bits = |bytes: &[u8; 32]| (0..256).map(|i| bit_of(bytes, i)).collect();
    vec![
        (wire(0, 0, 32 * SIB), bits(&CONSTANTS[0])),
        (wire(1, 0, 32 * SIB), bits(&CONSTANTS[1])),
        (wire(0, F_SLOT, 32 * OUT), bits(&statement.y)),
        (wire(N_HASHES - 1, F_SLOT, 32 * OUT), bits(&statement.root)),
        (wire(0, 0, DIRECTION), vec![false]),
        (wire(1, 0, DIRECTION), vec![false]),
    ]
}

/// Pin `r`'s batching coefficient.
fn pin_power(batching: &Batching, r: usize) -> F192 {
    (0..=r).fold(F192::ONE, |acc, _| acc * batching.beta)
}

/// The weight of bit `j` of pin `r`, given `eq(pi, .)`: a lone bit carries the coefficient alone.
fn pin_weight(batching: &Batching, pi: &[F192], r: usize, len: usize, j: usize) -> F192 {
    if len == 1 {
        pin_power(batching, r)
    } else {
        pin_power(batching, r) * pi[j]
    }
}

/// What the pinned wires, weighted, must sum to.
fn pin_target(batching: &Batching, pins: &[(usize, Vec<bool>)]) -> F192 {
    let pi = eq_table(&batching.pi);
    pins.iter().enumerate().fold(F192::ZERO, |acc, (r, (_, bits))| {
        let set = (0..bits.len()).filter(|&j| bits[j]);
        let sum = if bits.len() == 1 {
            F192::new(set.count() as u64, 0, 0)
        } else {
            set.fold(F192::ZERO, |sum, j| sum + pi[j])
        };
        acc + pin_power(batching, r) * sum
    })
}

/// The eq tables of a point over the slots and over the compressions.
fn instance_tables(point: &[F192]) -> [Vec<F192>; 2] {
    let (slot, compression) = point[LOG_BLOCK..].split_at(LOG_SLOTS);
    [eq_table(slot), eq_table(compression)]
}

/// The eq weight of the used slots, which is what the constant wires sum to.
fn used_slots(slots: &[F192]) -> F192 {
    slots[..N_SLOTS].iter().fold(F192::ZERO, |acc, &e| acc + e)
}

/// The lincheck's weight on every wire, and each block type's column marginal `(A + alpha B)^T eq(rho_local, .)`.
fn comb_table(
    circuit: &Circuit,
    rho: &[F192],
    batching: &Batching,
    pins: &[(usize, Vec<bool>)],
) -> (Vec<F192>, [Vec<F192>; N_KINDS]) {
    let local = eq_table(&rho[..LOG_BLOCK]);
    let [slots, compressions] = instance_tables(rho);
    let alpha = batching.alpha;
    let marginals: [Vec<F192>; N_KINDS] = std::array::from_fn(|k| {
        let block = &circuit.blocks[k];
        let mut marginal = vec![F192::ZERO; BLOCK];
        for row in 0..BLOCK {
            for col in set_bits(&block.a[row]) {
                marginal[col] += local[row];
            }
            for col in set_bits(&block.b[row]) {
                marginal[col] += alpha[1] * local[row];
            }
        }
        marginal
    });
    let mut comb = vec![F192::ZERO; N_WIRES];
    parallel::chunks_mut(&mut comb, BLOCK, |block, comb| {
        let (c, slot) = (block >> LOG_SLOTS, block % (1 << LOG_SLOTS));
        let weight = compressions[c] * slots[slot];
        for (y, value) in comb.iter_mut().enumerate() {
            let marginal = kind(slot).map_or(F192::ZERO, |k| marginals[k][y]);
            *value = weight * (marginal + alpha[2] * local[y]);
        }
        if kind(slot).is_some() {
            comb[CONST] += alpha[3] * weight;
        }
    });
    for c in 0..1 << LOG_COMPRESSIONS {
        for slot in 0..N_SLOTS {
            let block = &circuit.blocks[kind(slot).expect("a used slot")];
            let weight = compressions[c] * slots[slot];
            for row in (0..BLOCK).filter(|&row| block.routed[row]) {
                comb[source(c, slot, row)] += weight * local[row];
            }
        }
    }
    let pi = eq_table(&batching.pi);
    for (r, (base, bits)) in pins.iter().enumerate() {
        for j in 0..bits.len() {
            comb[base + j] += pin_weight(batching, &pi, r, bits.len(), j);
        }
    }
    // A mask wire carries its weight in the mask's value, and none in `C z`.
    let unit = compressions[0] * slots[0];
    for (at, weight) in mask_wires().zip(mask_weights(rho)) {
        comb[at] += alpha[4] * weight + alpha[2] * unit * local[at];
    }
    (comb, marginals)
}

/// The weight of each mask wire in the mask's value at `rho`: a coefficient's own weight, times each limb's.
fn mask_weights(rho: &[F192]) -> Vec<F192> {
    let coefficients = [F192::ONE].into_iter().chain(rho.iter().flat_map(|&x| [x, x.square()]));
    coefficients
        .flat_map(|w| [w, w * F192::Y, w * F192::Y.square()])
        .collect()
}

/// [`comb_table`]'s multilinear extension at `q`, from the three local-matrix evaluations `values` and the wiring.
fn comb_at(rho: &[F192], q: &[F192], batching: &Batching, pins: &[(usize, Vec<bool>)], values: &[F192]) -> F192 {
    let alpha = batching.alpha;
    let [slots_r, comps_r] = instance_tables(rho);
    let [slots_q, comps_q] = instance_tables(q);
    // A local index is a bit, then a word.
    let (words_r, words_q) = (eq_table(&rho[5..LOG_BLOCK]), eq_table(&q[5..LOG_BLOCK]));
    let same_bit = eq_eval(&rho[..5], &q[..5]);
    let same_compression = eq_eval(&rho[LOG_BLOCK + LOG_SLOTS..], &q[LOG_BLOCK + LOG_SLOTS..]);
    let sum = |terms: &mut dyn Iterator<Item = F192>| terms.fold(F192::ZERO, |acc, t| acc + t);

    // The local matrices, and the constant wire of every used block.
    let diagonal = |slot: usize| slots_r[slot] * slots_q[slot];
    let blocks = sum(&mut (0..N_SLOTS).map(|slot| diagonal(slot) * values[kind(slot).expect("a used slot")]));
    let constants = alpha[3] * eq_index(CONST, &q[..LOG_BLOCK]) * sum(&mut (0..N_SLOTS).map(diagonal));

    // The wiring: state words from the previous slot, message words from slot 0, the previous hash from another F.
    let words = |from: usize, to: &dyn Fn(usize) -> usize, n: usize| {
        sum(&mut (0..n).map(|k| words_r[from + k] * words_q[to(k)]))
    };
    // Slot 1 reads the state as it is, the others rotated one way or the other.
    let rotations: [F192; 3] = std::array::from_fn(|case| words(STATE_IN, &|k| OUT + state_source(case + 1, k), 16));
    let state = sum(&mut (1..N_SLOTS)
        .map(|slot| slots_r[slot] * slots_q[slot - 1] * rotations[if slot == 1 { 0 } else { 1 + slot % 2 }]));
    let message = slots_q[0]
        * sum(&mut (1..F_SLOT).map(|slot| slots_r[slot] * words(AUX, &|p| STATE_IN + message_source(slot, p), 8)));
    let from_base = |base: usize| words(AUX, &|k| base + k, 8);
    let (from_hash, from_x) = (from_base(OUT), from_base(AUX));
    let previous = slots_r[0]
        * slots_q[F_SLOT]
        * sum(&mut (0..1 << LOG_COMPRESSIONS).map(|c| {
            let (from, base) = previous_source(c);
            comps_r[c] * comps_q[from] * if base == OUT { from_hash } else { from_x }
        }));
    let wiring = same_bit * (same_compression * (state + message) + previous);

    let pinned = sum(&mut pins.iter().enumerate().map(|(r, (base, bits))| {
        let power = pin_power(batching, r);
        if bits.len() == 1 {
            power * eq_index(*base, q)
        } else {
            power * eq_eval(&batching.pi, &q[..8]) * eq_index(base >> 8, &q[8..])
        }
    }));
    // The mask wires sit in one aligned run of 256, in the first block. Each leaves `C z` and enters the mask's value.
    let (low_r, low_q) = (eq_table(&rho[..8]), eq_table(&q[..8]));
    let run = MASK % 256..MASK % 256 + 3 * MASK_COEFFS;
    let value = sum(&mut mask_weights(rho).iter().zip(&low_q[run.clone()]).map(|(&w, &x)| w * x));
    let leaves = sum(&mut run.map(|at| low_r[at] * low_q[at]));
    let mask = eq_index(MASK >> 8, &q[8..]) * (alpha[4] * value + alpha[2] * eq_index(MASK >> 8, &rho[8..]) * leaves);
    same_compression * (blocks + constants) + alpha[2] * eq_eval(rho, q) + wiring + pinned + mask
}

/// The zerocheck's mask `g(x) = c + sum_i (g_i x_i + h_i x_i^2)`, summed under the zerocheck's own `eq(r, x)`.
///
/// Round `i` meets `g_i` and `h_i` for the first time, so its two scalars are uniform whatever the witness.
/// A multilinear mask times a public factor cannot do this: its round polynomial has a root a verifier knows.
struct ZeroMask<'a> {
    /// `c`, then `(g_i, h_i)` for each variable.
    coeffs: &'a [F192],
    r: &'a [F192],
}

impl ZeroMask<'_> {
    fn pair(&self, i: usize) -> (F192, F192) {
        (self.coeffs[1 + 2 * i], self.coeffs[2 + 2 * i])
    }

    /// `g` summed over the variables from `from` on, each under its eq weight: `g_i(0) = 0`, so `r_i * g_i(1)`.
    fn tail(&self, from: usize) -> F192 {
        (from..self.r.len()).fold(F192::ZERO, |acc, i| {
            let (g, h) = self.pair(i);
            acc + self.r[i] * (g + h)
        })
    }

    fn sum(&self) -> F192 {
        self.coeffs[0] + self.tail(0)
    }

    fn eval(&self, point: &[F192]) -> F192 {
        point.iter().enumerate().fold(self.coeffs[0], |acc, (i, &x)| {
            let (g, h) = self.pair(i);
            acc + x * (g + x * h)
        })
    }

    /// `(G(1), G(inf))` of the round after `point`: `G(X) = g(point) + g_i X + h_i X^2 + (the later variables)`.
    fn round(&self, point: &[F192]) -> (F192, F192) {
        let i = point.len();
        let (g, h) = self.pair(i);
        (self.eval(point) + g + h + self.tail(i + 1), h)
    }
}

fn lift(table: &[F64]) -> Vec<F192> {
    parallel::map_collect(table.len(), |i| F192::from(table[i]))
}

/// The transcript's seed: the circuit and the statement.
fn label(index_root: &Hash, statement: &Statement) -> Vec<u8> {
    [
        b"flock-membership".as_slice(),
        index_root,
        &statement.y,
        &statement.root,
    ]
    .concat()
}

/// Prove `statement` from a witness of it, against the circuit committed as `index_root`.
/// Panics on two challenge values a sampled one meets with negligible probability.
///
/// `root` commits `P = (witness.z, masks)` ([`committed`]), the masks uniformly random. Returns the proof and the
/// two claims it leaves.
pub fn prove(
    circuit: &Circuit,
    index_root: &Hash,
    statement: &Statement,
    root: &Hash,
    witness: &Witness,
    masks: &[Vec<F64>; 3],
) -> (Proof, Claims) {
    let mut ps = ProverState::from_label(&label(index_root, statement));
    ps.add_root(root);

    // Zerocheck, masked.
    let span = tracing::info_span!("Zerocheck").entered();
    let r = ps.sample_vec(N_VARS);
    let mask = ZeroMask {
        coeffs: &witness.mask,
        r: &r,
    };
    let mask_sum = mask.sum();
    ps.add_scalar(mask_sum);
    let lambda = ps.sample();
    let (rho, a_eval, b_eval, _) = zerocheck::prove_tables(
        lift(&witness.a),
        lift(&witness.b),
        witness.c(),
        &r,
        lambda * mask_sum,
        &mut |point| {
            let (g1, g_inf) = mask.round(point);
            (lambda * g1, lambda * g_inf)
        },
        &mut ps,
    );
    let gamma = mask.eval(&rho);
    ps.add_scalars(&[a_eval, b_eval, gamma]);
    drop(span);

    // Lincheck on the witness plus a combination of the masks that is a uniformly random table.
    let span = tracing::info_span!("Lincheck").entered();
    let batching = Batching::sample(&mut ps);
    let pins = pins(statement);
    let (comb, marginals) = comb_table(circuit, &rho, &batching, &pins);
    let alpha = batching.alpha;
    let mask_sums = masks
        .each_ref()
        .map(|m| parallel::map_reduce(N_WIRES, || F192::ZERO, |i| comb[i].mul_base(m[i]), |x, y| x + y));
    ps.add_scalars(&mask_sums);
    let lambdas = mask_challenges(&mut ps);
    assert!(lambdas[0] != F192::ONE, "a mask challenge of 1");
    let weights = [lambdas[0], lambdas[1], lambdas[0] * lambdas[1]];
    let masked = parallel::map_collect(N_WIRES, |i| {
        (0..3).fold(F192::from(witness.z[i]), |acc, k| {
            acc + weights[k].mul_base(masks[k][i])
        })
    });
    let (q, _, masked_eval, _) = lincheck::product_sumcheck(comb, masked, 0, &mut ps);
    let local = eq_table(&q[..LOG_BLOCK]);
    let values = marginals.map(|marginal| pcs::ring_switch::inner_product_ext(&marginal, &local));
    ps.add_scalars(&values);
    let kinds = ps.sample_vec(2);
    drop(span);

    let [d0, d1] = lambdas.map(|l| F192::ONE + l);
    let claims = Claims {
        witness: Claim {
            point: [&q[..], &[lambdas[0] * d0.inv(), lambdas[1] * d1.inv()]].concat(),
            value: masked_eval * (d0 * d1).inv(),
        },
        index: index_claim(&rho, &q, &kinds, alpha[1], &values),
    };
    (ps.into_proof(), claims)
}

/// `(l, l^2)`: the three masks enter with `l, l^2, l^3`, a basis of the field over `GF(2^64)` unless `l` is in it.
fn mask_challenges(ch: &mut impl Challenger) -> [F192; 2] {
    let lambda = ch.sample();
    [lambda, lambda.square()]
}

fn index_claim(rho: &[F192], q: &[F192], kinds: &[F192], alpha: F192, values: &[F192]) -> Claim {
    let point = [&rho[..LOG_BLOCK], &q[..LOG_BLOCK], kinds, &[alpha]].concat();
    let value = values
        .iter()
        .enumerate()
        .fold(F192::ZERO, |acc, (k, &v)| acc + eq_index(k, kinds) * v);
    Claim { point, value }
}

/// Verify a proof of `statement` against the circuit committed as `index_root`, down to the witness commitment it
/// names and two claims: it holds if both are true, one of that commitment and one of the circuit's.
pub fn verify(index_root: &Hash, statement: &Statement, proof: &Proof) -> Result<(Hash, Claims), VerifyError> {
    let transcript = VerifyError::Transcript;
    let mut vs = VerifierState::from_label(&label(index_root, statement), proof);
    let root = vs.next_root().map_err(transcript)?;
    let r = vs.sample_vec(N_VARS);
    let mask_sum = vs.next_scalar().map_err(transcript)?;
    let lambda = vs.sample();
    let (rho, claim) = zerocheck::verify_tables(&r, lambda * mask_sum, &mut vs).map_err(VerifyError::Zerocheck)?;
    let [a_eval, b_eval, gamma] = vs.next_scalars(3).map_err(transcript)?[..] else {
        unreachable!("three scalars")
    };
    let c_eval = claim + a_eval * b_eval + lambda * gamma;

    let batching = Batching::sample(&mut vs);
    let pins = pins(statement);
    let alpha = batching.alpha;
    let mask_sums = vs.next_scalars(3).map_err(transcript)?;
    let lambdas = mask_challenges(&mut vs);
    let mut claim = a_eval
        + alpha[1] * b_eval
        + alpha[2] * c_eval
        + alpha[3] * used_slots(&instance_tables(&rho)[0])
        + pin_target(&batching, &pins)
        + alpha[4] * gamma
        + lambdas[0] * mask_sums[0]
        + lambdas[1] * mask_sums[1]
        + lambdas[0] * lambdas[1] * mask_sums[2];
    let mut q = Vec::with_capacity(N_VARS);
    for _ in 0..N_VARS {
        let round = vs.next_round_poly(3, claim, None).map_err(transcript)?;
        let challenge = vs.sample();
        claim = poly_eval(&round, challenge);
        q.push(challenge);
    }
    q.reverse();
    let values = vs.next_scalars(N_KINDS).map_err(transcript)?;
    let kinds = vs.sample_vec(2);
    vs.finish().map_err(transcript)?;

    // The sumcheck ends on `comb~(q) * (z + l_0 m_0 + l_1 m_1 + l_0 l_1 m_2)~(q)`: one evaluation of `P`, its two
    // top coordinates at `l_k / (1 + l_k)`, scaled by `(1 + l_0)(1 + l_1)`.
    let comb = comb_at(&rho, &q, &batching, &pins, &values);
    let [d0, d1] = lambdas.map(|l| F192::ONE + l);
    if comb * d0 * d1 == F192::ZERO {
        return Err(VerifyError::Degenerate);
    }
    let inverse = (comb * d0 * d1).inv();
    let claims = Claims {
        witness: Claim {
            point: [
                &q[..],
                &[lambdas[0] * inverse * comb * d1, lambdas[1] * inverse * comb * d0],
            ]
            .concat(),
            value: claim * inverse,
        },
        index: index_claim(&rho, &q, &kinds, alpha[1], &values),
    };
    Ok((root, claims))
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::standalone::opening;
    use primitives::multilinear::mle_eval;
    use primitives::test_rng::Rng;

    fn secret(rng: &mut Rng) -> Secret {
        let mut bytes = || std::array::from_fn(|_| rng.next_u64() as u8);
        Secret {
            x: bytes(),
            siblings: std::array::from_fn(|_| bytes()),
            directions: 0xA5C3_0F96,
        }
    }

    fn masks(rng: &mut Rng) -> [Vec<F64>; 3] {
        std::array::from_fn(|_| (0..N_WIRES).map(|_| F64(rng.next_u64())).collect())
    }

    fn stacked(witness: &Witness, masks: &[Vec<F64>; 3]) -> Vec<F64> {
        [&witness.z, &masks[0], &masks[1], &masks[2]]
            .into_iter()
            .flatten()
            .copied()
            .collect()
    }

    /// The 32 bytes the wires from `base` hold.
    fn bytes_at(witness: &Witness, base: usize) -> [u8; 32] {
        std::array::from_fn(|byte| (0..8).fold(0, |acc, i| acc | (witness.z[base + 8 * byte + i].0 as u8) << i))
    }

    /// The hashes a witness reaches, whatever it was run on.
    fn reached(witness: &Witness) -> Statement {
        Statement {
            y: bytes_at(witness, wire(0, F_SLOT, 32 * OUT)),
            root: bytes_at(witness, wire(N_HASHES - 1, F_SLOT, 32 * OUT)),
        }
    }

    /// Whether a proof from `witness` leaves a false claim on its commitment.
    fn leaves_a_false_claim(circuit: &Circuit, statement: &Statement, witness: &Witness, rng: &mut Rng) -> bool {
        let masks = masks(rng);
        let (proof, _) = prove(circuit, &[1; 32], statement, &[2; 32], witness, &masks);
        let (_, claims) = verify(&[1; 32], statement, &proof).expect("a reduction");
        mle_eval(&stacked(witness, &masks), &claims.witness.point) != claims.witness.value
    }

    /// The circuit computes the hashes the statement names: its `y` and `root` wires are the native ones.
    #[test]
    fn circuit_computes_the_statement() {
        let mut rng = Rng::new(0xB1A2E);
        let secret = secret(&mut rng);
        let witness = Circuit::new().witness(&secret, &mut || rng.next_u64());
        assert!(witness.satisfied());
        assert_eq!(reached(&witness), secret.statement());
    }

    /// The only wires a row leaves free of the bit constraint are the hiding wires' `u` and `v`.
    #[test]
    fn only_hiding_wires_are_free_field_elements() {
        let circuit = Circuit::new();
        for (k, block) in circuit.blocks.iter().enumerate() {
            for local in (0..BLOCK).filter(|&l| l != CONST) {
                let free = block.a[local] == one(local) && block.b[local] == one(CONST);
                let hiding = k == S && HIDING[..2].iter().any(|&base| (base..base + N_HIDING).contains(&local));
                assert_eq!(free, hiding, "block {k}, wire {local}");
            }
        }
    }

    /// The verifier's closed form of the lincheck weight is the extension of the table the prover sums against,
    /// and that table is the claim it stands for: `(Az, Bz, Cz)` at `rho`, the constant wires, the pins, the mask.
    #[test]
    fn comb_is_the_linear_claim() {
        let mut rng = Rng::new(0xC0B);
        let circuit = Circuit::new();
        let (rho, q) = (rng.ext_vec(N_VARS), rng.ext_vec(N_VARS));
        let batching = Batching {
            alpha: {
                let alpha = rng.ext();
                std::array::from_fn(|i| (0..i).fold(F192::ONE, |acc, _| acc * alpha))
            },
            beta: rng.ext(),
            pi: rng.ext_vec(8),
        };
        let secret = secret(&mut rng);
        let pins = pins(&secret.statement());
        let (comb, marginals) = comb_table(&circuit, &rho, &batching, &pins);
        let local = eq_table(&q[..LOG_BLOCK]);
        let values = marginals.map(|m| pcs::ring_switch::inner_product_ext(&m, &local));
        let eq_q = eq_table(&q);
        let want = parallel::map_reduce(N_WIRES, || F192::ZERO, |i| comb[i] * eq_q[i], |x, y| x + y);
        assert_eq!(comb_at(&rho, &q, &batching, &pins, &values), want);

        let witness = circuit.witness(&secret, &mut || rng.next_u64());
        let alpha = batching.alpha;
        let coefficient = |j: usize| {
            let limb = |l: usize| witness.z[mask_wires().start + 3 * j + l].0;
            F192::new(limb(0), limb(1), limb(2))
        };
        let gamma = (0..N_VARS).fold(coefficient(0), |acc, i| {
            acc + rho[i] * (coefficient(1 + 2 * i) + rho[i] * coefficient(2 + 2 * i))
        });
        let eq_rho = eq_table(&rho);
        let c_eval = witness
            .c()
            .iter()
            .zip(&eq_rho)
            .fold(F192::ZERO, |acc, (&c, &e)| acc + c * e);
        let claim = mle_eval(&witness.a, &rho)
            + alpha[1] * mle_eval(&witness.b, &rho)
            + alpha[2] * c_eval
            + alpha[3] * used_slots(&instance_tables(&rho)[0])
            + pin_target(&batching, &pins)
            + alpha[4] * gamma;
        let sum = (0..N_WIRES).fold(F192::ZERO, |acc, i| acc + comb[i].mul_base(witness.z[i]));
        assert_eq!(sum, claim);
    }

    /// An honest proof leaves two true claims, which the commitments open, and is bound to its transcript.
    #[test]
    fn proof_leaves_true_claims() {
        let mut rng = Rng::new(0x3E3B);
        let circuit = Circuit::new();
        let index = circuit.index();
        let (index_root, _) = opening::commit(&index);
        let secret = secret(&mut rng);
        let statement = secret.statement();
        let witness = circuit.witness(&secret, &mut || rng.next_u64());
        let masks = masks(&mut rng);
        let table = committed(&witness, &masks, &mut || rng.next_u64());
        let (root, data) = opening::commit(&table);

        let (mut proof, claims) = prove(&circuit, &index_root, &statement, &root, &witness, &masks);
        let n_scalars = 2 + (2 * N_VARS + 4) + (2 * N_VARS + 3 + N_KINDS);
        assert_eq!(proof.stream.len(), n_scalars);
        assert_eq!(verify(&index_root, &statement, &proof), Ok((root, claims.clone())));

        let stacked = stacked(&witness, &masks);
        assert_eq!(mle_eval(&stacked, &claims.witness.point), claims.witness.value);
        assert_eq!(mle_eval(&index, &claims.index.point), claims.index.value);
        let hidden = hidden_point(&claims.witness);
        assert!(opening::verify(
            &root,
            &hidden,
            &opening::open(&table, &root, &data, &hidden)
        ));

        // Another statement, or another circuit, is another transcript.
        let mut wrong = [statement; 2];
        wrong[0].y[7] ^= 1;
        wrong[1].root[7] ^= 1;
        for (index_root, statement) in [(index_root, wrong[0]), (index_root, wrong[1]), ([3; 32], statement)] {
            let (_, other) = verify(&index_root, &statement, &proof).expect("a reduction");
            assert_ne!(other.witness.point, claims.witness.point);
        }

        // A local-matrix evaluation the prover made up is caught by the circuit's claim.
        for k in 0..N_KINDS {
            proof.stream[n_scalars - N_KINDS + k] += F192::ONE;
            let (_, tampered) = verify(&index_root, &statement, &proof).expect("a reduction");
            assert_ne!(
                mle_eval(&index, &tampered.index.point),
                tampered.index.value,
                "kind {k}"
            );
            proof.stream[n_scalars - N_KINDS + k] += F192::ONE;
        }

        // Nothing rides after the last message.
        proof.stream.push(F192::ONE);
        assert!(verify(&index_root, &statement, &proof).is_err());
    }

    /// Every public value is enforced, one at a time: a witness that satisfies every row but departs from the
    /// statement in one pinned input, or reaches other hashes than the statement's, leaves a false claim.
    #[test]
    fn each_pin_is_enforced() {
        let mut rng = Rng::new(0x9175);
        let circuit = Circuit::new();
        let secret = secret(&mut rng);
        let honest = |c: usize| secret.inputs(c);
        // A name, the inputs, and which public value to flip afterwards (1: `y`, 2: `root`).
        type Case<'a> = (&'a str, &'a dyn Fn(usize) -> Inputs, usize);
        let cases: [Case; 7] = [
            ("honest", &honest, 0),
            (
                "first constant",
                &|c| {
                    if c == 0 {
                        ([0x33; 32], false, secret.x)
                    } else {
                        honest(c)
                    }
                },
                0,
            ),
            (
                "second constant",
                &|c| {
                    if c == 1 {
                        ([0x33; 32], false, [0; 32])
                    } else {
                        honest(c)
                    }
                },
                0,
            ),
            (
                "first direction",
                &|c| {
                    if c == 0 {
                        (CONSTANTS[0], true, secret.x)
                    } else {
                        honest(c)
                    }
                },
                0,
            ),
            (
                "second direction",
                &|c| {
                    if c == 1 {
                        (CONSTANTS[1], true, [0; 32])
                    } else {
                        honest(c)
                    }
                },
                0,
            ),
            ("y", &honest, 1),
            ("root", &honest, 2),
        ];
        for (name, inputs, flip) in cases {
            let witness = circuit.run(inputs, &mut || rng.next_u64());
            assert!(witness.satisfied());
            let mut statement = reached(&witness);
            match flip {
                1 => statement.y[31] ^= 0x80,
                2 => statement.root[0] ^= 1,
                _ => {}
            }
            let false_claim = leaves_a_false_claim(&circuit, &statement, &witness, &mut rng);
            assert_eq!(false_claim, name != "honest", "{name}");
        }
    }

    /// The constant wire of a block is one, and the mask the zerocheck ran with is the committed one.
    #[test]
    fn constant_and_mask_wires_are_bound() {
        let mut rng = Rng::new(0x78);
        let circuit = Circuit::new();
        let secret = secret(&mut rng);
        let statement = secret.statement();
        let honest = circuit.witness(&secret, &mut || rng.next_u64());
        let copy = || Witness {
            z: honest.z.clone(),
            a: honest.a.clone(),
            b: honest.b.clone(),
            mask: honest.mask.clone(),
        };

        // A padding compression of zeros, its constant wires included, satisfies every row.
        let mut zeroed = copy();
        for table in [&mut zeroed.z, &mut zeroed.a, &mut zeroed.b] {
            table[wire(40, 0, 0)..wire(41, 0, 0)].fill(F64::ZERO);
        }
        assert!(zeroed.satisfied());
        assert!(leaves_a_false_claim(&circuit, &statement, &zeroed, &mut rng));

        let mut other_mask = copy();
        other_mask.z[mask_wires().start + 4] += F64(7);
        assert!(other_mask.satisfied());
        assert!(leaves_a_false_claim(&circuit, &statement, &other_mask, &mut rng));
    }

    /// The property [`committed`]'s layout rests on: whatever leaves an opening shows, the random low half of a
    /// lane makes its values there independent. Checked on a small commitment, for adjacent leaves and for random
    /// ones: the low coefficients' codewords, restricted to as many positions as there are coefficients, have full rank.
    #[test]
    fn random_low_half_masks_any_leaves() {
        use pcs::whir::{LOG_INV_RATE_0, commit};
        let log_n = 14;
        let lanes = 1usize << INITIAL_FOLDING_FACTOR;
        let half = (1usize << log_n) / lanes / 2;
        let codewords: Vec<Vec<F64>> = (0..half)
            .map(|coefficient| {
                let mut table = vec![F64::ZERO; 1 << log_n];
                table[coefficient] = F64::ONE;
                let (_, data) = commit(&table, log_n, INITIAL_FOLDING_FACTOR, LOG_INV_RATE_0);
                // The first block is the last lane of every leaf.
                data.codeword.chunks(lanes).map(|leaf| leaf[lanes - 1]).collect()
            })
            .collect();
        let mut rng = Rng::new(0x1EAF);
        let n_leaves = codewords[0].len();
        for adjacent in [true, false] {
            let mut leaves: Vec<usize> = if adjacent { (0..half).collect() } else { Vec::new() };
            while leaves.len() < half {
                let leaf = rng.next_u64() as usize % n_leaves;
                if !leaves.contains(&leaf) {
                    leaves.push(leaf);
                }
            }
            // Gaussian elimination: every column finds a pivot.
            let mut rows: Vec<Vec<F64>> = leaves
                .iter()
                .map(|&l| codewords.iter().map(|c| c[l]).collect())
                .collect();
            for col in 0..half {
                let pivot = (col..half).find(|&r| rows[r][col] != F64::ZERO).expect("full rank");
                rows.swap(col, pivot);
                let (inverse, pivot_row) = (rows[col][col].inv(), rows[col].clone());
                for row in rows.iter_mut().skip(col + 1) {
                    let factor = row[col] * inverse;
                    for (value, &p) in row.iter_mut().zip(&pivot_row) {
                        *value += factor * p;
                    }
                }
            }
        }
    }
}
