# Steam-VRAM-Manager — Development Workflow

## Branching Model
```
main (protected, tagged releases)
  ↑
  │ PR + CI pass
  │
feature/vram-001-generalize-paths
feature/vram-002-systemd-service
feature/vram-003-vram-shim
...
```

- **Main** — Only tagged releases (`v1.0.0`, `v1.1.0`); deployable artifacts
- **Feature branches** — One per track (VRAM-XXX); short-lived (< 1 week)
- **No long-running develop branch** — Merge to main when track complete

## Commit Convention
```
<track-id>: <imperative summary>

<optional body: what/why, not how>

Refs: #<track-id>
```

Examples:
```
VRAM-001: Generalize vram-wrapper Proton discovery

Replace hardcoded milhy777 paths with dynamic discovery via
find_steam_roots(), parse_library_folders(), find_proton_in_library().

Refs: #VRAM-001
```

```
VRAM-004: Add --dry-run and --verify to install.sh

Guard all file ops with do_install/do_symlink/do_mkdir.
Add verify_steam(), verify_proton(), verify_nvidia(), verify_path().

Refs: #VRAM-004
```

## Pull Request Process

### Before Opening PR
1. Run `shellcheck -x` on all modified `.sh` files
2. Run `bash -n` on all modified scripts
3. Run `bats tests/` (if test suite exists)
4. Test `./install.sh --dry-run` and `./install.sh --verify`

### PR Requirements
- [ ] Title follows commit convention
- [ ] Description links to track (`conductor/tracks/XX-*.md`)
- [ ] CI passes (shellcheck + bats)
- [ ] At least one manual test on target hardware (or documented why not)
- [ ] No unrelated changes (no drive-by formatting)

### Review Checklist
- [ ] No hardcoded paths/usernames introduced
- [ ] All timeouts explicit (`timeout Ns cmd`)
- [ ] Error messages actionable (what, where, how to fix)
- [ ] Idempotency preserved (safe to re-run)
- [ ] `uninstall.sh` updated if new files installed

## Release Process

### Versioning
- **SemVer**: `MAJOR.MINOR.PATCH`
- **MAJOR**: Breaking installer interface or Steam compat tool schema
- **MINOR**: New features (systemd service, VRAM shim)
- **PATCH**: Bug fixes, path fixes, documentation

### Release Checklist (v1.0.0 Example)
1. All v1.0 tracks **Done** (VRAM-001, 002, 004, 005)
2. `status.md` updated → "Overall Health: 🟢 Release Ready"
3. `CHANGELOG.md` generated (manual or `git log --oneline v0.9.0..HEAD`)
4. Tag: `git tag -a v1.0.0 -m "v1.0.0 — Universal VRAM Manager for Proton"`
5. Push tag: `git push origin v1.0.0`
6. GitHub Release: attach `install.sh`, `uninstall.sh`, `README.md`
7. Announce: Discord/Reddit/MX Linux forum with install command

## CI/CD Pipeline (GitHub Actions)

### On Every Push/PR
```yaml
jobs:
  lint:
    - shellcheck all .sh
    - bash -n all scripts
  test:
    - bats tests/ (if exists)
  verify:
    - ./install.sh --verify (in clean container)
    - ./install.sh --dry-run (in clean container)
```

### On Tag Push (`v*.*.*`)
```yaml
jobs:
  release:
    - Create GitHub Release
    - Upload install.sh, uninstall.sh, README.md
    - (Future) Build .deb, AppImage, Flatpak
```

## Local Development Loop

### Quick Test Cycle
```bash
# 1. Edit script
vim compatibilitytool/vram-wrapper

# 2. Syntax check
bash -n compatibilitytool/vram-wrapper
shellcheck -x compatibilitytool/vram-wrapper

# 3. Unit test (mock)
HOME=/tmp/test ./test_vram_wrapper.sh

# 4. Integration test
./install.sh --dry-run
./install.sh --verify

# 5. Full install (if confident)
./install.sh
# Test in Steam → verify game launches
```

### Debugging Wrapper
```bash
# Run wrapper directly with debug
VRAM_LIMIT_MB=4000 ~/.local/bin/steam-gpu-wrap /path/to/proton run /path/to/game.exe

# Check logs
tail -f ~/.local/state/vram-manager.log

# Verify GPU context
nvidia-smi dmon -s pucvmet -i 0 -c 10
```

## Issue Tracking
- **GitHub Issues** for bugs, feature requests
- **Conductor Tracks** for planned work (VRAM-XXX)
- **Status.md** reflects current state of all tracks
- **No Jira/Linear/Trello** — single source of truth in repo

## Documentation Maintenance
- `README.md` — User-facing, updated on every release
- `conductor/context/*.md` — Updated when architecture changes
- `conductor/status.md` — Updated at track completion
- Inline script headers — Kept in sync with behavior

---

*Development Workflow — 2026-09-20*