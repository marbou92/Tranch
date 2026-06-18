# Editor setup — Godot 4.3

## One-time setup

1. Install Godot 4.3 stable from https://godotengine.org/download/
   - You need the **Standard** version (NOT mono — Tranch is pure GDScript)
2. Clone this repo:
   ```bash
   git clone <your-github-url> tranch
   cd tranch
   ```
3. Install GUT addon:
   ```bash
   bash scripts/install_gut.sh
   ```
4. Open Godot, click **Import**, navigate to the repo, select `project.godot`, click **Import & Edit**.
5. The editor will scan and import assets. This takes ~30 seconds the first time.

## Daily workflow

1. Pull latest: `git pull --rebase`
2. Open Godot editor (or just `godot --path . --editor`)
3. Make changes, F5 to play-test
4. Before committing:
   ```bash
   gdformat $(find . -name "*.gd" -not -path "./addons/*")   # auto-format
   godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://test/unit -gexit
   ```
5. Commit on a feature branch per `docs/CONTRIBUTING.md`

## Common gotchas

### "Cannot find resource" warnings in console
A `.tscn` references a `.gd` file that doesn't exist or was renamed.
- Fix: open the scene in editor, find the broken reference, repoint it.
- Prevent: the `scene-ref-check` job in CI catches these before merge.

### Save files in the way
When testing save/load, save files accumulate in:
- Linux: `~/.local/share/godot/app_userdata/Tranch/saves/`
- macOS: `~/Library/Application Support/Godot/app_userdata/Tranch/saves/`
- Windows: `%APPDATA%\Godot\app_userdata\Tranch\saves\`

To wipe between tests: delete that folder.

### Godot editor is slow / hangs
If you import a huge 4K texture, Godot will spend 30s compressing it. This is normal. If the editor hangs consistently, check the Import dock for stuck imports.

### GUT not found error
You forgot to run `bash scripts/install_gut.sh`. The `addons/gut/` folder will be empty.
