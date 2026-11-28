import sys
import os
import time
import json
import socket
import logging
import logging.handlers
import webbrowser
import subprocess
import threading
import platform
import queue
import ctypes
from datetime import datetime
from pathlib import Path
from threading import Thread, Event

if __name__ == "__main__":
    # Must run before anything else in a frozen exe: if any library ever starts a
    # multiprocessing worker, the worker is this same exe launched again, and
    # without this call it would run the whole backend again (and so on forever).
    import multiprocessing
    multiprocessing.freeze_support()

if sys.platform == "win32":
    # Up to Python 3.11, the first platform.system()/platform.platform() call
    # (ours or a library's) runs "cmd /c ver" to read the Windows version. From
    # an exe without a console that flashes a terminal window at every start.
    # The same information is available without it (sys.getwindowsversion),
    # which is what platform falls back to when this helper returns nothing.
    try:
        platform._syscmd_ver = lambda system="", release="", version="", *args, **kwargs: (system, release, version)
    except Exception:
        pass

APP_NAME = "ConsoleDeckPro"
APP_VERSION = "2.2.0"

# --background: started automatically at Windows sign-in (the installer registers
# the exe with this flag). No console window is ever created and nothing waits
# for a key press; all output goes to the log file only.
BACKGROUND_MODE = "--background" in sys.argv

def _setup_console() -> bool:
    """
    Make sure sys.stdout/sys.stderr are usable and return True when the user
    can actually see them.

    The Windows exe is built without a console (see console_deck_pro.spec) so
    that the automatic start at sign-in never flashes a terminal window. When
    the exe is started by hand we open a console ourselves, so status and error
    messages stay visible exactly as before.
    """
    if sys.stdout is not None and sys.stderr is not None:
        return True  # Started from a terminal / python.exe: nothing to do.

    if sys.platform == "win32" and not BACKGROUND_MODE:
        try:
            kernel32 = ctypes.windll.kernel32
            if kernel32.AllocConsole():
                kernel32.SetConsoleTitleW("Console Deck PRO backend")
                sys.stdout = open("CONOUT$", "w", encoding="utf-8", errors="replace", buffering=1)
                sys.stderr = sys.stdout
                sys.stdin = open("CONIN$", "r", encoding="utf-8", errors="replace")
                return True
        except Exception:
            pass

    # No console at all. Libraries such as uvicorn call sys.stdout.isatty() and
    # crash on None, so point the standard streams at the null device.
    try:
        if sys.stdout is None:
            sys.stdout = open(os.devnull, "w")
        if sys.stderr is None:
            sys.stderr = open(os.devnull, "w")
    except Exception:
        pass
    return False

HAS_CONSOLE = _setup_console()

def _default_app_dir() -> str:
    """
    Cross-platform, user-writable config directory.
    Override with CONSOLE_DECK_PRO_DIR or CONSOLE_DECK_PRO_CONFIG.
    """
    override = os.getenv("CONSOLE_DECK_PRO_DIR")
    if override:
        return override

    system = platform.system()
    home = Path.home()

    if system == "Windows":
        appdata = os.getenv("APPDATA") or os.getenv("LOCALAPPDATA")
        if appdata:
            return str(Path(appdata) / APP_NAME)
        return str(home / "AppData" / "Roaming" / APP_NAME)

    if system == "Darwin":
        return str(home / "Library" / "Application Support" / APP_NAME)

    xdg = os.getenv("XDG_CONFIG_HOME")
    if xdg:
        return str(Path(xdg) / APP_NAME)
    return str(home / ".config" / APP_NAME)

APP_DIR = _default_app_dir()
CONFIG_FILE = os.getenv("CONSOLE_DECK_PRO_CONFIG") or os.path.join(APP_DIR, "config.json")
LOG_DIR = os.path.join(APP_DIR, "logs")
LOG_FILE = os.path.join(LOG_DIR, "backend.log")

# Ensure the app directory exists
os.makedirs(APP_DIR, exist_ok=True)

log = logging.getLogger("consoledeck")

def _setup_logging():
    log.setLevel(logging.DEBUG)
    try:
        os.makedirs(LOG_DIR, exist_ok=True)
        file_handler = logging.handlers.RotatingFileHandler(
            LOG_FILE, maxBytes=1_000_000, backupCount=3, encoding="utf-8"
        )
        file_handler.setLevel(logging.DEBUG)
        file_handler.setFormatter(logging.Formatter("%(asctime)s [%(levelname)s] %(message)s"))
        log.addHandler(file_handler)
    except Exception:
        pass  # File logging is best-effort; console output still works.
    if HAS_CONSOLE:
        console_handler = logging.StreamHandler(sys.stdout)
        console_handler.setLevel(logging.INFO)
        console_handler.setFormatter(logging.Formatter("[%(levelname)s] %(message)s"))
        log.addHandler(console_handler)
    if not log.handlers:
        log.addHandler(logging.NullHandler())

_setup_logging()

def _log_unhandled_exception(exc_type, exc_value, exc_tb):
    if issubclass(exc_type, KeyboardInterrupt):
        return
    log.critical("Unhandled exception", exc_info=(exc_type, exc_value, exc_tb))

sys.excepthook = _log_unhandled_exception

_instance_mutex = None  # Keeps the handle alive for the lifetime of the process.

def _another_instance_is_running() -> bool:
    """
    Machine-wide single-instance lock (Windows named mutex).

    Windows creates the mutex atomically, so no matter how many copies are
    started, or how quickly, exactly one gets it and all the others exit before
    touching the serial port or the API port. Windows releases it automatically
    when the owning process ends, even after a crash. On other systems the API
    port check in main() does the same job.
    """
    global _instance_mutex
    if sys.platform != "win32":
        return False
    ERROR_ACCESS_DENIED = 5      # Mutex owned by a backend of another Windows user.
    ERROR_ALREADY_EXISTS = 183
    try:
        kernel32 = ctypes.WinDLL("kernel32", use_last_error=True)
        kernel32.CreateMutexW.restype = ctypes.c_void_p
        kernel32.CreateMutexW.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_wchar_p]
        handle = kernel32.CreateMutexW(None, 0, "Global\\ConsoleDeckProBackend")
        error = ctypes.get_last_error()
        if error in (ERROR_ALREADY_EXISTS, ERROR_ACCESS_DENIED):
            return True
        _instance_mutex = handle
    except Exception:
        pass  # Never block startup because of the lock itself.
    return False

if __name__ == "__main__" and _another_instance_is_running():
    if BACKGROUND_MODE:
        log.info("Another backend instance is already running. Exiting.")
        sys.exit(0)
    log.error(
        "The Console Deck PRO backend is already running in the background. "
        "To restart it, end console_deck_pro.exe in Task Manager first."
    )
    log.error(f"Full log: {LOG_FILE}")
    try:
        if HAS_CONSOLE and sys.stdin is not None and sys.stdin.isatty() and "--no-pause" not in sys.argv:
            input("\nPress Enter to close this window...")
    except Exception:
        pass
    sys.exit(1)

def _log_thread_exception(args):
    # Thread exceptions bypass sys.excepthook (the API server runs in a thread).
    if issubclass(args.exc_type, SystemExit):
        return
    thread_name = args.thread.name if args.thread else "?"
    log.critical(
        f"Unhandled exception in thread {thread_name}",
        exc_info=(args.exc_type, args.exc_value, args.exc_traceback),
    )

threading.excepthook = _log_thread_exception

def _pause_before_exit():
    """
    Keep the console window open so the user can read the error before it closes.
    Skipped for scheduled/headless runs via --background, --no-pause or
    CONSOLE_DECK_PRO_NO_PAUSE=1.
    """
    if BACKGROUND_MODE or not HAS_CONSOLE:
        return
    if os.getenv("CONSOLE_DECK_PRO_NO_PAUSE") in ("1", "true", "True"):
        return
    if "--no-pause" in sys.argv:
        return
    try:
        if sys.stdin is not None and sys.stdin.isatty():
            input("\nPress Enter to close this window...")
    except Exception:
        pass

def _fatal_exit(message):
    log.error(message)
    log.error(f"Full log: {LOG_FILE}")
    _pause_before_exit()
    sys.exit(1)

# Third-party imports: collect every missing package first so the user gets one
# clear, actionable message instead of the window closing on the first ImportError.
_MISSING_PACKAGES = []

def _require(pip_name, module_name):
    try:
        __import__(module_name)
    except ImportError:
        _MISSING_PACKAGES.append(pip_name)

_require("pyserial", "serial.tools.list_ports")
_require("pyautogui", "pyautogui")
_require("psutil", "psutil")
_require("fastapi", "fastapi")
_require("uvicorn", "uvicorn")
_require("requests", "requests")

if _MISSING_PACKAGES:
    log.error(f"Missing Python libraries: {', '.join(_MISSING_PACKAGES)}")
    _fatal_exit("Install them with:  pip install -r requirements.txt")

try:
    import serial
    import pyautogui
    import psutil
    from fastapi import FastAPI
    import uvicorn
    from serial.tools import list_ports
    import requests as _requests
except Exception:
    # Some libraries fail at import time with errors other than ImportError
    # (e.g. pyautogui without a display). Log and keep the window open.
    log.critical("A required library failed to load:", exc_info=True)
    _fatal_exit("Could not start due to the error above. See the log for details.")

try:
    import pygame
    HAS_PYGAME = True
except ImportError:
    HAS_PYGAME = False

try:
    from playsound import playsound
    HAS_PLAYSOUND = True
except Exception:
    HAS_PLAYSOUND = False

try:
    import winsound
    HAS_WINSOUND = True
except Exception:
    HAS_WINSOUND = False

_pygame_audio_ready = False

def _init_pygame_audio():
    global _pygame_audio_ready
    if _pygame_audio_ready:
        return True
    if not HAS_PYGAME:
        return False
    try:
        if not pygame.mixer.get_init():
            pygame.mixer.init(frequency=44100, size=-16, channels=2, buffer=512)
        _pygame_audio_ready = True
        return True
    except Exception as e:
        log.warning(f"pygame audio init failed: {e}")
        return False

def _play_audio_one_shot(file_path):
    """Play a one-shot audio file for button mappings."""
    if not file_path or not os.path.isfile(file_path):
        if ENABLE_ACTION_LOG:
            log.debug(f"[AUDIO] File not found: {file_path}")
        return

    if _init_pygame_audio():
        try:
            pygame.mixer.music.load(file_path)
            pygame.mixer.music.play()
            return
        except Exception:
            pass
        try:
            pygame.mixer.Sound(file_path).play()
            return
        except Exception:
            pass

    if HAS_PLAYSOUND:
        try:
            threading.Thread(
                target=playsound, args=(file_path,),
                kwargs={"block": False}, daemon=True,
            ).start()
            return
        except Exception:
            pass

    if HAS_WINSOUND and file_path.lower().endswith(".wav"):
        try:
            winsound.PlaySound(file_path, winsound.SND_FILENAME | winsound.SND_ASYNC)
            return
        except Exception:
            pass

    try:
        system = platform.system()
        if system == "Darwin":
            subprocess.Popen(["afplay", file_path], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        elif system == "Linux":
            subprocess.Popen(["aplay", "-q", file_path], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except (FileNotFoundError, OSError):
        pass


def _press_system_volume_key(key: str, count: int = 1):
    """
    Sends system volume keys in a platform-aware way.
    On Windows, WM_APPCOMMAND simulates hardware volume keys directly.
    """
    if count < 1:
        return

    if platform.system() == "Windows":
        # Prefer virtual media key injection; fallback to WM_APPCOMMAND broadcast.
        vk_map = {
            "volumeup": 0xAF,   # VK_VOLUME_UP
            "volumedown": 0xAE, # VK_VOLUME_DOWN
            "volumemute": 0xAD, # VK_VOLUME_MUTE
        }
        vk = vk_map.get(key)
        if vk is None:
            return

        KEYEVENTF_KEYUP = 0x0002
        try:
            for _ in range(count):
                ctypes.windll.user32.keybd_event(vk, 0, 0, 0)
                ctypes.windll.user32.keybd_event(vk, 0, KEYEVENTF_KEYUP, 0)
            return
        except Exception:
            pass

        # Fallback path (some systems react better to app commands).
        try:
            HWND_BROADCAST = 0xFFFF
            WM_APPCOMMAND = 0x0319
            app_map = {"volumeup": 10, "volumedown": 9, "volumemute": 8}
            app_cmd = app_map.get(key)
            if app_cmd is None:
                return
            for _ in range(count):
                ctypes.windll.user32.SendMessageW(HWND_BROADCAST, WM_APPCOMMAND, 0, app_cmd << 16)
            return
        except Exception:
            pass

    for _ in range(count):
        pyautogui.press(key)

# GPU Utils (Optional)
# Not used on Windows: GPUtil spawns nvidia-smi without CREATE_NO_WINDOW, which
# pops up a console window on every sample when the backend runs without one.
HAS_GPUTIL = False
if platform.system() != "Windows":
    try:
        import GPUtil
        HAS_GPUTIL = True
    except Exception:
        HAS_GPUTIL = False

# Keeps console child processes (nvidia-smi) from opening a window. 0 elsewhere.
_NO_WINDOW = getattr(subprocess, "CREATE_NO_WINDOW", 0)
_nvidia_smi_missing = False

# Debug / Logging Configuration
# Printing telemetry every 0.5s can cause micro-stutters on some systems due to console I/O.
ENABLE_TELEMETRY_LOG = os.getenv("CONSOLE_DECK_PRO_TELEMETRY_LOG", "0") in ("1", "true", "True")
ENABLE_EVENT_LOG = os.getenv("CONSOLE_DECK_PRO_EVENT_LOG", "0") in ("1", "true", "True")
ENABLE_ACTION_LOG = os.getenv("CONSOLE_DECK_PRO_ACTION_LOG", "0") in ("1", "true", "True")
ANALOG_ABSOLUTE_DEADBAND = 2

app = FastAPI()
config_data = None
config_updated_event = Event() # Used to signal the main thread to reload the config

@app.post("/reload")
def reload_config_endpoint():
    """
    Called by the UI when the config is saved.
    This simply sets an event to notify the main loop to re-read the config file.
    """
    config_updated_event.set()
    log.info("Configuration reload requested via API")
    return {"message": "Config reload signaled"}

@app.get("/audio/apps")
def get_audio_apps():
    """Apps that currently have an entry in the Windows volume mixer."""
    try:
        return windows_audio.list_apps()
    except Exception as e:
        log.error(f"Could not list audio apps: {e}")
        return []


@app.get("/serial/ports")
def get_serial_ports():
    ports = list_ports.comports()
    return [{"device": port.device, "description": port.description} for port in ports]


@app.get("/status")
def get_backend_status():
    cfg = config_data if isinstance(config_data, dict) else load_config()
    cfg = cfg if isinstance(cfg, dict) else {}
    serial_cfg = cfg.get("serial", {})
    port = serial_cfg.get("port") if isinstance(serial_cfg, dict) else None
    return {"running": True, "configured": bool(port), "port": port}


def run_server():
    # Uvicorn logging can be noisy, this can be changed to 'info' for more detail
    #
    # If the server cannot start or stops (e.g. port 8000 briefly taken), keep
    # trying: the serial loop stays alive so macros still work, and the UI can
    # connect again as soon as the port is free. Without the retry the backend
    # would stay invisible to the UI until it is killed by hand. uvicorn reports
    # a failed bind with SystemExit, not with an ordinary exception.
    failure_logged = False
    while True:
        try:
            uvicorn.run(app, host="127.0.0.1", port=8000, log_level="warning")
            reason = "stopped"
        except (Exception, SystemExit):
            reason = "failed to start"
            if not failure_logged:
                log.error("API server error:", exc_info=True)
        if not failure_logged:
            log.error(f"API server {reason}. The UI cannot connect until it is back; retrying every 5 seconds.")
            failure_logged = True
        time.sleep(5)


def _check_api_port_available():
    """Fail fast with a clear message if port 8000 is taken (second instance or another app)."""
    try:
        probe = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        try:
            probe.bind(("127.0.0.1", 8000))
        finally:
            probe.close()
        return
    except OSError:
        pass

    try:
        resp = _requests.get("http://127.0.0.1:8000/status", timeout=1)
        if resp.status_code == 200 and resp.json().get("running"):
            _fatal_exit(
                "The Console Deck PRO backend is already running. "
                "Close the other backend window first, or just use the one that is running."
            )
    except (_requests.exceptions.RequestException, ValueError):
        pass

    if BACKGROUND_MODE:
        # Started at sign-in or by the installer: nobody would see the error
        # and the deck would silently stop working. The single-instance lock
        # already ruled out a second backend, so the port is held by another
        # program, maybe only briefly: keep the macros running and let
        # run_server() retry until the UI can connect again.
        log.error(
            "Port 8000 is in use by another program. Macros keep working; "
            "the UI can connect once the port is free."
        )
        return

    _fatal_exit(
        "Port 8000 is already in use by another program. "
        "Close the program using it, then start the backend again."
    )

def load_config():
    default_config = {
        "serial": {
            "port": None,
            "baud_rate": 115200
        },
        "mappings": {
            "main": {},
            "modules": {}
        },
        "special_modules": {}
    }

    if not os.path.exists(CONFIG_FILE):
        log.info(f"{CONFIG_FILE} not found. Creating a new one with default values.")
        try:
            with open(CONFIG_FILE, 'w') as f:
                json.dump(default_config, f, indent=4)
            return default_config
        except Exception as e:
            log.error(f"Could not create default config file: {e}")
            return None

    try:
        # The UI rewrites this file in place while we may be reading it, so an
        # empty or half-written file is usually just bad timing: look again a
        # few times before deciding the file is really broken.
        content = ""
        parse_error = None
        for attempt in range(4):
            if attempt:
                time.sleep(0.25)
            with open(CONFIG_FILE, 'r', encoding='utf-8-sig') as f:
                content = f.read()
            if not content.strip():
                continue
            try:
                loaded = json.loads(content)
            except json.JSONDecodeError as e:
                parse_error = e
                continue
            if isinstance(loaded, dict):
                return loaded
            log.error(f"{CONFIG_FILE} does not contain a settings object. Ignoring it.")
            return default_config
        if not content.strip():
            log.warning(f"{CONFIG_FILE} is empty. Using default values.")
            return default_config
        raise parse_error
    except json.JSONDecodeError as e:
        log.error(f"Error parsing {CONFIG_FILE}: {e}. Backing up and resetting to defaults.")
        try:
            backup_path = f"{CONFIG_FILE}.bad.{int(time.time())}"
            os.replace(CONFIG_FILE, backup_path)
            log.info(f"Bad config moved to {backup_path}")
        except Exception:
            pass
        try:
            with open(CONFIG_FILE, 'w') as wf:
                json.dump(default_config, wf, indent=4)
            return default_config
        except Exception:
            return None
    except Exception as e:
        log.error(f"Error reading {CONFIG_FILE}: {e}")
        return None

def ensure_config_loaded():
    global config_data
    if not isinstance(config_data, dict):
        config_data = load_config()
    if not isinstance(config_data, dict):
        config_data = {"serial": {"port": None, "baud_rate": 115200}, "mappings": {"main": {}, "modules": {}}, "special_modules": {}}
    return config_data


def _open_url(value):
    url = str(value or "").strip()
    if not url:
        return
    # "example.com" without a scheme would be treated as a file name.
    if "://" not in url and not url.lower().startswith(("mailto:", "file:")):
        url = "https://" + url
    webbrowser.open(url)


def _open_app(value):
    target = os.path.expandvars(str(value or "").strip().strip('"'))
    if not target:
        return
    if platform.system() == "Windows" and os.path.exists(target):
        # Same as a double-click: works for .exe, shortcuts (.lnk) and
        # documents, and starts the program in its own folder.
        os.startfile(target, cwd=os.path.dirname(target) or None)
        return
    # A command line with arguments, or a program found through PATH.
    subprocess.Popen(target)


# Key names written by the UI (or by hand) that pyautogui calls differently.
_HOTKEY_ALIASES = {
    "meta": "win", "super": "win", "windows": "win", "cmd": "win",
    "control": "ctrl", "return": "enter", "del": "delete", "ins": "insert",
    "page up": "pageup", "page down": "pagedown",
    "arrow up": "up", "arrow down": "down", "arrow left": "left", "arrow right": "right",
    " ": "space", "plus": "+",
}

def _send_hotkey(value):
    if isinstance(value, str):
        value = value.split("+")
    if not isinstance(value, (list, tuple)):
        return
    keys = []
    for key in value:
        key = str(key).strip().lower()
        key = _HOTKEY_ALIASES.get(key, key)
        if key:
            keys.append(key)
    if not keys:
        return
    # pyautogui silently skips names it does not know, which would turn
    # e.g. Win+P into a plain "p". Send nothing rather than the wrong keys.
    known = getattr(pyautogui, "KEYBOARD_KEYS", None)
    if known:
        unknown = [k for k in keys if k not in known]
        if unknown:
            log.warning(f"Hotkey {'+'.join(keys)} not sent: unknown key(s) {', '.join(unknown)}.")
            return
    if len(keys) == 1:
        pyautogui.press(keys[0])
    else:
        pyautogui.hotkey(*keys)


class WindowsAudio:
    """
    Per-application and microphone volume through the Windows audio mixer
    (Core Audio, via pycaw). These are plain in-process calls to the audio
    service: cheap, and safe to repeat while a slider is being moved.
    Windows only; everywhere else every method reports "not available".
    """

    def __init__(self):
        self._tls = threading.local()
        self._utils = None
        self._unavailable = platform.system() != "Windows"

    def _ready(self):
        if self._unavailable:
            return False
        if not getattr(self._tls, "com_ready", False):
            try:
                import comtypes
                try:
                    comtypes.CoInitialize()  # Needed once in every thread that uses COM.
                except OSError:
                    pass  # Already initialised in another mode: usable as it is.
                self._tls.com_ready = True
            except Exception as e:
                log.error(f"Windows audio mixer not available: {e}")
                self._unavailable = True
                return False
        if self._utils is None:
            try:
                from pycaw.pycaw import AudioUtilities
                self._utils = AudioUtilities
            except Exception as e:
                log.error(f"Windows audio mixer not available: {e}")
                self._unavailable = True
                return False
        return True

    @staticmethod
    def normalize(name):
        name = str(name or "").strip().strip('"').replace("\\", "/").rsplit("/", 1)[-1].lower()
        return name[:-4] if name.endswith(".exe") else name

    def _sessions(self):
        """Yield (normalized process name, session) for apps in the mixer."""
        for session in self._utils.GetAllSessions():
            try:
                process = session.Process
                if process is None:
                    continue  # System sounds.
                yield self.normalize(process.name()), session
            except Exception:
                continue  # The app closed in the meantime.

    def list_apps(self):
        """Names of the apps that currently have an entry in the volume mixer."""
        if not self._ready():
            return []
        return sorted({name for name, _ in self._sessions() if name})

    def set_app_volume(self, app, percent):
        """Returns how many mixer entries were changed (0 = app not playing)."""
        if not self._ready():
            return 0
        wanted = self.normalize(app)
        if not wanted:
            return 0
        level = max(0.0, min(1.0, percent / 100.0))
        changed = 0
        for name, session in self._sessions():
            if name == wanted:
                try:
                    session.SimpleAudioVolume.SetMasterVolume(level, None)
                    changed += 1
                except Exception:
                    pass
        return changed

    def set_focus_volume(self, percent):
        """Volume of the app whose window is in the foreground."""
        if not self._ready():
            return 0
        pid = ctypes.c_ulong(0)
        hwnd = ctypes.windll.user32.GetForegroundWindow()
        ctypes.windll.user32.GetWindowThreadProcessId(hwnd, ctypes.byref(pid))
        if not pid.value:
            return 0
        try:
            return self.set_app_volume(psutil.Process(pid.value).name(), percent)
        except Exception:
            return 0

    def set_mic_volume(self, percent):
        if not self._ready():
            return 0
        device = self._utils.CreateDevice(self._utils.GetMicrophone())
        device.volume_percent = float(percent)
        return 1


windows_audio = WindowsAudio()

# Slider/knob functions that set a level directly (as opposed to 'set_volume',
# which follows the movement with volume keys).
_MIXER_ACTIONS = ('set_app_volume', 'set_focus_volume', 'set_mic_volume')


class AnalogOutputs:
    """
    Applies slider/knob positions (0-100) to the system volume, to the volume
    of one application, or to the microphone level.

    The deck reports the position of each control about 100 times per second.
    Handling every report as its own action floods whatever is being driven
    (this is what made displays go haywire when brightness was still offered),
    so only the latest position of each control is kept, and one background
    thread applies it:
      - nothing happens until the control is actually moved (the position at
        connection time is only a starting point), and jitter of +/-1 is ignored;
      - system volume follows the movement with volume keys (2% per key press);
      - app and microphone volume are set to the position itself;
      - after an error it waits before trying again instead of retrying non-stop.
    """

    DEADBAND = 2                    # percent; smaller changes are jitter
    MAX_VOLUME_KEYS = 25            # per step (50%)
    MIXER_ERROR_BACKOFF = 5.0       # seconds

    def __init__(self):
        self._lock = threading.Lock()
        self._wake = Event()
        self._controls = {}
        self._thread = None
        self._mixer_retry_time = 0.0
        self._mixer_error_logged = False

    def reset(self):
        """Forget all positions (called on every new serial connection)."""
        with self._lock:
            self._controls.clear()

    def update(self, control, kind, value, param=None):
        try:
            value = max(0, min(100, int(float(value))))
        except (TypeError, ValueError):
            return
        with self._lock:
            state = self._controls.get(control)
            if state is None or state["kind"] != kind or state["param"] != param:
                # First report (or the control was just given another
                # function): remember where it is, do nothing.
                self._controls[control] = {"kind": kind, "param": param, "applied": value, "wanted": value}
                return
            if state["wanted"] == value:
                return
            state["wanted"] = value
            if self._thread is None:
                self._thread = Thread(target=self._run, name="analog-outputs", daemon=True)
                self._thread.start()
        self._wake.set()

    def _pending(self):
        with self._lock:
            return [
                (name, st["kind"], st["param"], st["applied"], st["wanted"])
                for name, st in self._controls.items()
                if abs(st["wanted"] - st["applied"]) >= self.DEADBAND
                or (st["wanted"] != st["applied"] and st["wanted"] in (0, 100))
            ]

    def _mark_applied(self, name, kind, applied):
        with self._lock:
            state = self._controls.get(name)
            if state is not None and state["kind"] == kind:
                state["applied"] = applied

    def _run(self):
        while True:
            self._wake.wait(timeout=1.0)
            self._wake.clear()
            try:
                work_left = self._apply_pending()
            except Exception as e:
                log.error(f"Analog output worker error: {e}", exc_info=True)
                work_left = False
            # Pace the loop: at most ~20 rounds per second, however fast the
            # control is moved.
            time.sleep(0.05)
            if work_left:
                self._wake.set()

    def _apply_pending(self):
        work_left = False
        for name, kind, param, applied, wanted in self._pending():
            if kind in _MIXER_ACTIONS:
                if time.monotonic() < self._mixer_retry_time:
                    work_left = True
                    continue
                try:
                    if kind == 'set_app_volume':
                        changed = windows_audio.set_app_volume(param, wanted)
                    elif kind == 'set_focus_volume':
                        changed = windows_audio.set_focus_volume(wanted)
                    else:
                        changed = windows_audio.set_mic_volume(wanted)
                    self._mixer_error_logged = False
                    if ENABLE_ACTION_LOG:
                        log.debug(f"{kind} {param or ''} -> {wanted}% ({name}, {changed} mixer entries)")
                except Exception as e:
                    self._mixer_retry_time = time.monotonic() + self.MIXER_ERROR_BACKOFF
                    if not self._mixer_error_logged:
                        log.error(f"Could not set {kind}: {e}")
                        self._mixer_error_logged = True
                # Applied either way: if the app is not running there is nothing
                # to retry until the control moves again.
                self._mark_applied(name, kind, wanted)
            elif kind == 'set_volume':
                steps = min(self.MAX_VOLUME_KEYS, abs(wanted - applied) // 2)
                if steps < 1:
                    # 1% left to an end stop: nothing to press, call it done.
                    self._mark_applied(name, kind, wanted)
                    continue
                key = 'volumeup' if wanted > applied else 'volumedown'
                _press_system_volume_key(key, steps)
                new_applied = applied + (steps * 2 if wanted > applied else -steps * 2)
                if wanted in (0, 100) and abs(wanted - new_applied) < 2:
                    new_applied = wanted
                self._mark_applied(name, kind, new_applied)
                if ENABLE_ACTION_LOG:
                    log.debug(f"Volume {key} x {steps} ({name}: {applied}% -> {wanted}%)")
        return work_left


analog_outputs = AnalogOutputs()
_ANALOG_ACTIONS = ('set_volume',) + _MIXER_ACTIONS

# Screen brightness control was removed: on real hardware the monitor commands
# (DDC/CI) were unreliable and could destabilise the displays. Configs that
# still have it assigned keep loading; the control simply does nothing.
_REMOVED_ACTIONS = ('set_brightness', 'brightness')
_removed_actions_warned = set()

def _warn_removed_action(action_type):
    if action_type not in _removed_actions_warned:
        _removed_actions_warned.add(action_type)
        log.warning(
            f"'{action_type}' is assigned in the config but screen brightness is no "
            "longer supported. The control does nothing; pick another function in the UI."
        )


def execute_action(action_def, absolute_value=None, multiplier=1):
    if not action_def or not isinstance(action_def, dict):
        return

    action_type = action_def.get('action')
    value = action_def.get('value')

    if not action_type:
        return

    if absolute_value is not None:
        value = absolute_value

    if ENABLE_ACTION_LOG:
        log.debug(f"[ACTION] {action_type}: {value}")

    try:
        if action_type == 'open_url':
            if ENABLE_ACTION_LOG:
                log.debug(f"Opening URL: {value}")
            _open_url(value)
        elif action_type == 'open_app':
            if ENABLE_ACTION_LOG:
                log.debug(f"Opening App: {value}")
            _open_app(value)
        elif action_type == 'hotkey':
            if ENABLE_ACTION_LOG:
                log.debug(f"Sending Hotkey: {value}")
            _send_hotkey(value)
        elif action_type == 'type':
            if ENABLE_ACTION_LOG:
                log.debug(f"Typing: {value}")
            pyautogui.write(value)
        elif action_type in _REMOVED_ACTIONS:
            _warn_removed_action(action_type)
        elif action_type in _ANALOG_ACTIONS and absolute_value is not None:
            # Slider/knob position. Never handled here one sample at a time:
            # see AnalogOutputs for why.
            analog_outputs.update(action_type, action_type, absolute_value, action_def.get('value'))
        elif action_type in _ANALOG_ACTIONS:
            log.warning(f"'{action_type}' only works on a slider or knob. Ignored.")
        elif action_type == 'toggle_mute':
            _press_system_volume_key('volumemute', 1)
            if ENABLE_ACTION_LOG:
                log.debug("Toggled Mute")
        elif action_type == 'change_volume':
            key = 'volumeup' if float(value) > 0 else 'volumedown'
            count = int(round(abs(float(value)) * multiplier))
            if count < 1: count = 1
            if count > 25: count = 25
            if ENABLE_ACTION_LOG:
                log.debug(f"Change Volume: {key} x {count}")
            _press_system_volume_key(key, count)
        elif action_type == 'play_audio':
            file_path = str(value or "")
            if file_path:
                _play_audio_one_shot(file_path)
                if ENABLE_ACTION_LOG:
                    log.debug(f"Play Audio: {file_path}")
        elif action_type == 'home_assistant':
            ha_cfg = config_data.get('home_assistant', {}) if isinstance(config_data, dict) else {}
            host = str(ha_cfg.get('host', '')).rstrip('/')
            token = str(ha_cfg.get('token', ''))
            service = str(action_def.get('service', ''))
            entity_id = str(action_def.get('entity_id', ''))
            missing = [k for k, v in [('host', host), ('token', token), ('service', service), ('entity_id', entity_id)] if not v]
            if missing:
                log.warning(f"Home Assistant: missing {', '.join(missing)}. Configure HA in Settings.")
            else:
                try:
                    domain = entity_id.split('.')[0] if '.' in entity_id else entity_id
                    url = f"{host}/api/services/{domain}/{service}"
                    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
                    resp = _requests.post(url, headers=headers, json={"entity_id": entity_id}, timeout=5)
                    if resp.status_code in (200, 201):
                        if ENABLE_ACTION_LOG:
                            log.debug(f"HA {service} on {entity_id} → OK ({resp.status_code})")
                    elif resp.status_code == 401:
                        log.error("HA: Invalid or expired token. Update the token in Settings.")
                    elif resp.status_code == 404:
                        log.error(f"HA: Service '{domain}/{service}' or entity '{entity_id}' not found.")
                    elif resp.status_code == 400:
                        log.error(f"HA: Bad request for '{entity_id}'/'{service}': {resp.text[:200]}")
                    else:
                        log.error(f"HA: HTTP {resp.status_code} for '{entity_id}': {resp.text[:200]}")
                except _requests.exceptions.ConnectionError:
                    log.error(f"HA: Cannot connect to '{host}'. Check the URL in Settings.")
                except _requests.exceptions.Timeout:
                    log.error(f"HA: Request to '{host}' timed out. HA may be unreachable.")
                except _requests.exceptions.RequestException as e:
                    log.error(f"HA: Request failed: {e}")
        else:
            log.warning(f"Unknown action type: {action_type}")
    except Exception as e:
        log.error(f"Failed to execute action '{action_type}': {e}", exc_info=True)


def reload_config_if_requested():
    global config_data
    if config_updated_event.is_set():
        config_data = load_config()
        config_updated_event.clear()


def _get_gpu_stats():
    """
    Best-effort GPU utilization (%) and temperature (C).
    Returns (-1, -1) when unavailable.
    """
    global _nvidia_smi_missing
    if HAS_GPUTIL:
        try:
            gpus = GPUtil.getGPUs()
            if gpus:
                return int(gpus[0].load * 100), int(gpus[0].temperature)
        except Exception:
            pass

    if _nvidia_smi_missing:
        return -1, -1

    try:
        # Avoid shell=True for performance and safety.
        proc = subprocess.run(
            [
                "nvidia-smi",
                "--query-gpu=utilization.gpu,temperature.gpu",
                "--format=csv,noheader,nounits",
            ],
            capture_output=True,
            text=True,
            timeout=1.0,
            check=False,
            creationflags=_NO_WINDOW,
        )
        out = (proc.stdout or "").strip()
        if out:
            # One line per GPU: use the first one.
            parts = [p.strip() for p in out.splitlines()[0].split(",")]
            if len(parts) >= 2:
                return int(parts[0]), int(parts[1])
    except FileNotFoundError:
        # No NVIDIA driver installed: stop trying every couple of seconds.
        _nvidia_smi_missing = True
    except Exception:
        pass

    return -1, -1


class ActionExecutor:
    """
    Executes actions on a background thread so serial I/O stays responsive.
    """

    def __init__(self, max_queue=256):
        self._q = queue.Queue(maxsize=max_queue)
        self._stop = Event()
        self._thread = Thread(target=self._run, daemon=True)

    def start(self):
        self._thread.start()
        return self

    def stop(self):
        self._stop.set()

    def submit(self, action_def, absolute_value=None, multiplier=1):
        if not action_def:
            return
        item = (action_def, absolute_value, multiplier)
        try:
            self._q.put_nowait(item)
        except queue.Full:
            # Drop one item to keep latency bounded.
            try:
                self._q.get_nowait()
                self._q.task_done()
            except queue.Empty:
                pass
            try:
                self._q.put_nowait(item)
            except queue.Full:
                pass

    def _run(self):
        while not self._stop.is_set():
            try:
                action_def, absolute_value, multiplier = self._q.get(timeout=0.2)
            except queue.Empty:
                continue
            try:
                execute_action(action_def, absolute_value=absolute_value, multiplier=multiplier)
            except Exception as e:
                log.error(f"Action worker failed: {e}", exc_info=True)
            finally:
                self._q.task_done()


class TelemetrySampler:
    """
    Samples telemetry on a background thread to avoid blocking the serial loop.
    """

    def __init__(self, interval_s=0.5, slow_interval_s=2.0):
        self._interval_s = float(interval_s)
        self._slow_interval_s = float(slow_interval_s)
        self._stop = Event()
        self._lock = threading.Lock()
        self._thread = Thread(target=self._run, daemon=True)
        self._snapshot = {
            "cpu": 0,
            "gpu": -1,
            "ram": 0,
            "cpu_freq_mhz": -1,
            "gpu_temp_c": -1,
        }

    def start(self):
        # Prime cpu_percent() so the first read isn't 0/meaningless.
        try:
            psutil.cpu_percent(interval=None)
        except Exception:
            pass
        self._thread.start()
        return self

    def stop(self):
        self._stop.set()

    def get_snapshot(self):
        with self._lock:
            return dict(self._snapshot)

    def _run(self):
        last_time = time.monotonic()
        next_slow = 0.0
        gpu = -1
        gpu_temp_c = -1
        cpu_freq_mhz = -1

        while not self._stop.is_set():
            now = time.monotonic()

            # Fast metrics (every tick)
            try:
                cpu = int(psutil.cpu_percent(interval=None))
            except Exception:
                cpu = 0

            try:
                ram = int(psutil.virtual_memory().percent)
            except Exception:
                ram = 0

            # Slow metrics (GPU temp + CPU frequency) on a slower cadence
            if now >= next_slow:
                gpu, gpu_temp_c = _get_gpu_stats()
                freq_mhz = get_cpu_freq_mhz()
                # Keep wire format unchanged (4th field still same position),
                # but now it carries CPU frequency in MHz.
                cpu_freq_mhz = freq_mhz if freq_mhz > 0 else -1
                next_slow = now + self._slow_interval_s

            last_time = now

            with self._lock:
                self._snapshot.update(
                    {
                        "cpu": cpu,
                        "gpu": gpu,
                        "ram": ram,
                        "cpu_freq_mhz": cpu_freq_mhz,
                        "gpu_temp_c": gpu_temp_c,
                    }
                )

            self._stop.wait(self._interval_s)

def main():
    global config_data
    _check_api_port_available()
    server_thread = Thread(target=run_server, name="api-server")
    server_thread.daemon = True
    server_thread.start()

    # Load the initial configuration
    config_data = load_config()
    if not config_data:
        _fatal_exit("Could not load or create a configuration file.")

    # State flags so the wait/retry loops log once per state change instead of spamming.
    waiting_for_port_logged = False
    connect_fail_logged = False

    # --- Main Loop ---
    while True:
        try:
            reload_config_if_requested()
            ensure_config_loaded()

            serial_config = config_data.get('serial')
            if not isinstance(serial_config, dict):
                serial_config = {}
            port = serial_config.get('port')
            baud_rate = serial_config.get('baud_rate') or 115200

            # STATE 1: Port is not configured. Wait for the signal or a timeout.
            if not port:
                if not waiting_for_port_logged:
                    log.info("Serial port not configured. Waiting for selection in the UI...")
                    waiting_for_port_logged = True
                # Wait for the reload signal, with a 2-second timeout to keep the loop spinning
                config_updated_event.wait(timeout=2)
                continue
            waiting_for_port_logged = False

            # STATE 2: Port is configured. Attempt connection and run device logic.
            if not connect_fail_logged:
                log.info(f"Port configured. Attempting to connect to {port} at {baud_rate}...")
            try:
                # write_timeout: a device that stops accepting data must not
                # freeze the loop forever; the timeout triggers a reconnect.
                ser = serial.Serial(port, baud_rate, timeout=1, write_timeout=2)
                time.sleep(2) # Wait for connection to settle
                log.info("Connected to device!")
                connect_fail_logged = False
            except serial.SerialException as e:
                # Logged once per outage: retries are frequent and would fill the log.
                if not connect_fail_logged:
                    log.error(f"Failed to connect to serial port '{port}': {e}")
                    if "PermissionError" in str(e) or "Access is denied" in str(e):
                        log.info("Tip: the port might be in use by another application (e.g. Arduino IDE).")
                    log.info("Will keep retrying every few seconds. You can change the port in the UI.")
                    connect_fail_logged = True
                # Short, interruptible wait: the deck works again a few seconds
                # after the cable is plugged back in, and a port change made in
                # the UI is picked up immediately.
                config_updated_event.wait(timeout=3)
                continue

            # --- This is the main device loop ---
            run_device_loop(ser)

            # If the loop exits (e.g., device disconnect), inform the user and wait before retrying.
            log.info("Device disconnected. Waiting for reconnection or configuration change...")
            config_updated_event.wait(timeout=2)

        except KeyboardInterrupt:
            log.info("Exiting...")
            break
        except Exception as e:
            log.error(f"An unexpected error occurred in the main loop: {e}", exc_info=True)
            log.info("Restarting main loop in 10 seconds...")
            time.sleep(10)


def run_device_loop(ser):
    """
    Handles all the communication with the serial device.
    This function is extracted from main() to be called once a connection is established.
    """
    global config_data
    
    prev_main_btns = [0] * 9
    # These need to be lists to be mutable and have their state changed by the child function.
    prev_enc_click = [0]
    prev_enc_val = [None]
    prev_ext_btns = [0] * 6
    prev_slider_vals = [None, None]
    prev_knob_vals = [None, None]

    action_executor = ActionExecutor().start()
    telemetry = TelemetrySampler(interval_s=0.5, slow_interval_s=2.0).start()

    _send_boot_message(ser)

    # Slider/knob positions seen before this connection mean nothing now.
    analog_outputs.reset()

    rx_buffer = bytearray()  # Bytes received after the last complete line.
    line_synced = False
    stats_interval_s = 0.5
    next_stats_time = time.monotonic()
    consecutive_errors = 0

    try:
        while True:  # This loop will run as long as the device is connected
            try:
                if config_updated_event.is_set():
                    log.info("Reloading configuration in device loop...")
                    config_data = load_config()
                    config_updated_event.clear()

                now = time.monotonic()
                # Short timeout so we never block long: key presses are read within ~20ms
                timeout = max(0.0, min(0.02, next_stats_time - now))
                ser.timeout = timeout

                # Read whatever has arrived (drains the backlog so we never lag
                # behind the Arduino) and only parse lines whose newline has
                # been received. readline() with a short timeout returns half
                # lines whenever the timeout hits mid-line (timeout is 0 when
                # STATS are due), and a cut value such as "1023" -> "10" made
                # sliders/volume jump and fired phantom button presses.
                chunk = ser.read(ser.in_waiting or 1)
                if chunk:
                    rx_buffer.extend(chunk)
                    *complete_lines, rest = rx_buffer.split(b"\n")
                    rx_buffer = bytearray(rest)
                    if complete_lines and not line_synced:
                        # The first line after connecting may have started
                        # before we did: its head is missing, skip it.
                        complete_lines = complete_lines[1:]
                        line_synced = True
                    if len(rx_buffer) > 4096:
                        rx_buffer.clear()  # No newline in sight: garbage, drop it.
                    for raw_line in complete_lines:
                        line = raw_line.decode("utf-8", errors="ignore").strip()
                        if not line:
                            continue
                        process_serial_line(
                            line,
                            prev_main_btns,
                            prev_enc_click,
                            prev_enc_val,
                            prev_ext_btns,
                            prev_slider_vals,
                            prev_knob_vals,
                            action_executor,
                        )

                now = time.monotonic()
                if now >= next_stats_time:
                    snap = telemetry.get_snapshot()
                    cpu = snap["cpu"]
                    gpu = snap["gpu"]
                    ram = snap["ram"]
                    cpu_freq_mhz = snap["cpu_freq_mhz"]
                    gpu_temp_c = snap["gpu_temp_c"]

                    now_dt = datetime.now()
                    lang = config_data.get('language', 'en') if isinstance(config_data, dict) else 'en'
                    date_fmt = _get_date_format(lang)
                    stats_msg = f"STATS:{cpu},{gpu},{ram},{cpu_freq_mhz},{gpu_temp_c},{now_dt.strftime('%H:%M:%S')},{now_dt.strftime(date_fmt)}\n"
                    ser.write(stats_msg.encode("utf-8"))
                    if ENABLE_TELEMETRY_LOG:
                        gpu_str = f"{gpu}%" if gpu != -1 else "N/A"
                        fq_str = f"{cpu_freq_mhz/1000.0:.1f}GHz" if cpu_freq_mhz > 0 else "N/A"
                        tg_str = f"{gpu_temp_c}C" if gpu_temp_c != -1 else "N/A"
                        log.debug(f"[STATS] CPU:{cpu}% RAM:{ram}% GPU:{gpu_str} | F:{fq_str} G:{tg_str}")

                    # Keep cadence stable even if we fell behind.
                    next_stats_time = now + stats_interval_s

                consecutive_errors = 0

            except (serial.SerialException, OSError) as e:
                log.warning(f"Device disconnected or serial error: {e}")
                return
            except Exception as e:
                consecutive_errors += 1
                if consecutive_errors == 1:
                    log.error(f"An error occurred in device loop: {e}", exc_info=True)
                if consecutive_errors >= 25:
                    # Not a one-off: the port is probably in a bad state (e.g.
                    # after sleep/resume). Reopen it instead of spinning here.
                    log.error(f"Device loop keeps failing ({e}). Reconnecting...")
                    return
                time.sleep(0.2)
    finally:
        telemetry.stop()
        action_executor.stop()
        # Always release the COM port, otherwise the reconnect fails with
        # "Access is denied" on our own stale handle.
        try:
            ser.close()
        except Exception:
            pass


def process_serial_line(line, prev_main_btns, prev_enc_click, prev_enc_val, prev_ext_btns, prev_slider_vals, prev_knob_vals, action_executor):
    """
    Parses a single line of serial data and executes actions.
    This function is extracted to be callable for each line received.
    """
    global config_data

    try:
        mappings_raw = config_data.get('mappings', {}) if isinstance(config_data, dict) else {}
        if not isinstance(mappings_raw, dict):
            mappings_raw = {}

        # Preferred schema:
        # mappings.main -> main deck buttons (btn_1..btn_9)
        # mappings.modules -> ext_btn/slider/knob mappings
        if "main" in mappings_raw or "modules" in mappings_raw:
            main_mappings = mappings_raw.get("main", {}) if isinstance(mappings_raw.get("main", {}), dict) else {}
            module_mappings = mappings_raw.get("modules", {}) if isinstance(mappings_raw.get("modules", {}), dict) else {}
        else:
            # Backward compatibility: old flat mapping object.
            main_mappings = {}
            module_mappings = {}
            for k, v in mappings_raw.items():
                if isinstance(k, str) and k.startswith("btn_"):
                    main_mappings[k] = v
                else:
                    module_mappings[k] = v

        def get_mapping(key_name):
            if isinstance(key_name, str) and key_name.startswith("btn_"):
                return main_mappings.get(key_name)
            return module_mappings.get(key_name)
        parts = line.split(';')
        if len(parts) < 12: 
            return

        current_main_btns = [int(x) for x in parts[0:9]]
        current_enc_click = int(parts[9])
        current_enc_val = int(parts[10])
        module_id = int(parts[11])

        for i in range(9):
            if current_main_btns[i] == 1 and prev_main_btns[i] == 0:
                if ENABLE_EVENT_LOG:
                    log.debug(f"[EVENT] Main Button {i+1} Pressed")
                btn_key = f"btn_{i+1}"
                action_executor.submit(get_mapping(btn_key))
        # Update state for the next line processing
        for i in range(9):
            prev_main_btns[i] = current_main_btns[i]

        # Encoder is fixed-function (not configurable via JSON):
        # - click => toggle mute
        # - rotate CW/CCW => change volume
        if current_enc_click == 1 and prev_enc_click[0] == 0:
            if ENABLE_EVENT_LOG:
                log.debug("[EVENT] Encoder Clicked (Short)")
            execute_action({"action": "toggle_mute", "value": None})
        prev_enc_click[0] = current_enc_click

        if prev_enc_val[0] is not None:
            diff = current_enc_val - prev_enc_val[0]
            if diff != 0:
                multiplier = abs(diff) / 2.0
                if diff > 0:
                    if ENABLE_EVENT_LOG:
                        log.debug(f"[EVENT] Encoder Rotated CW (x{multiplier})")
                    execute_action({"action": "change_volume", "value": 1}, multiplier=multiplier)
                elif diff < 0:
                    if ENABLE_EVENT_LOG:
                        log.debug(f"[EVENT] Encoder Rotated CCW (x{multiplier})")
                    execute_action({"action": "change_volume", "value": -1}, multiplier=multiplier)
        prev_enc_val[0] = current_enc_val

        if module_id == 1: # Buttons
            if len(parts) >= 18:
                current_ext_btns = [int(x) for x in parts[12:18]]
                for i in range(6):
                        if current_ext_btns[i] == 1 and prev_ext_btns[i] == 0:
                            if ENABLE_EVENT_LOG:
                                log.debug(f"[EVENT] Ext Button {i+1} Pressed")
                            btn_key = f"ext_btn_{i+1}"
                            action_executor.submit(get_mapping(btn_key))
                for i in range(6):
                    prev_ext_btns[i] = current_ext_btns[i]
                
        elif module_id == 2 or module_id == 3: # Sliders or Knobs
            if len(parts) >= 14:
                val1 = int(parts[12])
                val2 = int(parts[13])
                
                is_slider = (module_id == 2)
                prefix = "slider" if is_slider else "knob"
                prev_vals = prev_slider_vals if is_slider else prev_knob_vals
                
                def handle_analog(curr, prev, name):
                    abs_mapping = get_mapping(name)
                    if isinstance(abs_mapping, dict) and abs_mapping.get('action') in _REMOVED_ACTIONS:
                        _warn_removed_action(abs_mapping['action'])
                        return curr
                    if isinstance(abs_mapping, dict) and abs_mapping.get('action') in _ANALOG_ACTIONS:
                        # Position-following outputs: only the latest position
                        # matters, so these never go through the action queue.
                        analog_outputs.update(name, abs_mapping['action'], curr, abs_mapping.get('value'))
                        return curr
                    if abs_mapping:
                        if prev is not None and abs(curr - prev) >= ANALOG_ABSOLUTE_DEADBAND:
                            action_executor.submit(abs_mapping, absolute_value=curr)
                            return curr
                        return curr if prev is None else prev

                    if prev is None:
                        return curr
                    diff = curr - prev
                    if abs(diff) > 2:
                        if diff > 0:
                            log.debug(f"[EVENT] {name} Moved UP/CW (Val: {curr})")
                            action_executor.submit(get_mapping(f"{name}_up" if is_slider else f"{name}_cw"))
                        else:
                            log.debug(f"[EVENT] {name} Moved DOWN/CCW (Val: {curr})")
                            action_executor.submit(get_mapping(f"{name}_down" if is_slider else f"{name}_ccw"))
                        return curr
                    return prev

                prev_vals[0] = handle_analog(val1, prev_vals[0], f"{prefix}_1")
                prev_vals[1] = handle_analog(val2, prev_vals[1], f"{prefix}_2")
    
    except (ValueError, IndexError) as e:
        log.warning(f"Could not parse serial line: '{line}'. Error: {e}")

_DATE_FORMATS = {
    'en': '%d/%m',
    'it': '%d/%m',
    'es': '%d/%m',
    'fr': '%d/%m',
    'de': '%d.%m',
    'zh': '%m-%d',
    'ja': '%m/%d',
}

def _get_date_format(lang: str) -> str:
    return _DATE_FORMATS.get(lang, '%d/%m')

def _send_boot_message(ser):
    """Send initial time sync immediately after serial connection is established."""
    try:
        now_dt = datetime.now()
        lang = config_data.get('language', 'en') if isinstance(config_data, dict) else 'en'
        date_fmt = _get_date_format(lang)
        boot_msg = f"BOOT:{now_dt.strftime('%H:%M:%S')},{now_dt.strftime(date_fmt)}\n"
        ser.write(boot_msg.encode("utf-8"))
        if ENABLE_ACTION_LOG:
            log.debug(f"Boot message sent: {boot_msg.strip()}")
    except Exception as e:
        log.warning(f"Could not send boot message: {e}")

def get_cpu_freq_mhz():
    """Best-effort CPU frequency (MHz). Returns -1 if unavailable."""
    try:
        freq = psutil.cpu_freq()
        if freq and freq.current:
            mhz = int(freq.current)
            if mhz > 0:
                return mhz
    except Exception:
        pass
    return -1

if __name__ == "__main__":
    build_kind = "frozen exe" if getattr(sys, "frozen", False) else "running from source"
    log.info(f"Console Deck PRO backend v{APP_VERSION} ({build_kind})")
    log.info(f"Python {sys.version.split()[0]} on {platform.platform()}")
    log.info(f"Config file: {CONFIG_FILE}")
    log.info(f"Log file: {LOG_FILE}")
    if BACKGROUND_MODE:
        log.info("Started in background mode (no console window)")
    try:
        main()
    except KeyboardInterrupt:
        log.info("Program terminated by user.")
    except Exception:
        log.critical("An unhandled exception occurred in main:", exc_info=True)
        _pause_before_exit()
        sys.exit(1)
