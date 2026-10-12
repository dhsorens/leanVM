//! A zero-knowledge proof of one hash preimage and one Merkle path, 34 BLAKE2s compressions, as two sumchecks and
//! two plain evaluation claims. `crates/flock/membership.md` is the description; this is its prover and verifier.
//!
//! A wire is `local + 2^11 * slot + 2^16 * compression`: 64 compressions of 32 blocks of 2048 wires. A compression's
//! slots are one `S` block, twenty `H` blocks (half a round each) and one `F` block; the rest are empty.

use std::ops::{Add, Mul};

use fiat_shamir::merkle::{Hash, scalars_to_hash};
use fiat_shamir::transcript::{
    Challenger, Error as TranscriptError, Proof, ProverState, Receiver, Transmitter, VerifierState,
};
use pcs::whir::INITIAL_FOLDING_FACTOR;
use primitives::field::{F64, F192};
use primitives::hash::{IV, PARAM_IV, SIGMA, hash};
use primitives::multilinear::eq_table;

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
/// `F`: the zerocheck's mask, an aligned run of 256 wires: coefficient `j`'s limb `l` at `4 j + l`. Compression 0's
/// are free, in no row and on no row's right-hand side (`C` is the identity but for them); the others are zero.
const MASK: usize = 40 * 32;
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

/// Where compression `c` reads its previous hash: the one before it, or `x` for the two hashes of `x`. The padding
/// compressions go on up the path, which keeps the rule one carry chain.
fn previous_source(c: usize) -> (usize, usize) {
    match c {
        0 | 1 => (0, AUX),
        _ => (c - 1, OUT),
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

impl Statement {
    /// `y` then `root`, each as its two [`halves`].
    pub fn halves(&self) -> [F192; 4] {
        let ([y0, y1], [root0, root1]) = (halves(&self.y), halves(&self.root));
        [y0, y1, root0, root1]
    }
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
        c[mask_block()].fill(F192::ZERO);
        c
    }

    fn satisfied(&self) -> bool {
        (0..N_WIRES).all(|i| {
            self.a[i] * self.b[i]
                == if mask_block().contains(&i) {
                    F64::ZERO
                } else {
                    self.z[i]
                }
        })
    }
}

/// The wires `C` is zero on: the mask's run.
fn mask_block() -> std::ops::Range<usize> {
    wire(0, F_SLOT, MASK)..wire(0, F_SLOT, MASK) + 256
}

/// The wire holding limb `limb` of the mask's coefficient `j`.
fn mask_wire(j: usize, limb: usize) -> usize {
    wire(0, F_SLOT, MASK + 4 * j + limb)
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
                if k == F && c == 0 {
                    for j in 0..MASK_COEFFS {
                        let limbs: [u64; 3] = std::array::from_fn(|_| random());
                        for (limb, &value) in limbs.iter().enumerate() {
                            z[mask_wire(j, limb)] = F64(value);
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
    Transcript(TranscriptError),
    /// A denominator of the final claim is zero.
    Degenerate,
}

/// What the verifier computes with: the field, or a recorder of its operations, which is how the EVM contract is
/// written (`crates/evm`).
pub trait Scalar: Copy + Add<Output = Self> + Mul<Output = Self> {
    fn constant(value: F192) -> Self;
    /// `self^(2^64)`.
    fn frobenius(self) -> Self;
    /// A recorder answers yes, and records that the verifier requires it.
    fn is_nonzero(self) -> bool;
}

impl Scalar for F192 {
    fn constant(value: F192) -> Self {
        value
    }

    fn frobenius(self) -> Self {
        F192::frobenius(self)
    }

    fn is_nonzero(self) -> bool {
        self != F192::ZERO
    }
}

/// Where the verifier reads the statement and the proof, and draws its challenges.
pub trait Channel<S> {
    /// `y` then `root`, each as its two halves ([`halves`]).
    fn statement(&mut self) -> [S; 4];
    /// The witness commitment, as the two scalars it rides the proof as.
    fn next_root(&mut self) -> Result<[S; 2], TranscriptError>;
    fn next(&mut self) -> Result<S, TranscriptError>;
    fn sample(&mut self) -> S;
    /// Nothing is left unread.
    fn finish(&mut self) -> Result<(), TranscriptError>;
}

/// What [`reduce`] leaves: the witness commitment's two scalars, and each claim's point and value.
pub struct Reduced<S> {
    pub root: [S; 2],
    pub witness: (Vec<S>, S),
    pub index: (Vec<S>, S),
}

fn unity<S: Scalar>() -> S {
    S::constant(F192::ONE)
}

fn sum<S: Scalar>(terms: impl Iterator<Item = S>) -> S {
    terms.fold(S::constant(F192::ZERO), |acc, t| acc + t)
}

/// `eq(point, i)` for every `i`, bit `k` of `i` against `point[k]`.
fn eq_points<S: Scalar>(point: &[S]) -> Vec<S> {
    let mut table = vec![unity()];
    for &p in point {
        for i in 0..table.len() {
            let high = table[i] * p;
            table.push(high);
            table[i] = table[i] + high;
        }
    }
    table
}

/// `eq(a, b)`: a factor is `a b + (1 + a)(1 + b) = 1 + a + b`.
fn eq_of<S: Scalar>(a: &[S], b: &[S]) -> S {
    a.iter()
        .zip(b)
        .fold(unity(), |acc, (&x, &y)| acc * (unity::<S>() + x + y))
}

fn eq_index<S: Scalar>(index: usize, point: &[S]) -> S {
    point.iter().enumerate().fold(unity(), |acc, (k, &x)| {
        acc * if (index >> k) & 1 == 1 { x } else { unity::<S>() + x }
    })
}

/// `x^-1` for a nonzero `x`, by its norm to `GF(2^64)`: `m = x^(2^64) x^(2^128)` makes `x m` the norm, whose
/// inverse is its power `2^64 - 2`.
fn inverse<S: Scalar>(x: S) -> S {
    let m = x.frobenius() * x.frobenius().frobenius();
    let mut power = x * m;
    power = power * power;
    let mut norm_inverse = power;
    for _ in 2..64 {
        power = power * power;
        norm_inverse = norm_inverse * power;
    }
    m * norm_inverse
}

/// A 32-byte value as two field elements, sixteen bytes each read as a big-endian number in the low two limbs.
pub fn halves(bytes: &[u8; 32]) -> [F192; 2] {
    std::array::from_fn(|h| {
        let v = u128::from_be_bytes(bytes[16 * h..16 * h + 16].try_into().unwrap());
        F192::new(v as u64, (v >> 64) as u64, 0)
    })
}

/// The weight of bit `j` of a half, so that the bits' weighted sum is [`halves`]' element. The wires hold bits, and
/// these weights are independent over `GF(2)`, so the sum determines every one of them.
fn bit_weight(j: usize) -> F192 {
    let position = 8 * (15 - j / 8) + j % 8;
    F192::new(
        if position < 64 { 1 << position } else { 0 },
        if position < 64 { 0 } else { 1 << (position - 64) },
        0,
    )
}

/// The first wire of each 256-bit public value: the two constants, `y`, `root`. Each is 256-aligned.
fn word_pins() -> [usize; 4] {
    [
        wire(0, 0, 32 * SIB),
        wire(1, 0, 32 * SIB),
        wire(0, F_SLOT, 32 * OUT),
        wire(N_HASHES - 1, F_SLOT, 32 * OUT),
    ]
}

/// The bits that are zero: the direction of the two hashes of `x`.
fn zero_pins() -> [usize; 2] {
    [wire(0, 0, DIRECTION), wire(1, 0, DIRECTION)]
}

/// The lincheck's batching: powers of `alpha` over its claims, the mask's weight in the third, and a power of `beta`
/// for each half of a 256-bit public value, then for each zero bit.
struct Batching<S> {
    alpha: [S; 4],
    /// `alpha^2 lambda`: the zerocheck's third claim is `(C z)~(rho) + lambda g(rho)`.
    mask: S,
    pins: Vec<S>,
}

impl<S: Scalar> Batching<S> {
    fn new(alpha: S, beta: S, lambda: S) -> Self {
        let n = 2 * word_pins().len() + zero_pins().len();
        let alpha: [S; 4] = std::array::from_fn(|i| (0..i).fold(unity(), |acc, _| acc * alpha));
        Self {
            alpha,
            mask: alpha[2] * lambda,
            pins: std::iter::successors(Some(beta), |&power| Some(power * beta))
                .take(n)
                .collect(),
        }
    }

    /// What the pinned wires, weighted, must sum to. `statement` is [`Channel::statement`]'s.
    fn pin_target(&self, statement: [S; 4]) -> S {
        let constants = CONSTANTS.iter().flat_map(halves).map(S::constant);
        sum(constants
            .chain(statement)
            .zip(&self.pins)
            .map(|(value, &power)| power * value))
    }
}

/// The eq table of a point over the slots.
fn slot_table<S: Scalar>(point: &[S]) -> Vec<S> {
    eq_points(&point[LOG_BLOCK..LOG_BLOCK + LOG_SLOTS])
}

/// The eq weight of the used slots, which is what the constant wires sum to.
fn used_slots<S: Scalar>(slots: &[S]) -> S {
    sum(slots[..N_SLOTS].iter().copied())
}

/// The weight of each block type in the lincheck's weight at `q`: its slots' `eq(rho, slot) eq(q, slot)`.
fn kind_weights<S: Scalar>(rho: &[S], q: &[S]) -> [S; N_KINDS] {
    let (slots_r, slots_q) = (slot_table(rho), slot_table(q));
    std::array::from_fn(|k| {
        sum((0..N_SLOTS)
            .filter(|&slot| kind(slot) == Some(k))
            .map(|slot| slots_r[slot] * slots_q[slot]))
    })
}

/// The lincheck's weight on every wire, and each block type's column marginal `(A + alpha B)^T eq(rho_local, .)`.
fn comb_table(circuit: &Circuit, rho: &[F192], batching: &Batching<F192>) -> (Vec<F192>, [Vec<F192>; N_KINDS]) {
    let local = eq_table(&rho[..LOG_BLOCK]);
    let (slots, compressions) = (slot_table(rho), eq_table(&rho[LOG_BLOCK + LOG_SLOTS..]));
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
    for (r, base) in word_pins().into_iter().enumerate() {
        for j in 0..256 {
            comb[base + j] += batching.pins[2 * r + j / 128] * bit_weight(j % 128);
        }
    }
    for (r, at) in zero_pins().into_iter().enumerate() {
        comb[at] += batching.pins[2 * word_pins().len() + r];
    }
    // The mask's run is out of `C z`, and a mask wire carries its weight in the mask's value.
    let unit = compressions[0] * slots[F_SLOT];
    for at in mask_block() {
        comb[at] += alpha[2] * unit * local[at % BLOCK];
    }
    for (j, weight) in mask_weights(rho).into_iter().enumerate() {
        for (limb, power) in limb_weights().into_iter().enumerate() {
            comb[mask_wire(j, limb)] += batching.mask * weight * power;
        }
    }
    (comb, marginals)
}

/// The weight of each mask coefficient in the mask's value at `rho`.
fn mask_weights<S: Scalar>(rho: &[S]) -> Vec<S> {
    [unity()]
        .into_iter()
        .chain(rho.iter().flat_map(|&x| [x, x * x]))
        .collect()
}

/// A coefficient is its three limbs under the field's basis over `GF(2^64)`.
fn limb_weights() -> [F192; 3] {
    [F192::ONE, F192::Y, F192::Y.square()]
}

/// [`comb_table`]'s multilinear extension at `q`, from the wiring and from `local`: the three local matrices at
/// `(rho, q)`, summed under their [`kind_weights`].
fn comb_at<S: Scalar>(rho: &[S], q: &[S], batching: &Batching<S>, local: S) -> S {
    let alpha = batching.alpha;
    let (slots_r, slots_q) = (slot_table(rho), slot_table(q));
    // A local index is a bit, then a word.
    let (words_r, words_q) = (eq_points(&rho[5..LOG_BLOCK]), eq_points(&q[5..LOG_BLOCK]));
    let same_bit = eq_of(&rho[..5], &q[..5]);
    let same_compression = eq_of(&rho[LOG_BLOCK + LOG_SLOTS..], &q[LOG_BLOCK + LOG_SLOTS..]);

    // The constant wire of every used block.
    let constants = alpha[3] * eq_index(CONST, &q[..LOG_BLOCK]) * sum(kind_weights(rho, q).into_iter());

    // The wiring: state words from the previous slot, message words from slot 0, the previous hash from another F.
    let words =
        |from: usize, to: &dyn Fn(usize) -> usize, n: usize| sum((0..n).map(|k| words_r[from + k] * words_q[to(k)]));
    // Slot 1 reads the state as it is, the others rotated one way or the other.
    let rotations: [S; 3] = std::array::from_fn(|case| words(STATE_IN, &|k| OUT + state_source(case + 1, k), 16));
    let state = sum((1..N_SLOTS)
        .map(|slot| slots_r[slot] * slots_q[slot - 1] * rotations[if slot == 1 { 0 } else { 1 + slot % 2 }]));
    let message = slots_q[0]
        * sum((1..F_SLOT).map(|slot| slots_r[slot] * words(AUX, &|p| STATE_IN + message_source(slot, p), 8)));
    let from_base = |base: usize| words(AUX, &|k| base + k, 8);
    let (from_hash, from_x) = (from_base(OUT), from_base(AUX));
    // The previous hash: compression `c` reads `c - 1`, a carry chain over the compression's bits, but for
    // compression 1, which reads `x` as compression 0 does.
    let (comp_r, comp_q) = (&rho[LOG_BLOCK + LOG_SLOTS..], &q[LOG_BLOCK + LOG_SLOTS..]);
    let mut above = [unity::<S>(); LOG_COMPRESSIONS];
    for k in (0..LOG_COMPRESSIONS - 1).rev() {
        above[k] = above[k + 1] * (unity::<S>() + comp_r[k + 1] + comp_q[k + 1]);
    }
    let mut below = unity::<S>();
    let mut successor = S::constant(F192::ZERO);
    for k in 0..LOG_COMPRESSIONS {
        successor = successor + below * comp_r[k] * (unity::<S>() + comp_q[k]) * above[k];
        below = below * (unity::<S>() + comp_r[k]) * comp_q[k];
    }
    let to_first = eq_index(0, comp_q);
    let (first, second) = (eq_index(0, comp_r), eq_index(1, comp_r));
    let previous = slots_r[0]
        * slots_q[F_SLOT]
        * ((successor + second * to_first) * from_hash + (first + second) * to_first * from_x);
    let wiring = same_bit * (same_compression * (state + message) + previous);

    // A half's bit weights are a product over the bits of the bit's position: `x^(2^k)` for bit `k` under 6, the
    // field's second basis element for bit 6. The position keeps the low three index bits and flips the others.
    let power = |k: usize| S::constant(F192::new(1 << (1 << k), 0, 0));
    let packed = (0..6).fold(q[6] + (unity::<S>() + q[6]) * S::constant(F192::Y), |acc, k| {
        let (set, clear) = if k < 3 {
            (q[k], unity::<S>() + q[k])
        } else {
            (unity::<S>() + q[k], q[k])
        };
        acc * (clear + set * power(k))
    });
    let word_pins = word_pins();
    let pinned = packed
        * sum(word_pins.iter().enumerate().map(|(r, base)| {
            let halves = batching.pins[2 * r] + q[7] * (batching.pins[2 * r] + batching.pins[2 * r + 1]);
            eq_index(base >> 8, &q[8..]) * halves
        }))
        + sum(zero_pins()
            .iter()
            .enumerate()
            .map(|(r, &at)| batching.pins[2 * word_pins.len() + r] * eq_index(at, q)));

    // The mask's run of 256: all of it leaves `C z`, and a coefficient's limb enters the mask's value.
    let run = mask_block().start >> 8;
    let limbs = sum(limb_weights()
        .into_iter()
        .enumerate()
        .map(|(limb, power)| S::constant(power) * eq_index(limb, &q[..2])));
    let value = limbs * sum(mask_weights(rho).iter().zip(eq_points(&q[2..8])).map(|(&w, e)| w * e));
    let mask = eq_index(run, &q[8..])
        * (batching.mask * value + alpha[2] * eq_index(run, &rho[8..]) * eq_of(&rho[..8], &q[..8]));
    same_compression * (local + constants) + alpha[2] * eq_of(rho, q) + wiring + pinned + mask
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
pub fn label(index_root: &Hash, statement: &Statement) -> Vec<u8> {
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
    let mut ps = ProverState::keccak(&label(index_root, statement));
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
    ps.add_scalars(&[a_eval, b_eval]);
    drop(span);

    // Lincheck on the witness plus a combination of the masks that is a uniformly random table.
    let span = tracing::info_span!("Lincheck").entered();
    let batching = Batching::new(ps.sample(), ps.sample(), lambda);
    let (comb, marginals) = comb_table(circuit, &rho, &batching);
    let alpha = batching.alpha;
    let mask_sums = masks
        .each_ref()
        .map(|m| parallel::map_reduce(N_WIRES, || F192::ZERO, |i| comb[i].mul_base(m[i]), |x, y| x + y));
    ps.add_scalars(&mask_sums);
    // The three masks enter with `mu, mu^2, mu^3`, a basis of the field over `GF(2^64)` unless `mu` is in it.
    let mu = ps.sample();
    assert!(mu != F192::ONE, "a mask challenge of 1");
    let weights = [mu, mu * mu, mu * mu * mu];
    let masked = parallel::map_collect(N_WIRES, |i| {
        (0..3).fold(F192::from(witness.z[i]), |acc, k| {
            acc + weights[k].mul_base(masks[k][i])
        })
    });
    let (q, _, masked_eval, _) = lincheck::product_sumcheck(comb, masked, 0, &mut ps);
    let local = eq_table(&q[..LOG_BLOCK]);
    let values = marginals.map(|marginal| pcs::ring_switch::inner_product_ext(&marginal, &local));
    let weights = kind_weights(&rho, &q);
    let local = sum(weights.iter().zip(&values).map(|(&w, &v)| w * v));
    ps.add_scalar(local);
    drop(span);

    let [d0, d1] = [F192::ONE + mu, F192::ONE + mu * mu];
    let [u0, u1] = [weights[S] + weights[H], weights[S] + weights[F]];
    assert!(u0 * u1 != F192::ZERO, "a degenerate block weight");
    let index = index_claim(&rho, &q, alpha[1], weights, local, (u0 * u1).inv());
    let claims = Claims {
        witness: Claim {
            point: [&q[..], &[mu * d0.inv(), mu * mu * d1.inv()]].concat(),
            value: masked_eval * (d0 * d1).inv(),
        },
        index: Claim {
            point: index.0,
            value: index.1,
        },
    };
    (ps.into_proof(), claims)
}

/// The circuit's claim. The three local matrices enter the lincheck's weight under `weights`, and that sum,
/// `local`, is one evaluation of the committed table scaled: the type's two coordinates at `a`, `b` with
/// `a / (1 + a) = w_H / w_S` and `b / (1 + b) = w_F / w_S`. `inverse` is that of `(w_S + w_H)(w_S + w_F)`.
fn index_claim<S: Scalar>(rho: &[S], q: &[S], alpha: S, weights: [S; N_KINDS], local: S, inverse: S) -> (Vec<S>, S) {
    let kinds = [
        weights[H] * (weights[S] + weights[F]) * inverse,
        weights[F] * (weights[S] + weights[H]) * inverse,
    ];
    let point = [&rho[..LOG_BLOCK], &q[..LOG_BLOCK], &kinds, &[alpha]].concat();
    (point, local * weights[S] * inverse)
}

/// The verifier, on any [`Scalar`]: the proof read from `channel`, down to the witness commitment it names and the
/// two claims. Every step is the same whatever the proof holds, but for the final rejection.
pub fn reduce<S: Scalar>(channel: &mut impl Channel<S>) -> Result<Reduced<S>, VerifyError> {
    let transcript = VerifyError::Transcript;
    let root = channel.next_root().map_err(transcript)?;

    // Zerocheck: a round sends its polynomial without the eq factor and without its constant, which the claim fixes.
    let r: Vec<S> = (0..N_VARS).map(|_| channel.sample()).collect();
    let mask_sum = channel.next().map_err(transcript)?;
    let lambda = channel.sample();
    let mut claim = lambda * mask_sum;
    let mut rho = Vec::with_capacity(N_VARS);
    for &r in &r {
        let (c1, c2) = (channel.next().map_err(transcript)?, channel.next().map_err(transcript)?);
        let c0 = claim + r * (c1 + c2);
        let x = channel.sample();
        claim = c0 + x * (c1 + x * c2);
        rho.push(x);
    }
    let a_eval = channel.next().map_err(transcript)?;
    let b_eval = channel.next().map_err(transcript)?;
    // The third claim, `(C z)~(rho) + lambda g(rho)`, is what the final claim leaves: the mask's value is not sent.
    let c_eval = claim + a_eval * b_eval;

    let batching = Batching::new(channel.sample(), channel.sample(), lambda);
    let alpha = batching.alpha;
    let mut mask_sums = Vec::with_capacity(3);
    for _ in 0..3 {
        mask_sums.push(channel.next().map_err(transcript)?);
    }
    let mu = channel.sample();
    let mu2 = mu * mu;
    let mut claim = a_eval
        + alpha[1] * b_eval
        + alpha[2] * c_eval
        + alpha[3] * used_slots(&slot_table(&rho))
        + batching.pin_target(channel.statement())
        + mu * mask_sums[0]
        + mu2 * mask_sums[1]
        + mu * mu2 * mask_sums[2];
    // Lincheck: a round sends its polynomial without its linear coefficient, which the claim fixes.
    let mut q = Vec::with_capacity(N_VARS);
    for _ in 0..N_VARS {
        let (c0, c2) = (channel.next().map_err(transcript)?, channel.next().map_err(transcript)?);
        let c1 = claim + c2;
        let x = channel.sample();
        claim = c0 + x * (c1 + x * c2);
        q.push(x);
    }
    q.reverse();
    let local = channel.next().map_err(transcript)?;
    channel.finish().map_err(transcript)?;

    // The sumcheck ends on `comb~(q) * (z + mu m_0 + mu^2 m_1 + mu^3 m_2)~(q)`: one evaluation of `P`, its two top
    // coordinates at `mu / (1 + mu)` and `mu^2 / (1 + mu^2)`, scaled by `(1 + mu)(1 + mu^2)`.
    let comb = comb_at(&rho, &q, &batching, local);
    let weights = kind_weights(&rho, &q);
    let [d0, d1] = [unity::<S>() + mu, unity::<S>() + mu2];
    let [u0, u1] = [weights[S] + weights[H], weights[S] + weights[F]];
    // One inversion serves both claims.
    let (scale, kinds) = (comb * d0 * d1, u0 * u1);
    if !(scale * kinds).is_nonzero() {
        return Err(VerifyError::Degenerate);
    }
    let both = inverse(scale * kinds);
    let scale_inverse = both * kinds;
    let point = [
        &q[..],
        &[mu * scale_inverse * comb * d1, mu2 * scale_inverse * comb * d0],
    ]
    .concat();
    Ok(Reduced {
        root,
        witness: (point, claim * scale_inverse),
        index: index_claim(&rho, &q, alpha[1], weights, local, both * scale),
    })
}

/// The proof as the field verifier reads it.
struct Stream<'a> {
    vs: VerifierState<'a>,
    statement: Statement,
}

impl Channel<F192> for Stream<'_> {
    fn statement(&mut self) -> [F192; 4] {
        self.statement.halves()
    }

    fn next_root(&mut self) -> Result<[F192; 2], TranscriptError> {
        let scalars = [self.vs.next_scalar()?, self.vs.next_scalar()?];
        scalars_to_hash(&scalars).map(|_| scalars)
    }

    fn next(&mut self) -> Result<F192, TranscriptError> {
        self.vs.next_scalar()
    }

    fn sample(&mut self) -> F192 {
        self.vs.sample()
    }

    fn finish(&mut self) -> Result<(), TranscriptError> {
        self.vs.finish()
    }
}

/// Verify a proof of `statement` against the circuit committed as `index_root`, down to the witness commitment it
/// names and two claims: it holds if both are true, one of that commitment and one of the circuit's.
pub fn verify(index_root: &Hash, statement: &Statement, proof: &Proof) -> Result<(Hash, Claims), VerifyError> {
    let mut stream = Stream {
        vs: VerifierState::keccak(&label(index_root, statement), proof),
        statement: *statement,
    };
    let reduced = reduce(&mut stream)?;
    let root = scalars_to_hash(&reduced.root).map_err(VerifyError::Transcript)?;
    let claim = |(point, value)| Claim { point, value };
    Ok((
        root,
        Claims {
            witness: claim(reduced.witness),
            index: claim(reduced.index),
        },
    ))
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
        let lambda = rng.ext();
        let batching = Batching::new(rng.ext(), rng.ext(), lambda);
        let secret = secret(&mut rng);
        let (comb, marginals) = comb_table(&circuit, &rho, &batching);
        let local = eq_table(&q[..LOG_BLOCK]);
        let values = marginals.map(|m| pcs::ring_switch::inner_product_ext(&m, &local));
        let local = sum(kind_weights(&rho, &q).iter().zip(&values).map(|(&w, &v)| w * v));
        let eq_q = eq_table(&q);
        let want = parallel::map_reduce(N_WIRES, || F192::ZERO, |i| comb[i] * eq_q[i], |x, y| x + y);
        assert_eq!(comb_at(&rho, &q, &batching, local), want);

        let witness = circuit.witness(&secret, &mut || rng.next_u64());
        let alpha = batching.alpha;
        let coefficient = |j: usize| {
            let limb = |l: usize| witness.z[mask_wire(j, l)].0;
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
            + alpha[2] * (c_eval + lambda * gamma)
            + alpha[3] * used_slots(&slot_table(&rho))
            + batching.pin_target(secret.statement().halves());
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
        let n_scalars = 2 + (2 * N_VARS + 3) + (2 * N_VARS + 3 + 1);
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
        proof.stream[n_scalars - 1] += F192::ONE;
        let (_, tampered) = verify(&index_root, &statement, &proof).expect("a reduction");
        assert_ne!(mle_eval(&index, &tampered.index.point), tampered.index.value);
        proof.stream[n_scalars - 1] += F192::ONE;

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

        // The last compression as zeros, its constant wires included, satisfies every row: only its copies of the
        // one before it keep their left-hand sides.
        let mut zeroed = copy();
        let last = (1 << LOG_COMPRESSIONS) - 1;
        for i in wire(last, 0, 0)..N_WIRES {
            let (slot, local) = ((i >> LOG_BLOCK) % (1 << LOG_SLOTS), i % BLOCK);
            let routed = kind(slot).is_some_and(|k| circuit.blocks[k].routed[local]);
            (zeroed.z[i], zeroed.b[i]) = (F64::ZERO, F64::ZERO);
            if !routed {
                zeroed.a[i] = F64::ZERO;
            }
        }
        assert!(zeroed.satisfied());
        assert!(leaves_a_false_claim(&circuit, &statement, &zeroed, &mut rng));

        let mut other_mask = copy();
        other_mask.z[mask_wire(1, 1)] += F64(7);
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
