# Plasma audio panel

A small set of KDE Plasma 6 panel utilities:

![The widgets in a Plasma panel: three donut monitors and the spectrum bars](docs/panel.png)

| Part | What it is |
|---|---|
| **EasyEffects Spectrum** (`plasmoid/`) | A panel widget that draws a live spectrum of the audio *after* EasyEffects (or any other processing), so you can see what your EQ and effects actually do. |
| **ee-spectrum** (`helper/`) | A tiny local service that captures the default output's monitor, runs an FFT and serves bar levels on `127.0.0.1`. |
| **Donut with Initial** (`donut-face/`) | A System Monitor sensor face: a thin donut ring with a large letter in the centre, for the stock *System Monitor* widgets (CPU, network, memory…). |

## Requirements

- KDE Plasma 6 (developed on 6.6)
- PipeWire with `pw-record` (package `pipewire-bin` / `pipewire-utils`)
- Python 3 with NumPy (your distro's `python3-numpy`)
- A user systemd session (for the helper service)

## Install

```sh
./install.sh            # everything, user-level only (no sudo)
./install.sh --no-donut # skip the donut face
```

Then right-click your panel → *Add Widgets…* → **EasyEffects Spectrum**. If it does not
show up, reload the shell with `systemctl --user restart plasma-plasmashell`.

Uninstall with `./uninstall.sh` (remove the widget from the panel first).

### Donut monitors

Add a stock *System Monitor* widget (e.g. *CPU Usage*), right-click → *Configure…* →
*Appearance*, choose **Donut with Initial** as the display style, and set the title to the
letter you want in the middle (`C`, `N`, `D`…). Leave *Show Title* off: the letter is drawn
inside the donut, not as a separate title.

## Configure the spectrum widget

Right-click the widget → *Configure…*

- number of bars, bar width and gap
- bass and treble colours (the bars blend between them)
- feed port (must match `EE_SPECTRUM_PORT` of the service; default `47823`)
- command to run on click (default opens EasyEffects)

If the feed is not running the widget dims, and clicking it starts the service.

## How it works and what it touches

```
default sink ─▶ pw-record (monitor) ─▶ ee-spectrum ─▶ http://127.0.0.1:47823/bands ─▶ widget
```

- The helper records the **output monitor** of your default sound device. Because it
  listens after EasyEffects, you see the processed signal.
- It computes only band levels (0–1) and discards the audio. Nothing is saved.
- It listens on **127.0.0.1 only**, serves only those levels, and makes no outbound
  connections. Any local process can read the levels, nothing else.
- The unit is capped at 150 MB of memory.
- Plasma 6 has no `QtWebSockets` QML module, so the widget polls with `XMLHttpRequest`
  (about 30 times a second while audio plays, 4 a second when idle).

## Known limitations

- It captures the **default** output's monitor. Switching output devices has not been
  tested; if the bars freeze afterwards, `systemctl --user restart ee-spectrum`.
- Plasma 6 only. The widget forces no representation; see the comment in `main.qml`.
- The package IDs (`org.trevayne.eespectrum`, `local.piechart.initial`) are the author's
  originals. Rename them before publishing to a store (see below).

## Licence

- Spectrum widget and helper: GPL-3.0-or-later (`licenses/GPL-3.0.txt`).
- `donut-face/` is a modified copy of KDE's pie-chart sensor face and stays
  **LGPL-2.0-or-later** under the original authors' copyright (Marco Martin, David
  Edmundson, Arjen Hiemstra, Kai Uwe Broulik); each file keeps its SPDX header
  (`licenses/LGPL-2.1.txt`).
