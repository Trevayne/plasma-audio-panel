#!/usr/bin/env bash
# Installs the EasyEffects spectrum panel widget, its feed helper and the donut face.
# User-level only: nothing is written outside your home directory and no sudo is used.
#   ./install.sh                 install everything
#   ./install.sh --no-donut      skip the donut sensor face
#   NO_SYSTEMD=1 ./install.sh    don't enable/start the user service
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
data="${XDG_DATA_HOME:-$HOME/.local/share}"
conf="${XDG_CONFIG_HOME:-$HOME/.config}"
bin="$HOME/.local/bin"
want_donut=1; [[ "${1:-}" == "--no-donut" ]] && want_donut=0

missing=0
need() { command -v "$1" >/dev/null || { echo "missing: $1 ($2)"; missing=1; }; }
need python3 "python3"
need pw-record "PipeWire tools, e.g. pipewire-bin / pipewire-utils"
python3 -c 'import numpy' 2>/dev/null || { echo "missing: python3 numpy (install your distro's python3-numpy)"; missing=1; }
if ! command -v plasmashell >/dev/null; then echo "warning: plasmashell not found; the widget needs KDE Plasma 6"; fi
[[ $missing -eq 0 ]] || { echo "Install the missing dependencies and run again."; exit 1; }

install -Dm755 "$here/helper/ee-spectrum" "$bin/ee-spectrum"
install -Dm644 "$here/helper/ee-spectrum.service" "$conf/systemd/user/ee-spectrum.service"
mkdir -p "$data/plasma/plasmoids"
rm -rf "$data/plasma/plasmoids/org.trevayne.eespectrum"
cp -r "$here/plasmoid/org.trevayne.eespectrum" "$data/plasma/plasmoids/"
if [[ $want_donut -eq 1 ]]; then
  mkdir -p "$data/ksysguard/sensorfaces"
  rm -rf "$data/ksysguard/sensorfaces/local.piechart.initial"
  cp -r "$here/donut-face/local.piechart.initial" "$data/ksysguard/sensorfaces/"
fi

if [[ -z "${NO_SYSTEMD:-}" ]] && command -v systemctl >/dev/null; then
  systemctl --user daemon-reload
  systemctl --user enable --now ee-spectrum.service
fi

cat <<MSG

Installed. Next steps:
  1. Right-click your panel > Add Widgets > "EasyEffects Spectrum".
  2. If it doesn't appear, reload plasmashell:  systemctl --user restart plasma-plasmashell
  3. Right-click the widget > Configure to set bars, colours, port and click action.
MSG
