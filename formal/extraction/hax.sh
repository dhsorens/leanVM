#!/usr/bin/env bash
# The Rust-to-Lean extraction of the crates that declare a hax scenario (crates/<crate>/hax.toml).
#
#   hax.sh setup               install the pinned cargo-hax, the charon and aeneas it resolves
#                              (hax.toml), and the Rust toolchain charon builds with
#   hax.sh extract [args]      regenerate every extraction; args go to `cargo hax extract`
#                              (scenario names, `-p <crate>`)
#   hax.sh extract --check     regenerate, then fail if the result differs from the commit
#   hax.sh patched <cmd...>    run a command on the patched source, e.g. `cargo test -p verifier`
#
# A scenario's patches live in crates/<crate>/proofs/<scenario>/patches. Those in pre/ rewrite
# the Rust source, only for the length of `extract` or `patched`: the committed source never
# carries them. Those in post/ (a last resort) rewrite the generated Lean after every extraction.
# Each extraction's Assumptions/ is then synced with the templates hax regenerates.
set -euo pipefail

# cargo-hax is installed from this commit of https://github.com/cryspen/hax (0.4.2 and later
# fixes); charon, aeneas and the Lean libraries are pinned in the root hax.toml.
HAX_REV=721d1a2710b1d7020a0b32de7291fe791885d215

root=$(git rev-parse --show-toplevel)
cd "$root"

usage() {
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
  exit 2
}

setup() {
  if ! cargo hax --version 2>/dev/null | grep -q "${HAX_REV:0:10}"; then
    cargo install --locked --force --git https://github.com/cryspen/hax --rev "$HAX_REV" cargo-hax
  fi
  cargo hax tools install
  local version charon
  version=$(cargo hax tools show | awk '$1 == "charon" { print $2; exit }')
  charon="${XDG_CACHE_HOME:-$HOME/.cache}/hax/tools/charon/$version/charon"
  rustup toolchain install "$("$charon" toolchain-version)" --profile minimal \
    --component rustc-dev,llvm-tools,rust-src
}

applied=()
revert() {
  for ((i = ${#applied[@]} - 1; i >= 0; i--)); do
    git apply -R "${applied[i]}"
  done
  applied=()
}

apply_patches() {
  trap revert EXIT
  shopt -s nullglob
  for patch in crates/*/proofs/*/patches/pre/*.patch; do
    if ! git apply "$patch"; then
      echo "error: $patch no longer applies to the Rust source; refresh it (formal/extraction/README.md)" >&2
      exit 1
    fi
    applied+=("$patch")
  done
}

extract() {
  local check=false
  if [[ "${1:-}" == "--check" ]]; then
    check=true
    shift
  fi
  apply_patches
  cargo hax extract "$@"
  revert
  for patch in crates/*/proofs/*/patches/post/*.patch; do
    if ! git apply "$patch"; then
      echo "error: $patch no longer applies to the generated Lean; refresh it (formal/extraction/README.md)" >&2
      exit 1
    fi
  done
  python3 formal/extraction/sync_assumptions.py crates/*/proofs/*/lean
  if $check; then
    git add --intent-to-add -- crates/*/proofs
    if ! git diff --exit-code --stat -- crates/*/proofs; then
      echo "error: the committed extraction is stale; run formal/extraction/hax.sh extract and commit the result" >&2
      exit 1
    fi
  fi
}

patched() {
  [[ $# -gt 0 ]] || usage
  apply_patches
  "$@"
}

case "${1:-}" in
  setup) setup ;;
  extract) shift; extract "$@" ;;
  patched) shift; patched "$@" ;;
  *) usage ;;
esac
