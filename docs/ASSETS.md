# Asset Intake Process

This document describes how 3D models, audio, textures, and fonts get from "found on the internet" or "received from a contractor" into the game.

**Single source of truth for asset status:** [`assets/MANIFEST.md`](../assets/MANIFEST.md)

## Folder structure

```
assets/                     ← SOURCE assets (organized by type)
├── MANIFEST.md             ← every asset listed here
├── audio/
│   ├── ambient/
│   ├── enemies/
│   ├── music/
│   └── sfx/
├── models/                 ← .glb / .gltf source files
├── textures/               ← PNG/JPG source, organised by material set
└── fonts/                  ← TTF/OTF source

audio/                      ← IN-ENGINE paths (Godot res://)
├── ambient/                ← (these are what scripts reference)
├── enemies/
├── music/
└── sfx/
```

The `assets/audio/` and `audio/` folders mirror each other. CI (or the dev) copies files from `assets/audio/<file>` to `audio/<file>`. This split exists so:
- `assets/` holds the SOURCE (high-resolution, editable)
- `audio/` / `textures/` / etc. hold the IMPORTED versions Godot actually uses
- The `.godot/imported/` cache stays out of git (per `.gitignore`)

## CC0 placeholder workflow (M1–M6)

1. **Identify need** — a script references `res://audio/enemies/janitor_ambient.ogg` and the file doesn't exist
2. **Find CC0 source** — see `assets/MANIFEST.md` "CC0 asset sources" section for recommended sites
3. **Download** to `assets/audio/enemies/janitor_ambient.ogg` (or appropriate subdir)
4. **Convert** to `.ogg` (audio) or `.glb` (3D) or `.png` (texture) if needed:
   ```bash
   # Audio: ffmpeg can convert anything to Ogg Vorbis
   ffmpeg -i input.wav -c:a libvorbis -qscale:a 5 assets/audio/enemies/janitor_ambient.ogg

   # 3D: use Blender to export .glb, or gltf-transform for CLI conversion
   gltf-transform optimize input.gltf assets/models/janitor_body.glb
   ```
5. **Copy to engine path**: `cp assets/audio/enemies/janitor_ambient.ogg audio/enemies/`
6. **Update MANIFEST.md**: change status from `todo` → `placeholder`, fill in License + Source URL
7. **Open Godot editor** once so it imports the asset and creates the `.import` file
8. **Commit** with: `git add assets/ audio/ .godot/imported/` and message `asset: add CC0 placeholder <asset_id>`

## Custom asset replacement workflow (M7+)

1. **Commission or create** the replacement asset
2. **Save at the SAME path** in `assets/` (e.g. `assets/audio/enemies/janitor_ambient.ogg` overwrites the CC0 version)
3. **Copy to engine path**: `cp assets/audio/enemies/janitor_ambient.ogg audio/enemies/`
4. **Reimport in Godot**: Project menu → Reload Current Project (or just restart Godot)
5. **Update MANIFEST.md**: change status from `placeholder` → `final`, update License + Source
6. **Playtest** the zone where this asset is used — verify no regression
7. **Commit** with: `asset: swap <asset_id> for final (<old_license> → <new_license>)`

## Naming conventions

| Type | Convention | Example |
|---|---|---|
| Audio | `<purpose>_<descriptor>.ogg` | `janitor_ambient.ogg`, `sfx_door_creak.ogg` |
| 3D model | `<entity>_<part>.glb` | `janitor_body.glb`, `zone_main_building_shell.glb` |
| Texture | `<surface>_<set>_<map>.png` | `wall_pbr_set_01_roughness.png` |
| Font | `font_<role>.ttf` | `font_body.ttf`, `font_title.ttf` |

Always lowercase, underscores, no spaces.

## License requirements

| License | Allowed in Tranch? | Attribution required? | Notes |
|---|---|---|---|
| CC0 1.0 Universal | ✅ Yes | No | Preferred for placeholders |
| CC-BY 3.0/4.0 | ✅ Yes | Yes (in `CREDITS.md` and in-game credits screen) | |
| CC-BY-SA 3.0/4.0 | ⚠️ Avoid | Yes | Triggers copyleft on derivative works — discuss before use |
| CC-BY-NC * | ❌ No | — | Non-commercial clauses incompatible with future commercial release |
| Pixabay License | ✅ Yes | No (similar to CC0) | |
| Kenney.nl CC0 | ✅ Yes | No (attribution appreciated but not required) | |
| Freesound CC0 | ✅ Yes | No | Filter license=CC0 when searching |
| GPL/LGPL | ❌ No | — | Copyleft incompatible with closed-source game shipping |
| Proprietary / "All Rights Reserved" | ✅ Yes if you own it or have written permission | Per agreement | Commissioned assets fall here |

When in doubt: **do not commit the asset**. Ask first.

## CREDITS.md (created at M8)

At ship time, `CREDITS.md` lists every asset that requires attribution, alphabetically by author. The in-game credits screen (a new UI panel added in M8) mirrors this file.

## Quality bar

### Placeholder (CC0) — acceptable for M1–M6
- Audio: 128 kbps Ogg Vorbis, mono or stereo as appropriate
- 3D: low-poly is fine; ideally <5000 tris for prop, <20000 tris for zone shell
- Texture: 512×512 to 1024×1024; tileable for floors/walls

### Final (M7+) — required for ship
- Audio: 192+ kbps Ogg Vorbis, normalized to -16 LUFS
- 3D: per GDD §3 detail; LOD0 <30000 tris, LOD1 <10000, LOD2 <3000
- Texture: 2K PBR set (albedo + normal + roughness + AO + height), tileable variants for surfaces
- Animation: rigged characters need walk/run/idle/alert at minimum (Janitor needs 7 anims per state machine)
