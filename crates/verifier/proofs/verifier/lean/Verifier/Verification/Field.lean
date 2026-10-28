import Verifier.Verification.Field.Base
import Verifier.Verification.Field.Ext

/-! The verifier's fields are CompPoly's: the extracted `K` and `E` products are `BF64` and `Ext3`
multiplication (`Field.mul_ok`, `Field.E_mul_ok`), so ArkLib's statements over those fields
apply to the extracted arithmetic. -/
