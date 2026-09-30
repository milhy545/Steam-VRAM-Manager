# Steam-VRAM-Manager — Tech Stack

## Runtime Environment
| Layer | Technology | Version Constraint | Purpose |
|-------|------------|-------------------|---------|
| **Shell** | GNU Bash | ≥ 4.0 (associative arrays, `mapfile`) | All scripts |
| **Init System** | systemd (user mode) | ≥ 245 | Service/timer units |
| **GPU Stack** | NVIDIA Driver | 550.x (Pascal), 560+ (Turing+) | Proprietary driver |
| | CUDA Runtime | ≥ 11.0 (for VRAM shim) | `cudaMalloc` interposition |
| | PRIME / DRM | Kernel 6.x | Render offload |
| **Container** | Steam Flatpak | com.valvesoftware.Steam | Alternative Steam |
| **Desktop** | Any (KDE/GNOME/X11/Wayland) | — | DE-agnostic |

## Build / Dev Tools
| Tool | Version | Purpose |
|------|---------|---------|
| `shellcheck` | ≥ 0.9.0 | Static analysis (CI gate) |
| `bats` | ≥ 1.5.0 | Unit/integration testing |
| `gcc` | ≥ 11 | Compile `libvram_limit.so` |
| `make` | ≥ 4.3 | Build orchestration (optional) |
| `git` | ≥ 2.39 | Version control |

## Dependencies (Runtime)
| Dependency | Type | Required? | Notes |
|------------|------|-----------|-------|
| `nvidia-smi` | Binary | ✅ Yes | GPU detection, VRAM query |
| `timeout` | Binary | ✅ Yes | Coreutils — all external calls |
| `find` | Binary | ✅ Yes | Steam/Proton discovery |
| `grep` / `sed` / `awk` | Binary | ✅ Yes | VDF parsing, text processing |
| `notify-send` | Binary | ⚠️ Optional | Desktop notifications (libnotify) |
| `kdialog` \| `zenity` \| `yad` | Binary | ⚠️ Optional | GUI prompts in installer |
| `flatpak` | Binary | ⚠️ Optional | Flatpak Steam detection |
| `cuda_runtime.h` | Header | ⚠️ Optional | Only for building VRAM shim |

## Project Structure
```
Steam-VRAM-Manager/
├── bin/
│   └── steam-gpu-wrap          # Main wrapper (install → ~/.local/bin/)
├── compatibilitytool/          # Steam Compat Tool payload
│   ├── compatibilitytool.vdf   # Tool metadata (VDF)
│   ├── toolmanifest.vdf        # Verb manifest (VDF)
│   └── vram-wrapper            # Proton discovery + wrapper injection
├── driver-fix/
│   ├── fix-nvidia-pascal.sh    # Driver remediation (needs sudo)
│   └── nvidia-debian.pref      # APT pinning (deb822 format)
├── systemd/                    # User service units (future)
├── shim/                       # C shim for VRAM enforcement (future)
│   ├── libvram_limit.c
│   └── Makefile
├── tests/                      # Bats test suite (future)
│   ├── helpers.bash
│   ├── vram-wrapper.bats
│   ├── steam-gpu-wrap.bats
│   └── install-sh.bats
├── .github/workflows/ci.yml    # GitHub Actions CI
├── install.sh                  # Universal installer
├── uninstall.sh                # Clean removal
├── README.md                   # User documentation
└── conductor/                  # Conductor context (this dir)
    ├── context/
    │   ├── product.md
    │   ├── product-guidelines.md
    │   ├── tech-stack.md
    │   └── workflow.md
    ├── status.md
    ├── tracks/
    ├── specs/
    └── plans/
```

## External Interfaces

### Steam Compatibility Tool Protocol
- `compatibilitytool.vdf` → `SteamCompatTool2` schema
- `toolmanifest.vdf` → Verbs: `launch`, `configure`, `uninstall`
- Install paths: `~/.steam/root/compatibilitytools.d/`, `~/.local/share/Steam/compatibilitytools.d/`

### APT / DKMS (Driver Fix)
- `/etc/apt/preferences.d/nvidia-debian.pref` — Pinning
- `apt install -t stable nvidia-driver=550.163.01-2`
- `dkms status` verification

### Environment Variables (Wrapper Contract)
| Variable | Scope | Description |
|----------|-------|-------------|
| `__NV_PRIME_RENDER_OFFLOAD=1` | Process | Enable PRIME offload |
| `__GLX_VENDOR_LIBRARY_NAME=nvidia` | Process | Force NVIDIA GLX |
| `__VK_LAYER_NV_optimus=NVIDIA_only` | Process | Vulkan Optimus layer |
| `CUDA_VISIBLE_DEVICES=0` | Process | Restrict CUDA device |
| `VRAM_LIMIT_MB` | Process | Soft/hard VRAM cap (MB) |
| `LD_PRELOAD` | Process | Injected VRAM shim path |

---

*Tech Stack — 2026-09-20*