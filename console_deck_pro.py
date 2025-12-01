import serial
import time
import json
import webbrowser
import subprocess
import pyautogui
import screen_brightness_control as sbc
from ctypes import cast, POINTER
from comtypes import CLSCTX_ALL, CoInitialize
from pycaw.pycaw import AudioUtilities, IAudioEndpointVolume
import os
import sys

# Configuration
CONFIG_FILE = 'config.json'

# Global Audio Interface
volume_interface = None

def init_audio():
    global volume_interface
    try:
        # CoInitialize is needed for some environments, though often optional in main thread
        CoInitialize()
        devices = AudioUtilities.GetSpeakers()
        # Debug: Print available methods to troubleshoot 'Activate' missing
        # print(f"[DEBUG] AudioDevice methods: {dir(devices)}")
        
        # Pycaw 2025+ might have changed API or it's a specific Windows issue
        # Try accessing the interface directly if Activate fails
        if hasattr(devices, 'Activate'):
            interface = devices.Activate(
                IAudioEndpointVolume._iid_, CLSCTX_ALL, None)
        else:
            # Fallback for some versions/systems
            from comtypes import GUID
            CLSID_MMDeviceEnumerator = GUID('{BCDE0395-E52F-467C-8E3D-C4579291692E}')
            IID_IMMDeviceEnumerator = GUID('{A95664D2-9614-4F35-A746-DE8DB63617E6}')
            
            # This is a deeper fallback if the high-level wrapper fails
            # But for now, let's just try to catch it gracefully
            print("[ERROR] AudioDevice missing 'Activate'. Absolute volume disabled.")
            return

        volume_interface = cast(interface, POINTER(IAudioEndpointVolume))
        print("[INFO] Audio Interface Initialized Successfully")
    except Exception as e:
        print(f"[ERROR] Failed to init audio: {e}")

def load_config():
    if not os.path.exists(CONFIG_FILE):
        print(f"Error: {CONFIG_FILE} not found.")
        return None
    try:
        with open(CONFIG_FILE, 'r') as f:
            return json.load(f)
    except json.JSONDecodeError as e:
        print(f"Error parsing {CONFIG_FILE}: {e}")
        return None

def execute_action(action_def, absolute_value=None):
    if not action_def:
        return

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
            if volume_interface:
                vol_scalar = max(0.0, min(1.0, float(value) / 100.0))
                volume_interface.SetMasterVolumeLevelScalar(vol_scalar, None)
                print(f"     Set Volume: {int(vol_scalar*100)}%")
            else:
                print("     [ERROR] Volume Interface not initialized.")
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
    init_audio()
    config = load_config()
    if not config:
        return

    serial_config = config.get('serial', {})
    port = serial_config.get('port', 'COM3')
    baud_rate = serial_config.get('baud_rate', 9600)

    print(f"Connecting to {port} at {baud_rate}...")

    try:
        ser = serial.Serial(port, baud_rate, timeout=1)
        time.sleep(2) # Wait for connection to settle
        print("Connected!")
    except serial.SerialException as e:
        print(f"Failed to connect to serial port: {e}")
        if "PermissionError" in str(e) or "Access is denied" in str(e):
            print("\n[TIP] The port might be in use by another application.")
        return

    prev_main_btns = [0] * 9
    prev_enc_click = 0
    prev_enc_val = None
    prev_ext_btns = [0] * 6
    prev_slider_vals = [None, None]
    prev_knob_vals = [None, None]

    try:
        while True:
            # Read all waiting data and take only the last line (Real-time, no buffer lag)
            if ser.in_waiting > 0:
                try:
                    data = ser.read(ser.in_waiting).decode('utf-8', errors='ignore')
                    lines = data.strip().split('\n')
                    if not lines:
                        continue
                    line = lines[-1].strip() # Take the most recent complete line
                except Exception:
                    continue
                
                if not line:
                    continue
                
                parts = line.split(';')
                # Fix: Check for 12 parts because we access index 11
                if len(parts) < 12: 
                    continue

                try:
                    current_main_btns = [int(x) for x in parts[0:9]]
                    current_enc_click = int(parts[9])
                    current_enc_val = int(parts[10])
                    module_id = int(parts[11])
                    
                    for i in range(9):
                        # Keep edge detection for buttons to avoid spamming actions
                        if current_main_btns[i] == 1 and prev_main_btns[i] == 0:
                            print(f"[EVENT] Main Button {i+1} Pressed")
                            btn_key = f"btn_{i+1}"
                            execute_action(config['mappings'].get(btn_key))
                    prev_main_btns = current_main_btns

                    if current_enc_click == 1 and prev_enc_click == 0:
                        print(f"[EVENT] Encoder Clicked")
                        execute_action(config['mappings'].get('enc_click'))
                    prev_enc_click = current_enc_click

                    if prev_enc_val is not None:
                        diff = current_enc_val - prev_enc_val
                        if diff > 0:
                            print(f"[EVENT] Encoder Rotated CW")
                            execute_action(config['mappings'].get('enc_cw'))
                        elif diff < 0:
                            print(f"[EVENT] Encoder Rotated CCW")
                            execute_action(config['mappings'].get('enc_ccw'))
                    prev_enc_val = current_enc_val

                    if module_id == 1: # Buttons
                        if len(parts) >= 18:
                            current_ext_btns = [int(x) for x in parts[12:18]]
                            for i in range(6):
                                if current_ext_btns[i] == 1 and prev_ext_btns[i] == 0:
                                    print(f"[EVENT] Ext Button {i+1} Pressed")
                                    btn_key = f"ext_btn_{i+1}"
                                    execute_action(config['mappings'].get(btn_key))
                            prev_ext_btns = current_ext_btns
                            
                    elif module_id == 2 or module_id == 3: # Sliders or Knobs
                        if len(parts) >= 14:
                            val1 = int(parts[12])
                            val2 = int(parts[13])
                            
                            is_slider = (module_id == 2)
                            prefix = "slider" if is_slider else "knob"
                            prev_vals = prev_slider_vals if is_slider else prev_knob_vals
                            
                            def handle_analog(curr, prev, name):
                                abs_mapping = config['mappings'].get(name)
                                if abs_mapping:
                                    # Absolute Control: Update immediately (Real-time)
                                    # Only update if value actually changed to avoid API spam
                                    if curr != prev:
                                        execute_action(abs_mapping, absolute_value=curr)
                                    return curr

                                if prev is None: return curr
                                diff = curr - prev
                                if abs(diff) > 2:
                                    if diff > 0:
                                        print(f"[EVENT] {name} Moved UP/CW (Val: {curr})")
                                        execute_action(config['mappings'].get(f"{name}_up" if is_slider else f"{name}_cw"))
                                    else:
                                        print(f"[EVENT] {name} Moved DOWN/CCW (Val: {curr})")
                                        execute_action(config['mappings'].get(f"{name}_down" if is_slider else f"{name}_ccw"))
                                    return curr
                                return prev

                            prev_vals[0] = handle_analog(val1, prev_vals[0], f"{prefix}_1")
                            prev_vals[1] = handle_analog(val2, prev_vals[1], f"{prefix}_2")

                except ValueError:
                    pass 

            time.sleep(0.001)

    except KeyboardInterrupt:
        print("Exiting...")
        ser.close()

if __name__ == "__main__":
    main()
