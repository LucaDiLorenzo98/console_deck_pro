import serial
import time
import json
import webbrowser
import subprocess
import pyautogui
import screen_brightness_control as sbc
import os
import sys
import threading
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
ENABLE_TELEMETRY_LOG = True

# Configuration
APP_NAME = "ConsoleDeckPro"
APP_DIR = os.path.join(os.getenv('APPDATA'), APP_NAME)
CONFIG_FILE = os.path.join(APP_DIR, 'config.json')

# Ensure the app directory exists
os.makedirs(APP_DIR, exist_ok=True)

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
    print("Configuration reload requested via API")
    return {"message": "Config reload signaled"}

@app.get("/serial/ports")
def get_serial_ports():
    ports = list_ports.comports()
    return [{"device": port.device, "description": port.description} for port in ports]

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
                return {"serial": {"port": None}, "mappings": {}}
            return json.loads(content)
    except json.JSONDecodeError as e:
        print(f"Error parsing {CONFIG_FILE}: {e}")
        return None

def execute_action(action_def, absolute_value=None, multiplier=1):
    global config_data
    if not config_data:
        config_data = load_config()

    if not action_def:
        return

    # Use the latest config for mappings
    mappings = config_data.get('mappings', {})
    
    # The action_def key (e.g., 'btn_1') is needed to look up the fresh definition
    action_key = None
    for key, value in mappings.items():
        if value == action_def:
            action_key = key
            break
            
    if action_key:
        action_def = mappings.get(action_key, action_def)


    action_type = action_def.get('action')
    value = action_def.get('value')
    
    if absolute_value is not None:
        value = absolute_value

    print(f"  -> [ACTION] {action_type}: {value}")

    try:
        if action_type == 'open_url':
            print(f"     Opening URL: {value}")
            webbrowser.open(value)
        elif action_type == 'open_app':
            print(f"     Opening App: {value}")
            subprocess.Popen(value)
        elif action_type == 'hotkey':
            print(f"     Sending Hotkey: {value}")
            if isinstance(value, list):
                pyautogui.hotkey(*value)
            else:
                pyautogui.press(value)
        elif action_type == 'type':
            print(f"     Typing: {value}")
            pyautogui.write(value)
        elif action_type == 'brightness':
            print(f"     Changing Brightness: {value}")
            try:
                current = sbc.get_brightness()
                if isinstance(current, list): current = current[0]
                new_val = min(100, max(0, current + int(value)))
                sbc.set_brightness(new_val)
                print(f"     Brightness: {current} -> {new_val}")
            except Exception as e:
                print(f"     [ERROR] Brightness control failed: {e}")
        elif action_type == 'set_volume':
            # Absolute volume not easily supported via keys
            print("     [WARNING] 'set_volume' (absolute) is not supported without pycaw. Using rough approximation or ignored.")
            
        elif action_type == 'toggle_mute':
            pyautogui.press('volumemute')
            print("     Toggled Mute")

        elif action_type == 'change_volume':
             # Simplified key-based control
             # multiplier coming from encoder diff / 2.0
             # We round it to nearest int to get number of key presses
             
             key = 'volumeup' if float(value) > 0 else 'volumedown'
             count = int(round(abs(float(value)) * multiplier))
             if count < 1: count = 1
             
             print(f"     Change Volume: {key} x {count}")
             for _ in range(count):
                 pyautogui.press(key)
        elif action_type == 'set_brightness':
            try:
                sbc.set_brightness(int(value))
                print(f"     Set Brightness: {value}%")
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
            # CHECK FOR CONFIGURATION UPDATES (THE FIX)
            # This is the most important part of the fix.
            # We check if the UI has signaled a reload on every loop.
            if config_updated_event.is_set():
                print("\n[INFO] Reloading configuration in device loop...")
                config_data = load_config()
                config_updated_event.clear() # Reset the signal

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
    
    last_stats_time = 0
    last_net_recv, last_net_sent = get_net_bytes()

    while True: # This loop will run as long as the device is connected
        try:
            # CHECK FOR CONFIGURATION UPDATES (THE FIX)
            # This is the most important part of the fix.
            # We check if the UI has signaled a reload on every loop.
            if config_updated_event.is_set():
                print("\n[INFO] Reloading configuration in device loop...")
                config_data = load_config()
                config_updated_event.clear() # Reset the signal

            current_time = time.time()
            
            # --- SEND STATS TO ARDUINO (Every 0.5 seconds) ---
            if current_time - last_stats_time > 0.5:
                # 1. CPU
                cpu = int(psutil.cpu_percent())
                
                # 2. GPU
                gpu = -1
                temp_gpu = -1
                
                # GPUtil
                if HAS_GPUTIL:
                    try:
                        gpus = GPUtil.getGPUs()
                        if gpus:
                            gpu = int(gpus[0].load * 100)
                            temp_gpu = int(gpus[0].temperature)
                    except: pass
                
                # Nvidia-SMI Fallback
                if gpu == -1:
                    try:
                            cmd = "nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv,noheader,nounits"
                            output = subprocess.check_output(cmd, shell=True).decode('utf-8').strip()
                            parts_gpu = output.split(',')
                            if len(parts_gpu) >= 2:
                                gpu = int(parts_gpu[0].strip())
                                temp_gpu = int(parts_gpu[1].strip())
                    except: pass

                # 3. RAM
                ram = int(psutil.virtual_memory().percent)
                
                # 4. CPU TEMP
                temp_cpu = get_cpu_temp()
                if temp_cpu <= 0: temp_cpu = -1 # Final sanity check

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
                print() # Newline to separate stats from events
                data = ser.read(ser.in_waiting).decode('utf-8', errors='ignore')
                lines = data.strip().split('\n')

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
        parts = line.split(';')
        if len(parts) < 12: 
            return

        current_main_btns = [int(x) for x in parts[0:9]]
        current_enc_click = int(parts[9])
        current_enc_val = int(parts[10])
        module_id = int(parts[11])
        
        for i in range(9):
            if current_main_btns[i] == 1 and prev_main_btns[i] == 0:
                print(f"[EVENT] Main Button {i+1} Pressed")
                btn_key = f"btn_{i+1}"
                execute_action(config_data['mappings'].get(btn_key))
        # Update state for the next line processing
        for i in range(9):
            prev_main_btns[i] = current_main_btns[i]

        # Encoder Button Logic (Short vs Long Press) is stateful and complex,
        # for now, we assume the user doesn't press and rotate between serial messages.
        # This part might need more robust state management if issues arise.
        if current_enc_click == 1 and prev_enc_click[0] == 0:
            print(f"[EVENT] Encoder Clicked (Short)")
            execute_action(config_data['mappings'].get('enc_click'))
        prev_enc_click[0] = current_enc_click


        if prev_enc_val[0] is not None:
            diff = current_enc_val - prev_enc_val[0]
            if diff != 0: # Process only if there is a change
                multiplier = abs(diff) / 2.0
                
                if diff > 0:
                    print(f"[EVENT] Encoder Rotated CW (x{multiplier})")
                    execute_action(config_data['mappings'].get('enc_cw'), multiplier=multiplier)
                elif diff < 0:
                    print(f"[EVENT] Encoder Rotated CCW (x{multiplier})")
                    execute_action(config_data['mappings'].get('enc_ccw'), multiplier=multiplier)
        prev_enc_val[0] = current_enc_val

        if module_id == 1: # Buttons
            if len(parts) >= 18:
                current_ext_btns = [int(x) for x in parts[12:18]]
                for i in range(6):
                        if current_ext_btns[i] == 1 and prev_ext_btns[i] == 0:
                            print(f"[EVENT] Ext Button {i+1} Pressed")
                            btn_key = f"ext_btn_{i+1}"
                            execute_action(config_data['mappings'].get(btn_key))
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
                    abs_mapping = config_data['mappings'].get(name)
                    if abs_mapping:
                        if curr != prev:
                            execute_action(abs_mapping, absolute_value=curr)
                        return curr

                    if prev is None: return curr
                    diff = curr - prev
                    if abs(diff) > 2:
                        if diff > 0:
                            print(f"[EVENT] {name} Moved UP/CW (Val: {curr})")
                            execute_action(config_data['mappings'].get(f"{name}_up" if is_slider else f"{name}_cw"))
                        else:
                            print(f"[EVENT] {name} Moved DOWN/CCW (Val: {curr})")
                            execute_action(config_data['mappings'].get(f"{name}_down" if is_slider else f"{name}_ccw"))
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
    
    # If invalid, Try WMI
    if t <= 0:
        try:
            ps_cmd = "Get-WmiObject MSAcpi_ThermalZoneTemperature -Namespace \"root/wmi\" | Select -ExpandProperty CurrentTemperature"
            out = subprocess.check_output(["powershell", "-c", ps_cmd], creationflags=subprocess.CREATE_NO_WINDOW).decode().strip()
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
        
    input("\n[INFO] Press Enter to close this window...")
