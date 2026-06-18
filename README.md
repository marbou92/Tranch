# Tranch

> **"Don't run. He hears everything."**
>
> Open-world first-person horror survival set in Greenfield Academy.
> No combat. No weapons. Only darkness, silence, and footsteps that aren't yours.

**Engine:** Godot 4.3 (GDScript)
**Platforms:** Windows 7+ · Android 8.0+ (iOS 14+ planned for v1.1)
**Status:** Pre-alpha — vertical slice in development
**Version:** 0.1.0

---

## Quick start

### Requirements
- [Godot 4.3 stable](https://godotengine.org/download/) (mono NOT required — pure GDScript)
- ~200 MB disk space (will grow as assets are added)

### Run the game
```bash
# From the repo root:
godot --path .                    # Opens the editor
godot --path . --main-scene res://scenes/main.tscn   # Runs the game directly
```

### Run the test suite locally
```bash
# Headless smoke test (uses qa/test_playthrough.gd via scenes/test_runner.tscn)
godot --path . --headless --quit-after 8 res://scenes/test_runner.tscn

# GUT unit tests (requires GUT addon — see docs/TESTING.md)
godot --path . --headless -s addons/gut/gut_cmdln.gd -gdir=res://test/unit -gexit
```

---

## Repository layout

```
tranch/
├── autoloads/          # Singleton globals (EventBus, GameState, SanitySystem, …)
├── audio/              # In-engine audio paths (assets live in /assets/audio)
├── data/               # JSON data tables (items, lore notes)
├── enemies/            # AI scripts: Janitor, Crawler, Reflection, Teacher
├── inventory/          # 8-slot inventory system + UI
├── items/              # Interactable base class
├── localization/       # CSV string tables (en, fr, es, de)
├── mobile/             # Touch controls + haptics
├── player/             # Player controller, flashlight, scene
├── puzzles/            # 7 environmental puzzles
├── qa/                 # Headless test playthrough script
├── scenes/             # Main, test_room, test_runner
├── shaders/            # 9 custom .gdshader files (flashlight, sanity, hallucination…)
├── ui/                 # HUD, main menu, pause, death, journal, settings, a11y
├── zones/              # 8 zone scenes + zone_base + streaming manager
│
├── addons/gut/         # Godot Unit Test framework (installed via CI — see docs/TESTING.md)
├── test/               # GUT unit + integration tests
├── assets/             # SOURCE art/audio — see /assets/MANIFEST.md
├── docs/               # Roadmap, testing, CI/CD, asset strategy, contributing
├── .github/workflows/  # Lint, test, build pipelines
├── scripts/            # Dev helper scripts (asset validation, etc.)
└── project.godot
```

---

## CI/CD

| Workflow | Trigger | What it does |
|---|---|---|
| [`lint.yml`](.github/workflows/lint.yml) | every push & PR | `gdformat --check` + `gdlint` on all `.gd` files |
| [`test.yml`](.github/workflows/test.yml) | every push & PR | GUT unit tests + headless playthrough smoke test |
| [`build.yml`](.github/workflows/build.yml) | tags `v*` + manual | Exports Windows `.exe` and Android `.apk`, uploads as CI artifact (24h) |

All builds are **internal-only** for now (no auto-publish to stores). See [`docs/CI-CD.md`](docs/CI-CD.md) for the full pipeline diagram and how to extend it.

---

## Documentation

- [`docs/ROADMAP.md`](docs/ROADMAP.md) — Milestone breakdown (M0 → M8, ~6–9 months)
- [`docs/TESTING.md`](docs/TESTING.md) — How to run tests locally and in CI
- [`docs/CI-CD.md`](docs/CI-CD.md) — GitHub Actions pipeline architecture
- [`docs/ASSETS.md`](docs/ASSETS.md) — Asset intake process & CC0→custom swap strategy
- [`docs/CONTRIBUTING.md`](docs/CONTRIBUTING.md) — Branch model, commit conventions, PR checklist
- [`qa/MANUAL_QA_CHECKLIST.md`](qa/MANUAL_QA_CHECKLIST.md) — Human playthrough checklist
- **`Tranch_Master_Roadmap.pdf`** (in `/download/`) — Polished multi-chapter big-picture plan

---

## License

Source code: **MIT** (see [LICENSE](LICENSE)).
Game design document, narrative, characters, and the "Tranch" name: **All Rights Reserved**.

Third-party assets (when added) are listed in [`assets/MANIFEST.md`](assets/MANIFEST.md) with their individual licenses.
