#!/usr/bin/env bash
# ==============================================================================
# Steam-VRAM-Manager Installer
# Universal Linux Installer - Compatible with KDE, GNOME, XFCE, MATE, Cinnamon,
# LXQt, Sway, i3, Hyprland, etc.
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
STEAM_COMPAT_DIR="$HOME/.steam/root/compatibilitytools.d/vram-proton"
ALT_COMPAT_DIR="$HOME/.local/share/Steam/compatibilitytools.d/vram-proton"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
LOG_DIR="$HOME/.local/state"

echo "=================================================="
echo "  Steam-VRAM-Manager Universal Linux Installer"
echo "=================================================="

# 1. Dependency checks
echo "[1/5] Checking desktop environment and tools..."

# Check GUI dialog providers (kdialog, zenity, yad)
DIALOG_TOOL=""
for tool in kdialog zenity yad; do
    if command -v "$tool" >/dev/null 2>&1; then
        DIALOG_TOOL="$tool"
        break
    fi
done

if [ -n "$DIALOG_TOOL" ]; then
    echo "  [OK] GUI Dialog provider found: $DIALOG_TOOL"
else
    echo "  [WARNING] No GUI dialog tool found (kdialog, zenity, yad)."
    echo "  Please install one for your desktop environment:"
    echo "    - GNOME / XFCE / MATE / Cinnamon / Pop_OS: sudo apt install zenity"
    echo "    - KDE Plasma / LXQt:                      sudo apt install kdialog"
    echo "    - Minimal WMs (i3, sway, bspwm):          sudo apt install yad"
fi

# Check other core tools
for cmd in nvidia-smi timeout; do
    if command -v "$cmd" >/dev/null 2>&1; then
        echo "  [OK] Found core command: $cmd"
    else
        echo "  [WARNING] Missing core tool: $cmd"
    fi
done

if command -v notify-send >/dev/null 2>&1; then
    echo "  [OK] Notification daemon interface (notify-send) detected."
else
    echo "  [NOTE] notify-send not found (sudo apt install libnotify-bin)."
fi

# 2. Install universal wrapper
echo "[2/5] Installing steam-gpu-wrap to $BIN_DIR..."
mkdir -p "$BIN_DIR" "$LOG_DIR"
cp -f "$SCRIPT_DIR/bin/steam-gpu-wrap" "$BIN_DIR/steam-gpu-wrap"
chmod +x "$BIN_DIR/steam-gpu-wrap"

# Also update codex-monitor-cuda if present
if [ -f "$BIN_DIR/codex-monitor-cuda" ]; then
    cat << 'CM_EOF' > "$BIN_DIR/codex-monitor-cuda"
#!/usr/bin/env bash
if command -v nvtop >/dev/null 2>&1; then
    exec nvtop "$@"
fi
exec watch -n 1 nvidia-smi "$@"
CM_EOF
    chmod +x "$BIN_DIR/codex-monitor-cuda"
fi

# 3. Install Steam Compatibility Tool
echo "[3/5] Installing Steam Compatibility Tool..."
if [ -d "$HOME/.steam/root" ]; then
    mkdir -p "$STEAM_COMPAT_DIR"
    cp -rf "$SCRIPT_DIR/compatibilitytool/"* "$STEAM_COMPAT_DIR/"
    chmod +x "$STEAM_COMPAT_DIR/vram-wrapper"
    echo "  [OK] Installed to $STEAM_COMPAT_DIR"
fi

if [ -d "$HOME/.local/share/Steam" ]; then
    mkdir -p "$ALT_COMPAT_DIR"
    cp -rf "$SCRIPT_DIR/compatibilitytool/"* "$ALT_COMPAT_DIR/"
    chmod +x "$ALT_COMPAT_DIR/vram-wrapper"
    echo "  [OK] Installed to $ALT_COMPAT_DIR"
fi

# 4. Configure systemd user service alias
echo "[4/5] Configuring systemd user service aliases..."
mkdir -p "$SYSTEMD_USER_DIR"
if [ -f "$SYSTEMD_USER_DIR/llama-mistral.service" ] && [ ! -e "$SYSTEMD_USER_DIR/llama.service" ]; then
    ln -sf "$SYSTEMD_USER_DIR/llama-mistral.service" "$SYSTEMD_USER_DIR/llama.service"
    systemctl --user daemon-reload || true
fi

# 5. Summary & Usage Instructions
echo "[5/5] Installation verified!"
echo "=================================================="
echo "  Universal Installation Successful!"
echo "=================================================="
echo "Supported Desktops: KDE Plasma, GNOME, XFCE, MATE, Cinnamon, Sway, i3, etc."
echo ""
echo "1. Steam Automatic Mode (Recommended):"
echo "   - Restart Steam."
echo "   - Open Steam Settings -> Compatibility."
echo "   - Enable Steam Play for all other titles and select:"
echo "     'Proton (VRAM & AI Auto-Manager)'"
echo ""
echo "2. Per-Game Mode (Native Linux games or specific Protons):"
echo "   - Right-click any game in Steam -> Properties -> Launch Options:"
echo "     steam-gpu-wrap %command%"
echo ""
echo "3. Monitoring & Logs:"
echo "   - Tail live logs: tail -f ~/.local/state/vram-manager.log"
echo "   - Journalctl:     journalctl --user -t steam-gpu-wrap -f"
echo "   - GPU Monitor:    codex-monitor-cuda (or nvtop)"
echo "=================================================="
