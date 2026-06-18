# Contributing

Tranch is currently a single-developer project, but the process below keeps the history clean and makes future collaboration (or returning to a section after months away) painless.

## Branch model

```
main              ← shippable. Always green CI. Tagged with v0.1, v0.2, …
 └── develop      ← integration branch for the next milestone
      └── feature/<short-name>   ← one branch per feature/fix
      └── fix/<short-name>
      └── asset/<asset-id>       ← one branch per asset swap (see docs/ASSETS.md)
```

- **`main`**: only ever receives merge commits from `develop` (or hotfixes). Tagged at the end of each milestone.
- **`develop`**: where milestone work integrates. May temporarily be red CI during a milestone — that's OK.
- **`feature/*`, `fix/*`, `asset/*`**: short-lived, one purpose per branch, rebased onto `develop` before merge.

## Commit conventions

Format: `<type>(<scope>): <subject>`

| Type | When to use |
|---|---|
| `feat` | New feature (new puzzle, new enemy state, new UI panel) |
| `fix` | Bug fix |
| `refactor` | Code restructure without behaviour change |
| `test` | Adding or changing tests |
| `asset` | Adding or swapping a non-code asset (see `docs/ASSETS.md`) |
| `docs` | Documentation only |
| `ci` | CI/CD config changes |
| `chore` | Misc (gitignore, editor config, dependency bumps) |

Examples:
```
feat(janitor): add search state sweep pattern
fix(save-load): restore enemy state enum correctly
test(inventory): add stack-overflow edge case
asset(sfx): swap door_creak placeholder for final (CC0 → custom)
docs(roadmap): update M3 progress
ci(build): cache Godot templates across jobs
```

Subject line: imperative mood, lowercase first word, no period, ≤72 chars.

Body (optional, for non-trivial commits): explain **why**, not **what**. Wrap at 72 chars.

## Pull request checklist

Before clicking "Create pull request":

- [ ] Branch is rebased on latest `develop`
- [ ] `gdformat --check` passes locally
- [ ] `gdlint` produces no new warnings vs. develop
- [ ] New unit tests added for any new logic (target: every public function)
- [ ] All existing unit tests pass
- [ ] Headless playthrough still prints `ALL TESTS PASSED`
- [ ] If adding an asset: `assets/MANIFEST.md` updated
- [ ] If changing gameplay: `qa/MANUAL_QA_CHECKLIST.md` updated
- [ ] PR description explains the **what** and **why**; links to any related issue

## PR review

For solo development, the "review" step is: open the PR yourself the next morning, read the diff cold, and ask "would I understand this in 6 months?". If no, add comments or refactor before merging.

Squash-merge feature branches into `develop`. Use a no-ff merge when bringing `develop` into `main` (preserves the milestone boundary in history).

## Release process (per milestone)

1. Cut `release/v0.X` branch from `develop`
2. Run full `qa/MANUAL_QA_CHECKLIST.md`
3. Fix any blockers directly on `release/v0.X`
4. Update `project.godot` `config/version`
5. Merge `release/v0.X` → `main` (no-ff)
6. Tag `main` as `v0.X.0` — this triggers `build.yml`
7. Download Windows + Android artifacts, smoke-test on real hardware
8. Merge `main` back into `develop`

## Issue tracking

GitHub Issues with labels:

| Label | Meaning |
|---|---|
| `bug` | Something broken |
| `feature` | New gameplay/system |
| `milestone:M1` … `M8` | Which milestone this belongs to |
| `priority:high/medium/low` | Urgency |
| `size:S/M/L/XL` | Rough effort (½ day / 1–2 days / 1 week / 2+ weeks) |
| `good first issue` | Beginner-friendly (small, isolated, well-described) |
| `needs:assets` | Blocked on asset creation/swap |
| `needs:design` | Blocked on GDD clarification |

Use GitHub Projects (kanban) to visualise the current milestone's work.
