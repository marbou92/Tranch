# CI/CD Pipeline

Tranch's CI/CD runs entirely on GitHub Actions. No external services, no self-hosted runners.

## Pipeline diagram

```
Push to PR / main
        │
        ├─→ lint.yml ──────────────────┬─→ gdformat --check     (blocking)
        │                              ├─→ gdlint                (advisory)
        │                              └─→ scene-ref-check       (blocking)
        │
        ├─→ test.yml ──────────────────┬─→ GUT unit tests        (blocking)
        │                              └─→ headless playthrough  (blocking)
        │
        └─→ [no build on PR — too slow]

Tag push (v0.1.0, v0.2.0, …)
        │
        └─→ build.yml ─────────────────┬─→ Windows .exe export   (blocking)
                                       ├─→ Android .apk export   (blocking)
                                       └─→ Upload as CI artifact (30-day retention)
```

## Secrets and signing

### Currently required: NONE

M0 ships unsigned debug builds. The Android debug APK uses Godot's default debug keystore, which is fine for internal testing but NOT for Play Store submission.

### When you're ready to sign release builds (M8 or earlier)

Add these as GitHub repo secrets (Settings → Secrets and variables → Actions):

| Secret name | Purpose | How to generate |
|---|---|---|
| `ANDROID_KEYSTORE_BASE64` | Release keystore file (base64-encoded) | `keytool -genkey -v -keystore tranch.keystore -alias tranch -keyalg RSA -keysize 2048 -validity 10000` then `base64 tranch.keystore` |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password | (from keytool prompt) |
| `ANDROID_KEY_ALIAS` | Key alias inside keystore | e.g. `tranch` |
| `ANDROID_KEY_PASSWORD` | Key password | (from keytool prompt) |

Then update `.github/workflows/build.yml` Android job to:
1. `echo $ANDROID_KEYSTORE_BASE64 | base64 -d > $RUNNER_TEMP/tranch.keystore`
2. Pass the path via env var to Godot export
3. Switch preset from `"Android (debug)"` to `"Android (release)"`

See [`export_presets.cfg`](../export_presets.cfg) — the keystore fields are already wired to read from Godot's env-var substitution system.

## Windows code signing

Skipped for M0–M7. Windows will show "Unknown Publisher" SmartScreen warning. For M8 ship:
- Purchase an OV (Organization Validation) code signing cert (~$200/yr from Sectigo or DigiCert)
- Add `WINDOWS_CERT_BASE64` and `WINDOWS_CERT_PASSWORD` secrets
- Update `export_presets.cfg` `codesign/enable=true` and `codesign/identity=` fields

## Caching strategy

| Cache key | What's cached | Saves |
|---|---|---|
| `godot-4.3-stable-linux-x86_64` | Godot editor binary (~80 MB) | ~30s per test job |
| `godot-4.3-stable-templates` | Godot + export templates (~200 MB) | ~60s per build job |

Caches persist for 7 days of inactivity. First run after expiry is slow; subsequent runs are fast.

## Running workflows manually

The `build.yml` workflow has `workflow_dispatch` trigger — you can run it from the Actions tab on any branch without tagging. Useful for testing export changes pre-release.

## Local CI reproduction

Want to run the exact CI steps locally before pushing?

```bash
# Install Godot 4.3 stable + Python 3.11+ first

# 1. Lint
pip install gdtoolkit==4.*
gdformat --check $(find . -name "*.gd" -not -path "./addons/*")
gdlint $(find . -name "*.gd" -not -path "./addons/*")

# 2. Scene ref check
python3 scripts/check_scene_refs.py   # TODO: extract from lint.yml

# 3. Unit tests
bash scripts/install_gut.sh
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://test/unit -gexit

# 4. Headless playthrough
godot --headless --path . --main-scene res://scenes/test_runner.tscn --quit-after 10

# 5. Build (Windows example)
godot --headless --path . --export-release "Windows Desktop" builds/windows/Tranch.exe
```

If all 5 pass locally, CI will pass.

## Extending the pipeline

### Adding a new platform (e.g. macOS)

1. Add a new preset to `export_presets.cfg` (`[preset.2]` with `platform="macOS"`)
2. Add a new job to `.github/workflows/build.yml` mirroring the Windows job
3. Update `docs/CI-CD.md` and `README.md`

### Adding a new test layer

1. Add the script to `test/integration/` or `test/unit/`
2. If it needs a special scene, add it under `scenes/`
3. Update `.github/workflows/test.yml` to invoke it
4. Update `docs/TESTING.md` matrix

### Publishing to itch.io (future)

When the user is ready to switch from "Internal only" to itch.io:
1. Create an itch.io project page for Tranch
2. Get an itch.io API key from https://itch.io/api-keys
3. Add `BUTLER_API_KEY` secret to GitHub repo
4. Add a new job to `build.yml` after the build jobs that runs:
   ```bash
   butler push builds/windows/ tranch/windows:latest
   butler push builds/android/ tranch/android:latest
   ```
5. Add `workflow_dispatch` trigger so you can push builds on demand
