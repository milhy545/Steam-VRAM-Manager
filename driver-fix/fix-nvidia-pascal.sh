#!/usr/bin/env bash
# ==============================================================================
# Automated NVIDIA Pascal (GTX 1060 / GP106) Driver Fix for Debian 13 / MX Linux
# Resolves the missing GSP firmware conflict caused by open-dkms (branch >= 560)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUDO_CMD=""

if [ "$EUID" -ne 0 ]; then
    if [ -n "${SSH_ASKPASS:-}" ] || [ -x "/usr/bin/ssh-askpass" ]; then
        SUDO_CMD="SUDO_ASKPASS=/usr/bin/ssh-askpass sudo -A -p 'Password: '"
    else
        SUDO_CMD="sudo"
    fi
fi

echo "=== [1/5] Applying APT Pinning for Debian Stable/Trixie ==="
eval "$SUDO_CMD cp '$SCRIPT_DIR/nvidia-debian.pref' /etc/apt/preferences.d/nvidia-debian.pref"

echo "=== [2/5] Updating APT and installing proprietary NVIDIA 550 driver ==="
eval "$SUDO_CMD apt-get update"
eval "$SUDO_CMD apt-get --allow-downgrades -y install \
  nvidia-driver=550.163.01-2 \
  nvidia-kernel-dkms=550.163.01-2 \
  nvidia-smi=550.163.01-2 \
  nvtop \
  nvidia-kernel-open-dkms-"

echo "=== [3/5] Wiring Modprobe Aliases and Blacklisting Nouveau ==="
eval "$SUDO_CMD ln -sf /etc/alternatives/glx--nvidia-modprobe.conf /etc/modprobe.d/nvidia-modprobe.conf"

if [ -f /etc/modprobe.d/nvidia.conf.dpkg-new ]; then
    eval "$SUDO_CMD mv -f /etc/modprobe.d/nvidia.conf.dpkg-new /etc/modprobe.d/nvidia.conf"
fi

if ! grep -q "blacklist nouveau" /etc/modprobe.d/nvidia.conf 2>/dev/null; then
    eval "$SUDO_CMD bash -c 'echo \"blacklist nouveau\" >> /etc/modprobe.d/nvidia.conf'"
fi

echo "=== [4/5] Regenerating initramfs ==="
eval "$SUDO_CMD depmod -a"
eval "$SUDO_CMD update-initramfs -u"

echo "=== [5/5] Verifying DKMS Status ==="
dkms status || true

echo "=== NVIDIA Pascal Fix Complete! Please reboot or reload modules. ==="
