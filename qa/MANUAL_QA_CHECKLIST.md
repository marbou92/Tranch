# Manual QA Checklist

> A human must complete this checklist before tagging any release (`v0.X.0`).
> Automation catches code bugs; this catches feel, atmosphere, and design issues.

Copy this file to `qa/checklists/YYYY-MM-DD-vX.Y.md` before starting, then tick boxes as you go.

---

## Pre-flight (5 minutes)

- [ ] Pull latest `main`, clean rebuild, no editor warnings in console
- [ ] `git describe --tags` shows the expected version
- [ ] CI is green on the commit you're testing
- [ ] Fresh save folder: delete `~/.local/share/godot/app_userdata/Tranch/saves/` (or `%APPDATA%\Godot\app_userdata\Tranch\saves` on Windows)

## Boot & menu (5 min)

- [ ] Game launches within 5 seconds
- [ ] Main menu shows: Tranch logo, school exterior photo, 4 menu options (New Game / Continue / Settings / Quit)
- [ ] "Continue" is greyed out when no save exists
- [ ] "Settings" opens, all sliders/buttons respond
- [ ] Changing graphics tier takes effect immediately (no restart needed)
- [ ] Quit works without crash

## Player controller — Tier 3 (HIGH) hardware (10 min)

- [ ] Walk forward/back/left/right with WASD — smooth, no stutter
- [ ] Mouse look is responsive, not laggy, inverts correctly when "Invert Y" toggled
- [ ] Crouch (C) lowers camera, slows movement, silent footsteps
- [ ] Sprint (Shift) drains stamina bar over 3s, cooldown 6s before sprint again
- [ ] Sprint noise radius feels right (Janitor within ~8m should react)
- [ ] Cannot sprint while crouched
- [ ] Cannot sprint while flashlight off (per GDD §6 — actually wait, GDD says sprint works without flashlight; verify design intent)
- [ ] Head bob: subtle on walk, off on crouch, strong on sprint
- [ ] No jumping (GDD §6 — jump disabled)
- [ ] Step over small debris (0.35m step height) — find a low obstacle and verify

## Flashlight (5 min)

- [ ] F toggles flashlight on/off
- [ ] Battery drains at ~1.5%/sec on full beam
- [ ] G toggles dim mode — drain drops to ~0.6%/sec, cone narrows
- [ ] Battery hits 0% — flashlight auto-turns off
- [ ] Pick up battery — inventory shows it stacked (max 4)
- [ ] Use battery from inventory — flashlight battery increases by 35%

## Sanity (15 min — needs all 5 tiers tested)

- [ ] At 100% sanity: no visual effects, no heartbeat
- [ ] Stand in dark without flashlight → sanity drops at 0.4/sec
- [ ] At 75%: still no effect (GDD threshold is 75–100 = none)
- [ ] At 50–74%: mild vignette appears, soft heartbeat starts
- [ ] At 25–49%: stronger vignette, edge blur, loud heartbeat, whispers begin
- [ ] At 10–24%: pulsing black borders, hallucinations appear, fake Janitor can manifest
- [ ] At 0–9%: full distortion, loss of directional input for 2s intervals
- [ ] Use painkiller → sanity +25
- [ ] Enter safe room → sanity regenerates at 1.2/sec
- [ ] Sanity recovers slowly (0.1/sec) when flashlight is on

## Inventory (5 min)

- [ ] I opens inventory, blur background visible
- [ ] 8 slots visible
- [ ] Pick up: 4 batteries → all stack in slot 1
- [ ] Pick up: 4 key fragments → each in its own slot (no stacking)
- [ ] Pick up: lore note → does NOT occupy normal inventory slot (separate journal)
- [ ] Pick up 9th non-stackable item → "Inventory Full" prompt
- [ ] Drop item (Q) removes from slot
- [ ] Use item (click) triggers effect

## Janitor AI (20 min — most complex)

Spawn in Main Building, find Janitor, observe:

- [ ] **PATROL**: walks predetermined route between waypoints, slow (2.1 m/s)
- [ ] **INVESTIGATE**: walk within 3m of him while crouching — he turns and walks toward noise point
- [ ] **SEARCH**: after reaching investigate point, spends 30s checking nearby rooms
- [ ] **ALERT**: when he sees you, brief 0.8s pause + turns toward you
- [ ] **CHASE**: runs at 6.2 m/s, faster than your sprint (5.6) — you cannot outrun, must break LoS
- [ ] **CATCH**: at <0.5m distance, catch animation plays, death screen loads
- [ ] **RESET**: after losing you for 8+ seconds, returns to patrol start
- [ ] **Memory**: after losing sight, remembers last known position for 45s
- [ ] **Flashlight**: turning on flashlight within 20m of him while in LoS triggers ALERT
- [ ] **Exterior**: Janitor cannot follow you into Z-08 Exterior (boundary rule, GDD §5)
- [ ] **Distract**: throw stone (if Distraction Stone item unlocked) — Janitor investigates stone position
- [ ] **Audio cues**: dragging footstep at 15m, heavy breathing at 8m, radio static at 5m, breath at 1m

## Crawler AI (10 min — Science Wing)

- [ ] Stationary until triggered
- [ ] Triggers when player within 0.8m
- [ ] Lunge speed 9 m/s, range 1.5m
- [ ] If lunge misses, returns to dormant after 4s
- [ ] Flashlight aimed at it for 2+ seconds → retreats slightly
- [ ] Wet clicking sound at 2m, otherwise silent

## Reflection entity (10 min — needs sanity <60)

- [ ] Lower sanity to <60 (turn off flashlight, wait)
- [ ] Look in a mirror → reflection appears, mimics movement with 1–2s delay
- [ ] Look directly at it for 3s → disappears
- [ ] Look away entirely → disappears
- [ ] While visible, drains sanity at 0.3/sec
- [ ] At very low sanity, reflection gestures / mouths words / exits frame

## Teacher AI (15 min — Basement Lab only, M5+)

- [ ] Walks slowly (1.6 m/s), absolute silence
- [ ] No visual detection — sprint past her in LoS, no reaction (if silent)
- [ ] Sound triggers pursuit at 12m
- [ ] Once alerted, 60s search before reset (longer than Janitor's 30s)
- [ ] Carpet in her zone reduces player noise radius by 40%
- [ ] Drop an item (5m noise) → she investigates
- [ ] At 3m distance: single quiet exhale cue

## Puzzles (per zone — full GDD §4.5)

| Puzzle | Zone | Solvable? | Code/Clue visible? | Resets on zone exit? |
|---|---|---|---|---|
| Principal's office combo lock | Z-01 | ☐ | ☐ | ☐ |
| Ventilation valve sequence | Z-02 | ☐ | ☐ | ☐ |
| Climbing wall padlock | Z-03 | ☐ | ☐ | ☐ |
| Cold storage power restore | Z-04 | ☐ | ☐ | ☐ |
| Courtyard gate (4-digit) | Z-05 | ☐ | ☐ | ☐ |
| Fuse box configuration | Z-06 | ☐ | ☐ | ☐ |
| Final 3-stage puzzle | Z-07 | ☐ | ☐ | ☐ |

## Save/Load (15 min)

- [ ] Save at journal (safe room) → save file written to `user://saves/save_0.json`
- [ ] 3 save slots on PC, each independent
- [ ] Quit → relaunch → Continue → resumes at exact saved position with saved inventory/sanity/zone
- [ ] Permadeath toggle in settings → only 1 save slot, no manual save
- [ ] Die in permadeath → save deleted, must start new game
- [ ] New Game+ (after True Ending) → enemies have new routes, 5 new notes appear

## Endings (test each via dev cheat console if available)

- [ ] **Bad ending**: escape through main gate without Marsh's report → epilogue text "missing persons report filed for the next student"
- [ ] **True ending**: escape with Marsh's report → school condemned, Harold's remains found, entity fades
- [ ] **Secret ending**: collect all 12 lore fragments, administer TRN-7 antidote to Harold → Harold briefly human, says one sentence, disintegrates

## Mobile controls (Android only — needs real device)

- [ ] Left virtual joystick moves player
- [ ] Right 60% of screen swipe looks
- [ ] Flashlight icon (bottom-right) toggles
- [ ] Crouch button toggles
- [ ] Double-tap joystick sprints
- [ ] Swipe up from bottom edge → inventory
- [ ] Top-right journal icon → journal
- [ ] Top-left hamburger → pause
- [ ] Haptic on jump scare (short)
- [ ] Haptic on catch (long)
- [ ] App backgrounded → full pause, state preserved
- [ ] 30 FPS locked on minimum-spec device (3 GB RAM)

## Performance (per tier)

### Tier 1 — Low-end (2 GB RAM, Intel HD 4000)
- [ ] 30 FPS locked in Main Building
- [ ] No pop-in within 40m draw distance
- [ ] Memory <800 MB peak

### Tier 2 — Medium (4 GB RAM, GTX 750 Ti)
- [ ] 60 FPS in all zones
- [ ] 80m draw distance
- [ ] Memory <1.5 GB peak

### Tier 3 — High (8+ GB RAM, GTX 1060)
- [ ] 60–144 FPS
- [ ] 200m draw distance
- [ ] Volumetric fog visible
- [ ] SDFGI enabled

## Localization (4 languages)

- [ ] English: complete (source of truth)
- [ ] French: switch in settings, all UI strings translated
- [ ] Spanish: switch in settings, all UI strings translated
- [ ] German: switch in settings, all UI strings translated
- [ ] Lore notes translate correctly
- [ ] No string overflow in buttons/menus (longest translation fits)

## Accessibility

- [ ] Subtitles toggle works for all audio events
- [ ] Colorblind mode applies correctly (test all 3 types)
- [ ] Text size scaling 100% / 125% / 150% — no clipping
- [ ] All controls remappable
- [ ] Permadeath toggle clearly labelled as "high difficulty"

## Final sign-off

- [ ] All boxes above ticked (or explicitly deferred with issue link)
- [ ] No crash-to-desktop in 2-hour continuous playthrough
- [ ] `git tag -a v0.X.0 -m "Tranch v0.X.0 — <milestone name>"`
- [ ] Push tag → `build.yml` triggers
- [ ] Download Win + Android artifacts, smoke-test on real hardware
- [ ] Update `docs/ROADMAP.md` decision log

**Tester name:** _______________
**Date:** _______________
**Version:** _______________
**Hardware tested:** _______________
