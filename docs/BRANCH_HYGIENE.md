# Repository hygiene — branches and AI context

Audit: 2026-11-03, before cleanup. Default branch: `main`.

## Baseline

| Classification | Branches |
| --- | ---: |
| Total | 407 |
| `main` | 1 |
| Branches associated with merged PRs | 365 |
| Branches whose PRs were closed without merging | 33 |
| Branches without matching PRs | 8 |

No open PRs at audit time. The repo setting `delete_branch_on_merge` was **false**. Classification is an inventory, **not** permission to blindly remove all 365 heads: a branch might have moved since its PR merged. The executable audit cross-checks the PR's exact HEAD SHA, target `main`, matching repository, and current branch SHA before deletion.

## Safe cleanup procedure

1. Merge this PR after CI succeeds; do **not** delete branches before the cleanup tool exists on `main`.
2. In GitHub **Actions → Branch hygiene (manual, safe) → Run workflow**, leave **execute unchecked**. Inspect the job summary and `branch-hygiene-report` artifact.
3. Review `eligible_branches`, `review_required` and `preserved`. The action always leaves `main`, protected refs, `archive/*`, `checkpoint/*`, unknown branches and closed-without-merge PR heads untouched.
4. If the report is acceptable, rerun with **execute checked** and limit **10**, then repeat in batches of at most 50. Every execution fetches the fresh branch/PR inventory and rechecks each HEAD; unexpected changes are skipped.
5. Enable **Settings → General → Pull Requests → Automatically delete head branches** to prevent future accumulation. This repository setting cannot be changed by the installed GitHub connector.
6. Verify branch counts, `main`, PR status and Windows CI. Do not mix this cleanup with gameplay/art changes.

For CLI-only environments: `GITHUB_TOKEN=... python3 tools/branch_cleanup.py` is dry-run by default. Deletion additionally requires `ALLOW_BRANCH_DELETE=true python3 tools/branch_cleanup.py --execute --limit 10`. Use a token with Contents write and PR read. No Python dependencies beyond the standard library.

### Review separately (do not bulk-delete)

The 8 no-PR branches observed:
`archive/classic-before-topdown-2026-10-29`,
`checkpoint/v0.9`,
`docs/record-soul-altar-animated-vfx`,
`docs/soul-altar-production-handoff`,
`feat/soul-altar-approved-pixel-atlas`,
`feature/td2-synergy-visualization`,
`feature/v5-mouse-help-controls`,
`tests/td-fortress-snapshot-compatibility`.

The 33 closed-unmerged PR branches may hold abandoned, superseded or genuinely unique changes. Don't delete them automatically; compare against current `main` and examine their PR context first.

## AI context policy

**Canonical files:**
- `AGENTS.md` — workflow and safety rules (read first).
- `docs/AI_HANDOFF.md` — current focus, known blocker and next PR.
- `docs/PROJECT_STATE.md` — verified playable state, CI and remaining QA.
- `docs/ROADMAP.md` — authoritative ordered plan.
- `docs/ARCHITECTURE.md`, `docs/GAME_DESIGN.md`, `docs/DECISIONS.md` — consult as required by the task.

**Rules:**
- The source code, PR status and exact-head CI override stale document claims.
- Keep `AI_HANDOFF` and `PROJECT_STATE` focused on **current** reality. Do not append per-PR chronicles; the GitHub history already stores them.
- Detail for paused art work belongs in existing art docs, read only when working on art. Avoid reading all 42 `docs/` files for every gameplay change.
- Keep a small `AI_HANDOFF` section linking to task-specific technical notes; do not duplicate them.
- Do not mass-delete or rename docs until references from scripts, workflows, manifests and other documentation have been checked; archive obsolete notes in a separate small PR.
- Never confuse **deleting a branch** with deleting repo history: merged PR changes persist in `main`, while unmerged branch-only commits can eventually become unreachable.
