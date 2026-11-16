#!/usr/bin/env bash
# Removes what install.sh put in your home directory.
set -euo pipefail
data="${XDG_DATA_HOME:-$HOME/.local/share}"
conf="${XDG_CONFIG_HOME:-$HOME/.config}"
if [[ -z "${NO_SYSTEMD:-}" ]] && command -v systemctl >/dev/null; then
  systemctl --user disable --now ee-spectrum.service 2>/dev/null || true
fi
rm -f  "$HOME/.local/bin/ee-spectrum" "$conf/systemd/user/ee-spectrum.service"
rm -rf "$data/plasma/plasmoids/org.trevayne.eespectrum" "$data/ksysguard/sensorfaces/local.piechart.initial"
[[ -z "${NO_SYSTEMD:-}" ]] && command -v systemctl >/dev/null && systemctl --user daemon-reload || true
echo "Removed. Remove the widget from your panel first if it is still there."
