# Repository hygiene — branches

## Current policy (since 2026-11-03)

- **`main` is the only long-lived branch.** Work happens in short PR branches; GitHub deletes them automatically after merge (`delete_branch_on_merge=true`).
- Nothing is stored only in a branch. Old work is recoverable from either `main` history or the PR ref GitHub keeps forever (`refs/pull/<N>/head`).
- Release tags: `windows-preview` (rolling Windows build), `soul-altar-approved-rgba-v1` (approved art archive).

## Recovering an archived branch

Every removed branch is listed with its exact SHA in [`branch_archive.tsv`](branch_archive.tsv).

```sh
# recovery = pull/N/head
git fetch origin pull/316/head:feat/soul-altar-approved-pixel-art-runtime
# recovery = main  (commit is already part of main history)
git branch archive/classic-before-topdown-2026-10-29 c750d54c96296c2371300b12de2e42ca74097ae1
```

Notable entries: the classic platformer snapshot `archive/classic-before-topdown-2026-10-29` (`c750d54`) and `checkpoint/v0.9` (`5cf1db0`) are both contained in `main` history.

## How branches are removed

1. Add rows (`branch`, exact 40-char `sha`, `recovery`, note) to `docs/branch_archive.tsv` in a PR. `recovery` must be `main` or `pull/N/head`. A branch without a PR gets a PR opened and closed first (see #401–#403) so GitHub pins its commits.
2. CI runs `tests/test_branch_cleanup.py`, which validates the file format.
3. After merge, the **Branch hygiene** workflow (push trigger on that file) runs `tools/branch_cleanup.py --archive-list docs/branch_archive.tsv --execute`. Each branch is deleted only if its current SHA still equals the listed SHA **and** the SHA is an ancestor of `main` or equals PR #N's head. Anything else is skipped and reported.
4. Dry run locally: `GITHUB_TOKEN=... python3 tools/branch_cleanup.py --archive-list docs/branch_archive.tsv`.

The manual `workflow_dispatch` mode (merged-PR heads only, dry-run by default) is still available for routine pruning.

## History

- 2026-11-03 (#400): 365 merged-PR branches removed with the exact-HEAD audit; 41 left for review.
- 2026-11-03: the remaining 41 (5 contained in `main`, 36 closed-unmerged or PR-less, all superseded by later merged work) archived via `branch_archive.tsv`.
