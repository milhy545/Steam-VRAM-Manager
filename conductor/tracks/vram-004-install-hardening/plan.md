# Plan: VRAM-004 — `install.sh` Hardening

## Phase 1: Add Flag Parsing & Guards (45 min)

### Step 1.1: Add Flag Parsing at Top
```bash
# After shebang/set -u, before any logic
DRY_RUN=false
VERIFY_ONLY=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run) DRY_RUN=true; shift ;;
        --verify) VERIFY_ONLY=true; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done
```

### Step 1.2: Define Guard Functions
```bash
# After flag parsing
do_install() { ... }
do_symlink() { ... }
do_mkdir() { ... }
```

### Step 1.3: Replace All Direct Calls
- `install -m ...` → `do_install ...`
- `ln -sf ...` → `do_symlink ...`
- `mkdir -p ...` → `do_mkdir ...`

## Phase 2: Add Verification Functions (30 min)

### Step 2.1: Implement Checks
```bash
verify_steam() { ... }
verify_proton() { ... }
verify_nvidia() { ... }
verify_path() { ... }
```

### Step 2.2: Handle `--verify` Early Exit
```bash
if $VERIFY_ONLY; then
    verify_steam   || { echo "Steam not found"; exit 2; }
    verify_proton  || { echo "No Proton found"; exit 2; }
    verify_nvidia  || { echo "NVIDIA GPU/driver not detected"; exit 2; }
    verify_path    || { echo "~/.local/bin not in PATH"; exit 2; }
    echo "All checks passed"
    exit 0
fi
```

## Phase 3: Test (15 min)

```bash
# 1. Dry-run
./install.sh --dry-run
# Verify: only [DRY-RUN] lines, no actual files created

# 2. Verify on clean system
./install.sh --verify
# Expect: exit 2 with specific reason

# 3. Full install
./install.sh
# Verify: works normally

# 4. Idempotency
./install.sh
# Verify: no errors, no duplicate symlinks

# 5. Shellcheck
shellcheck -x install.sh
```

## Rollback
```bash
git checkout HEAD -- install.sh
```

## Success Criteria
- [ ] `./install.sh --dry-run` shows planned actions, writes nothing
- [ ] `./install.sh --verify` passes on valid system, fails with clear message on invalid
- [ ] Re-running `./install.sh` twice produces no errors
- [ ] `shellcheck -x install.sh` → 0 warnings
- [ ] Exit codes: 0/1/2/3 as specified

---

*Plan version: 1.0*
*Date: 2026-09-20*