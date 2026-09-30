# Plan: VRAM-002 — systemd User Service for Log Rotation

## Phase 1: Create Unit Files (15 min)

### Step 1.1: Create Service File
```bash
mkdir -p systemd
cat > systemd/steam-gpu-wrap-logrotate.service <<'EOF'
[Unit]
Description=Rotate steam-gpu-wrap VRAM log
Documentation=https://github.com/milhy777/Steam-VRAM-Manager

[Service]
Type=oneshot
ExecStart=/usr/bin/find %h/.local/state -name 'vram-manager.log' -size +10M -exec mv {} {}.old \;
EOF
```

### Step 1.2: Create Timer File
```bash
cat > systemd/steam-gpu-wrap-logrotate.timer <<'EOF'
[Unit]
Description=Daily VRAM log rotation

[Timer]
OnCalendar=daily
Persistent=true
RandomizedDelaySec=1h

[Install]
WantedBy=timers.target
EOF
```

## Phase 2: Update Installer (20 min)

### Step 2.1: Add Deployment to `install.sh`
```bash
# In install.sh, after main install:
deploy_systemd_units() {
    local unit_dir="$HOME/.config/systemd/user"
    mkdir -p "$unit_dir"
    cp systemd/steam-gpu-wrap-logrotate.{service,timer} "$unit_dir/"
    systemctl --user daemon-reload
    systemctl --user enable --now steam-gpu-wrap-logrotate.timer
    echo "[OK] systemd log rotation timer enabled"
}
```

### Step 2.2: Add Removal to `uninstall.sh`
```bash
# In uninstall.sh:
systemctl --user disable --now steam-gpu-wrap-logrotate.timer 2>/dev/null
rm -f "$HOME/.config/systemd/user/steam-gpu-wrap-logrotate."{service,timer}
systemctl --user daemon-reload
```

## Phase 3: Test (15 min)

```bash
# 1. Dry-run install
./install.sh --dry-run | grep -i systemd

# 2. Full install
./install.sh

# 3. Verify
systemctl --user status steam-gpu-wrap-logrotate.timer
systemctl --user list-timers | grep steam-gpu-wrap

# 4. Manual trigger test
systemctl --user start steam-gpu-wrap-logrotate.service
# Create large log
dd if=/dev/zero of=~/.local/state/vram-manager.log bs=1M count=15
systemctl --user start steam-gpu-wrap-logrotate.service
ls -la ~/.local/state/vram-manager.log*
# Expect: .old file created

# 5. Uninstall test
./uninstall.sh
systemctl --user list-timers | grep steam-gpu-wrap || echo "Removed"
```

## Rollback
```bash
git checkout HEAD -- systemd/
./install.sh  # re-deploy without systemd units
```

## Success Criteria
- [ ] `systemctl --user list-timers` shows `steam-gpu-wrap-logrotate.timer` active
- [ ] Log rotation triggers and creates `.old` file
- [ ] `install.sh` and `uninstall.sh` handle units correctly
- [ ] `shellcheck -x install.sh uninstall.sh` passes

---

*Plan version: 1.0*
*Date: 2026-09-20*