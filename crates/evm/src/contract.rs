//! The membership verifier's contract, and its calldata and return value.

use fiat_shamir::merkle::{Hash, scalars_to_hash};
use fiat_shamir::transcript::{Error, Proof};
use fiat_shamir::{DS_OBSERVE, DS_SQUEEZE};
use flock::membership::{Channel, Claims, Reduced, Scalar, Statement, label, reduce};
use flock::standalone::Claim;
use primitives::field::F192;

use crate::codegen::{Contract, SCALAR_BYTES, SCALARS, compile};
use crate::record::{Node, Sym, record};

/// The proof as the recorder reads it: every read and every challenge is a node.
struct Recorder {
    state: Sym,
    read: u16,
}

impl Recorder {
    fn observe(&mut self, scalar: Sym) {
        self.state = Sym::new(Node::Hash(self.state.0, scalar.0, DS_OBSERVE.0 as u8));
    }
}

impl Channel<Sym> for Recorder {
    fn statement(&mut self) -> [Sym; 4] {
        std::array::from_fn(|k| Sym::new(Node::Statement(k as u8)))
    }

    fn next_root(&mut self) -> Result<[Sym; 2], Error> {
        let scalars = std::array::from_fn(|k| Sym::new(Node::Root(k as u8)));
        scalars.iter().for_each(|&scalar| self.observe(scalar));
        Ok(scalars)
    }

    fn next(&mut self) -> Result<Sym, Error> {
        let scalar = Sym::new(Node::Input(self.read));
        self.read += 1;
        self.observe(scalar);
        Ok(scalar)
    }

    fn sample(&mut self) -> Sym {
        let zero = Sym::constant(F192::ZERO);
        self.state = Sym::new(Node::Hash(self.state.0, zero.0, DS_SQUEEZE.0 as u8));
        Sym::new(Node::Low(self.state.0))
    }

    fn finish(&mut self) -> Result<(), Error> {
        Ok(())
    }
}

/// The contract verifying proofs against the circuit committed as `index_root`.
pub fn contract(index_root: &Hash) -> Contract {
    let ((reduced, read), graph) = record(|| {
        let mut recorder = Recorder {
            state: Sym::new(Node::Seed),
            read: 0,
        };
        let reduced = reduce(&mut recorder).unwrap_or_else(|_| unreachable!("a recorder rejects nothing"));
        (reduced, recorder.read)
    });
    let Reduced { root, witness, index } = reduced;
    let outputs: Vec<u32> = root
        .into_iter()
        .chain(witness.0)
        .chain([witness.1])
        .chain(index.0)
        .chain([index.1])
        .map(|sym| sym.0)
        .collect();
    // The statement's 64 bytes close the label: the contract copies them from calldata.
    let label = label(
        index_root,
        &Statement {
            y: [0; 32],
            root: [0; 32],
        },
    );
    let prefix = label[..label.len() - 64].try_into().expect("a 48-byte prefix");
    compile(&graph, &outputs, prefix, SCALARS + SCALAR_BYTES * read as usize)
}

/// A statement and its proof as the contract's calldata.
pub fn calldata(statement: &Statement, proof: &Proof) -> Vec<u8> {
    let mut data = [statement.y, statement.root].concat();
    for (i, scalar) in proof.stream.iter().enumerate() {
        // The commitment's two scalars are 128-bit.
        let limbs = if i < 2 {
            vec![scalar.c1, scalar.c0]
        } else {
            vec![scalar.c2, scalar.c1, scalar.c0]
        };
        limbs.iter().for_each(|limb| data.extend(limb.to_be_bytes()));
    }
    data
}

/// What the contract returned: the witness commitment and the two claims.
pub fn decode(output: &[u8]) -> Option<(Hash, Claims)> {
    let words: Vec<F192> = output
        .as_chunks::<32>()
        .0
        .iter()
        .map(|word| {
            let limb = |i: usize| u64::from_be_bytes(word[24 - 8 * i..32 - 8 * i].try_into().unwrap());
            F192::new(limb(0), limb(1), limb(2))
        })
        .collect();
    let (root, claims) = words.split_at_checked(2)?;
    let n = flock::membership::COMMITTED_VARS + 1;
    let claim = |words: &[F192]| {
        let (value, point) = words.split_last()?;
        Some(Claim {
            point: point.to_vec(),
            value: *value,
        })
    };
    let (witness, index) = claims.split_at_checked(n)?;
    Some((
        scalars_to_hash(&[root[0], root[1]]).ok()?,
        Claims {
            witness: claim(witness)?,
            index: claim(index)?,
        },
    ))
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::machine::call;
    use flock::membership::{Circuit, DEPTH, N_VARS, Secret, prove, verify};
    use primitives::field::F64;
    use primitives::test_rng::Rng;

    fn proof(rng: &mut Rng) -> (Hash, Statement, Proof) {
        let mut bytes = || std::array::from_fn(|_| rng.next_u64() as u8);
        let secret = Secret {
            x: bytes(),
            siblings: std::array::from_fn::<_, DEPTH, _>(|_| bytes()),
            directions: 0x5A3C_96F0,
        };
        let (index_root, root, statement) = (bytes(), bytes(), secret.statement());
        let circuit = Circuit::new();
        let witness = circuit.witness(&secret, &mut || rng.next_u64());
        let masks = std::array::from_fn(|_| (0..1 << N_VARS).map(|_| F64(rng.next_u64())).collect());
        let (proof, _) = prove(&circuit, &index_root, &statement, &root, &witness, &masks);
        (index_root, statement, proof)
    }

    /// The contract and the Rust verifier leave the same commitment and claims, on an honest proof and on
    /// tampered ones, and the contract reverts on calldata of another length.
    #[test]
    fn contract_is_the_verifier() {
        let mut rng = Rng::new(0xE7);
        let (index_root, statement, mut proof) = proof(&mut rng);
        let code = contract(&index_root).code;
        let outcome = call(&code, &calldata(&statement, &proof));
        let expected = verify(&index_root, &statement, &proof).expect("a reduction");
        assert_eq!(outcome.output.as_deref().and_then(decode), Some(expected));

        for at in [2, 3, 40, 49, 50, 53, 97, 99] {
            proof.stream[at] += F192::new(1, 2, 3);
            let returned = call(&code, &calldata(&statement, &proof)).output;
            assert_eq!(
                returned.as_deref().and_then(decode),
                verify(&index_root, &statement, &proof).ok(),
                "{at}"
            );
            proof.stream[at] += F192::new(1, 2, 3);
        }
        let mut other = statement;
        other.y[5] ^= 4;
        let returned = call(&code, &calldata(&other, &proof)).output;
        assert_eq!(
            returned.as_deref().and_then(decode),
            verify(&index_root, &other, &proof).ok()
        );

        let mut long = calldata(&statement, &proof);
        long.push(0);
        assert!(call(&code, &long).output.is_none());
        assert!(call(&code, &long[..long.len() - 2]).output.is_none());
    }

    /// What a call costs: `cargo test --release -p evm -- --ignored --nocapture gas_report`.
    #[test]
    #[ignore]
    fn gas_report() {
        let (index_root, statement, proof) = proof(&mut Rng::new(0x6A5));
        let contract = contract(&index_root);
        let data = calldata(&statement, &proof);
        let outcome = call(&contract.code, &data);
        assert!(outcome.output.is_some());
        let zeros = data.iter().filter(|&&byte| byte == 0).count();
        let standard = 16 * (data.len() - zeros) + 4 * zeros;
        let execution = outcome.gas as usize - 21_000 - standard;
        println!("code                 : {} bytes", contract.code.len());
        println!("calldata             : {} bytes, {zeros} of them zero", data.len());
        println!("FIELD_MUL            : {}", contract.field_muls);
        println!("KECCAK256            : {}", contract.hashes);
        println!("memory               : {} words", contract.memory_words);
        println!("execution            : {execution} gas");
        println!("transaction, EIP-7623: {} gas", outcome.gas);
        for claims in [0, 2] {
            let execution = execution + 20_000 * claims;
            println!(
                "with {claims} claims at 20,000: {} gas at a floor of 40 per byte, {} at 64",
                21_000 + (standard + execution).max(40 * (data.len() - zeros) + 10 * zeros),
                21_000 + (standard + execution).max(64 * data.len())
            );
        }
    }
}
