# Console Deck PRO

A DIY macro deck built around an Arduino Nano — 9 programmable buttons, a rotary encoder, an OLED display, and an expandable module system (sliders, knobs, extra buttons). Each button can open a URL, launch an app, send a hotkey, control volume, and more. Configure everything from the desktop UI, no code editing required.

This is an **open-source maker project**. The full package (3D-printable enclosure files, electronics schematics, and BOM) is available as part of the crowdfunding campaign.

---

## What's in this repo

| Folder / File | Description |
|---|---|
| `console_deck_pro_arduino/` | Arduino firmware (upload once to the board) |
| `UI/` | Flutter desktop app (Windows / macOS / Linux) |
| `console_deck_pro.py` | Python backend source — bridges the Arduino with the OS |
| `dist/console_deck_pro/` | Compiled backend: `console_deck_pro.exe` plus its `_internal` folder (produced by CI via PyInstaller) |
| `config.example.json` | Example configuration — copy to get started |
| `requirements.txt` | Python dependencies (for manual / dev use) |
| `BUILDING.md` | How to build the installer from source |
| `PLATFORMS.md` | Platform-specific notes (Windows / macOS / Linux) |

---

## Getting started (Windows)

### Step 1 — Download this repo

Click **Code → Download ZIP** on GitHub, then extract the folder anywhere on your PC.

> Alternatively: `git clone https://github.com/LucaDiLorenzo98/console_deck_pro.git`

---

### Step 2 — Flash the Arduino firmware

You only need to do this once.

1. Download and install [Arduino IDE](https://www.arduino.cc/en/software)
2. Open Arduino IDE → **Sketch → Include Library → Manage Libraries** → search **U8g2** → Install
3. In the extracted folder, open `console_deck_pro_arduino/console_deck_pro_arduino.ino`
4. Plug the Arduino Nano into your PC via USB
5. Set **Tools → Board → Arduino AVR Boards → Arduino Nano**
6. Set **Tools → Processor → ATmega328P** *(try "Old Bootloader" if upload fails)*
7. Set **Tools → Port** → select the COM port that appeared when you plugged in the Nano
8. Click **Upload** (the → arrow)

The OLED display should light up and show the boot screen. Done — you never need to touch Arduino IDE again.

---

### Step 3 — Install the desktop software

1. Go to the [latest release](../../releases/latest) on GitHub
2. Download `ConsoleDeckPro_Setup.exe`
3. Run the installer and follow the wizard

The installer includes everything: the UI app and the compiled backend — no Python installation required.

---

### Step 4 — First launch

The installer starts the backend for you, hidden in the background, and registers it to start automatically every time you sign in to Windows — there is nothing to launch by hand and no console window.

1. Open **Console Deck PRO** from the Start menu (or desktop shortcut) to launch the UI.
2. Go to **Settings** and select the Arduino serial port (e.g. `COM3`).
3. The OLED display will show the connected state and begin displaying PC stats.

> Everything the backend does is logged to `%APPDATA%\ConsoleDeckPro\logs\backend.log`. See [Backend autostart](#backend-autostart) to turn the automatic start off or to run the backend by hand.

---

### Step 5 — Configure your buttons

1. Go to the **Modules** tab in the app
2. Click any button slot to assign an action
3. Changes save automatically and take effect immediately

---

## Button actions

| Action | What it does |
|---|---|
| `open_url` | Opens a URL in the default browser |
| `open_app` | Launches an executable by name |
| `hotkey` | Sends a key combination (e.g. `Ctrl+C`, `Win+PrintScreen`) |
| `type_text` | Types a text string |
| `mute` | Toggles system mute |
| `set_volume` | Maps slider/knob to system volume |
| `home_assistant` | Triggers a Home Assistant service call |

---

## Expansion modules

Connect an expansion board to the side connector and select the module type from the on-device menu:

- **Sliders** — 2 analog sliders (e.g. volume)
- **Knobs** — 2 rotary knobs
- **Buttons** — 6 additional momentary buttons

---

## Installing Python and dependencies (advanced / dev use)

If you want to run the backend from source instead of using the compiled `.exe`:

### Step 1 — Install Python

1. Go to [python.org/downloads](https://www.python.org/downloads/) and download the latest **Python 3.10+** installer for Windows
2. Run the installer — **check "Add Python to PATH"** before clicking Install
3. Verify the installation by opening a terminal and running:
   ```
   python --version
   ```

### Step 2 — Install dependencies

1. Open a terminal in the project folder (where `requirements.txt` is located)
2. Run:
   ```
   pip install -r requirements.txt
   ```

### Step 3 — Start the backend

```
python console_deck_pro.py
```

---

## Backend autostart

The installer adds the backend to the Windows startup apps (option *"Start the backend automatically when I sign in to Windows"*, ticked by default). At every sign-in Windows runs:

```
"C:\Program Files\Console Deck PRO\console_deck_pro.exe" --background
```

`--background` means: no console window, no waiting for a key press, output only in the log file. The backend runs in your own desktop session, which is required for hotkeys and volume control.

- **Turn it off / on:** Task Manager → **Startup apps** → `console_deck_pro` → Disable / Enable. Or re-run the installer and untick the option.
- **Stop the running backend:** Task Manager → Details → end `console_deck_pro.exe`.
- **Start it by hand with a visible console** (useful for debugging): stop the running one first, then double-click `console_deck_pro.exe` in the installation folder. Without `--background` it opens a console window showing what it is doing; closing that window stops the backend.

> Upgrading from v2.1.0: if you created the `Console Deck PRO Backend` scheduled task described in the old README, the installer removes it — it is no longer needed.

---

## Troubleshooting

**Where are the logs?**
The backend writes everything to `%APPDATA%\ConsoleDeckPro\logs\backend.log` (paste that path in the Explorer address bar). **When reporting a bug, always attach this file** — it contains the app version, your OS, and the full error history.

| Problem | Fix |
|---|---|
| The backend does not seem to start | Check the last lines of `backend.log`. For live output, start `console_deck_pro.exe` by hand (see [Backend autostart](#backend-autostart)) |
| `Port 8000 is already in use` / `backend is already running` | The backend is already running in the background (that is normal after installation), or another program is using port 8000 |
| The UI says **"Backend not running"** | Sign out and back in, or double-click `console_deck_pro.exe` in the installation folder. Make sure it is not disabled in Task Manager → Startup apps |
| `Failed to connect to serial port ... Access is denied` | The COM port is in use by another program — close Arduino IDE, its Serial Monitor, or any other serial app |
| `Missing Python libraries` (running from source) | Run `pip install -r requirements.txt` |
| Windows SmartScreen: *"Windows protected your PC"* | The exe is unsigned. Click **More info → Run anyway** |
| Buttons/hotkeys do nothing while a specific app is focused | That app probably runs as administrator — keystrokes from a normal-privilege backend can't reach it. Run the backend as administrator too |

---

## Building from source

See [BUILDING.md](BUILDING.md) for instructions on building the Python backend, the Flutter app, and the Windows installer.

---

## License

[MIT](LICENSE)
