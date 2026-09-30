# Spec: VRAM-001 — Generalize `vram-wrapper` Proton Discovery

## Function: `find_steam_roots()`

**Purpose**: Enumerate all plausible Steam installation roots for current user (apt, snap, flatpak).

**Signature**: `find_steam_roots() -> stdout: newline-separated paths`

**Algorithm**:
```bash
find_steam_roots() {
    local roots=()
    # 1. Native .deb (symlink)
    [[ -L "$HOME/.steam/root" ]] && roots+=("$(readlink -f "$HOME/.steam/root")")
    # 2. Native .deb / default (directory)
    [[ -d "$HOME/.local/share/Steam" ]] && roots+=("$HOME/.local/share/Steam")
    # 3. Flatpak
    [[ -d "$HOME/.var/app/com.valvesoftware.Steam/data/Steam" ]] && roots+=("$HOME/.var/app/com.valvesoftware.Steam/data/Steam")
    # 4. Snap (if applicable)
    [[ -d "$HOME/snap/steam/common/.local/share/Steam" ]] && roots+=("$HOME/snap/steam/common/.local/share/Steam")
    # 5. External mounts under /media/$USER
    for d in /media/"$USER"/Steam*; do
        [[ -d "$d" ]] && roots+=("$d")
    done
    # 6. Common manual mounts
    for d in /mnt/Steam* /run/media/"$USER"/Steam*; do
        [[ -d "$d" ]] && roots+=("$d")
    done
    # Deduplicate
    printf '%s\n' "${roots[@]}" | sort -u
}
```

---

## Function: `parse_library_folders(steam_root)`

**Purpose**: Parse `steam_root/steamapps/libraryfolders.vdf` (VDF format) to extract all configured library paths.

**Input**: `$1` = Steam root path

**Output**: Newline-separated library paths (including the root itself)

**VDF Format** (simplified):
```vdf
"libraryfolders"
{
    "0"     { "path"    "/home/user/.local/share/Steam" }
    "1"     { "path"    "/media/user/SteamLibrary" }
}
```

**Implementation** (awk-based, no external deps):
```bash
parse_library_folders() {
    local root="$1"
    local vdf="$root/steamapps/libraryfolders.vdf"
    [[ -f "$vdf" ]] || { echo "$root"; return; }
    
    # Print root first
    echo "$root"
    
    # Extract paths from VDF - handles both old and new format
    awk -F'"' '
        /"path"[[:space:]]+/ {
            gsub(/\\\\/, "/", $4)
            print $4
        }
    ' "$vdf" | sort -u
}
```

---

## Function: `find_proton_in_library(lib_path)`

**Purpose**: Search a single Steam library folder for Proton installations.

**Input**: `$1` = library path (e.g., `/media/user/SteamLibrary`)

**Output**: First found executable Proton binary path, or empty

**Search Priority**:
1. `Proton - Experimental/proton`
2. `Proton Hotfix/proton`
3. `Proton Next/proton`
4. `Proton/proton` (stable)

```bash
find_proton_in_library() {
    local lib="$1"
    local candidates=(
        "Proton - Experimental/proton"
        "Proton Hotfix/proton"
        "Proton Next/proton"
        "Proton/proton"
    )
    for c in "${candidates[@]}"; do
        local p="$lib/steamapps/common/$c"
        [[ -x "$p" ]] && { echo "$p"; return 0; }
    done
    return 1
}
```

---

## Refactored `find_proton()` — Main Entry Point

```bash
find_proton() {
    # 1. Fast path: check each Steam root + its libraries
    local roots
    mapfile -t roots < <(find_steam_roots)
    
    for root in "${roots[@]}"; do
        local libraries
        mapfile -t libraries < <(parse_library_folders "$root")
        for lib in "${libraries[@]}"; do
            local proton
            proton=$(find_proton_in_library "$lib")
            [[ -n "$proton" ]] && { echo "$proton"; return 0; }
        end
    done
    
    # 2. Fallback: broad find (slow, last resort) — 60s timeout
    local fallback
    fallback=$(timeout 60s find /media/"$USER"/ "$HOME/.steam" "$HOME/.local/share/Steam" "$HOME/.var/app/com.valvesoftware.Steam/data/Steam" "$HOME/snap/steam/common/.local/share/Steam" \
        -name "proton" -type f -perm -111 2>/dev/null | head -n 1)
    [[ -n "$fallback" ]] && { echo "$fallback"; return 0; }
    
    return 1
}
```

---

## Integration Points

### `vram-wrapper` — Replace lines 4–26 with above functions + new `find_proton()`

**Shebang & strict mode preserved**:
```bash
#!/usr/bin/env bash
set -u
```

**Error handling**: If `find_proton` fails, show `notify-send` error (existing) and exit 1.

### `install.sh` — Verify No Path Injection

Check that `install.sh` does not template or rewrite `vram-wrapper`. It should copy as-is.

---

## Test Plan

### Unit Tests (bats)
```bash
@test "find_steam_roots finds ~/.local/share/Steam" {
    mkdir -p "$BATS_TMPDIR/.local/share/Steam"
    HOME="$BATS_TMPDIR" run find_steam_roots
    [[ "$output" == *"$BATS_TMPDIR/.local/share/Steam"* ]]
}

@test "parse_library_folders extracts paths from VDF" {
    cat > "$BATS_TMPDIR/libraryfolders.vdf" <<'EOF'
"libraryfolders"
{
    "0" { "path" "/home/user/Steam" }
    "1" { "path" "/media/user/Extra" }
}
EOF
    run parse_library_folders "$BATS_TMPDIR"
    [[ "${lines[0]}" == "$BATS_TMPDIR" ]]
    [[ "${lines[1]}" == "/home/user/Steam" ]]
    [[ "${lines[2]}" == "/media/user/Extra" ]]
}

@test "find_proton_in_library returns first match by priority" {
    mkdir -p "$BATS_TMPDIR/steamapps/common/Proton - Experimental"
    touch "$BATS_TMPDIR/steamapps/common/Proton - Experimental/proton"
    chmod +x "$BATS_TMPDIR/steamapps/common/Proton - Experimental/proton"
    mkdir -p "$BATS_TMPDIR/steamapps/common/Proton Hotfix"
    touch "$BATS_TMPDIR/steamapps/common/Proton Hotfix/proton"
    chmod +x "$BATS_TMPDIR/steamapps/common/Proton Hotfix/proton"
    
    run find_proton_in_library "$BATS_TMPDIR"
    [[ "$output" == *"Proton - Experimental"* ]]
}
```

### Integration Test
```bash
@test "vram-wrapper finds Proton in mock multi-library setup" {
    # Create mock Steam root with 2 libraries
    # Run vram-wrapper --dry-run (add flag) or source and call find_proton
    # Assert correct Proton binary returned
}
```

---

## Shellcheck Compliance

All new functions must pass:
```bash
shellcheck -x vram-wrapper
```
- No SC2034 (unused vars)
- No SC2155 (declare and assign separately)
- Quote all expansions
- Use `local` for all function variables

---

## Rollback Plan

If regression detected:
1. `git checkout HEAD -- compatibilitytool/vram-wrapper`
2. Re-run `install.sh` (idempotent)
3. Verify Steam still launches Proton via compat tool

---

*Spec version: 1.0*
*Date: 2026-09-20*