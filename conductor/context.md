# Steam-VRAM-Manager — Project Context

## Project Overview
**Steam-VRAM-Manager** is a universal Linux toolkit for managing VRAM and GPU context when running Windows games via Steam Proton on Linux, with specialized support for **NVIDIA Pascal (GTX 1060 / GP106)** cards on **Debian 13 (Trixie) / MX Linux**.

### Problem Space
- NVIDIA open-dkms driver branch 560+ introduces GSP firmware requirements that conflict with Pascal GPUs (GTX 10-series)
- Steam Proton lacks built-in VRAM management for high-memory games
- Games crash or OOM when VRAM exceeds physical limits
- No universal, DE-agnostic way to inject GPU wrappers into Steam launch options

### Solution
A three-layer system:
1. **`steam-gpu-wrap`** — Universal runtime wrapper (bash) that:
   - Detects discrete GPU via PRIME/render nodes
   - Exports `__NV_PRIME_RENDER_OFFLOAD=1`, `__GLX_VENDOR_LIBRARY_NAME=nvidia`
   - Sets GPU memory fraction limits via `cudaMalloc` preloading (if available)
   - Spawns background VRAM monitor logging to `~/.local/state/vram-manager.log`
   - Executes the target command (Proton or native game) under controlled environment

2. **Steam Compatibility Tool** — `"Proton (VRAM & AI Auto-Manager)"`
   - Installs to `~/.steam/root/compatibilitytools.d/vram-proton` and `~/.local/share/Steam/compatibilitytools.d/vram-proton`
   - `toolmanifest.vdf` routes all verbs through `vram-wrapper`
   - `vram-wrapper` auto-discovers system Proton (Experimental, Hotfix, Next) and wraps it with `steam-gpu-wrap`

3. **Driver Fix (`driver-fix/`)** — Automated remediation for Pascal GPUs on Debian 13/MX:
   - APT pinning to prefer Debian stable NVIDIA 550 over upstream 560+
   - Downgrades/installs `nvidia-driver=550.163.01-2`, `nvidia-kernel-dkms=550.163.01-2`
   - Removes conflicting `nvidia-kernel-open-dkms`
   - Configures modprobe aliases, blacklists nouveau, regenerates initramfs

## Architecture

```
Steam-VRAM-Manager/
├── bin/
│   └── steam-gpu-wrap          # Main runtime wrapper (install target: ~/.local/bin/)
├── compatibilitytool/          # Steam Compat Tool payload
│   ├── compatibilitytool.vdf   # Tool metadata (display name, OS mapping)
│   ├── toolmanifest.vdf        # Verb routing -> vram-wrapper
│   └── vram-wrapper            # Proton discovery + steam-gpu-wrap injection
├── driver-fix/
│   ├── fix-nvidia-pascal.sh    # Automated driver remediation (requires sudo)
│   └── nvidia-debian.pref      # APT pinning: block NVIDIA upstream, prefer Debian 550
├── systemd/                    # (Empty) Reserved for user service units
├── install.sh                  # Universal installer (DE-agnostic, detects kdialog/zenity/yad)
└── uninstall.sh                # Clean removal, preserves logs
```

## Key Technical Details

### `steam-gpu-wrap` Environment Variables
| Variable | Purpose |
|----------|---------|
| `__NV_PRIME_RENDER_OFFLOAD=1` | Enable PRIME render offload to dGPU |
| `__GLX_VENDOR_LIBRARY_NAME=nvidia` | Force NVIDIA GLX vendor |
| `__VK_LAYER_NV_optimus=NVIDIA_only` | Vulkan layer for Optimus |
| `CUDA_VISIBLE_DEVICES=0` | Restrict CUDA to primary GPU |
| `VRAM_LIMIT_MB` | Optional: soft VRAM cap (enforced via LD_PRELOAD if lib available) |

### Proton Discovery Priority (in `vram-wrapper`)
1. `/media/milhy777/Steam/SteamLibrary/steamapps/common/Proton - Experimental/proton`
2. `/media/milhy777/Steam/SteamLibrary/steamapps/common/Proton Hotfix/proton`
3. `/media/milhy777/Steam/Steamapps/common/Proton Next/proton`
4. `~/.steam/root/steamapps/common/Proton - Experimental/proton`
5. `/media/milhy777/4cc3eeb0-c16e-4249-a262-6ffd1e58a302/Steam/steamapps/common/Proton - Experimental/proton`
6. Fallback: `find` across `/media/milhy777/` and `~/.steam/root/steamapps/`

### Installation Paths
| Component | Target |
|-----------|--------|
| `steam-gpu-wrap` | `~/.local/bin/steam-gpu-wrap` |
| Compat Tool (Steam root) | `~/.steam/root/compatibilitytools.d/vram-proton/` |
| Compat Tool (Flatpak/alt) | `~/.local/share/Steam/compatibilitytools.d/vram-proton/` |
| systemd user units | `~/.config/systemd/user/` (symlink `llama.service` → `llama-mistral.service`) |
| Logs | `~/.local/state/vram-manager.log` |

## Constraints & Assumptions
- **Target Distro**: Debian 13 (Trixie), MX Linux 23+, derivatives
- **Target GPU**: NVIDIA Pascal (GTX 1060 6GB primary test), also works on newer
- **Desktop Environments**: Universal (KDE, GNOME, XFCE, MATE, Cinnamon, Sway, i3, Hyprland)
- **Steam**: Native .deb or Flatpak — both compat tool paths covered
- **Root Access**: Required only for `driver-fix/fix-nvidia-pascal.sh`
- **Dependencies**: `nvidia-smi`, `timeout`, `notify-send` (optional), `kdialog|zenity|yad` (optional GUI)

## Current State
- ✅ Core wrapper (`steam-gpu-wrap`) functional
- ✅ Steam Compat Tool package complete
- ✅ Pascal driver fix script tested on MX Linux 23
- ✅ Universal installer with DE detection
- ⚠️ `systemd/` directory empty — reserved for future `steam-gpu-wrap` user service (log rotation, watchdog)
- ⚠️ `vram-wrapper` has hardcoded paths for user `milhy777` — needs generalization
- ⚠️ No test suite / CI
- ⚠️ No versioning / release artifacts

## Open Tracks (Implicit)
1. **Generalize hardcoded paths** in `vram-wrapper` (user `milhy777` → `$USER` / `$HOME`)
2. **systemd user service** for managed wrapper lifecycle (log rotation, crash restart)
3. **VRAM limit enforcement** via LD_PRELOAD shim (currently only monitoring)
4. **Automated testing** (bats/shellcheck in CI)
5. **Packaging** (Flatpak, AppImage, .deb for easier distribution)

---

*Generated from codebase analysis — 2026-09-20*