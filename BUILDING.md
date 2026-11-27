# Building from source

## Prerequisites

- Python 3.10+ with pip
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (stable channel)
- [Inno Setup 6](https://jrsoftware.org/isinfo.php) (Windows installer, optional)
- PyInstaller: `pip install pyinstaller`

---

## 1 — Build the Python backend

From the project root:

```bash
py -m PyInstaller --noconfirm console_deck_pro.spec
```

Output: the folder `dist\console_deck_pro\` (`console_deck_pro.exe` plus `_internal\`). The exe does not run without the `_internal` folder next to it.

> Always build from the `.spec` file — it includes the uvicorn hidden imports the exe needs at runtime and builds a **windowed** (no console) app on purpose, so the automatic start at sign-in (`--background`) never shows a terminal. Started by hand without `--background`, the exe opens its own console window; everything is also written to `%APPDATA%\ConsoleDeckPro\logs\backend.log`.

---

## 2 — Build the Flutter UI

```bash
cd UI
flutter build windows
```

Output: `UI\build\windows\x64\runner\Release\console_deck_ui.exe`

To include the skin creator feature, pass the API credentials at build time:

```bash
flutter build windows \
  --dart-define=SKIN_API_URL=https://your-cloud-function-url \
  --dart-define=SKIN_API_KEY=your-api-key
```

---

## 3 — Build the Windows installer

1. Make sure the folder `dist\console_deck_pro\` exists (built in step 1 — the `.iss` script reads it from there)
2. Open `UI\setup.iss` in Inno Setup Compiler
3. Press **Compile** (Ctrl+F9)

Output: `UI\Output\ConsoleDeckPro_Setup.exe`

**Optional:** add a custom app icon by placing `app_icon.ico` in `UI\windows\runner\resources\` and enabling the icon resource in `UI\windows\runner\Runner.rc`.

---

## Installer behavior

- Installs the Flutter UI (`console_deck_ui.exe`) and the compiled backend (`console_deck_pro.exe`) to the app directory
- Copies `config.example.json` for reference
- Does **not** launch the UI at the end of setup unless the user ticks the option (unticked by default); only the backend is started
- Registers the backend to start hidden at sign-in (`HKLM\...\CurrentVersion\Run` → `console_deck_pro.exe --background`, optional task ticked by default) and starts it at the end of setup
- Stops a running backend before upgrading or uninstalling, and removes the old manual `Console Deck PRO Backend` scheduled task
- Cleans up legacy files from older installer versions on upgrade

---

## Running in development (no installer)

```bash
# Terminal 1 — start the backend
python console_deck_pro.py

# Terminal 2 — run the UI in debug mode
cd UI
flutter run -d windows
```
