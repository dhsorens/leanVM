//! revm with `FIELD_MUL`.

use primitives::field::F192;
use revm::context::result::{ExecutionResult, Output};
use revm::context::{Context, TxEnv};
use revm::database::{CacheDB, EmptyDB};
use revm::handler::{ExecuteEvm, MainBuilder, MainContext};
use revm::interpreter::interpreter_types::{InterpreterTypes, StackTr};
use revm::interpreter::{InstructionContext, InstructionResult, gas};
use revm::primitives::{Address, Bytes, TxKind, U256};
use revm::state::{AccountInfo, Bytecode};

/// The opcode of `FIELD_MUL`, unassigned on mainnet.
pub const FIELD_MUL: u8 = 0x0c;
pub const FIELD_MUL_GAS: u64 = 10;

fn element(word: U256) -> F192 {
    let [c0, c1, c2, _] = word.into_limbs();
    F192::new(c0, c1, c2)
}

/// Pops two words and pushes the product of their low 192 bits as elements of `GF(2^192)`.
fn field_mul<W: InterpreterTypes, H: ?Sized>(context: InstructionContext<'_, H, W>) {
    gas!(context.interpreter, FIELD_MUL_GAS);
    let Some(([a], b)) = context.interpreter.stack.popn_top() else {
        context.interpreter.halt(InstructionResult::StackUnderflow);
        return;
    };
    let product = element(a) * element(*b);
    *b = U256::from_limbs([product.c0, product.c1, product.c2, 0]);
}

/// What a call did.
#[derive(Debug)]
pub struct Outcome {
    /// What it returned, or `None` if it reverted or halted.
    pub output: Option<Vec<u8>>,
    /// The transaction's gas, intrinsic cost and calldata floor included.
    pub gas: u64,
}

/// Call a contract holding `code` with `calldata`, in one transaction.
pub fn call(code: &[u8], calldata: &[u8]) -> Outcome {
    let (contract, caller) = (Address::with_last_byte(0xc0), Address::with_last_byte(0xca));
    let mut db = CacheDB::new(EmptyDB::default());
    db.insert_account_info(
        contract,
        AccountInfo::from_bytecode(Bytecode::new_legacy(Bytes::copy_from_slice(code))),
    );
    let mut evm = Context::mainnet().with_db(db).build_mainnet();
    evm.instruction.insert_instruction(FIELD_MUL, field_mul);
    let tx = TxEnv::builder()
        .caller(caller)
        .kind(TxKind::Call(contract))
        .data(Bytes::copy_from_slice(calldata))
        .gas_limit(10_000_000)
        .build()
        .expect("a transaction");
    match evm.transact_one(tx).expect("a valid transaction") {
        ExecutionResult::Success {
            gas_used,
            output: Output::Call(output),
            ..
        } => Outcome {
            output: Some(output.to_vec()),
            gas: gas_used,
        },
        other => Outcome {
            output: None,
            gas: other.gas_used(),
        },
    }
}
