import QuotientSecurity.Bits
import QuotientSecurity.RandomOracle
import QuotientSecurity.ZeroKnowledge
import QuotientSecurity.Encoding

/-- info: 'QuotientSecurity.verifier_rbrKnowledgeSoundness' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms QuotientSecurity.verifier_rbrKnowledgeSoundness

/-- info: 'QuotientSecurity.rbrError_le' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms QuotientSecurity.rbrError_le

/-- info: 'QuotientSecurity.knowledgeSoundness' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms QuotientSecurity.knowledgeSoundness

/-- info: 'QuotientSecurity.knowledgeSoundness_bits' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms QuotientSecurity.knowledgeSoundness_bits

/-- info: 'QuotientSecurity.realValues_uniform' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms QuotientSecurity.realValues_uniform

/-- info: 'QuotientSecurity.baseValues_uniform' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms QuotientSecurity.baseValues_uniform
