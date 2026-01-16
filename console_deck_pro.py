import serial
import time
import json
import webbrowser
import subprocess
import pyautogui
import screen_brightness_control as sbc
import os
import sys

# Configuration
CONFIG_FILE = 'config.json'

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

def execute_action(action_def, absolute_value=None, multiplier=1):
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
    # init_audio() removed
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
    
    # State for Encoder Long Press
    enc_press_start_time = None
    enc_long_press_triggered = False

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

                    # Encoder Button Logic (Short vs Long Press)
                    if current_enc_click == 1:
                        if prev_enc_click == 0:
                            # Rising Edge: Start Timer
                            enc_press_start_time = time.time()
                            enc_long_press_triggered = False
                        else:
                            # Button Held: Check for Long Press
                            if not enc_long_press_triggered and (time.time() - enc_press_start_time > 0.8):
                                print(f"[EVENT] Encoder Long Press (System Menu)")
                                # System Menu is handled by hardware/firmware or just ignored by Python
                                enc_long_press_triggered = True
                                
                    elif current_enc_click == 0 and prev_enc_click == 1:
                        # Falling Edge: Check if it was a short click
                        if not enc_long_press_triggered:
                            print(f"[EVENT] Encoder Clicked (Short)")
                            execute_action(config['mappings'].get('enc_click'))
                        
                        enc_press_start_time = None
                        
                    prev_enc_click = current_enc_click

                    if prev_enc_val is not None:
                        diff = current_enc_val - prev_enc_val
                        
                        # 1 Physical Detent = 2 Logical Steps on this Arduino Logic
                        # So we divide by 2.0 to get "Physical Detents"
                        multiplier = abs(diff) / 2.0
                        
                        # Minimal threshold: if multiplier is 0 (diff=0), skip. 
                        # But diff is != 0 here per logic. 
                        # If diff is 1, multiplier is 0.5. We accept that for fine control or accumulation?
                        # User wants 1:1. 
                        # If diff is always 2, multiplier becomes 1.0. Perfect.
                        
                        if diff > 0:
                            print(f"[EVENT] Encoder Rotated CW (x{multiplier})")
                            execute_action(config['mappings'].get('enc_cw'), multiplier=multiplier)
                        elif diff < 0:
                            print(f"[EVENT] Encoder Rotated CCW (x{multiplier})")
                            execute_action(config['mappings'].get('enc_ccw'), multiplier=multiplier)
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
