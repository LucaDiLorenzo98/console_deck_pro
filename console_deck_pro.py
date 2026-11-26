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
_require("screen-brightness-control", "screen_brightness_control")
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
    import screen_brightness_control as sbc
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
last_volume_target = None
# For slider brightness: store previous raw value so we apply delta, not absolute
_last_brightness_slider_raw = None

@app.post("/reload")
def reload_config_endpoint():
    """
    Called by the UI when the config is saved.
    This simply sets an event to notify the main loop to re-read the config file.
    """
    config_updated_event.set()
    log.info("Configuration reload requested via API")
    return {"message": "Config reload signaled"}

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
    try:
        uvicorn.run(app, host="127.0.0.1", port=8000, log_level="warning")
    except Exception:
        # Keep the serial loop alive: macros still work without the API,
        # but the UI will not be able to connect.
        log.error("API server failed to start. The UI will not be able to connect.", exc_info=True)
        log.error(f"See log at {LOG_FILE}")


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
        with open(CONFIG_FILE, 'r') as f:
            content = f.read()
            if not content.strip():
                log.warning(f"{CONFIG_FILE} is empty. Using default values.")
                return default_config
            return json.loads(content)
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


def execute_action(action_def, absolute_value=None, multiplier=1):
    global last_volume_target, _last_brightness_slider_raw
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
            webbrowser.open(value)
        elif action_type == 'open_app':
            if ENABLE_ACTION_LOG:
                log.debug(f"Opening App: {value}")
            subprocess.Popen(value)
        elif action_type == 'hotkey':
            if ENABLE_ACTION_LOG:
                log.debug(f"Sending Hotkey: {value}")
            if isinstance(value, list):
                pyautogui.hotkey(*value)
            else:
                pyautogui.press(value)
        elif action_type == 'type':
            if ENABLE_ACTION_LOG:
                log.debug(f"Typing: {value}")
            pyautogui.write(value)
        elif action_type == 'brightness':
            # Relative: current + value (encoder/button)
            if ENABLE_ACTION_LOG:
                log.debug(f"Changing Brightness (delta): {value}")
            try:
                current = sbc.get_brightness()
                if isinstance(current, list): current = current[0]
                new_val = min(100, max(0, current + int(value)))
                sbc.set_brightness(new_val)
                if ENABLE_ACTION_LOG:
                    log.debug(f"Brightness: {current} -> {new_val}")
            except Exception as e:
                log.error(f"Brightness control failed: {e}")
        elif action_type == 'set_volume':
            target = max(0, min(100, int(float(value))))
            if last_volume_target is None:
                last_volume_target = target
                return
            delta = target - last_volume_target
            if abs(delta) < ANALOG_ABSOLUTE_DEADBAND:
                return
            key = 'volumeup' if delta > 0 else 'volumedown'
            count = min(30, max(1, int(round(abs(delta) / 2.0))))
            if ENABLE_ACTION_LOG:
                log.debug(f"Set Volume (approx): {key} x {count} (target {target}%)")
            _press_system_volume_key(key, count)
            last_volume_target = target
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
        elif action_type == 'set_brightness':
            # Relative everywhere: from slider use delta of position; from config use value as delta
            try:
                current = sbc.get_brightness()
                if isinstance(current, list): current = current[0]
                if absolute_value is not None:
                    # Slider: apply difference from previous position (raw 0–1023)
                    raw = int(float(absolute_value))
                    if _last_brightness_slider_raw is None:
                        _last_brightness_slider_raw = raw
                        return
                    delta_raw = raw - _last_brightness_slider_raw
                    _last_brightness_slider_raw = raw
                    # Scale slider delta to brightness delta (~0–1023 -> ~0–100)
                    delta_pct = round(delta_raw * 100.0 / 1023.0)
                    new_val = min(100, max(0, current + delta_pct))
                else:
                    # Button/config: value is delta
                    delta_pct = int(value)
                    new_val = min(100, max(0, current + delta_pct))
                sbc.set_brightness(new_val)
                if ENABLE_ACTION_LOG:
                    log.debug(f"Brightness: {current} -> {new_val} (relative)")
            except Exception as e:
                log.error(f"Set Brightness failed: {e}")
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
    if HAS_GPUTIL:
        try:
            gpus = GPUtil.getGPUs()
            if gpus:
                return int(gpus[0].load * 100), int(gpus[0].temperature)
        except Exception:
            pass

    global _nvidia_smi_missing
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

            serial_config = config_data.get('serial', {})
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
                ser = serial.Serial(port, baud_rate, timeout=1)
                time.sleep(2) # Wait for connection to settle
                log.info("Connected to device!")
                connect_fail_logged = False
            except serial.SerialException as e:
                if connect_fail_logged:
                    log.debug(f"Still failing to connect to serial port '{port}': {e}")
                else:
                    log.error(f"Failed to connect to serial port '{port}': {e}")
                    if "PermissionError" in str(e) or "Access is denied" in str(e):
                        log.info("Tip: the port might be in use by another application (e.g. Arduino IDE).")
                    log.info("Will retry every 10 seconds. You can change the port in the UI.")
                    connect_fail_logged = True
                time.sleep(10)
                config_data = load_config() # Reload config before retrying
                continue

            # --- This is the main device loop ---
            run_device_loop(ser)

            # If the loop exits (e.g., device disconnect), inform the user and wait before retrying.
            log.info("Device disconnected. Waiting for reconnection or configuration change...")
            time.sleep(5)

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

    stats_interval_s = 0.5
    next_stats_time = time.monotonic()

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

                raw = ser.readline()
                if raw:
                    text = raw.decode("utf-8", errors="ignore")
                    for line in text.splitlines():
                        line = line.strip()
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
                    # Drain remaining lines so we don't lag behind Arduino
                    while ser.in_waiting:
                        raw = ser.readline()
                        if not raw:
                            break
                        text = raw.decode("utf-8", errors="ignore")
                        for line in text.splitlines():
                            line = line.strip()
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

            except (serial.SerialException, OSError) as e:
                log.warning(f"Device disconnected or serial error: {e}")
                try:
                    ser.close()
                except Exception:
                    pass
                return
            except Exception as e:
                log.error(f"An error occurred in device loop: {e}", exc_info=True)
                time.sleep(0.2)
    finally:
        telemetry.stop()
        action_executor.stop()


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
                    if abs_mapping:
                        if curr != prev:
                            action_executor.submit(abs_mapping, absolute_value=curr)
                        return curr

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
