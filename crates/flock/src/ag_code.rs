// CREDIT: https://github.com/succinctlabs/flock (branch `ag-union`, flock-core `genus95_curve_code`), MIT OR Apache-2.0.
//! The binary-preserving multiplication code of the AG skip (doc/leanvm Annex C).
//!
//! A 64-bit message `v` is the function `f_v = sum_i v_i f_i` on a genus-95 curve over GF(2),
//! where `f_i` is 1 at the `i`-th rational point and 0 at the other 63.
//! Its codeword is `f_v` evaluated at the curve's F192 points.
//!
//! ```text
//!     base code       L(D),   dimension 64:   the f_i
//!     product code    L(2D),  dimension 222:  the 64 squares f_i^2, and 158 products f_i f_k
//! ```
//!
//! A product `f_a f_b` has bits for coordinates in the jet basis of `L(2D)` ([`product_suffix`]),
//! which is what makes the prover's skip round a sum of selected weights.
//! The verifier never sees that basis: the message is sent over the 158 products ([`to_pairs`]),
//! so evaluating it needs the 64 values `f_i(Q)` and nothing else ([`eval_pairs`]).

use std::sync::OnceLock;

use primitives::field::F192;

pub mod tables;

use tables::{BASE_DENOMINATOR, BASE_SLOT_MASKS, PAIRS, PRODUCT_DENOMINATOR, R_ROWS};

/// Message bits of the base code.
pub const K: usize = 64;
/// Product-message coordinates past the 64 of the prefix.
pub const SUFFIX: usize = 158;
/// The prover offsets the sampled `x` by a counter below `2^COUNTER_BITS` to land on the curve.
pub const COUNTER_BITS: usize = 16;
/// What one count moves `x` by: the first 192 bits of the fractional part of pi.
///
/// A step in the base field would not do. The first condition on `x` is `Tr(x^3 + x) = 0`, and
/// the trace of the base field vanishes on every polynomial in `g` of degree below 60, so a
/// counter stepping by 1 only ever moves that trace linearly: for one sampled `x` in `2^17`, no
/// counter at all would pass. Asserted by `tests::counters_do_not_stall`.
pub const COUNTER_STEP: F192 = F192::new(0x243f_6a88_85a3_08d3, 0x1319_8a2e_0370_7344, 0xa409_3822_299f_31d0);

/// `x^10 + x^4 + 1` times `x + 1`: the denominator of the three Artin-Schreier right-hand sides.
pub const AS_DENOMINATOR: u64 = times_x_plus_1(0x411);
/// `AS_NUMERATORS[i][b]` is the coefficient of `y^b` in `AS_DENOMINATOR * (z_i^2 + z_i)`.
pub const AS_NUMERATORS: [[u64; 4]; 3] = [
    [
        times_x_plus_1(0x27c),
        times_x_plus_1(0x3d),
        times_x_plus_1(0x1c),
        times_x_plus_1(0x9),
    ],
    [times_x_plus_1(0x13e), times_x_plus_1(0x66), times_x_plus_1(0xa), 0x16],
    [
        times_x_plus_1(0x5c),
        times_x_plus_1(0x21),
        times_x_plus_1(0xf),
        times_x_plus_1(0xc),
    ],
];

const fn times_x_plus_1(p: u64) -> u64 {
    p ^ (p << 1)
}

/// The polynomial whose coefficient of `x^d` is bit `d` of `mask`.
fn poly(mask: u64, x_powers: &[F192]) -> F192 {
    (0..64)
        .filter(|d| mask >> d & 1 == 1)
        .fold(F192::ZERO, |acc, d| acc + x_powers[d])
}

/// A point `(x, y, z_1, z_2, z_3)` of the curve's affine model:
///
/// ```text
///     y^4 + (x + 1) y^2 + (x^3 + x) y + x^7 + x^3 = 0
///     z_i^2 + z_i = g_i(x, y)                              i = 1, 2, 3
/// ```
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct CurvePoint {
    pub x: F192,
    pub y: F192,
    pub z: [F192; 3],
}

impl CurvePoint {
    /// The 64 weights `f_i(Q)`, or `None` if `Q` is not in the evaluation set:
    /// off the curve, or over a root of one of the denominators.
    pub fn weights(&self) -> Option<[F192; K]> {
        let Self { x, y, z } = *self;
        let x_powers = primitives::field::powers(x, 50);
        let y2 = y.square();
        let y_powers = [F192::ONE, y, y2, y2 * y];

        let as_denominator = poly(AS_DENOMINATOR, &x_powers);
        let base_denominator = poly(BASE_DENOMINATOR, &x_powers);
        if (as_denominator * poly(PRODUCT_DENOMINATOR, &x_powers) * base_denominator).is_zero() {
            return None;
        }
        let quartic = y2.square() + (x + F192::ONE) * y2 + (x_powers[3] + x) * y + x_powers[7] + x_powers[3];
        if !quartic.is_zero() {
            return None;
        }
        for (z, numerators) in z.iter().zip(&AS_NUMERATORS) {
            let rhs = (0..4).fold(F192::ZERO, |acc, b| acc + poly(numerators[b], &x_powers) * y_powers[b]);
            if as_denominator * (z.square() + *z) != rhs {
                return None;
            }
        }

        let cover = [
            F192::ONE,
            z[2],
            z[1],
            z[1] * z[2],
            z[0],
            z[0] * z[2],
            z[0] * z[1],
            z[0] * z[1] * z[2],
        ];
        let mut weights = [F192::ZERO; K];
        for (group, masks) in BASE_SLOT_MASKS.chunks(32).enumerate() {
            let cover_y = cover[group / 4] * y_powers[group % 4];
            for (d, &mask) in masks.iter().enumerate().filter(|(_, mask)| **mask != 0) {
                let monomial = cover_y * x_powers[d];
                for i in (0..K).filter(|i| mask >> i & 1 == 1) {
                    weights[i] += monomial;
                }
            }
        }
        let scale = base_denominator.inv();
        Some(weights.map(|w| w * scale))
    }
}

/// `sum_t p_t f_i(Q) f_k(Q)` over the pairs `(i, k)`: the product codeword of the message `p`
/// at the point whose weights are `w`.
pub fn eval_pairs(p: &[F192], w: &[F192; K]) -> F192 {
    assert_eq!(p.len(), SUFFIX);
    let mut rows = [F192::ZERO; K];
    for (&p, &(i, k)) in p.iter().zip(&PAIRS) {
        rows[i as usize] += p * w[k as usize];
    }
    rows.iter().zip(w).fold(F192::ZERO, |acc, (&row, &w)| acc + row * w)
}

// ---------------------------------------------------------------------------
// Prover side: the jet basis, the change of basis to the pairs, the point search.
// ---------------------------------------------------------------------------

/// A vector of up to 192 bits.
type Bits = [u64; 3];

fn bit(v: &Bits, i: usize) -> bool {
    v[i / 64] >> (i % 64) & 1 == 1
}

fn xor(a: &mut Bits, b: &Bits) {
    for (a, b) in a.iter_mut().zip(b) {
        *a ^= b;
    }
}

/// `R m` past the prefix: the order-1, order-2 and (30-bit) order-3 jets of `f_m` at the points.
fn extend(m: u64) -> Bits {
    let mut out = [0u64; 3];
    for (j, &row) in R_ROWS[K..].iter().enumerate() {
        out[j / 64] |= u64::from((row & m).count_ones() & 1) << (j % 64);
    }
    out
}

/// The jet coordinates, past the prefix, of `f_a f_b + f_c`.
///
/// Jets multiply as power series, order by order. The prefix is `a & b ^ c`, which the zerocheck
/// has at zero.
pub fn product_suffix(a: u64, b: u64, c: u64) -> Bits {
    let (l, r, c) = (extend(a), extend(b), extend(c));
    [
        (a & r[0]) ^ (l[0] & b) ^ c[0],
        (a & r[1]) ^ (l[0] & r[0]) ^ (l[1] & b) ^ c[1],
        ((a & r[2]) ^ (l[0] & r[1]) ^ (l[1] & r[0]) ^ (l[2] & b) ^ c[2]) & ((1 << 30) - 1),
    ]
}

/// Row `t` selects the jet coordinates that sum to pair coordinate `t`.
fn jets_to_pairs() -> &'static [Bits; SUFFIX] {
    static CACHE: OnceLock<[Bits; SUFFIX]> = OnceLock::new();
    CACHE.get_or_init(|| {
        // Row `j` of `[M | I]`, where column `t` of `M` is the jet vector of pair `t`.
        let jets = PAIRS.map(|(i, k)| product_suffix(1 << i, 1 << k, 0));
        let mut rows: Vec<(Bits, Bits)> = (0..SUFFIX)
            .map(|j| {
                let mut row = ([0u64; 3], [0u64; 3]);
                for (t, _) in jets.iter().enumerate().filter(|(_, jet)| bit(jet, j)) {
                    row.0[t / 64] |= 1 << (t % 64);
                }
                row.1[j / 64] |= 1 << (j % 64);
                row
            })
            .collect();
        for t in 0..SUFFIX {
            let pivot = (t..SUFFIX)
                .find(|&j| bit(&rows[j].0, t))
                .expect("the pairs are a basis");
            rows.swap(t, pivot);
            let pivot_row = rows[t];
            for (j, row) in rows.iter_mut().enumerate() {
                if j != t && bit(&row.0, t) {
                    xor(&mut row.0, &pivot_row.0);
                    xor(&mut row.1, &pivot_row.1);
                }
            }
        }
        std::array::from_fn(|t| rows[t].1)
    })
}

/// Change a product message with a zero prefix from the jet basis to the pairs.
pub fn to_pairs(jets: &[F192; SUFFIX]) -> [F192; SUFFIX] {
    jets_to_pairs().map(|row| {
        (0..SUFFIX)
            .filter(|&j| bit(&row, j))
            .fold(F192::ZERO, |acc, j| acc + jets[j])
    })
}

fn to_bits(v: F192) -> Bits {
    [v.c0, v.c1, v.c2]
}

/// Solves `s^2 + s = rhs`, which half of the field allows. The other root is `s + 1`.
struct ArtinSchreier {
    /// `(image, preimage)` pairs of `s -> s^2 + s`, the image's top bit its pivot.
    pivots: Vec<Option<(Bits, Bits)>>,
}

impl ArtinSchreier {
    fn get() -> &'static Self {
        static CACHE: OnceLock<ArtinSchreier> = OnceLock::new();
        CACHE.get_or_init(|| {
            let mut solver = Self {
                pivots: vec![None; 192],
            };
            for i in 0..192 {
                let mut s = [0u64; 3];
                s[i / 64] = 1 << (i % 64);
                let basis = F192::new(s[0], s[1], s[2]);
                let (image, preimage) = solver.reduce(to_bits(basis.square() + basis), s);
                if let Some(top) = (0..192).rev().find(|&j| bit(&image, j)) {
                    solver.pivots[top] = Some((image, preimage));
                }
            }
            solver
        })
    }

    fn reduce(&self, mut image: Bits, mut preimage: Bits) -> (Bits, Bits) {
        for j in (0..192).rev() {
            if let (true, Some((pivot_image, pivot_preimage))) = (bit(&image, j), &self.pivots[j]) {
                xor(&mut image, pivot_image);
                xor(&mut preimage, pivot_preimage);
            }
        }
        (image, preimage)
    }

    fn solve(&self, rhs: F192) -> Option<F192> {
        let (rest, s) = self.reduce(to_bits(rhs), [0; 3]);
        (rest == [0; 3]).then(|| F192::new(s[0], s[1], s[2]))
    }
}

/// The roots `y` of the quartic over `x`.
///
/// With `u = x + 1`, `y = u s` and `s^2 + s = (x / u) t`, the quartic is `t^2 + t = x^3 + x`.
fn quartic_roots(x: F192) -> Vec<F192> {
    let solver = ArtinSchreier::get();
    let u = x + F192::ONE;
    let Some(t) = solver.solve(x.square() * x + x) else {
        return Vec::new();
    };
    let x_over_u = x * u.inv();
    let mut roots = Vec::new();
    for t in [t, t + F192::ONE] {
        if let Some(s) = solver.solve(x_over_u * t) {
            roots.extend([u * s, u * s + u]);
        }
    }
    roots
}

/// The `x` a counter moves the sampled `x0` to.
pub fn counter_x(x0: F192, delta: F192) -> F192 {
    x0 + COUNTER_STEP * delta
}

/// The first counter `delta` that puts [`counter_x`] under a point of the evaluation set, and that point.
pub fn find_point(x0: F192) -> (F192, CurvePoint) {
    let solver = ArtinSchreier::get();
    for counter in 0..1u64 << COUNTER_BITS {
        let delta = F192::new(counter, 0, 0);
        let x = counter_x(x0, delta);
        let x_powers = primitives::field::powers(x, 12);
        let as_denominator = poly(AS_DENOMINATOR, &x_powers);
        if as_denominator.is_zero() {
            continue;
        }
        let scale = as_denominator.inv();
        for y in quartic_roots(x) {
            let y2 = y.square();
            let y_powers = [F192::ONE, y, y2, y2 * y];
            let z: Option<Vec<F192>> = AS_NUMERATORS
                .iter()
                .map(|numerators| {
                    let rhs = (0..4).fold(F192::ZERO, |acc, b| acc + poly(numerators[b], &x_powers) * y_powers[b]);
                    solver.solve(rhs * scale)
                })
                .collect();
            let Some(z) = z else { continue };
            let point = CurvePoint {
                x,
                y,
                z: [z[0], z[1], z[2]],
            };
            if point.weights().is_some() {
                return (delta, point);
            }
        }
    }
    panic!("no curve point within 2^{COUNTER_BITS} of the sampled x");
}

/// Whether `delta` is a counter [`find_point`] can return.
pub fn is_counter(delta: F192) -> bool {
    (delta.c1, delta.c2) == (0, 0) && delta.c0 >> COUNTER_BITS == 0
}

#[cfg(test)]
mod tests {
    use primitives::test_rng::Rng;

    use super::*;

    fn dot(m: u64, w: &[F192; K]) -> F192 {
        (0..K).filter(|i| m >> i & 1 == 1).fold(F192::ZERO, |acc, i| acc + w[i])
    }

    /// `f_a(Q) f_b(Q) + f_c(Q)`, with `c = a & b`, is the pair message evaluated at `Q`.
    /// This is the one identity the zerocheck needs, and it ties together the matrix `R`,
    /// the jet products, the pairs, the weights and the curve equations.
    #[test]
    fn product_identity_at_sampled_points() {
        let mut rng = Rng::new(7);
        let mut counters = 0;
        for _ in 0..8 {
            let (delta, point) = find_point(rng.ext());
            assert!(is_counter(delta));
            counters += delta.c0;
            let w = point.weights().expect("a sampled point is in the evaluation set");
            for _ in 0..16 {
                let (a, b) = (rng.next_u64(), rng.next_u64());
                let suffix = product_suffix(a, b, a & b);
                let jets: [F192; SUFFIX] =
                    std::array::from_fn(|j| if bit(&suffix, j) { F192::ONE } else { F192::ZERO });
                assert_eq!(
                    dot(a, &w) * dot(b, &w) + dot(a & b, &w),
                    eval_pairs(&to_pairs(&jets), &w)
                );
            }
        }
        // A counter of zero every time would mean the search never had to move.
        assert!(counters > 0);
    }

    /// About one `x` in twelve lies under a point, and the counters must find it at that rate
    /// from every start: a longest search far past a geometric tail means some condition on `x`
    /// is degenerate along the counter, and then for some `x0` no counter passes at all.
    #[test]
    fn counters_do_not_stall() {
        let mut rng = Rng::new(9);
        let longest = (0..2000).map(|_| find_point(rng.ext()).0.c0).max().unwrap();
        assert!(longest < 400, "a search took {longest} counters");
    }

    #[test]
    fn off_curve_points_are_rejected() {
        let mut rng = Rng::new(8);
        let (_, point) = find_point(rng.ext());
        for i in 0..5 {
            let mut bad = point;
            let [z1, z2, z3] = &mut bad.z;
            *[&mut bad.x, &mut bad.y, z1, z2, z3][i] += F192::Y;
            assert!(bad.weights().is_none());
        }
    }
}
