#!/usr/bin/env bash
# What each extraction takes on trust, as Markdown: the Rust items left opaque (axioms in
# Assumptions/), the standard-library models (Assumptions/Std.lean), the bodies Aeneas could
# not translate (`sorry` in Extraction/), and the pre-extraction patches.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

count() { grep -cE "$1" "$2" 2>/dev/null || true; }

echo "| extraction | definitions | opaque Rust items | std models (opaque) | sorry | patches |"
echo "| --- | ---: | ---: | ---: | ---: | ---: |"
for lean in crates/*/proofs/*/lean; do
  pkg=$(awk -F'"' '/^name = /{ print $2; exit }' "$lean/lakefile.toml")
  ext="$lean/$pkg/Extraction"
  asm="$lean/$pkg/Assumptions"
  defs=$(cat "$ext"/Types.lean "$ext"/Funs.lean | grep -cE '^(@\[[^]]*\] *)*(def|structure|inductive|instance) ' || true)
  axioms=$(cat "$asm"/*External.lean 2>/dev/null | grep -cE '^axiom ' || true)
  std=$(count '^(def|opaque|abbrev|instance) ' "$asm/Std.lean")
  std_opaque=$(count '^opaque ' "$asm/Std.lean")
  sorries=$(cat "$ext"/Types.lean "$ext"/Funs.lean | grep -cw sorry || true)
  patches=$(find "${lean%/lean}/patches" -name '*.patch' 2>/dev/null | wc -l | tr -d ' ')
  echo "| \`${lean%/lean}\` | $defs | $axioms | $std ($std_opaque) | $sorries | $patches |"
done
