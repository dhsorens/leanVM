//! A zero-knowledge proof of one hash preimage and one Merkle path, 34 BLAKE2s compressions, as two sumchecks and
//! two plain evaluation claims. `crates/flock/membership.md` is the description; this is its prover and verifier.
//!
//! A wire is `local + 2^11 * slot + 2^16 * compression`: 64 compressions of 32 blocks of 2048 wires. A compression's
//! slots are one `S` block, twenty `H` blocks (half a round each) and one `F` block; the rest are empty.

use fiat_shamir::transcript::{Challenger, ProverState, Receiver, Transmitter, VerifierState};
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

    /// The eight or sixteen words at `base` copy wires of other blocks.
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
}

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

    /// Run the circuit on `secret`. `random` supplies the hiding wires.
    pub fn witness(&self, secret: &Secret, random: &mut dyn FnMut() -> u64) -> Witness {
        let mut z = vec![F64::ZERO; N_WIRES];
        let mut a = vec![F64::ZERO; N_WIRES];
        let mut b = vec![F64::ZERO; N_WIRES];
        let bit = |v: bool| F64(v as u64);
        for c in 0..1 << LOG_COMPRESSIONS {
            // The free inputs of this compression. Padding compressions hash zeros.
            let sibling = match c {
                0 | 1 => CONSTANTS[c],
                2..N_HASHES => secret.siblings[c - 2],
                _ => [0; 32],
            };
            let direction = (2..N_HASHES).contains(&c) && (secret.directions >> (c - 2)) & 1 == 1;
            let x = if c == 0 { secret.x } else { [0; 32] };
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
            }
        }
        debug_assert!((0..N_WIRES).all(|i| a[i] * b[i] == z[i]));
        Witness { z, a, b }
    }
}

/// The committed polynomial: the witness, then the mask, then (the second half) nothing.
///
/// Its opening must reveal one value only, so it is committed with a variable of random values below and one above,
/// the polynomial itself at `(0, ., 1)`: [`hidden_point`] is where a claim on it lands.
pub fn committed(witness: &Witness, mask: &[F64], random: &mut dyn FnMut() -> u64) -> Vec<F64> {
    assert_eq!(mask.len(), N_WIRES);
    let mut table: Vec<F64> = (0..8 * N_WIRES).map(|_| F64(random())).collect();
    for (i, &value) in witness.z.iter().chain(mask).enumerate() {
        table[2 * i + 4 * N_WIRES] = value;
    }
    table
}

/// A claim on `(z ‖ m)` as a claim on what [`committed`] returns.
pub fn hidden_point(claim: &Claim) -> Claim {
    Claim {
        point: [F192::ZERO]
            .into_iter()
            .chain(claim.point.iter().copied())
            .chain([F192::ONE])
            .collect(),
        value: claim.value,
    }
}

/// What a proof leaves to the two commitments.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Claims {
    /// On `(z ‖ m)`, `N_VARS + 1` variables.
    pub witness: Claim,
    /// On [`Circuit::index`].
    pub index: Claim,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum VerifyError {
    Zerocheck(zerocheck::VerifyError),
    Transcript(fiat_shamir::transcript::Error),
    /// The witness and the mask meet the final claim with weights summing to zero.
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
    (comb, marginals)
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
    same_compression * (blocks + constants) + alpha[2] * eq_eval(rho, q) + wiring + pinned
}

/// The mask's share of the zerocheck: its summand is `eq(tau, x) * m(x)` under the zerocheck's own `eq(r, x)`.
struct Mask {
    /// `m`, with the bound variables folded away.
    table: Vec<F192>,
    r: Vec<F192>,
    tau: Vec<F192>,
    /// `eq(tau, .)` on the bound variables.
    bound: F192,
}

impl Mask {
    /// `sum_x' eq(r, x') eq(tau, x') m(b, x')` for `b = 0, 1`, over the variables past `i`.
    fn halves(&self, i: usize) -> (F192, F192) {
        let mut weights = vec![F192::ONE];
        for (&r, &tau) in self.r[i + 1..].iter().zip(&self.tau[i + 1..]) {
            let (lo, hi) = ((F192::ONE + r) * (F192::ONE + tau), r * tau);
            let len = weights.len();
            weights.extend_from_within(..);
            for k in 0..len {
                weights[len + k] = weights[k] * hi;
                weights[k] *= lo;
            }
        }
        parallel::map_reduce(
            weights.len(),
            || (F192::ZERO, F192::ZERO),
            |k| (weights[k] * self.table[2 * k], weights[k] * self.table[2 * k + 1]),
            |x, y| (x.0 + y.0, x.1 + y.1),
        )
    }

    /// The whole sum.
    fn sum(&self) -> F192 {
        let (q0, q1) = self.halves(0);
        let (r, tau) = (self.r[0], self.tau[0]);
        (F192::ONE + r) * (F192::ONE + tau) * q0 + r * tau * q1
    }

    fn bind(&mut self, chi: F192) {
        let table = &self.table;
        self.table = parallel::map_collect(table.len() / 2, |k| {
            table[2 * k] + chi * (table[2 * k] + table[2 * k + 1])
        });
        self.bound *= F192::ONE + self.tau[self.r.len() - self.table.len().trailing_zeros() as usize - 1] + chi;
    }

    /// `(G(1), G(inf))` of the round after `point`, where `G(X) = bound * eq(tau_i, X) * (q0 + X (q0 + q1))`.
    fn round(&mut self, point: &[F192]) -> (F192, F192) {
        if let Some(&chi) = point.last() {
            self.bind(chi);
        }
        let i = point.len();
        let (q0, q1) = self.halves(i);
        (self.bound * self.tau[i] * q1, self.bound * (q0 + q1))
    }
}

fn lift(table: &[F64]) -> Vec<F192> {
    parallel::map_collect(table.len(), |i| F192::from(table[i]))
}

/// Prove `statement` from a witness of it. The caller has bound the statement and both commitments into `ps`, and
/// committed `(witness.z ‖ mask)`, `mask` uniformly random.
pub fn prove(
    circuit: &Circuit,
    statement: &Statement,
    witness: &Witness,
    mask: &[F64],
    ps: &mut ProverState,
) -> Claims {
    // Zerocheck, masked.
    let span = tracing::info_span!("Zerocheck").entered();
    let r = ps.sample_vec(N_VARS);
    let tau = ps.sample_vec(N_VARS);
    let mut masking = Mask {
        table: lift(mask),
        r: r.clone(),
        tau: tau.clone(),
        bound: F192::ONE,
    };
    let mask_sum = masking.sum();
    ps.add_scalar(mask_sum);
    let lambda = ps.sample();
    let (rho, a_eval, b_eval, claim) = zerocheck::prove_tables(
        lift(&witness.a),
        lift(&witness.b),
        lift(&witness.z),
        &r,
        lambda * mask_sum,
        &mut |point| {
            let (g1, g_inf) = masking.round(point);
            (lambda * g1, lambda * g_inf)
        },
        ps,
    );
    masking.bind(rho[N_VARS - 1]);
    let mu = masking.table[0];
    ps.add_scalars(&[a_eval, b_eval, mu]);
    let c_eval = claim + a_eval * b_eval + lambda * eq_eval(&tau, &rho) * mu;
    drop(span);

    // Lincheck over every wire, the mask's claim riding it.
    let span = tracing::info_span!("Lincheck").entered();
    let batching = Batching::sample(ps);
    let pins = pins(statement);
    let (comb, marginals) = comb_table(circuit, &rho, &batching, &pins);
    let alpha = batching.alpha;
    let mut mask_weight = eq_table(&rho);
    parallel::for_each_mut(&mut mask_weight, |_, e| *e *= alpha[4]);
    debug_assert_eq!(
        comb.iter()
            .zip(&witness.z)
            .fold(F192::ZERO, |acc, (&c, &z)| acc + c.mul_base(z)),
        a_eval
            + alpha[1] * b_eval
            + alpha[2] * c_eval
            + alpha[3] * used_slots(&instance_tables(&rho)[0])
            + pin_target(&batching, &pins)
    );
    let (q, finals) = lincheck::sum_of_products_sumcheck(vec![(comb, lift(&witness.z)), (mask_weight, lift(mask))], ps);
    let local = eq_table(&q[..LOG_BLOCK]);
    let values = marginals.map(|marginal| pcs::ring_switch::inner_product_ext(&marginal, &local));
    ps.add_scalars(&values);
    let kinds = ps.sample_vec(2);
    drop(span);

    let [(w0, z_eval), (w1, mask_eval)] = finals[..] else {
        unreachable!("two products")
    };
    let t = w1 * (w0 + w1).inv();
    Claims {
        witness: Claim {
            point: q.iter().copied().chain([t]).collect(),
            value: z_eval + t * (z_eval + mask_eval),
        },
        index: index_claim(&rho, &q, &kinds, alpha[1], &values),
    }
}

fn index_claim(rho: &[F192], q: &[F192], kinds: &[F192], alpha: F192, values: &[F192]) -> Claim {
    let point = [&rho[..LOG_BLOCK], &q[..LOG_BLOCK], kinds, &[alpha]].concat();
    let value = values
        .iter()
        .enumerate()
        .fold(F192::ZERO, |acc, (k, &v)| acc + eq_index(k, kinds) * v);
    Claim { point, value }
}

/// Verify a proof of `statement` down to its two claims: it holds if both are true of the committed polynomials.
pub fn verify(statement: &Statement, vs: &mut VerifierState<'_>) -> Result<Claims, VerifyError> {
    let transcript = VerifyError::Transcript;
    let r = vs.sample_vec(N_VARS);
    let tau = vs.sample_vec(N_VARS);
    let mask_sum = vs.next_scalar().map_err(transcript)?;
    let lambda = vs.sample();
    let (rho, claim) = zerocheck::verify_tables(&r, lambda * mask_sum, vs).map_err(VerifyError::Zerocheck)?;
    let [a_eval, b_eval, mu] = vs.next_scalars(3).map_err(transcript)?[..] else {
        unreachable!("three scalars")
    };
    let c_eval = claim + a_eval * b_eval + lambda * eq_eval(&tau, &rho) * mu;

    let batching = Batching::sample(vs);
    let pins = pins(statement);
    let alpha = batching.alpha;
    let mut claim = a_eval
        + alpha[1] * b_eval
        + alpha[2] * c_eval
        + alpha[3] * used_slots(&instance_tables(&rho)[0])
        + pin_target(&batching, &pins)
        + alpha[4] * mu;
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

    let w0 = comb_at(&rho, &q, &batching, &pins, &values);
    let w1 = alpha[4] * eq_eval(&rho, &q);
    if w0 + w1 == F192::ZERO {
        return Err(VerifyError::Degenerate);
    }
    let inverse = (w0 + w1).inv();
    Ok(Claims {
        witness: Claim {
            point: q.iter().copied().chain([w1 * inverse]).collect(),
            value: claim * inverse,
        },
        index: index_claim(&rho, &q, &kinds, alpha[1], &values),
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::standalone::opening;
    use primitives::multilinear::mle_eval;
    use primitives::test_rng::Rng;

    const LABEL: &[u8] = b"membership-test";

    fn secret(rng: &mut Rng) -> Secret {
        let mut bytes = || std::array::from_fn(|_| rng.next_u64() as u8);
        Secret {
            x: bytes(),
            siblings: std::array::from_fn(|_| bytes()),
            directions: 0xA5C3_0F96,
        }
    }

    /// The circuit computes the hashes the statement names: its `y` and `root` wires are the native ones.
    #[test]
    fn circuit_computes_the_statement() {
        let mut rng = Rng::new(0xB1A2E);
        let secret = secret(&mut rng);
        let statement = secret.statement();
        let witness = Circuit::new().witness(&secret, &mut || rng.next_u64());
        assert!((0..N_WIRES).all(|i| witness.a[i] * witness.b[i] == witness.z[i]));
        for (base, bits) in pins(&statement) {
            for (j, &bit) in bits.iter().enumerate() {
                assert_eq!(witness.z[base + j], F64(bit as u64), "wire {base} + {j}");
            }
        }
    }

    /// The verifier's closed form of the lincheck weight is the extension of the table the prover sums against.
    #[test]
    fn comb_closed_form_matches_its_table() {
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
        let pins = pins(&secret(&mut rng).statement());
        let (comb, marginals) = comb_table(&circuit, &rho, &batching, &pins);
        let local = eq_table(&q[..LOG_BLOCK]);
        let values = marginals.map(|m| pcs::ring_switch::inner_product_ext(&m, &local));
        let eq_q = eq_table(&q);
        let want = parallel::map_reduce(N_WIRES, || F192::ZERO, |i| comb[i] * eq_q[i], |x, y| x + y);
        assert_eq!(comb_at(&rho, &q, &batching, &pins, &values), want);
    }

    /// An honest proof leaves two true claims, and a different statement turns the witness claim false.
    #[test]
    fn proof_leaves_true_claims() {
        let mut rng = Rng::new(0x3E3B);
        let circuit = Circuit::new();
        let secret = secret(&mut rng);
        let statement = secret.statement();
        let witness = circuit.witness(&secret, &mut || rng.next_u64());
        let mask: Vec<F64> = (0..N_WIRES).map(|_| F64(rng.next_u64())).collect();

        let mut ps = ProverState::from_label(LABEL);
        let claims = prove(&circuit, &statement, &witness, &mask, &mut ps);
        let proof = ps.into_proof();
        assert_eq!(proof.stream.len(), (2 * N_VARS + 4) + (2 * N_VARS + N_KINDS));
        let verify_with = |statement: &Statement| {
            let mut vs = VerifierState::from_label(LABEL, &proof);
            let claims = verify(statement, &mut vs);
            assert!(vs.finish().is_ok());
            claims
        };
        assert_eq!(verify_with(&statement), Ok(claims.clone()));

        let stacked: Vec<F64> = witness.z.iter().chain(&mask).copied().collect();
        assert_eq!(mle_eval(&stacked, &claims.witness.point), claims.witness.value);
        let index = circuit.index();
        assert_eq!(mle_eval(&index, &claims.index.point), claims.index.value);

        let mut wrong = statement;
        wrong.root[7] ^= 1;
        let claim = verify_with(&wrong).expect("a reduction").witness;
        assert_ne!(mle_eval(&stacked, &claim.point), claim.value);

        // The hidden commitment answers the same claim.
        let table = committed(&witness, &mask, &mut || rng.next_u64());
        let (root, data) = opening::commit(&table);
        let hidden = hidden_point(&claims.witness);
        assert!(opening::verify(
            &root,
            &hidden,
            &opening::open(&table, &root, &data, &hidden)
        ));
    }
}
