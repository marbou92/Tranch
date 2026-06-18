# Asset Manifest

This document is the **single source of truth** for every external asset used in Tranch.
No asset may be added to the project without an entry here.

## Strategy: CC0 placeholders now, custom assets later

Per the user's chosen strategy:
- **Phase 1 (M1–M4)**: Use CC0 / public-domain placeholder assets so the game is playable end-to-end without licensing friction.
- **Phase 2 (M5–M8)**: Swap placeholders for commissioned / custom assets one-for-one, keeping the same `res://` paths.

To swap an asset:
1. Drop the new file at the SAME path (e.g. `audio/enemies/janitor_ambient.ogg`).
2. Update the `License` and `Source` columns below.
3. Commit with message `asset: swap <asset_id> for final (<old> → <new>)`.

## Folder mapping

| Source folder (in this repo) | Godot `res://` path | Notes |
|---|---|---|
| `assets/audio/` | `audio/` | Drop originals here; CI copies to `audio/` |
| `assets/textures/` | (used by materials) | PNG/JPG source; imported via `.import` |
| `assets/models/` | (used by MeshInstance3D) | `.glb`/`.gltf` source |
| `assets/fonts/` | (used by UI) | TTF/OTF source |

## Manifest

> Format: one row per asset. Status = `placeholder` | `final` | `todo`.

### Audio — Music & Ambient

| Asset ID | res:// path | Status | License | Source | Notes |
|---|---|---|---|---|---|
| `music_calm_loop` | `audio/music/calm_loop.ogg` | todo | — | — | 5-layer stem system (GDD §8) |
| `music_tense_loop` | `audio/music/tense_loop.ogg` | todo | — | — | |
| `music_alert_loop` | `audio/music/alert_loop.ogg` | todo | — | — | |
| `music_chase_loop` | `audio/music/chase_loop.ogg` | todo | — | — | |
| `music_caught_sting` | `audio/music/caught_sting.ogg` | todo | — | — | Used ≤3 times total |
| `ambient_safe_room` | `audio/ambient/safe_room.ogg` | todo | — | — | Reversed sustained piano note |

### Audio — SFX

| Asset ID | res:// path | Status | License | Source | Notes |
|---|---|---|---|---|---|
| `sfx_heartbeat` | `audio/sfx/heartbeat.ogg` | todo | — | — | Loop, tempo-driven |
| `sfx_whisper` | `audio/sfx/whisper.ogg` | todo | — | — | Panned L/R randomly |
| `sfx_door_creak` | `audio/sfx/door_creak.ogg` | todo | — | — | Procedural ±15% pitch in code |
| `sfx_crawler_click` | `audio/sfx/crawler_click.ogg` | todo | — | — | High-pass filtered, binaural |
| `sfx_stone_throw` | `audio/sfx/stone_throw.ogg` | todo | — | — | Distraction item |
| `sfx_flashlight_click` | `audio/sfx/flashlight_click.ogg` | todo | — | — | |

### Audio — Enemy Cues

| Asset ID | res:// path | Status | License | Source | Notes |
|---|---|---|---|---|---|
| `janitor_ambient` | `audio/enemies/janitor_ambient.ogg` | todo | — | — | Dragging footstep, 15m cue |
| `janitor_alert` | `audio/enemies/janitor_alert.ogg` | todo | — | — | |
| `janitor_chase` | `audio/enemies/janitor_chase.ogg` | todo | — | — | |
| `janitor_radio` | `audio/enemies/janitor_radio.ogg` | todo | — | — | Distorted station, 20m cue |

### 3D Models

| Asset ID | res:// path | Status | License | Source | Notes |
|---|---|---|---|---|---|
| `player_first_person_arms` | (not yet linked) | todo | — | — | Hidden in FP view; just arm/hand rig |
| `janitor_body` | (not yet linked) | todo | — | — | ~1.9m, hunched posture |
| `crawler_body` | (not yet linked) | todo | — | — | Floor-dwelling, low profile |
| `teacher_body` | (not yet linked) | todo | — | — | Dr. Marsh, lab coat |
| `zone_main_building_shell` | (not yet linked) | todo | — | — | 3-floor exterior shell |
| (7 more zone shells) | | todo | | | See GDD §3 |

### Textures

| Asset ID | res:// path | Status | License | Source | Notes |
|---|---|---|---|---|---|
| `wall_pbr_set_01` | (not yet linked) | todo | — | — | Albedo + Normal + Roughness + AO |
| `floor_tile_set_01` | (not yet linked) | todo | — | — | |
| `wood_door_set_01` | (not yet linked) | todo | — | — | |

### Fonts

| Asset ID | res:// path | Status | License | Source | Notes |
|---|---|---|---|---|---|
| `font_body` | (not yet linked) | todo | — | — | Recommended: Inter or Noto Sans |
| `font_title` | (not yet linked) | todo | — | — | Recommended: Cinzel or similar serif |

---

## CC0 asset sources (recommended for placeholder phase)

- **Kenney.nl** — https://kenney.nl/assets — game-ready CC0 packs (buildings, props, audio)
- **Quaternius** — https://quaternius.com — CC0 3D models, especially `Ultimate Kit` series
- **CC0 Textures** — https://cc0textures.com — PBR texture sets
- **Pixabay Music** — https://pixabay.com/music/ — Pixabay License (close to CC0)
- **Freesound CC0** — https://freesound.org — filter by "CC0" license
- **Open Game Art** — https://opengameart.org — filter by "CC0" license

When adding an asset from these sources, fill in the License column with the exact license name (e.g. `CC0 1.0 Universal`, `Pixabay License`) and the Source column with the direct URL.
