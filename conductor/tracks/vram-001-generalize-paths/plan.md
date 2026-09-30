# Plan: VRAM-001 — Generalize `vram-wrapper` Hardcoded Paths

## Objective
Replace hardcoded user-specific paths in `compatibilitytool/vram-wrapper` with dynamic discovery using `$HOME`, `$USER`, and Steam library detection. **Support all three Steam installation methods: apt (native .deb), snap, flatpak.**

## Phase 1: Implementation (Est. 2 hrs)

### Step 1.1: Add Helper Functions to `vram-wrapper`
- Insert after shebang/set -u, before `find_proton()`
- Functions: `find_steam_roots()`, `parse_library_folders()`, `find_proton_in_library()`
- Use awk for VDF parsing (no external deps)
- `find_steam_roots()` checks: `.steam/root`, `.local/share/Steam`, `.var/app/com.valvesoftware.Steam/data/Steam` (flatpak), `snap/steam/common/.local/share/Steam` (snap), `/media/$USER/Steam*`, `/mnt/Steam*`, `/run/media/$USER/Steam*`

### Step 1.2: Replace `find_proton()` Implementation
- Remove hardcoded paths array
- Implement dynamic discovery per spec
- Keep fallback `find` with **60s timeout** for robustness

### Step 1.3: Validate Syntax
```bash
shellcheck -x compatibilitytool/vram-wrapper
bash -n compatibilitytool/vram-wrapper
```

## Phase 2: Testing (Est. 30 min)

### Step 2.1: Unit Tests (Manual + Bats-ready)
```bash
# Test 1: Mock home with standard Steam (apt)
HOME=/tmp/test1 mkdir -p /tmp/test1/.local/share/Steam/steamapps/common/Proton\ -\ Experimental
touch /tmp/test1/.local/share/Steam/steamapps/common/Proton\ -\ Experimental/proton
chmod +x /tmp/test1/.local/share/Steam/steamapps/common/Proton\ -\ Experimental/proton

HOME=/tmp/test1 bash -c 'source compatibilitytool/vram-wrapper && find_proton'
# Expect: /tmp/test1/.local/share/Steam/steamapps/common/Proton - Experimental/proton

# Test 2: Flatpak path
HOME=/tmp/test2 mkdir -p /tmp/test2/.var/app/com.valvesoftware.Steam/data/Steam/steamapps/common/Proton\ -\ Experimental
touch /tmp/test2/.var/app/com.valvesoftware.Steam/data/Steam/steamapps/common/Proton\ -\ Experimental/proton
chmod +x /tmp/test2/.var/app/com.valvesoftware.Steam/data/Steam/steamapps/common/Proton\ -\ Experimental/proton

HOME=/tmp/test2 bash -c 'source compatibilitytool/vram-wrapper && find_proton'

# Test 3: Multi-library via libraryfolders.vdf
# Test 4: Snap path
```

### Step 2.2: Integration Test
```bash
# Run install.sh --dry-run (after Track 04) or manually copy vram-wrapper to compat tool dir
# Verify Steam recognizes compat tool and launches game
```

## Phase 3: Verification & Commit

### Step 3.1: Run Full Install
```bash
./install.sh
# Verify no errors, compat tool appears in Steam
```

### Step 3.2: Commit
```bash
git add compatibilitytool/vram-wrapper
git commit -m "VRAM-001: Generalize vram-wrapper Proton discovery

- Remove hardcoded milhy777 paths
- Add find_steam_roots(), parse_library_folders(), find_proton_in_library()
- Dynamic discovery via $HOME, $USER, libraryfolders.vdf parsing
- Supports apt, snap, flatpak Steam installations
- Maintains priority: Experimental > Hotfix > Next > Stable
- Falls back to broad find with 60s timeout for edge cases"
```

## Rollback Trigger
If `shellcheck` fails OR integration test fails OR Steam fails to launch Proton:
```bash
git checkout HEAD -- compatibilitytool/vram-wrapper
./install.sh  # re-deploy working version
```

## Success Criteria
- [ ] `shellcheck -x compatibilitytool/vram-wrapper` → 0 warnings
- [ ] `bash -n compatibilitytool/vram-wrapper` → 0 errors
- [ ] Manual test with 3 different `$HOME` paths (apt, flatpak, snap) → Proton found
- [ ] `install.sh` completes without error
- [ ] Steam Compat Tool "Proton (VRAM & AI Auto-Manager)" works in Steam UI

---

*Plan version: 1.1*
*Date: 2026-09-20*