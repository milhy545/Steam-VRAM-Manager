# Spec: VRAM-004 — `install.sh` Hardening

## Flag Parsing
```bash
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

## Guarded File Operations
```bash
do_install() {
    local src="$1" dst="$2" mode="${3:-0644}"
    if $DRY_RUN; then
        echo "[DRY-RUN] install -m $mode \"$src\" \"$dst\""
        return 0
    fi
    install -m "$mode" "$src" "$dst"
}

do_symlink() {
    local target="$1" link="$2"
    if $DRY_RUN; then
        echo "[DRY-RUN] ln -sf \"$target\" \"$link\""
        return 0
    fi
    ln -sf "$target" "$link"
}

do_mkdir() {
    local dir="$1"
    if $DRY_RUN; then
        echo "[DRY-RUN] mkdir -p \"$dir\""
        return 0
    fi
    mkdir -p "$dir"
}
```

## Verification Functions
```bash
verify_steam() {
    local found=false
    [[ -d "$HOME/.steam/root" ]] && found=true
    [[ -d "$HOME/.local/share/Steam" ]] && found=true
    flatpak info com.valvesoftware.Steam >/dev/null 2>&1 && found=true
    $found
}

verify_proton() {
    # Source vram-wrapper's find_proton or duplicate logic
    # Return 0 if any Proton found
    bash -c 'source compatibilitytool/vram-wrapper && find_proton' >/dev/null 2>&1
}

verify_nvidia() {
    command -v nvidia-smi >/dev/null && nvidia-smi >/dev/null 2>&1
}

verify_path() {
    [[ ":$PATH:" == *":$HOME/.local/bin:"* ]]
}
```

## Main Flow
```bash
if $VERIFY_ONLY; then
    verify_steam   || { echo "Steam not found"; exit 2; }
    verify_proton  || { echo "No Proton found"; exit 2; }
    verify_nvidia  || { echo "NVIDIA GPU/driver not detected"; exit 2; }
    verify_path    || { echo "~/.local/bin not in PATH"; exit 2; }
    echo "All checks passed"
    exit 0
fi

# ... existing install logic, all writes via do_install/do_symlink/do_mkdir ...
```

## Exit Codes
- 0: Success
- 1: General error
- 2: Verification failed
- 3: Dry-run complete (no changes made)

---

*Spec version: 1.0*
*Date: 2026-09-20*