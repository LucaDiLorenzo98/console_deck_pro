import serial
import time
import json
import webbrowser
import subprocess
import pyautogui
import screen_brightness_control as sbc
import os
import sys
import psutil
from fastapi import FastAPI
from threading import Thread, Event
import uvicorn
from serial.tools import list_ports

# GPU Utils (Optional)
try:
    import GPUtil
    HAS_GPUTIL = True
except ImportError:
    HAS_GPUTIL = False

# Debug Configuration
ENABLE_TELEMETRY_LOG = False
ENABLE_ACTION_LOG = False
ENABLE_EVENT_LOG = False

# Configuration
APP_NAME = "ConsoleDeckPro"


def get_app_dir():
    app_data = os.getenv('APPDATA')
    if app_data:
        return os.path.join(app_data, APP_NAME)
    # Linux/macOS fallback (useful for local development and CI)
    return os.path.join(os.path.expanduser("~"), f".{APP_NAME.lower()}")


APP_DIR = get_app_dir()
CONFIG_FILE = os.path.join(APP_DIR, 'config.json')
TELEMETRY_INTERVAL_SECONDS = 0.5
HEAVY_SENSOR_INTERVAL_SECONDS = 2.0
ANALOG_ABSOLUTE_DEADBAND = 2

# Ensure the app directory exists
os.makedirs(APP_DIR, exist_ok=True)

app = FastAPI()
config_data = None
config_updated_event = Event() # Used to signal the main thread to reload the config
last_volume_target = None
last_brightness_target = None

@app.post("/reload")
def reload_config_endpoint():
    """
    Called by the UI when the config is saved.
    This simply sets an event to notify the main loop to re-read the config file.
    """
    config_updated_event.set()
    print("Configuration reload requested via API")
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
    uvicorn.run(app, host="127.0.0.1", port=8000, log_level="warning")

def load_config():
    if not os.path.exists(CONFIG_FILE):
        print(f"Info: {CONFIG_FILE} not found. Creating a new one with default values.")
        default_config = {
            "serial": {
                "port": None,
                "baud_rate": 115200
            },
            "mappings": {}
        }
        try:
            with open(CONFIG_FILE, 'w') as f:
                json.dump(default_config, f, indent=4)
            return default_config
        except Exception as e:
            print(f"Error: Could not create default config file: {e}")
            return None

    try:
        with open(CONFIG_FILE, 'r') as f:
            content = f.read()
            if not content.strip():
                print(f"Warning: {CONFIG_FILE} is empty. Using default values.")
                return {"serial": {"port": None, "baud_rate": 115200}, "mappings": {}}
            parsed = json.loads(content)
            if not isinstance(parsed, dict):
                return {"serial": {"port": None, "baud_rate": 115200}, "mappings": {}}

            serial_cfg = parsed.get("serial", {})
            if not isinstance(serial_cfg, dict):
                serial_cfg = {}
            serial_cfg.setdefault("port", None)
            serial_cfg.setdefault("baud_rate", 115200)
            parsed["serial"] = serial_cfg

            mappings = parsed.get("mappings", {})
            if not isinstance(mappings, dict):
                mappings = {}
            parsed["mappings"] = mappings
            return parsed
    except (json.JSONDecodeError, OSError, ValueError) as e:
        print(f"Error parsing {CONFIG_FILE}: {e}")
        return None

def ensure_config_loaded():
    global config_data
    if not isinstance(config_data, dict):
        config_data = load_config()
    if not isinstance(config_data, dict):
        config_data = {"serial": {"port": None, "baud_rate": 115200}, "mappings": {}}
    return config_data


def reload_config_if_requested():
    global config_data
    if not config_updated_event.is_set():
        return

    print("\n[INFO] Reloading configuration in device loop...")
    reloaded = load_config()
    if isinstance(reloaded, dict):
        config_data = reloaded
    else:
        print("[WARNING] New config is invalid, keeping previous configuration.")
    config_updated_event.clear()


def execute_action(action_def=None, mapping_key=None, absolute_value=None, multiplier=1):
    global last_volume_target, last_brightness_target
    config = ensure_config_loaded()
    mappings = config.get('mappings', {})

    if mapping_key:
        action_def = mappings.get(mapping_key)

    if not isinstance(action_def, dict):
        return

    action_type = action_def.get('action')
    value = action_def.get('value')

    if not action_type:
        return

    if absolute_value is not None:
        value = absolute_value

    if ENABLE_ACTION_LOG:
        print(f"  -> [ACTION] {action_type}: {value}")

    try:
        if action_type == 'open_url':
            if ENABLE_ACTION_LOG:
                print(f"     Opening URL: {value}")
            webbrowser.open(value)
        elif action_type == 'open_app':
            if ENABLE_ACTION_LOG:
                print(f"     Opening App: {value}")
            subprocess.Popen(value)
        elif action_type == 'hotkey':
            if ENABLE_ACTION_LOG:
                print(f"     Sending Hotkey: {value}")
            if isinstance(value, list):
                pyautogui.hotkey(*value)
            else:
                pyautogui.press(value)
        elif action_type == 'type':
            if ENABLE_ACTION_LOG:
                print(f"     Typing: {value}")
            pyautogui.write(value)
        elif action_type == 'brightness':
            if ENABLE_ACTION_LOG:
                print(f"     Changing Brightness: {value}")
            try:
                current = sbc.get_brightness()
                if isinstance(current, list): current = current[0]
                new_val = min(100, max(0, current + int(value)))
                sbc.set_brightness(new_val)
                if ENABLE_ACTION_LOG:
                    print(f"     Brightness: {current} -> {new_val}")
            except Exception as e:
                print(f"     [ERROR] Brightness control failed: {e}")
        elif action_type == 'set_volume':
            # Approximate absolute volume by tracking previous target and
            # sending the required up/down key presses.
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
                print(f"     Set Volume (approx): {key} x {count} (target {target}%)")
            for _ in range(count):
                pyautogui.press(key)
            last_volume_target = target
            
        elif action_type == 'toggle_mute':
            pyautogui.press('volumemute')
            if ENABLE_ACTION_LOG:
                print("     Toggled Mute")

        elif action_type == 'change_volume':
             # Simplified key-based control
             # multiplier coming from encoder diff / 2.0
             # We round it to nearest int to get number of key presses
             
             key = 'volumeup' if float(value) > 0 else 'volumedown'
             count = int(round(abs(float(value)) * multiplier))
             if count < 1:
                 count = 1
             if count > 20:
                 count = 20
             
             if ENABLE_ACTION_LOG:
                 print(f"     Change Volume: {key} x {count}")
             for _ in range(count):
                 pyautogui.press(key)
        elif action_type == 'set_brightness':
            try:
                target = max(0, min(100, int(float(value))))
                if last_brightness_target is not None and abs(target - last_brightness_target) < ANALOG_ABSOLUTE_DEADBAND:
                    return
                sbc.set_brightness(target)
                last_brightness_target = target
                if ENABLE_ACTION_LOG:
                    print(f"     Set Brightness: {target}%")
            except Exception as e:
                print(f"     [ERROR] Set Brightness failed: {e}")
        else:
            print(f"     [WARNING] Unknown action type: {action_type}")
    except Exception as e:
        print(f"     [ERROR] Failed to execute action: {e}")

def main():
    global config_data
    server_thread = Thread(target=run_server)
    server_thread.daemon = True
    server_thread.start()
    
    # Load the initial configuration
    config_data = load_config()
    if not config_data:
        print("Error: Could not load or create a configuration file. Exiting.")
        return

    # --- Main Loop ---
    while True:
        try:
            reload_config_if_requested()
            ensure_config_loaded()

            serial_config = config_data.get('serial', {})
            port = serial_config.get('port')
            baud_rate = serial_config.get('baud_rate', 9600)

            # STATE 1: Port is not configured. Wait for the signal or a timeout.
            if not port:
                print("\r[INFO] Serial port not configured. Waiting for selection in the UI...", end="", flush=True)
                # Wait for the reload signal, with a 2-second timeout to keep the loop spinning
                config_updated_event.wait(timeout=2)
                continue

            # STATE 2: Port is configured. Attempt connection and run device logic.
            print(f"\n[INFO] Port configured. Attempting to connect to {port} at {baud_rate}...")
            try:
                ser = serial.Serial(port, baud_rate, timeout=1)
                time.sleep(2) # Wait for connection to settle
                print("[SUCCESS] Connected to device!")
            except serial.SerialException as e:
                print(f"[ERROR] Failed to connect to serial port '{port}': {e}")
                if "PermissionError" in str(e) or "Access is denied" in str(e):
                    print("[TIP] The port might be in use by another application.")
                print("[INFO] Will retry in 10 seconds. You can change the port in the UI.")
                time.sleep(10)
                config_data = load_config() # Reload config before retrying
                continue

            # --- This is the main device loop ---
            run_device_loop(ser)
            
            # If the loop exits (e.g., device disconnect), inform the user and wait before retrying.
            print("\n[INFO] Device disconnected. Waiting for reconnection or configuration change...")
            time.sleep(5)
            
        except KeyboardInterrupt:
            print("\nExiting...")
            break
        except Exception as e:
            print(f"\n[FATAL] An unexpected error occurred in the main loop: {e}")
            print("[INFO] Restarting main loop in 10 seconds...")
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
    
    last_stats_time = 0.0
    last_heavy_stats_time = 0.0
    cached_gpu = -1
    cached_temp_gpu = -1
    cached_temp_cpu = -1
    last_net_recv, last_net_sent = get_net_bytes()
    serial_buffer = ""

    while True: # This loop will run as long as the device is connected
        try:
            reload_config_if_requested()
            ensure_config_loaded()

            current_time = time.time()
            
            # --- SEND STATS TO ARDUINO ---
            if current_time - last_stats_time > TELEMETRY_INTERVAL_SECONDS:
                # 1. CPU
                cpu = int(psutil.cpu_percent())
                
                # Heavy stats are sampled less frequently to avoid stutters.
                if current_time - last_heavy_stats_time > HEAVY_SENSOR_INTERVAL_SECONDS:
                    cached_gpu, cached_temp_gpu = get_gpu_stats()
                    cached_temp_cpu = get_cpu_temp()
                    last_heavy_stats_time = current_time

                # 3. RAM
                ram = int(psutil.virtual_memory().percent)
                
                # 4. CPU TEMP
                temp_cpu = cached_temp_cpu
                if temp_cpu <= 0: temp_cpu = -1 # Final sanity check
                gpu = cached_gpu
                temp_gpu = cached_temp_gpu

                # 5. NETWORK
                down_speed = 0.0
                up_speed = 0.0
                curr_recv, curr_sent = get_net_bytes()
                
                time_diff = current_time - last_stats_time
                if time_diff < 0.1: time_diff = 0.5
                
                if last_stats_time != 0 and last_net_recv > 0:
                        delta_recv = max(0, curr_recv - last_net_recv)
                        delta_sent = max(0, curr_sent - last_net_sent)
                        
                        # Mbps
                        down_speed = (delta_recv * 8) / 1000000.0 / time_diff
                        up_speed = (delta_sent * 8) / 1000000.0 / time_diff
                
                last_net_recv = curr_recv
                last_net_sent = curr_sent
                last_stats_time = current_time
                
                # Format
                stats_msg = f"STATS:{cpu},{gpu},{ram},{temp_cpu},{temp_gpu},{down_speed:.1f},{up_speed:.1f}\n"
                ser.write(stats_msg.encode('utf-8'))
                if ENABLE_TELEMETRY_LOG:
                    gpu_str = f"{gpu}%" if gpu != -1 else "N/A"
                    tq_str = f"{temp_cpu}C" if temp_cpu != -1 else "N/A"
                    tg_str = f"{temp_gpu}C" if temp_gpu != -1 else "N/A"
                    print(f"\r[STATS] CPU:{cpu}% Temp:{tq_str} | GPU:{gpu_str} Temp:{tg_str} | RAM:{ram}% | Net:D{down_speed:.1f}Mb/U{up_speed:.1f}Mb", end="")

            # Read all waiting data and process each line.
            if ser.in_waiting > 0:
                data = ser.read(ser.in_waiting).decode('utf-8', errors='ignore')
                serial_buffer += data
                lines = serial_buffer.split('\n')
                serial_buffer = lines.pop()

                if lines:
                    print() # Newline to separate stats from events
                for line in lines:
                    line = line.strip()
                    if not line:
                        continue
                    
                    # Process the most recent complete line
                    process_serial_line(line, prev_main_btns, prev_enc_click, prev_enc_val, prev_ext_btns, prev_slider_vals, prev_knob_vals)
            
            time.sleep(0.001)

        except (serial.SerialException, OSError) as e:
            print(f"\n[ERROR] Device disconnected or serial error: {e}")
            ser.close()
            return # Exit this function to allow main() to try reconnecting
        except Exception as e:
            print(f"\n[ERROR] An error occurred in device loop: {e}")
            time.sleep(1)


def process_serial_line(line, prev_main_btns, prev_enc_click, prev_enc_val, prev_ext_btns, prev_slider_vals, prev_knob_vals):
    """
    Parses a single line of serial data and executes actions.
    This function is extracted to be callable for each line received.
    """
    global config_data

    try:
        mappings = config_data.get('mappings', {}) if isinstance(config_data, dict) else {}
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
                    print(f"[EVENT] Main Button {i+1} Pressed")
                btn_key = f"btn_{i+1}"
                execute_action(mapping_key=btn_key)
        # Update state for the next line processing
        for i in range(9):
            prev_main_btns[i] = current_main_btns[i]

        # Encoder Button Logic (Short vs Long Press) is stateful and complex,
        # for now, we assume the user doesn't press and rotate between serial messages.
        # This part might need more robust state management if issues arise.
        if current_enc_click == 1 and prev_enc_click[0] == 0:
            if ENABLE_EVENT_LOG:
                print(f"[EVENT] Encoder Clicked (Short)")
            execute_action(mapping_key='enc_click')
        prev_enc_click[0] = current_enc_click


        if prev_enc_val[0] is not None:
            diff = current_enc_val - prev_enc_val[0]
            if diff != 0: # Process only if there is a change
                multiplier = abs(diff) / 2.0
                
                if diff > 0:
                    if ENABLE_EVENT_LOG:
                        print(f"[EVENT] Encoder Rotated CW (x{multiplier})")
                    execute_action(mapping_key='enc_cw', multiplier=multiplier)
                elif diff < 0:
                    if ENABLE_EVENT_LOG:
                        print(f"[EVENT] Encoder Rotated CCW (x{multiplier})")
                    execute_action(mapping_key='enc_ccw', multiplier=multiplier)
        prev_enc_val[0] = current_enc_val

        if module_id == 1: # Buttons
            if len(parts) >= 18:
                current_ext_btns = [int(x) for x in parts[12:18]]
                for i in range(6):
                        if current_ext_btns[i] == 1 and prev_ext_btns[i] == 0:
                            if ENABLE_EVENT_LOG:
                                print(f"[EVENT] Ext Button {i+1} Pressed")
                            btn_key = f"ext_btn_{i+1}"
                            execute_action(mapping_key=btn_key)
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
                    abs_mapping = mappings.get(name)
                    if abs_mapping:
                        if prev is None or abs(curr - prev) >= ANALOG_ABSOLUTE_DEADBAND:
                            execute_action(abs_mapping, absolute_value=curr)
                        return curr

                    if prev is None:
                        return curr
                    diff = curr - prev
                    if abs(diff) > 2:
                        if diff > 0:
                            if ENABLE_EVENT_LOG:
                                print(f"[EVENT] {name} Moved UP/CW (Val: {curr})")
                            execute_action(mapping_key=f"{name}_up" if is_slider else f"{name}_cw")
                        else:
                            if ENABLE_EVENT_LOG:
                                print(f"[EVENT] {name} Moved DOWN/CCW (Val: {curr})")
                            execute_action(mapping_key=f"{name}_down" if is_slider else f"{name}_ccw")
                        return curr
                    return prev

                prev_vals[0] = handle_analog(val1, prev_vals[0], f"{prefix}_1")
                prev_vals[1] = handle_analog(val2, prev_vals[1], f"{prefix}_2")
    
    except (ValueError, IndexError) as e:
        print(f"\n[WARNING] Could not parse serial line: '{line}'. Error: {e}")

# State for Encoder Long Press
# --- HELPER FUNCTIONS ---
def get_net_bytes():
    try:
        counters = psutil.net_io_counters(pernic=True)
        rx = 0
        tx = 0
        for nic, c in counters.items():
            rx += c.bytes_recv
            tx += c.bytes_sent
        return rx, tx
    except:
        return 0, 0

def get_gpu_stats():
    gpu = -1
    temp_gpu = -1

    if HAS_GPUTIL:
        try:
            gpus = GPUtil.getGPUs()
            if gpus:
                return int(gpus[0].load * 100), int(gpus[0].temperature)
        except Exception:
            pass

    try:
        output = subprocess.check_output(
            [
                "nvidia-smi",
                "--query-gpu=utilization.gpu,temperature.gpu",
                "--format=csv,noheader,nounits",
            ],
            stderr=subprocess.DEVNULL,
            timeout=1,
        ).decode("utf-8").strip()
        parts_gpu = output.split(',')
        if len(parts_gpu) >= 2:
            gpu = int(parts_gpu[0].strip())
            temp_gpu = int(parts_gpu[1].strip())
    except Exception:
        pass

    return gpu, temp_gpu


def get_cpu_temp():
    # Try psutil
    t = -1
    try:
        temps = psutil.sensors_temperatures()
        if temps:
            for name, entries in temps.items():
                if 'cpu' in name.lower() or 'core' in name.lower() or 'package' in name.lower():
                    val = int(entries[0].current)
                    if val > 0: 
                        t = val
                        break
    except:
        pass
    
    # If invalid on Windows, try WMI.
    if t <= 0 and os.name == "nt":
        try:
            ps_cmd = "Get-WmiObject MSAcpi_ThermalZoneTemperature -Namespace \"root/wmi\" | Select -ExpandProperty CurrentTemperature"
            creation_flags = getattr(subprocess, "CREATE_NO_WINDOW", 0)
            out = subprocess.check_output(
                ["powershell", "-c", ps_cmd],
                creationflags=creation_flags,
            ).decode().strip()
            if out and out.isdigit():
                kelvin_x10 = int(out)
                cels = (kelvin_x10 / 10.0) - 273.15
                t = int(cels)
        except:
            pass
    return t

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n[INFO] Program terminated by user.")
    except Exception as e:
        print(f"\n[FATAL] An unhandled exception occurred in main: {e}")
        
    if os.name == "nt" and sys.stdin.isatty():
        input("\n[INFO] Press Enter to close this window...")
