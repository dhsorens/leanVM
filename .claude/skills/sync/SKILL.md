---
name: sync
description: Sync this fork's main with leanEthereum/leanVM main and bring the hax Rust-to-Lean extractions back to a clean state. Use when asked to sync, update or catch up the fork with upstream, or to repair the extractions after upstream moved.
---

# Sync the fork with upstream and repair the extractions

This fork is upstream's Rust plus the hax extraction of it to Lean. The Rust is never edited here. What the fork owns is each crate's `hax.toml` and `proofs/`, `formal/extraction/`, `.github/workflows/extraction.yml`, `VERIFICATION.md` and one bullet in `AGENTS.md`.

**Done means:** the fork's `main` is some commits ahead of and **zero behind** `leanEthereum/leanVM:main`, every scenario extracts with no `sorry`, the workspace builds, and the docs say what the state is. The result goes on `main` of the fork, not on a side branch and not in a pull request.

The remotes are `origin` for upstream (leanEthereum/leanVM) and `fork` for dhsorens/leanVM. Check with `git remote -v` before pushing.

`formal/extraction/README.md` is the reference for the tools. This file is the order to do things in.

## 1. Merge

Work in a worktree of `main` (share `CARGO_TARGET_DIR` with the main checkout, and remove the worktree when done).

```bash
git fetch origin && git fetch fork
git merge origin/main
```

Merge, do not rebase: the fork's history stays a fast-forward, so the push needs no force. Conflicts can only be in files the fork adds; for `AGENTS.md` take upstream's and re-add the extraction bullet.

Then see what moved: `git diff --stat ORIG_HEAD HEAD -- crates ':!crates/**/proofs'`. A crate that is new, renamed, split or deleted needs step 2. Otherwise go to step 3.

## 2. Follow crates that moved

`repair.py` does not do this.

- **Renamed or moved:** `git mv` its `hax.toml` scenario and `proofs/<scenario>` with it, and rename the scenario to match. Delete the old generated `lean/` package: a stale one corrupts the workspace's Lake manifest.
- **Split:** one scenario per new crate, the old lists divided between them.
- **New:** a `hax.toml` with an empty `[scenario.<name>]`, modelled on a small one such as `crates/claims/hax.toml`. Skip crates upstream marks experimental.
- **Deleted:** delete its `proofs/` and scenario.

## 3. Repair

```bash
formal/extraction/repair.py patches     # keeps hunks whose context is still there, drops the rest
formal/extraction/repair.py extract     # every scenario, in dependency order
```

`repair.py extract` loops extract and Lean build per crate, and puts whatever no longer translates on the scenario's `opaque` (or `exclude`) list under a dated heading with the error. Save its output: it is the record of what the sync cost. Run one extraction at a time per checkout, because `hax.sh` patches the source while it runs.

Where it stops and needs a hand:

- **Aeneas crashes on the whole crate and names no item.** Bisect by marking modules opaque (`"crate::module"`), then narrow to the item.
- **A signature Aeneas refuses** (`dyn Fn`, a function pointer, `impl Iterator` result) must be on `exclude`, not `opaque`: an opaque item still needs its signature translated.
- **Charon fails on a name that is gone.** The tool removes entries Charon reports; an `include` naming a gone item is removed by hand.
- **Lean reports an unknown `core.*` or `alloc.*` constant in several crates.** Model it once in `formal/extraction/CoreModelsExt` rather than leaving each user opaque.

## 4. Win coverage back, with as few patches as possible

The repair only shrinks the extraction. Before calling the sync done, go through the entries under the new dated heading, cheapest fix first:

1. **A model in `CoreModelsExt`** when the error is a missing standard-library item. One model clears every crate that uses it, and nothing has to be kept in step with upstream's source.
2. **A rule in `mechanical.py`** when the same rewrite recurs across crates. It is regenerated from the source each time, so it never goes stale.
3. **A hand patch in `patches/pre/`** only for an item worth having a body for (a verifier or signature entry point, core arithmetic). Every patch is a cost at the next sync, so keep each small, one construct per patch, and add the crate's tests to `patches/pre/tests`.
4. **Leave it opaque** with the reason, when none of the above is cheap.

Remove an entry from the list and rerun `repair.py extract <crate dir>` to see whether the fix holds. Never edit generated Lean, and never silence a warning.

## 5. Verify

All of these must pass before pushing:

```bash
formal/extraction/hax.sh extract --check     # the committed extraction is what the source gives
formal/extraction/hax.sh test                # clippy and tests on the patched source
(cd formal/extraction && lake build)         # the whole workspace
grep -rl sorry crates/*/proofs/*/lean/*/Extraction crates/*/*/proofs/*/lean/*/Extraction   # nothing
formal/extraction/report.sh                  # the counts
```

`hax.sh test` is not optional: a patch hunk can still apply and be wrong for the new code. The build has one known warning, `dupNamespace` in `CoreModelsExt/Collections.lean`; any other is new and is fixed, not suppressed.

## 6. Record and push

- Update the coverage table and the sync section of `formal/extraction/LIMITATIONS.md` from `report.sh`, and the date and status in `VERIFICATION.md`.
- If the tool needed help, teach `repair.py` the case so the next sync does not.
- Commit in steps a reader can follow: the merge, the crate moves, the repair, the fixes, the docs. No attribution trailers.
- Push to the fork's `main` and confirm the count:

```bash
git push fork HEAD:main
git fetch fork && git rev-list --left-right --count origin/main...fork/main    # first number must be 0
```

Report in a few lines: commits merged, what went opaque and what was won back, the `report.sh` totals, and anything left for a decision.
