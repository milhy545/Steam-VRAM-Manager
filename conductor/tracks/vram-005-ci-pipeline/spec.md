# Spec: VRAM-005 — CI Pipeline

## GitHub Actions Workflow: `.github/workflows/ci.yml`

```yaml
name: CI
on: [push, pull_request]

jobs:
  lint-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y shellcheck bats coreutils findutils grep sed gawk
      
      - name: Shellcheck all scripts
        run: |
          find . -name '*.sh' -type f -exec shellcheck -x {} +
          shellcheck -x bin/steam-gpu-wrap
          shellcheck -x compatibilitytool/vram-wrapper
          shellcheck -x driver-fix/fix-nvidia-pascal.sh
          shellcheck -x install.sh
          shellcheck -x uninstall.sh
      
      - name: Run bats tests
        run: |
          bats tests/
```

---

## Test Structure: `tests/`

```
tests/
├── helpers.bash          # Shared fixtures, mock functions
├── vram-wrapper.bats     # find_steam_roots, parse_library_folders, find_proton
├── steam-gpu-wrap.bats   # argument parsing, env setup, timeout logic
├── install-sh.bats       # --dry-run, --verify, idempotency
└── integration.bats      # Full mock Steam + Proton + wrapper execution
```

---

## Helpers: `tests/helpers.bash`

```bash
setup_mock_steam() {
    export MOCK_HOME="$BATS_TMPDIR/mockhome"
    mkdir -p "$MOCK_HOME/.local/share/Steam/steamapps/common/Proton - Experimental"
    touch "$MOCK_HOME/.local/share/Steam/steamapps/common/Proton - Experimental/proton"
    chmod +x "$MOCK_HOME/.local/share/Steam/steamapps/common/Proton - Experimental/proton"
    
    mkdir -p "$MOCK_HOME/.local/share/Steam/steamapps"
    cat > "$MOCK_HOME/.local/share/Steam/steamapps/libraryfolders.vdf" <<'EOF'
"libraryfolders"
{
    "0" { "path" "/home/user/.local/share/Steam" }
    "1" { "path" "/media/user/SteamLibrary" }
}
EOF
    export HOME="$MOCK_HOME"
}

mock_nvidia_smi() {
    cat > "$BATS_TMPDIR/bin/nvidia-smi" <<'EOF'
#!/bin/bash
echo "GPU 0: NVIDIA GeForce GTX 1060 6GB"
EOF
    chmod +x "$BATS_TMPDIR/bin/nvidia-smi"
    export PATH="$BATS_TMPDIR/bin:$PATH"
}
```

---

## Example Test: `tests/vram-wrapper.bats`

```bash
load helpers

@test "find_steam_roots finds ~/.local/share/Steam" {
    setup_mock_steam
    source compatibilitytool/vram-wrapper
    run find_steam_roots
    [[ "$output" == *"$MOCK_HOME/.local/share/Steam"* ]]
}

@test "parse_library_folders extracts VDF paths" {
    setup_mock_steam
    source compatibilitytool/vram-wrapper
    run parse_library_folders "$MOCK_HOME/.local/share/Steam"
    [[ "${lines[0]}" == "$MOCK_HOME/.local/share/Steam" ]]
    [[ "${lines[1]}" == "/media/user/SteamLibrary" ]]
}

@test "find_proton returns highest priority Proton" {
    setup_mock_steam
    mkdir -p "$MOCK_HOME/.local/share/Steam/steamapps/common/Proton Hotfix"
    touch "$MOCK_HOME/.local/share/Steam/steamapps/common/Proton Hotfix/proton"
    chmod +x "$MOCK_HOME/.local/share/Steam/steamapps/common/Proton Hotfix/proton"
    
    source compatibilitytool/vram-wrapper
    run find_proton
    [[ "$output" == *"Proton - Experimental"* ]]
}
```

---

## shellcheck Configuration: `.shellcheckrc`

```
# Project-specific suppressions (if needed)
# disable=SC2034  # Unused variables allowed in library scripts
# disable=SC1090  # Can't follow non-constant source
```

---

## Acceptance Criteria
- [ ] Workflow runs on every push/PR
- [ ] `shellcheck -x` passes on all `.sh` files
- [ ] `bats tests/` passes (all tests green)
- [ ] Pipeline fails on any warning/error
- [ ] Test output visible in GitHub Actions UI

---

*Spec version: 1.0*
*Date: 2026-09-20*