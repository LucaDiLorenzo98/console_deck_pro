# Console Deck PRO

A DIY macro deck built around an Arduino Nano — 9 programmable buttons, a rotary encoder, an OLED display, and an expandable module system (sliders, knobs, extra buttons). Each button can open a URL, launch an app, send a hotkey, control volume or screen brightness, and more. Configure everything from the desktop UI, no code editing required.

This is an **open-source maker project**. The full package (3D-printable enclosure files, electronics schematics, and BOM) is available as part of the crowdfunding campaign.

---

## What's in this repo

| Folder / File | Description |
|---|---|
| `console_deck_pro_arduino/` | Arduino firmware (upload once to the board) |
| `UI/` | Flutter desktop app (Windows / macOS / Linux) |
| `console_deck_pro.py` | Python backend source — bridges the Arduino with the OS |
| `dist/console_deck_pro.exe` | Compiled backend executable (produced by CI via PyInstaller) |
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

1. In the installation folder (default: `C:\Program Files\Console Deck PRO`), double-click **`console_deck_pro.exe`** to start the backend. A console window opens showing what the backend is doing — **keep it open** (you can minimize it); closing it stops the backend. Everything it prints is also saved to `%APPDATA%\ConsoleDeckPro\logs\backend.log`.
2. Open **Console Deck PRO** from the Start menu (or desktop shortcut) to launch the UI.
3. Go to **Settings** and select the Arduino serial port (e.g. `COM3`).
4. The OLED display will show the connected state and begin displaying PC stats.

> **Tip:** to avoid starting the backend by hand every time, see [Start the backend automatically at login](#start-the-backend-automatically-at-login-task-scheduler) below.

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
| `set_brightness` | Maps slider/knob to screen brightness |
| `home_assistant` | Triggers a Home Assistant service call |

---

## Expansion modules

Connect an expansion board to the side connector and select the module type from the on-device menu:

- **Sliders** — 2 analog sliders (typically volume + brightness)
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

## Start the backend automatically at login (Task Scheduler)

The installer intentionally does **not** auto-start the backend. If you want it to start by itself when you log in to Windows, create a scheduled task once:

> ⚠️ **Important:** choose **"Run only when user is logged on"**. Do NOT pick *"Run whether user is logged on or not"* — that runs the backend in a non-interactive session where hotkeys, volume and brightness control do not work.

### Option A — Task Scheduler GUI

1. Press `Win` and search for **Task Scheduler**, open it
2. Click **Create Task…** (not "Basic Task") in the right panel
3. **General** tab: name it `Console Deck PRO Backend`, select **Run only when user is logged on**
4. **Triggers** tab: **New…** → Begin the task: **At log on** → Specific user (you) → OK
5. **Actions** tab: **New…** → Action: **Start a program** →
   - Program/script: `C:\Program Files\Console Deck PRO\console_deck_pro.exe`
   - Add arguments: `--no-pause`
6. **Conditions** tab: untick **"Start the task only if the computer is on AC power"** (important on laptops)
7. **Settings** tab: untick **"Stop the task if it runs longer than 3 days"**
8. Click **OK**. Done — the backend will start at your next login. To test it now: right-click the task → **Run**

The `--no-pause` argument tells the backend not to wait for a key press on errors, so a failed scheduled run exits cleanly instead of hanging.

### Option B — one command

Open **PowerShell** and run:

```
schtasks /Create /TN "Console Deck PRO Backend" /SC ONLOGON /TR "\"C:\Program Files\Console Deck PRO\console_deck_pro.exe\" --no-pause"
```

Then apply steps 6–7 above from the Task Scheduler GUI (the command-line tool cannot set those options).

### Running without a visible window (optional)

By default the backend shows a console window (that's on purpose — you can see status and errors). If you prefer it fully hidden, set the task's **Action** to run PowerShell instead:

- Program/script: `powershell.exe`
- Add arguments:
  ```
  -WindowStyle Hidden -Command "Start-Process -WindowStyle Hidden 'C:\Program Files\Console Deck PRO\console_deck_pro.exe' -ArgumentList '--no-pause'"
  ```

> Note: when hidden, errors are only visible in the log file (see Troubleshooting below). The "Hidden" checkbox in Task Scheduler does **not** hide the console window — use the PowerShell wrapper above.

A simpler alternative: put a shortcut to `console_deck_pro.exe` in the `shell:startup` folder (Win+R → `shell:startup`) and set the shortcut's **Run** option to **Minimized**.

---

## Troubleshooting

**Where are the logs?**
The backend writes everything to `%APPDATA%\ConsoleDeckPro\logs\backend.log` (paste that path in the Explorer address bar). **When reporting a bug, always attach this file** — it contains the app version, your OS, and the full error history.

| Problem | Fix |
|---|---|
| The backend window closes immediately | It now stays open and shows the error — read it, and check the last lines of `backend.log` |
| `Port 8000 is already in use` / `backend is already running` | Another backend window is already open (check the taskbar / system tray), or another program is using port 8000. Close it and retry |
| The UI says **"Backend not running"** | Start `console_deck_pro.exe` (see Step 4). The UI does not start it for you |
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
