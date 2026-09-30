# Spec: VRAM-002 — systemd User Service for Log Rotation

## Unit: `steam-gpu-wrap-logrotate.service`

```ini
[Unit]
Description=Rotate steam-gpu-wrap VRAM log
Documentation=https://github.com/milhy777/Steam-VRAM-Manager

[Service]
Type=oneshot
ExecStart=/usr/bin/find %h/.local/state -name 'vram-manager.log' -size +10M -exec mv {} {}.old \;
```

---

## Timer: `steam-gpu-wrap-logrotate.timer`

```ini
[Unit]
Description=Daily VRAM log rotation

[Timer]
OnCalendar=daily
Persistent=true
RandomizedDelaySec=1h

[Install]
WantedBy=timers.target
```

---

## Installation (via `install.sh`)

```bash
# Deploy to user systemd directory
mkdir -p "$HOME/.config/systemd/user"
cp systemd/steam-gpu-wrap-logrotate.{service,timer} "$HOME/.config/systemd/user/"
systemctl --user daemon-reload
systemctl --user enable --now steam-gpu-wrap-logrotate.timer
```

---

## Acceptance Criteria
- [ ] Timer triggers daily (verify with `systemctl --user list-timers`)
- [ ] Log rotation works: creates `.old` when > 10MB
- [ ] `install.sh` deploys and enables automatically
- [ ] `uninstall.sh` disables and removes units

---

*Spec version: 1.0*
*Date: 2026-09-20*