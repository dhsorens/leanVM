//! The Cantor basis of `GF(2^64)`, its subspaces, and the additive transform between a polynomial's novel-basis
//! coefficients and its values on a coset.

use std::ops::Add;
use std::sync::OnceLock;

use primitives::field::{F64, F192};

/// Basis vectors computed: enough for a quotient domain of `2^26` points.
pub const BASIS: usize = 28;

/// `S(x) = x^2 + x`.
pub fn s(x: F64) -> F64 {
    x.square() + x
}

/// `beta[0] = 1` and `S(beta[k + 1]) = beta[k]`, each the solution with its low bit clear.
pub fn beta() -> &'static [F64; BASIS] {
    static BETA: OnceLock<[F64; BASIS]> = OnceLock::new();
    BETA.get_or_init(|| {
        // `S` is linear over GF(2): reduce its matrix once, keeping what each pivot was made of.
        let mut pivots = [(0u64, 0u64); 64];
        for j in 0..64 {
            let (mut image, mut source) = (s(F64(1 << j)).0, 1u64 << j);
            while image != 0 {
                let top = 63 - image.leading_zeros() as usize;
                if pivots[top].0 == 0 {
                    pivots[top] = (image, source);
                    break;
                }
                image ^= pivots[top].0;
                source ^= pivots[top].1;
            }
        }
        let solve = |target: F64| {
            let (mut image, mut source) = (target.0, 0u64);
            while image != 0 {
                let top = 63 - image.leading_zeros() as usize;
                assert!(pivots[top].0 != 0, "outside the image of S");
                image ^= pivots[top].0;
                source ^= pivots[top].1;
            }
            F64(source & !1)
        };
        let mut beta = [F64::ONE; BASIS];
        for k in 1..BASIS {
            beta[k] = solve(beta[k - 1]);
        }
        beta
    })
}

/// `B(i)`: the point of index `i`, the sum of `beta[k]` over its bits.
pub fn point(index: usize) -> F64 {
    static TABLES: OnceLock<Vec<[F64; 256]>> = OnceLock::new();
    let tables = TABLES.get_or_init(|| {
        (0..BASIS.div_ceil(8))
            .map(|byte| {
                std::array::from_fn(|low| {
                    (0..8)
                        .filter(|bit| (low >> bit) & 1 == 1 && 8 * byte + bit < BASIS)
                        .fold(F64::ZERO, |acc, bit| acc + beta()[8 * byte + bit])
                })
            })
            .collect()
    });
    debug_assert!(index >> BASIS == 0);
    tables.iter().enumerate().fold(F64::ZERO, |acc, (byte, table)| {
        acc + table[(index >> (8 * byte)) & 0xff]
    })
}

/// `w_k(x)` for `k < count`: `w_0 = x`, `w_{k+1} = S(w_k)`.
pub fn chain(x: F64, count: usize) -> Vec<F64> {
    std::iter::successors(Some(x), |&w| Some(s(w))).take(count).collect()
}

/// The constants `b` with `x_k = sum_j b[j - k] w_j(x)` the `k`-th coordinate of a point `x` of the span of the
/// first `count` basis vectors: the inverse of `w_k(x) = sum_j beta[j - k] x_j`.
pub fn coordinates(count: usize) -> Vec<F64> {
    let mut b = vec![F64::ONE; count];
    for d in 1..count {
        b[d] = (1..=d).fold(F64::ZERO, |acc, e| acc + beta()[e] * b[d - e]);
    }
    b
}

/// `tau` with `sum_k tau[k] w_k` the additive polynomial of degree `2^(m - 2)` vanishing on the span of
/// `beta[2..m]`, the cells of role `X`.
pub fn row_vanishing(m: usize) -> Vec<F64> {
    // Unknowns `tau[0..m - 2]`, with `tau[m - 2] = 1`: one equation per `beta[j]`, as `w_k(beta[j]) = beta[j - k]`.
    let n = m - 2;
    let mut rows: Vec<Vec<F64>> = (2..m)
        .map(|j| {
            (0..=n)
                .map(|k| if k <= j { beta()[j - k] } else { F64::ZERO })
                .collect()
        })
        .collect();
    for col in 0..n {
        let pivot = (col..n).find(|&r| !rows[r][col].is_zero()).expect("a pivot");
        rows.swap(col, pivot);
        let inverse = rows[col][col].inv();
        rows[col].iter_mut().for_each(|x| *x *= inverse);
        for r in 0..n {
            let factor = rows[r][col];
            if r != col && !factor.is_zero() {
                let pivot_row = rows[col].clone();
                rows[r].iter_mut().zip(&pivot_row).for_each(|(x, &p)| *x += factor * p);
            }
        }
    }
    (0..n).map(|k| rows[k][n]).chain([F64::ONE]).collect()
}

/// What the transform moves: the field, or its extension.
pub trait Module: Copy + Send + Sync + Add<Output = Self> {
    fn scale(self, by: F64) -> Self;
}

impl Module for F64 {
    fn scale(self, by: F64) -> Self {
        self * by
    }
}

impl Module for F192 {
    fn scale(self, by: F64) -> Self {
        self.mul_base(by)
    }
}

/// Blocks at most this long are transformed whole by one worker.
const LEAF: usize = 1 << 14;

fn forward_layer<M: Module>(lo: &mut [M], hi: &mut [M], lambda: F64) {
    for (a, b) in lo.iter_mut().zip(hi) {
        *a = *a + b.scale(lambda);
        *b = *b + *a;
    }
}

fn inverse_layer<M: Module>(lo: &mut [M], hi: &mut [M], lambda: F64) {
    for (a, b) in lo.iter_mut().zip(hi) {
        *b = *b + *a;
        *a = *a + b.scale(lambda);
    }
}

/// The layers `layers` (in the order given) of the transform on `data`, block `first` of its layer onwards.
fn layers<M: Module>(data: &mut [M], first: usize, offsets: &[F64], order: &[usize], forward: bool) {
    for &k in order {
        let block = 2 << k;
        for (j, chunk) in data.chunks_exact_mut(block).enumerate() {
            // `w_k` is constant on a block's low half.
            let lambda = offsets[k] + point(2 * (first / block + j));
            let (lo, hi) = chunk.split_at_mut(block / 2);
            if forward {
                forward_layer(lo, hi, lambda);
            } else {
                inverse_layer(lo, hi, lambda);
            }
        }
    }
}

fn transform<M: Module>(data: &mut [M], offset: F64, forward: bool) {
    let m = data.len().trailing_zeros() as usize;
    assert_eq!(data.len(), 1 << m);
    let offsets = chain(offset, m);
    let split = m.min(LEAF.trailing_zeros() as usize);
    let (small, large): (Vec<usize>, Vec<usize>) = if forward {
        ((0..split).rev().collect(), (split..m).rev().collect())
    } else {
        ((0..split).collect(), (split..m).collect())
    };
    let leaves = |data: &mut [M]| {
        parallel::chunks_mut(data, 1 << split, |j, chunk| {
            layers(chunk, j << split, &offsets, &small, forward)
        });
    };
    let wide = |data: &mut [M]| {
        for &k in &large {
            let block = 2 << k;
            for (j, chunk) in data.chunks_exact_mut(block).enumerate() {
                let lambda = offsets[k] + point(2 * j);
                let (lo, hi) = chunk.split_at_mut(block / 2);
                parallel::chunks_mut2(lo, hi, LEAF, |_, lo, hi| {
                    if forward {
                        forward_layer(lo, hi, lambda);
                    } else {
                        inverse_layer(lo, hi, lambda);
                    }
                });
            }
        }
    };
    if forward {
        wide(data);
        leaves(data);
    } else {
        leaves(data);
        wide(data);
    }
}

/// Coefficients to values: entry `i` becomes the polynomial at `offset + B(i)`.
pub fn values<M: Module>(data: &mut [M], offset: F64) {
    transform(data, offset, true);
}

/// Values at `offset + B(i)` to coefficients.
pub fn coefficients<M: Module>(data: &mut [M], offset: F64) {
    transform(data, offset, false);
}

/// The polynomial of coefficients `coeffs[first + step * i]` at the point whose `w_k` are `digits`.
pub fn evaluate(coeffs: &[F64], first: usize, step: usize, digits: &[F192]) -> F192 {
    let len = 1 << digits.len();
    let at = |i: usize| coeffs[first + step * i];
    let Some((&low, rest)) = digits.split_first() else {
        return F192::from(at(0));
    };
    let mut folded: Vec<F192> = parallel::map_collect(len / 2, |i| F192::from(at(2 * i)) + low.mul_base(at(2 * i + 1)));
    for &digit in rest {
        let half = folded.len() / 2;
        for i in 0..half {
            folded[i] = folded[2 * i] + digit * folded[2 * i + 1];
        }
        folded.truncate(half);
    }
    folded[0]
}

#[cfg(test)]
mod tests {
    use super::*;
    use primitives::test_rng::Rng;

    /// The transform inverts itself and agrees with direct evaluation, on a coset; a sum over the subspace is the
    /// top coefficient; and the row polynomial vanishes exactly on the `X` cells.
    #[test]
    fn transform_matches_the_basis() {
        let mut rng = Rng::new(0xD0);
        let (m, offset) = (6, beta()[9]);
        let coeffs: Vec<F64> = (0..1 << m).map(|_| F64(rng.next_u64())).collect();
        let direct = |x: F64| {
            let w: Vec<F192> = chain(x, m).into_iter().map(F192::from).collect();
            evaluate(&coeffs, 0, 1, &w)
        };
        for offset in [F64::ZERO, offset] {
            let mut data = coeffs.clone();
            values(&mut data, offset);
            for (i, &v) in data.iter().enumerate() {
                assert_eq!(F192::from(v), direct(offset + point(i)));
            }
            if offset.is_zero() {
                let sum = data.iter().fold(F64::ZERO, |acc, &v| acc + v);
                assert_eq!(sum, coeffs[(1 << m) - 1]);
            }
            coefficients(&mut data, offset);
            assert_eq!(data, coeffs);
        }

        let tau = row_vanishing(m);
        let b = coordinates(m);
        for i in 0..1usize << m {
            let w = chain(point(i), m);
            let v = (0..m - 1).fold(F64::ZERO, |acc, k| acc + tau[k] * w[k]);
            assert_eq!(v.is_zero(), i % 4 == 0);
            for k in 0..m {
                let x = (k..m).fold(F64::ZERO, |acc, j| acc + b[j - k] * w[j]);
                assert_eq!(x, F64(((i >> k) & 1) as u64));
            }
        }
        assert_eq!(beta()[1].square() + beta()[1], F64::ONE);
    }

    /// Digit `k` of a cell is its bit `k` plus a function of its higher bits, at the protocol's size: what
    /// `formal/quotient`'s `sum_digitsEval` assumes of the cells.
    #[test]
    fn digits_are_triangular() {
        let mut rng = Rng::new(0xD1);
        let m = 22;
        for _ in 0..2000 {
            let i = rng.next_u64() as usize & ((1 << m) - 1);
            let digits = chain(point(i), m);
            for (k, &digit) in digits.iter().enumerate() {
                let higher = i & !((2 << k) - 1);
                assert_eq!(digit + chain(point(higher), m)[k], F64(((i >> k) & 1) as u64));
            }
        }
    }
}
