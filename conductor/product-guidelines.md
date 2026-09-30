# Steam-VRAM-Manager — Product Guidelines

## Design Principles

### 1. **Functionality > Aesthetics** (Duck Tape Principle)
- Ugly but working bash > pretty but broken Python
- If `timeout 60s nvidia-smi` works, use it — don't abstract
- Copy-pasteable one-liners in README > complex config files

### 2. **Universal > Opinionated**
- No hardcoded paths, usernames, or UUIDs
- Detect, don't assume: Steam location, Proton version, GPU, DE
- Support both native `.deb` Steam and Flatpak Steam equally

### 3. **Safe by Default**
- `install.sh` is idempotent and reversible (`uninstall.sh` exists)
- Never overwrite user files without backup (`.bak` suffix)
- `--dry-run` and `--verify` modes for safe preview
- Root only where absolutely necessary (driver fix)

### 4. **Explicit > Implicit**
- Every env var documented in `steam-gpu-wrap` header
- Every install step logged to stdout
- Errors are actionable: "Steam not found at X, Y, Z — install Steam first"

### 5. **Linux-Native, Not Portable**
- Target: systemd, bash 4+, awk, sed, grep, find, nvidia-smi
- No cross-platform abstractions (no Go, no Python runtime dep)
- Leverage kernel/userspace interfaces directly (cgroups, PRIME, VK_LAYER)

## User Experience Guidelines

### Installation
- **Single command**: `curl -fsSL <url> | bash` or `./install.sh`
- **Progress feedback**: Each phase prints `[OK]` or `[SKIP]` with reason
- **No interactive prompts** in default mode (CI-friendly)
- **GUI fallback**: `kdialog` → `zenity` → `yad` → CLI for confirmations

### Steam Integration
- Compat Tool name: `"Proton (VRAM & AI Auto-Manager)"` — descriptive, searchable
- No Steam restart required after install (Steam watches `compatibilitytools.d/`)
- Uninstall removes compat tool cleanly; Steam refreshes automatically

### Error Messaging
| Scenario | Message Pattern |
|----------|-----------------|
| Steam not found | `Steam not detected. Checked: ~/.steam/root, ~/.local/share/Steam, Flatpak. Install Steam first.` |
| No Proton found | `No Proton installation found. Enable "Steam Play" in Steam settings or install Proton-GE.` |
| NVIDIA driver missing | `nvidia-smi failed. Is NVIDIA driver installed? Run: sudo apt install nvidia-driver` |
| VRAM limit hit | `VRAM limit (5500 MB) exceeded. Game may crash. Increase VRAM_LIMIT_MB or lower textures.` |

## Coding Standards (Bash)

### Mandatory
- `#!/usr/bin/env bash` + `set -euo pipefail` (or `set -u` for sourced libs)
- `shellcheck -x` clean on all scripts
- Timeout on every external command: `timeout 30s cmd`
- Quote all expansions: `"$VAR"`, not `$VAR`
- Local variables in functions: `local var=value`

### Preferred Patterns
```bash
# Array for multi-line commands
cmd=(timeout 10s nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits)
"${cmd[@]}"

# Guard clauses
[[ -f "$file" ]] || return 1

# Named regex captures (bash 3.2+)
if [[ $line =~ ^\"([0-9]+)\"[[:space:]]+\{[[:space:]]+\"path\"[[:space:]]+\"([^\"]+)\" ]]; then
    index=${BASH_REMATCH[1]}
    path=${BASH_REMATCH[2]}
fi
```

### Forbidden
- `eval` (except `eval "$(dircolors)"` etc.)
- `source /dev/stdin <<< "$(curl ...)"` in install.sh (use temp file + verify)
- Hardcoded `/home/username` or `/media/username`
- `sudo` inside scripts (document requirement, let user run)

## Testing Guidelines
- **Unit**: Pure bash functions → bats with mocked `$HOME`, `$PATH`
- **Integration**: Full `install.sh --dry-run` on clean container
- **E2E**: Manual on target hardware (GTX 1060, MX Linux 23)
- **Regression**: Every PR runs shellcheck + bats in CI

---

*Product Guidelines — 2026-09-20*