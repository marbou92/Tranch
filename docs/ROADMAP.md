# Roadmap

> **Living document** — also see `Tranch_Master_Roadmap.pdf` for the polished version.
> Last updated: 2025-06-18 (M0)

This roadmap takes Tranch from the current pre-alpha code skeleton to a fully shippable horror game across Windows and Android. The user picked **Full content** scope with **Mix** asset strategy (CC0 placeholders now, custom assets later).

---

## Milestone overview

| ID | Name | Duration | Focus | Definition of Done |
|---|---|---|---|---|
| **M0** | Engineering foundation | 1 week | Repo, CI, tests, lint, build smoke | ✅ Green CI on every push; Windows + Android export artifacts produced |
| **M1** | Vertical slice — Main Building | 3 weeks | 1 zone fully playable end-to-end | Player can: spawn, walk, crouch, sprint, toggle flashlight, open 1 door, read 1 note, get caught by Janitor, see death screen, restart |
| **M2** | Core systems hardening | 2 weeks | Fix bugs found in M1; save/load round trip; sanity tier effects; inventory UI | Full save/load works; all 5 sanity tiers produce visible/audio symptoms |
| **M3** | Zones 2–4 (Science Wing, Gym, Cafeteria) | 4 weeks | 3 more zones + their puzzles + their key items | 4 zones playable back-to-back via courtyard; puzzles solvable |
| **M4** | Zones 5–6 (Courtyard, Maintenance) | 3 weeks | Hub zone + Harold's lair | All 6 interior zones interconnected; courtyard gate puzzle works |
| **M5** | Zone 7 (Basement Lab) + The Teacher | 2 weeks | Apex threat + 3-stage final puzzle | Teacher AI fully functional; final puzzle solvable; True Ending achievable |
| **M6** | Zone 8 (Exterior) + 3 endings | 1 week | All endings wired | Bad / True / Secret endings all reachable from in-game choices |
| **M7** | Asset replacement phase 1 | 4 weeks | Swap CC0 placeholders for final art | All `placeholder` rows in `assets/MANIFEST.md` become `final` |
| **M8** | Polish, balance, localization, ship | 3 weeks | QA, perf, full localization, store prep | 8 hr story playthrough stable at 30+ FPS on min-spec hardware |

**Total estimated duration: ~23 weeks (~5.5 months) for one full-time developer.**
For part-time / solo dev, multiply by 2–3×.

---

## M0 — Engineering foundation ✅ (this push)

**Goal:** Every push to GitHub runs lint + tests; every tag produces Windows + Android builds.

- [x] Fresh git repo with clean history
- [x] `.gitignore` correct for Godot 4
- [x] `README.md`, `LICENSE` (MIT for code, ARR for narrative/IP)
- [x] Fix missing `icon.svg`
- [x] Fix missing `InventorySystem` autoload (was breaking save/load)
- [x] Defensive audio loading (no crash on missing `.ogg`)
- [x] Add `WorldEnvironment` to `main.tscn` so scene renders
- [x] Add basic floor collision so player doesn't fall through
- [x] GUT addon install script (`scripts/install_gut.sh`)
- [x] 3 example GUT unit tests (sanity, game_state, inventory) — 30+ assertions
- [x] `scenes/test_runner.tscn` for headless playtest
- [x] `.github/workflows/lint.yml` — gdformat + gdlint + scene-ref check
- [x] `.github/workflows/test.yml` — GUT tests + headless playthrough
- [x] `.github/workflows/build.yml` — Windows + Android export, upload as artifacts
- [x] `export_presets.cfg` committed
- [x] `docs/` folder with ROADMAP, TESTING, CI-CD, ASSETS, CONTRIBUTING
- [x] `qa/MANUAL_QA_CHECKLIST.md` for human playthroughs
- [x] `assets/MANIFEST.md` with CC0→custom swap strategy

## M1 — Vertical slice (Main Building) — weeks 2–4

**Goal:** One zone fully playable from menu to death to restart. Proves the architecture works end-to-end.

### Build
- [ ] Replace placeholder `MainBuilding` floor/walls/ceiling with real CSG or mesh geometry (~12 rooms × 3 floors)
- [ ] Place 1 working door (open/close, locked state, slow/fast open noise radius)
- [ ] Place 1 readable lore note (uses `data/lore_notes.json` schema)
- [ ] Place 1 battery pickup
- [ ] Place 1 safe room (gazebo-style save point)
- [ ] Place 1 puzzle: principal's office combination lock (3-digit code visible on staff noticeboard)
- [ ] Spawn 1 Janitor with 4–6 patrol waypoints
- [ ] Spawn 1 zone-transition trigger to a stub courtyard

### Wire
- [ ] Main menu loads → "New Game" → MainBuilding.tscn with player at PlayerSpawn
- [ ] Journal UI opens with J, displays last-found note
- [ ] HUD shows flashlight battery bar; pulses red at <15%
- [ ] Pause menu (Esc) suspends simulation
- [ ] Death screen on Janitor catch → respawn at last save

### Acceptance test
> A new player (no prior knowledge) can: launch the game → start → walk to the staff room → read the code → enter the principal's office → pick up the key fragment → hide from the Janitor in a locker → escape to the safe room → save → quit → reload the save and resume in the same state.

## M2 — Core systems hardening — weeks 5–6

- [ ] Save/load round-trip tests for every subsystem (player, inventory, sanity, enemy state, zone state)
- [ ] All 5 sanity tiers (75–100, 50–74, 25–49, 10–24, 0–9) produce correct visual + audio + gameplay effects
- [ ] Inventory UI renders all 8 slots, supports drag-drop, stacking, item use
- [ ] Flashlight dim mode (G key) drains at 0.6/sec vs full 1.5/sec
- [ ] 5-layer music stem system (CALM/TENSE/ALERT/CHASE/CAUGHT) with crossfades
- [ ] Graphics tier auto-detection tested on 3 reference machines (LOW/MED/HIGH)

## M3 — Zones 2–4 — weeks 7–10

- [ ] Z-02 Science Wing: 8 rooms, valve puzzle, Crawler enemy intro
- [ ] Z-03 Gymnasium: padlock puzzle, rope item, Janitor extended patrol
- [ ] Z-04 Cafeteria: cold storage power puzzle, wire cutters
- [ ] All 3 zones connect to Z-05 Courtyard via zone triggers
- [ ] Crawler AI fully implemented (proximity trigger, lunge, retreat on flashlight)

## M4 — Zones 5–6 — weeks 11–13

- [ ] Z-05 Courtyard: hub, gazebo save, gate padlock (4-digit from 4 wing clues)
- [ ] Z-06 Maintenance: Harold's diary (4 notes), fuse box puzzle, elevator key
- [ ] Reflection enemy intro (appears in any mirror at sanity <60)
- [ ] Service elevator transition to basement

## M5 — Zone 7 + Teacher — weeks 14–15

- [ ] Z-07 Basement Lab: 5 rooms, 3-stage final puzzle
- [ ] Teacher AI: sound-only detection, never gives up during search
- [ ] Marsh's office → True Ending trigger
- [ ] TRN-7 antidote components → Secret Ending trigger

## M6 — Zone 8 + endings — week 16

- [ ] Z-08 Exterior: parking lot, bus stop (Bad Ending), perimeter gate (True Ending)
- [ ] All 3 endings have unique cutscene + epilogue text
- [ ] NG+ unlock after True Ending

## M7 — Asset replacement — weeks 17–20

For each row in `assets/MANIFEST.md` with status `placeholder`:
- [ ] Commission or create custom asset
- [ ] Drop at same `res://` path
- [ ] Update MANIFEST with `final` status, license, source URL
- [ ] Playtest zone where asset is used; verify no regressions
- [ ] Commit with `asset: swap <id> for final`

Priority order: Janitor model → Teacher model → wall PBR set → music stems → SFX → Crawler model → Reflection VFX.

## M8 — Polish & ship — weeks 21–23

- [ ] Full localization pass (en/fr/es/de — currently partial)
- [ ] Performance audit: 30 FPS locked on Tier 1 hardware (2 GB RAM, Intel HD 4000)
- [ ] Mobile control QA on 3 reference Android devices
- [ ] Accessibility: subtitle timing, colorblind palette, control remapping
- [ ] Permadeath mode integration test
- [ ] NG+ content (5 new notes, shifted patrol routes)
- [ ] Steam/itch.io store page prep (post-M8 decision)

---

## Risk register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Asset commissioning slips schedule | Medium | High | M1–M6 use CC0 placeholders; assets are decoupled from code via `MANIFEST.md` |
| Performance on Tier 1 hardware unachievable | Medium | High | Graphics tier manager exists; budget enforced via LOD/draw-distance settings; M8 perf audit early in M4 |
| Save/load corruption across versions | Medium | Critical | Save schema versioning added in M2; migration script per version |
| Janitor AI gets stuck on navigation | High | Medium | NavigationRegion3D baked per zone; M2 adds automated nav-stuck test |
| Mobile controls feel wrong on small screens | Medium | Medium | M3 playtest on real hardware weekly; haptics tuning in M4 |
| Localization strings break UI layout | Medium | Low | en source-of-truth CSV; fr/es/de translated after M6; UI auto-sizes to longest translation |
| Burnout (solo dev, 23-week schedule) | High | Critical | Cut M7 scope if needed — ship with CC0 assets. NEVER cut M2 (save/load). |

---

## Decision log

| Date | Decision | Rationale |
|---|---|---|
| 2025-06-18 | Use GUT v9.3.0 for unit tests | Industry standard for Godot 4, MIT licensed, CI-installable |
| 2025-06-18 | Windows + Android first; iOS deferred to v1.1 | User selected Win+Android; iOS requires Apple Developer cert ($99/yr) |
| 2025-06-18 | Internal-only CI artifacts; no auto-publish | User selected internal-only; revisit at M8 |
| 2025-06-18 | CC0 placeholders + custom later (Mix) | User selected Mix; gives path to ship without art-block |
