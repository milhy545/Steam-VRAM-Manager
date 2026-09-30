# Steam-VRAM-Manager — Project Status

## Overall Health: 🟡 **Operational — Hardening Phase**

Core functionality works end-to-end. Remaining work is **generalization**, **robustness**, and **distribution readiness**.

---

## Component Status

| Component | Status | Notes |
|-----------|--------|-------|
| `bin/steam-gpu-wrap` | ✅ **Done** | Universal wrapper, PRIME detection, VRAM monitoring, timeout guards |
| `compatibilitytool/` | ✅ **Done** | Steam Compat Tool v2 manifest, Proton auto-discovery, dual install paths |
| `driver-fix/` | ✅ **Done** | APT pinning + 550 downgrade, DKMS verify, initramfs regen |
| `install.sh` | ✅ **Done** | DE-agnostic (kdialog/zenity/yad/CLI), idempotent, rollback-safe |
| `uninstall.sh` | ✅ **Done** | Clean removal, preserves user logs |
| `systemd/` | ⚪ **Empty** | Directory exists, no units yet |
| **Tests / CI** | ❌ **Missing** | No shellcheck, bats, or GitHub Actions |
| **Release / Versioning** | ❌ **Missing** | No tags, changelog, or build artifacts |

---

## Known Issues (Technical Debt)

| ID | Severity | Component | Description |
|----|----------|-----------|-------------|
| VRAM-001 | 🔴 High | `vram-wrapper` | Hardcoded user `milhy777` and UUID paths — fails for other users |
| VRAM-002 | 🟡 Medium | `systemd/` | No user service for log rotation / watchdog / auto-restart |
| VRAM-003 | 🟡 Medium | `steam-gpu-wrap` | VRAM limit (`VRAM_LIMIT_MB`) only monitored, not enforced (no LD_PRELOAD shim) |
| VRAM-004 | 🟢 Low | `install.sh` | No `--dry-run` flag; no verification of Steam install before compat tool deploy |
| VRAM-005 | 🟢 Low | `driver-fix/` | Pins specific version 550.163.01-2 — will need update for future Debian point releases |

---

## Immediate Next Actions (Priority Order)

1. **Fix VRAM-001** — Generalize `vram-wrapper` paths to `$HOME`, `$USER`, `find` Steam library dirs dynamically
2. **Implement VRAM-002** — Add systemd user unit: `steam-gpu-wrap.service` (Type=simple, Restart=on-failure, StandardOutput=journal)
3. **Add CI** — GitHub Actions: shellcheck on all `.sh`, bats integration test (mock Proton + steam-gpu-wrap)
4. **VRAM-003** — Optional: Write minimal C shim (`libvram_limit.so`) for `LD_PRELOAD` enforcement via `cudaMalloc` interposition

---

## Metrics

- **Lines of Code**: ~450 (bash + VDF)
- **Test Coverage**: 0%
- **Open Issues**: 5 (see above)
- **Last Verified**: 2026-09-20 (manual install on MX Linux 23, GTX 1060 6GB)

---

## Definition of Done (v1.0 Release)

- [ ] VRAM-001 resolved (paths generalized)
- [ ] VRAM-002 implemented (systemd user service)
- [ ] Shellcheck clean on all scripts
- [ ] `install.sh --dry-run` works
- [ ] GitHub Actions CI passing
- [ ] Tagged release `v1.0.0` with changelog
- [ ] README updated with verified distro/GPU matrix

---

*Status generated from context analysis — 2026-09-20*