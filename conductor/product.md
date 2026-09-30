# Steam-VRAM-Manager — Product Definition

## Product Vision
**Steam-VRAM-Manager** is a universal, zero-config Linux toolkit that enables stable execution of VRAM-intensive Windows games via Steam Proton on NVIDIA GPUs — starting with Pascal (GTX 10-series) on Debian 13/MX Linux — by managing GPU context, VRAM allocation, and driver compatibility automatically.

## Target Users
| Segment | Profile | Pain Point |
|---------|---------|------------|
| **Linux Gamers (Enthusiast)** | Debian/MX/Ubuntu/Arch users, NVIDIA GPU, Proton power users | Games crash at high textures; manual PRIME/env vars per game |
| **Pascal Owners (GTX 1060/1070/1080)** | Stuck on Debian 13 with broken open-dkms 560+ | Driver regression forces manual downgrade to 550 |
| **Steam Deck / HTPC Users** | Immutable OS, limited terminal access | Need "just works" compat tool selection in Steam UI |

## Core Value Propositions
1. **Zero-Config PRIME Offload** — `steam-gpu-wrap` detects dGPU, sets `__NV_PRIME_RENDER_OFFLOAD=1`, `__GLX_VENDOR_LIBRARY_NAME=nvidia` automatically
2. **VRAM Guardrails** — Optional soft/hard VRAM limits prevent OOM crashes on 6GB/8GB cards
3. **Pascal Driver Fix** — One-command APT pin + downgrade to NVIDIA 550 (Debian stable) — no manual DKMS
4. **Steam-Native Integration** — Installs as Compatibility Tool; appears in Steam → Properties → Compatibility dropdown
5. **DE-Agnostic** — Works on KDE, GNOME, XFCE, Sway, i3, Hyprland — no desktop dependencies

## Success Metrics (v1.0)
| Metric | Target |
|--------|--------|
| Install success rate (clean MX Linux 23) | 100% |
| Proton launch success (GTX 1060, 5 test games) | 100% |
| VRAM OOM crashes (with `VRAM_LIMIT_MB=5500`) | 0 |
| Install time (fresh system) | < 2 min |
| Shellcheck clean | Pass |

## Non-Goals (v1.0)
- AMD/Intel GPU support (PRIME logic is NVIDIA-specific)
- GUI configuration tool (env vars + Steam UI sufficient)
- Overclocking / fan control / monitoring dashboard
- Flatpak-only distribution (supports both native + Flatpak Steam)

## Roadmap Highlights
| Version | Focus |
|---------|-------|
| **v1.0** | Core wrapper, compat tool, Pascal fix, installer hardening, CI |
| **v1.1** | VRAM enforcement shim (LD_PRELOAD), log rotation systemd |
| **v2.0** | AMD support (ROCm), per-game profiles, TUI config (`vram-manager`) |

---

*Product Definition — 2026-09-20*