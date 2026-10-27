#!/usr/bin/env bash
# The Rust-to-Lean extraction of the crates that declare a hax scenario (crates/<crate>/hax.toml).
#
#   hax.sh setup               install the pinned cargo-hax, the charon and aeneas it resolves
#                              (hax.toml), and the Rust toolchain charon builds with
#   hax.sh extract [args]      regenerate every extraction; args go to `cargo hax extract`
#                              (scenario names, `-p <crate>`)
#   hax.sh extract --check     regenerate, then fail if the result differs from the commit
#   hax.sh patched <cmd...>    run a command on the patched source, e.g. `cargo test -p verifier`
#   hax.sh test                clippy and the tests of every patched crate, on the patched source:
#                              `cargo test -p <crate>`, or each line of patches/pre/tests as its args
#
# A scenario's patches live in crates/<crate>/proofs/<scenario>/patches. Those in pre/ rewrite
# the Rust source, only for the length of `extract` or `patched`: the committed source never
# carries them. Those in post/ (a last resort) rewrite the generated Lean after every extraction.
# Each extraction is then wired into the workspace in formal/extraction (wire.py).
set -euo pipefail

# cargo-hax is installed from this commit of https://github.com/cryspen/hax (0.4.2 and later
# fixes); charon, aeneas and the Lean libraries are pinned in the root hax.toml.
HAX_REV=721d1a2710b1d7020a0b32de7291fe791885d215

root=$(git rev-parse --show-toplevel)
cd "$root"

# The extraction models the portable code paths, the same on every host: the hardware features
# the crates dispatch on are off (on x86-64 they are off by default, with `target-cpu=native`
# overridden), so each `cfg(target_feature)` choice takes its fallback. The tests run on these
# paths too, the ones the extraction and its patches describe.
case "$(uname -m)" in
  arm64 | aarch64) export RUSTFLAGS="-C target-feature=-aes,-sha2,-sha3" ;;
  *) export RUSTFLAGS="" ;;
esac
export RUSTDOCFLAGS="$RUSTFLAGS" # doctests build with these

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
    --component rustc-dev,llvm-tools,rust-src,miri # miri builds charon's full-MIR standard library
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
  rm -f crates/*/proofs/*/lean/aeneas-error.log
  cargo hax extract "$@"
  revert
  for patch in crates/*/proofs/*/patches/post/*.patch; do
    if ! git apply "$patch"; then
      echo "error: $patch no longer applies to the generated Lean; refresh it (formal/extraction/README.md)" >&2
      exit 1
    fi
  done
  python3 formal/extraction/wire.py
  if $check; then
    git add --intent-to-add -- crates/*/proofs
    if ! git diff --exit-code -- crates/*/proofs; then
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

test_patched() {
  apply_patches
  local runs=() dir crate line
  for dir in crates/*/proofs/*/patches/pre; do
    local patches=("$dir"/*.patch)
    [[ ${#patches[@]} -gt 0 ]] || continue
    crate=$(basename "${dir%%/proofs/*}")
    cargo clippy --release -p "$crate" --all-targets -- -D warnings
    if [[ -f "$dir/tests" ]]; then
      while read -r line; do
        [[ -z "$line" || "$line" == \#* ]] || runs+=("$line")
      done < "$dir/tests"
    else
      runs+=("-p $crate")
    fi
  done
  # A suite several crates name (the verifier's checks against real proofs) runs once.
  local args
  while read -r -a args; do
    cargo test --release "${args[@]}"
  done < <(printf '%s\n' "${runs[@]}" | awk '!seen[$0]++')
}

case "${1:-}" in
  setup) setup ;;
  extract) shift; extract "$@" ;;
  patched) shift; patched "$@" ;;
  test) test_patched ;;
  *) usage ;;
esac
