# Testing

Tranch uses three layers of testing, from cheap-and-fast to expensive-and-thorough.

## Layer 1 — Static lint (every PR, ~30 seconds)

**Tools:** `gdformat` (formatter) + `gdlint` (linter) from [gdtoolkit](https://github.com/Scony/godot-gdscript-toolkit).

**What it catches:** style violations, unused variables, naming issues, formatting drift.

```bash
# Install locally
pip install gdtoolkit==4.*

# Check formatting (CI fails if this returns non-zero)
gdformat --check $(find . -name "*.gd" -not -path "./addons/*")

# Auto-fix formatting
gdformat $(find . -name "*.gd" -not -path "./addons/*")

# Lint (non-blocking in CI for now)
gdlint $(find . -name "*.gd" -not -path "./addons/*")
```

**Scene reference check:** A Python script in `.github/workflows/lint.yml` opens every `.tscn` file and verifies that every `ext_resource path="..."` actually exists on disk. This catches the most common Godot bug: renaming a `.gd` file but forgetting to update scenes that reference it.

## Layer 2 — GUT unit tests (every PR, ~1 minute)

**Tool:** [GUT (Godot Unit Test)](https://github.com/bitwes/Gut) — the standard unit test framework for Godot 4.

**What it tests:** pure logic — sanity drain rates, inventory stacking rules, game state transitions, puzzle state machines. No rendering, no physics, no audio.

### Run locally

```bash
# One-time: install GUT addon
bash scripts/install_gut.sh

# Run all unit tests
godot --headless --path . \
  -s addons/gut/gut_cmdln.gd \
  -gdir=res://test/unit \
  -gexit
```

### Write a new test

1. Create `test/unit/test_<system>.gd`
2. `extends GutTest`
3. Use `before_each()` to reset state
4. Use `assert_eq(actual, expected, "message")`, `assert_true()`, `assert_false()`, `assert_lt()`, etc.
5. Each `func test_*()` is one test case

Example (from `test/unit/test_sanity_system.gd`):
```gdscript
extends GutTest

func before_each():
    SanitySystem.sanity = 100.0

func test_drain_dark_reduces_sanity():
    var start := SanitySystem.sanity
    SanitySystem.drain_dark(1.0)
    assert_lt(SanitySystem.sanity, start, "Sanity should drop in the dark")
```

### Current test coverage

| System | Tests | Assertions |
|---|---|---|
| SanitySystem | 9 | ~15 |
| GameState | 9 | ~12 |
| InventorySystem | 7 | ~20 |
| **Total** | **25** | **~47** |

**M2 target:** 100+ unit tests covering all 7 puzzles, save/load round-trips, all 4 enemy AIs.

## Layer 3 — Headless playthrough smoke test (every PR, ~30 seconds)

**Tool:** `qa/test_playthrough.gd` + `scenes/test_runner.tscn`, run via Godot headless.

**What it tests:** that the project actually boots, the test scene loads, the player spawns, autoloads initialize, and no script throws an unhandled error in the first 10 seconds.

### Run locally

```bash
godot --headless --path . \
  --main-scene res://scenes/test_runner.tscn \
  --quit-after 10
```

CI scans the output for:
- `SCRIPT ERROR` — any uncaught script error → fail
- `Cannot` — Godot's "cannot find resource" messages → fail
- `FAIL:` or `SOME TESTS FAILED` — from the playthrough script's own assertions → fail
- Missing `=== TRANCH QA TEST SUITE ===` banner → scene failed to load → fail

### Extending the playthrough

`qa/test_playthrough.gd` is a hand-written integration test runner. To add a check:

```gdscript
func _test_my_new_thing():
    _start_test("My New Thing")
    var actual = SomeSystem.compute_something()
    if actual == expected_value:
        _pass("compute_something returned correct value")
    else:
        _fail("compute_something returned %s, expected %s" % [actual, expected_value])
```

Then add `_test_my_new_thing()` to the `_run_all_tests()` function.

## Layer 4 — Manual QA checklist (before each release tag)

See [`qa/MANUAL_QA_CHECKLIST.md`](../qa/MANUAL_QA_CHECKLIST.md). A human must play through the game and tick every box before tagging a release. This catches everything automation can't: "does this feel scary?", "is the puzzle fair?", "does the music transition feel right?".

## Layer 5 — Build smoke test (on every tag)

`.github/workflows/build.yml` exports Windows and Android builds and verifies the export process succeeds and produces a non-zero-byte binary. It does NOT launch the binary in CI (that would require GPU + display). The user downloads the artifact and launches it locally.

## CI matrix summary

| Layer | When | Runtime | Failure = block merge? |
|---|---|---|---|
| Lint (gdformat) | every PR | ~30s | Yes |
| Lint (gdlint) | every PR | ~30s | No (advisory) |
| Scene ref check | every PR | ~10s | Yes |
| GUT unit tests | every PR | ~1min | Yes |
| Headless playthrough | every PR | ~30s | Yes |
| Build (Win+Android) | every tag `v*` | ~10min | Yes (release blocker) |
| Manual QA | before tag | ~2hrs | Yes (sign-off required) |
