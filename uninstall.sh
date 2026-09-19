#!/usr/bin/env bash
# ==============================================================================
# Steam-VRAM-Manager Uninstaller
# ==============================================================================
set -euo pipefail

echo "Removing Steam-VRAM-Manager..."

rm -f "$HOME/.local/bin/steam-gpu-wrap"
rm -rf "$HOME/.steam/root/compatibilitytools.d/vram-proton" 2>/dev/null || true
rm -rf "$HOME/.local/share/Steam/compatibilitytools.d/vram-proton" 2>/dev/null || true

echo "Uninstallation complete. Note: Logs in ~/.local/state/vram-manager.log were preserved."
