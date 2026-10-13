//! Rows of full adders and the permutation that wires them, and the circuit of the membership statement.

use primitives::field::F64;
use primitives::hash::{IV, PARAM_IV, SIGMA};

use super::domain::beta;
use crate::membership::{DEPTH, Secret};

/// The rows holding the public bits: eight words of 128, two bits a row.
pub const PUBLIC_ROWS: usize = 512;
pub const WORD_BITS: usize = 128;

/// What a cell reads: a constant, or row `r`'s `V` cell.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Src {
    Zero,
    One,
    Row(u32),
}

/// A full adder: the bits of `x` and `y`, the carry of `c`.
#[derive(Clone, Copy, Debug)]
pub struct Row {
    pub x: Src,
    pub y: Src,
    pub c: Src,
}

const IDLE: Row = Row {
    x: Src::Zero,
    y: Src::Zero,
    c: Src::Zero,
};

pub struct Circuit {
    pub log_rows: usize,
    rows: Vec<Row>,
    /// The rows that are free input bits, in the order [`Circuit::cells`] takes them.
    inputs: Vec<u32>,
    /// Each cell's successor on its cycle. Cell `4 r + role`, the roles `X, Y, C, V`.
    pub sigma: Vec<u32>,
}

pub struct Builder {
    rows: Vec<Row>,
    inputs: Vec<u32>,
    carry_one: Option<Src>,
}

impl Default for Builder {
    fn default() -> Self {
        Self::new()
    }
}

impl Builder {
    pub fn new() -> Self {
        Self {
            rows: vec![IDLE; PUBLIC_ROWS],
            inputs: Vec::new(),
            carry_one: None,
        }
    }

    pub fn row(&mut self, x: Src, y: Src, c: Src) -> Src {
        self.rows.push(Row { x, y, c });
        Src::Row(self.rows.len() as u32 - 1)
    }

    /// A free bit: a row reading its own output, which the gate then makes `0` or `1`.
    pub fn input(&mut self) -> Src {
        let at = self.rows.len() as u32;
        self.inputs.push(at);
        self.row(Src::Row(at), Src::Zero, Src::Zero)
    }

    pub fn xor(&mut self, x: Src, y: Src) -> Src {
        self.row(x, y, Src::Zero)
    }

    /// The bit of `x` alone, without the carry its cell holds.
    pub fn bit(&mut self, x: Src) -> Src {
        self.row(x, Src::Zero, Src::Zero)
    }

    /// A cell of carry one.
    fn carry_one(&mut self) -> Src {
        if self.carry_one.is_none() {
            self.carry_one = Some(self.row(Src::One, Src::One, Src::Zero));
        }
        self.carry_one.unwrap()
    }

    /// `x + y` on as many bits as they have, low bit first, the carry riding from row to row.
    pub fn add(&mut self, x: &[Src], y: &[Src]) -> Vec<Src> {
        let mut carry = Src::Zero;
        x.iter()
            .zip(y)
            .map(|(&a, &b)| {
                carry = self.row(a, b, carry);
                carry
            })
            .collect()
    }

    /// One BLAKE2s compression of a single final 64-byte block, its bits low first.
    fn compress(&mut self, message: &[Src]) -> Vec<Src> {
        let constant = |word: u32| -> Vec<Src> {
            (0..32)
                .map(|i| if (word >> i) & 1 == 1 { Src::One } else { Src::Zero })
                .collect()
        };
        let rotate = |word: &[Src], by: usize| -> Vec<Src> { (0..32).map(|i| word[(i + by) % 32]).collect() };
        let mut v: Vec<Vec<Src>> = PARAM_IV.iter().chain(&IV).map(|&word| constant(word)).collect();
        v[12] = constant(IV[4] ^ 64);
        v[14] = constant(!IV[6]);
        for sigma in &SIGMA {
            for (g, [a, b, c, d]) in [
                [0, 4, 8, 12],
                [1, 5, 9, 13],
                [2, 6, 10, 14],
                [3, 7, 11, 15],
                [0, 5, 10, 15],
                [1, 6, 11, 12],
                [2, 7, 8, 13],
                [3, 4, 9, 14],
            ]
            .into_iter()
            .enumerate()
            {
                for (half, [first, second]) in [[16, 12], [8, 7]].into_iter().enumerate() {
                    let word = sigma[2 * g + half];
                    let sum = self.add(&v[a], &v[b]);
                    v[a] = self.add(&sum, &message[32 * word..32 * word + 32]);
                    let mixed: Vec<Src> = (0..32).map(|i| self.xor(v[d][i], v[a][i])).collect();
                    v[d] = rotate(&mixed, first);
                    v[c] = self.add(&v[c], &v[d]);
                    let mixed: Vec<Src> = (0..32).map(|i| self.xor(v[b][i], v[c][i])).collect();
                    v[b] = rotate(&mixed, second);
                }
            }
        }
        let mut out = Vec::with_capacity(256);
        for k in 0..8 {
            for i in 0..32 {
                let carry = if (PARAM_IV[k] >> i) & 1 == 1 {
                    self.carry_one()
                } else {
                    Src::Zero
                };
                out.push(self.row(v[k][i], v[k + 8][i], carry));
            }
        }
        out
    }

    /// Close the circuit on `2^log_rows` rows, `public[J][j]` being bit `j` of public word `J`.
    pub fn finish(mut self, log_rows: usize, public: &[Vec<Src>; 4]) -> Circuit {
        let n = 1 << log_rows;
        assert!(self.rows.len() <= n, "{} rows", self.rows.len());
        let bit = |word: usize, j: usize| match word {
            0..4 => public[word][j],
            4 if j == 0 => Src::One,
            _ => Src::Zero,
        };
        for (r, row) in self.rows[..PUBLIC_ROWS].iter_mut().enumerate() {
            let (word, pair) = (r / (WORD_BITS / 2), r % (WORD_BITS / 2));
            *row = Row {
                x: bit(word, 2 * pair),
                y: bit(word, 2 * pair + 1),
                c: Src::Zero,
            };
        }
        self.rows.resize(n, IDLE);

        // A cycle is a source and the cells reading it, in cell order.
        const NONE: u32 = u32::MAX;
        let slot = |src: Src| match src {
            Src::Zero => 0,
            Src::One => 1,
            Src::Row(r) => 2 + r as usize,
        };
        let mut first = vec![NONE; n + 2];
        let mut last = vec![NONE; n + 2];
        let mut sigma: Vec<u32> = (0..4 * n as u32).collect();
        let mut join = |at: usize, cell: u32, sigma: &mut Vec<u32>| {
            if first[at] == NONE {
                first[at] = cell;
            } else {
                sigma[last[at] as usize] = cell;
            }
            last[at] = cell;
            sigma[cell as usize] = first[at];
        };
        for r in 0..n {
            join(2 + r, 4 * r as u32 + 3, &mut sigma);
        }
        for (r, row) in self.rows.iter().enumerate() {
            for (role, src) in [row.x, row.y, row.c].into_iter().enumerate() {
                join(slot(src), (4 * r + role) as u32, &mut sigma);
            }
        }
        Circuit {
            log_rows,
            rows: self.rows,
            inputs: self.inputs,
            sigma,
        }
    }
}

impl Circuit {
    pub fn n_inputs(&self) -> usize {
        self.inputs.len()
    }

    /// Every cell's value, from the free inputs. A cell holds `a + theta b`, bit `a` and carry `b`.
    pub fn cells(&self, inputs: &[bool]) -> Vec<F64> {
        assert_eq!(inputs.len(), self.inputs.len());
        let mut v = vec![0u8; self.rows.len()];
        for (&row, &input) in self.inputs.iter().zip(inputs) {
            v[row as usize] = input as u8;
        }
        let read = |v: &[u8], src: Src| match src {
            Src::Zero => 0,
            Src::One => 1,
            Src::Row(r) => v[r as usize],
        };
        // A row reads rows before it, or itself; the public rows read the outputs.
        for r in (PUBLIC_ROWS..self.rows.len()).chain(0..PUBLIC_ROWS) {
            let row = self.rows[r];
            let (x, y, c) = (read(&v, row.x) & 1, read(&v, row.y) & 1, read(&v, row.c) >> 1);
            v[r] = (x ^ y ^ c) | ((x & y) ^ (c & (x ^ y))) << 1;
        }
        let theta = beta()[1];
        let element = [F64::ZERO, F64::ONE, theta, theta + F64::ONE];
        parallel::map_collect(4 * self.rows.len(), |cell| {
            let (r, row) = (cell / 4, self.rows[cell / 4]);
            let code = match cell % 4 {
                0 => read(&v, row.x),
                1 => read(&v, row.y),
                2 => read(&v, row.c),
                _ => v[r],
            };
            element[code as usize]
        })
    }
}

/// The 256 wires of 32 bytes to the four public words they are read as: a word is sixteen bytes, big-endian.
pub fn public_words(y: &[Src], root: &[Src]) -> [Vec<Src>; 4] {
    std::array::from_fn(|word| {
        let (bytes, half) = (if word < 2 { y } else { root }, word % 2);
        (0..WORD_BITS)
            .map(|j| bytes[8 * (16 * half + 15 - j / 8) + j % 8])
            .collect()
    })
}

/// The membership statement: `y = H(x | 0x11..)`, and the path from `H(x | 0x22..)` up to `root`.
pub fn membership() -> Circuit {
    let mut b = Builder::new();
    let constant = |byte: u8| -> Vec<Src> {
        (0..256)
            .map(|i| {
                if (byte >> (i % 8)) & 1 == 1 {
                    Src::One
                } else {
                    Src::Zero
                }
            })
            .collect()
    };
    let x: Vec<Src> = (0..256).map(|_| b.input()).collect();
    let y = b.compress(&[&x[..], &constant(0x11)].concat());
    let mut node = b.compress(&[&x[..], &constant(0x22)].concat());
    for _ in 0..DEPTH {
        let sibling: Vec<Src> = (0..256).map(|_| b.input()).collect();
        let direction = b.input();
        // `swap` is the carry of its row: the direction and the two sides differing.
        let (mut left, mut right) = (Vec::with_capacity(256), Vec::with_capacity(256));
        for i in 0..256 {
            let differ = b.xor(node[i], sibling[i]);
            let swap = b.row(direction, differ, Src::Zero);
            left.push(b.row(node[i], Src::Zero, swap));
            right.push(b.row(sibling[i], Src::Zero, swap));
        }
        node = b.compress(&[left, right].concat());
    }
    let pure = |b: &mut Builder, wires: &[Src]| -> Vec<Src> { wires.iter().map(|&w| b.bit(w)).collect() };
    let (y, root) = (pure(&mut b, &y), pure(&mut b, &node));
    b.finish(20, &public_words(&y, &root))
}

/// The free inputs of [`membership`] for a secret.
pub fn membership_inputs(secret: &Secret) -> Vec<bool> {
    let bits = |bytes: &[u8; 32]| -> Vec<bool> { (0..256).map(|i| (bytes[i / 8] >> (i % 8)) & 1 == 1).collect() };
    let mut inputs = bits(&secret.x);
    for (level, sibling) in secret.siblings.iter().enumerate() {
        inputs.extend(bits(sibling));
        inputs.push((secret.directions >> level) & 1 == 1);
    }
    inputs
}
