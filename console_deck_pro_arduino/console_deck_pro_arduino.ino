#include <Arduino.h>
#include <U8g2lib.h>
#include <Wire.h>
#include <EEPROM.h>
#include "console_deck_pro_globals.h"

// Display: single definition (constructor) — declared in globals.h
U8G2_SH1107_SEEED_128X128_1_HW_I2C u8g2(U8G2_R2, U8X8_PIN_NONE);

void loadSettings()
{
  if (EEPROM.read(EEPROM_ADDR_MAGIC) == MAGIC_NUMBER)
  {
    int h = EEPROM.read(EEPROM_ADDR_HOME);
    if (h <= 1) currentHomeMode = HOME_PC_STATS;
    else if (h == 2) currentHomeMode = HOME_SPLASH;
    else currentHomeMode = HOME_TESTING;
    currentModule = (ModuleType)EEPROM.read(EEPROM_ADDR_MOD);
    backlightEnabled = (bool)EEPROM.read(EEPROM_ADDR_LIGHT);
    int ss = EEPROM.read(EEPROM_ADDR_SCREENSAVER);
    if (ss >= 0 && ss <= 5) screenSaverDelayIndex = ss;

    // Load Map
    for(int i=0; i<9; i++) {
       uint8_t val = EEPROM.read(EEPROM_ADDR_MAP + i);
       if(val < 9) btnMap[i] = val;
       else btnMap[i] = i; // Reset if invalid
    }
  }
}

void saveSettings()
{
  EEPROM.update(EEPROM_ADDR_MAGIC, MAGIC_NUMBER);
  EEPROM.update(EEPROM_ADDR_HOME, (uint8_t)currentHomeMode);
  EEPROM.update(EEPROM_ADDR_MOD, (uint8_t)currentModule);
  EEPROM.update(EEPROM_ADDR_LIGHT, (uint8_t)backlightEnabled);
  EEPROM.update(EEPROM_ADDR_SCREENSAVER, (uint8_t)screenSaverDelayIndex);
}

void saveBtnMap() {
  for(int i=0; i<9; i++) {
    EEPROM.update(EEPROM_ADDR_MAP + i, btnMap[i]);
  }
}

void setupExtModule()
{
  pinMode(EXT_A0, INPUT);
  pinMode(EXT_A1, INPUT);
  pinMode(EXT_A2, INPUT);
  pinMode(EXT_A3, INPUT);
  if (currentModule == MOD_NONE)
  {
    moduleConnected = false;
    extAction[0] = '\0';
  }
  else if (currentModule == MOD_SLIDERS || currentModule == MOD_KNOBS)
  {
    pinMode(EXT_A0, INPUT_PULLUP);
    pinMode(EXT_A1, INPUT_PULLUP);
  }
  else if (currentModule == MOD_EXT_BTNS)
  {
    pinMode(EXT_A0, INPUT_PULLUP);
    pinMode(EXT_A1, INPUT_PULLUP);
    pinMode(EXT_A2, INPUT_PULLUP);
    pinMode(EXT_A3, INPUT_PULLUP);
  }
}

int rawToPercent(int raw)
{
  if (raw < 15)
    return 0;
  if (raw > 1015)
    return 100;
  return map(raw, 15, 1015, 0, 100);
}

void handleEncoder()
{
  int clk = digitalRead(PIN_ENC_CLK);
  int dt = digitalRead(PIN_ENC_DT);
  if (clk != lastCLKState)
  {
    if (dt != clk)
      encoderValue++;
    else
      encoderValue--;
    lastCLKState = clk;
  }
}

void readExtModule()
{
  if (currentModule == MOD_NONE)
    return;
  if (currentModule == MOD_SLIDERS || currentModule == MOD_KNOBS)
  {
    // Fast path: quick probe first. If module is disconnected, avoid expensive smoothing.
    int quick1 = analogRead(EXT_A0);
    int quick2 = analogRead(EXT_A1);

    if (quick1 > 1018 && quick2 > 1018)
    {
      if (disconnectTimer == 0)
        disconnectTimer = millis();
      else if (millis() - disconnectTimer > 500)
      {
        moduleConnected = false;
        extAction[0] = '\0';
      }
      return;
    }
    else
    {
      disconnectTimer = 0;
      moduleConnected = true;
    }
    if (!moduleConnected)
      return;

    // Lightweight filtering (IIR) instead of 16x analogRead + delay.
    static int filt1 = -1;
    static int filt2 = -1;
    if (filt1 < 0) filt1 = quick1;
    if (filt2 < 0) filt2 = quick2;
    filt1 = (filt1 * 3 + quick1) / 4;
    filt2 = (filt2 * 3 + quick2) / 4;

    int p1 = rawToPercent(filt1);
    int p2 = rawToPercent(filt2);

    // Update Serial Vars
    serVal1 = p1;
    serVal2 = p2;

    static int lp1 = -1, lp2 = -1;
    if (p1 != lp1 || p2 != lp2 || extAction[0] == '\0')
    {
      // Manual formatting
      strcpy(extAction, "S1:");
      char tmp[4]; 
      itoa(p1, tmp, 10); strcat(extAction, tmp);
      strcat(extAction, "% S2:");
      itoa(p2, tmp, 10); strcat(extAction, tmp);
      strcat(extAction, "%");
      
      lp1 = p1;
      lp2 = p2;
    }
  }
  else if (currentModule == MOD_EXT_BTNS)
  {
    moduleConnected = true;
    extAction[0] = '\0';

    // Reset Serial Buttons Array
    for (int i = 0; i < 6; i++)
      extBtnStates[i] = 0;

    // Buttons 1-4 (Digital, Internal Pullup, Active LOW)
    if (digitalRead(EXT_A0) == LOW) { strcpy(extAction, "E Btn 1"); extBtnStates[0] = 1; }
    if (digitalRead(EXT_A1) == LOW) { strcpy(extAction, "E Btn 2"); extBtnStates[1] = 1; }
    if (digitalRead(EXT_A2) == LOW) { strcpy(extAction, "E Btn 3"); extBtnStates[2] = 1; }
    if (digitalRead(EXT_A3) == LOW) { strcpy(extAction, "E Btn 4"); extBtnStates[3] = 1; }

    // Buttons 5-6 (Analog)
    if (analogRead(EXT_A6) < 500) { strcpy(extAction, "E Btn 5"); extBtnStates[4] = 1; }
    if (analogRead(EXT_A7) < 500) { strcpy(extAction, "E Btn 6"); extBtnStates[5] = 1; }
  }
}

void setup()
{
  Serial.begin(115200); // SERIAL INIT
  Wire.setClock(400000); // Fast I2C
  if (ENABLE_DISPLAY) {
    u8g2.begin();
    u8g2.setFontMode(1);
  }
  pinMode(PIN_LED, OUTPUT);
  digitalWrite(PIN_LED, LOW);
  pinMode(PIN_ENC_CLK, INPUT);
  pinMode(PIN_ENC_DT, INPUT);
  pinMode(PIN_ENC_SW, INPUT_PULLUP);
  for (int i = 0; i < 3; i++)
  {
    pinMode(rows[i], INPUT_PULLUP); // Simular to High Output, but with 10k Pull-Up to prevent short circuit
    pinMode(cols[i], INPUT_PULLUP);
  }
  loadSettings();
  setupExtModule();
  lastCLKState = digitalRead(PIN_ENC_CLK);
  attachInterrupt(digitalPinToInterrupt(PIN_ENC_CLK), handleEncoder, CHANGE);
  lastActivityTime = millis();
  if (ENABLE_DISPLAY) updateDisplay();
}

void loop()
{
  static unsigned long lastDisplayUpdate = 0;
  static unsigned long lastModuleReadTime = 0;
  static unsigned long lastUserInputTime = 0;
  static ScreenState lastRenderedState = STATE_DEFAULT;
  static bool lastRenderedScreenSaver = false;
  static bool pendingDisplayUpdate = false;
  bool update = false;
  unsigned long now = millis();

  // READ INCOMING SERIAL: at most one line per loop to keep loop responsive (avoids lag on key press)
  while (Serial.available() > 0) {
      char c = Serial.read();
      if (c == '\n') {
          serialBuf[serialBufIdx] = '\0';
          serialBufIdx = 0;
          if (strncmp(serialBuf, "STATS:", 6) == 0) {
              lastStatsTime = now;
              if (!pcConnected) { pcConnected = true; update = true; }
              char* ptr = serialBuf + 6;
              char* token = strtok(ptr, ",");
              if(token) cpuUsage = atoi(token);
              token = strtok(NULL, ",");
              if(token) gpuUsage = atoi(token);
              token = strtok(NULL, ",");
              if(token) ramUsage = atoi(token);
              token = strtok(NULL, ",");
              if(token) cpuFreqMHz = atoi(token);
              token = strtok(NULL, ",");
              if(token) gpuTempC = atoi(token);
              token = strtok(NULL, ",");
              if(token) { strncpy(timeStr, token, 5); timeStr[5] = '\0'; }
              token = strtok(NULL, ",");
              if(token) { strncpy(dateStr, token, 5); dateStr[5] = '\0'; }
              if (currentState == STATE_DEFAULT && (currentHomeMode == HOME_PC_STATS || currentHomeMode == HOME_SPLASH)) update = true;
          }
          break;  // process only one line per loop
      } else {
          if (serialBufIdx < 47) serialBuf[serialBufIdx++] = c;
      }
  }
  
  // Check Timeout
  if (pcConnected && (now - lastStatsTime > 5000)) {
      pcConnected = false;
      if (currentState == STATE_DEFAULT && currentHomeMode == HOME_PC_STATS) {
          update = true;
      }
  }

  // MATRIX SCANNING LOGIC WITH CALIBRATION SUPPORT
  matrixActive = false;
  
  // We scan matrix *always* to detect presses for calibration or normal usage
  // Temporarily store which physical button is pressed
  int pressedPhysicalId = -1;

  for (int r = 0; r < 3; r++)
  {
      pinMode(rows[r], OUTPUT);
      digitalWrite(rows[r], LOW); // Only one row can be LOW, the other Rows are pulled Up to HIGH
      for (int c = 0; c < 3; c++)
      {
        if (digitalRead(cols[c]) == LOW)
        {
           pressedPhysicalId = (c * 3) + r;
           matrixActive = true;
        }
      }
      pinMode(rows[r], INPUT_PULLUP); // Row get pulled up to HIGH with 10k
  }
  if (pressedPhysicalId != -1) lastUserInputTime = now;

  // --- CALIBRATION LOGIC ---
  if (currentState == STATE_CALIBRATION) {
      if (pressedPhysicalId != -1) {
          if (!calibWaitingRelease) {
             // Register Mapping
             // We map this Physical ID -> Current Logical Step
             btnMap[pressedPhysicalId] = calibStep;
             
             // Move to next step
             calibStep++;
             calibWaitingRelease = true; // Wait for release before accepting next
             update = true;
             
             if (calibStep >= 9) {
                 // Done
                 saveBtnMap();
                 currentState = STATE_MENU;
                 menuIndex = 0; // Go to exit
             }
          }
      } else {
          // Button released
          calibWaitingRelease = false;
      }
      
      // Handle Encoder to Exit?
      // Optional: Click encoder to abort
      if (digitalRead(PIN_ENC_SW) == LOW) {
           // Simple debounce could go here, but for now strict checking
      }
      
      if (ENABLE_DISPLAY && update) updateDisplay();
      return; // Skip the rest of loop in calibration mode
  }
  
  // --- NORMAL LOOP ---

  if (digitalRead(PIN_ENC_SW) == LOW)
  {
    lastUserInputTime = now;
    if (!btnPressed)
    {
      btnPressed = true;
      btnPressStartTime = now;
      longPressTriggered = false;
    }
    else if (!longPressTriggered && (now - btnPressStartTime > LONG_PRESS_MS))
    {
      longPressTriggered = true;
      if (currentState == STATE_DEFAULT) {
        currentState = STATE_MENU;
        menuIndex = 1;
      } else {
        currentState = STATE_DEFAULT;
        lastActivityTime = now;
      }
      update = true;
    }
  }
  else
  {
    if (btnPressed)
    {
       if (!longPressTriggered)
       {
          if (currentState == STATE_DEFAULT)
          {
             strcpy(mainAction, "Enc Click");
             lastActionTime = now;
             update = true;
          }
          else if (currentState == STATE_MENU)
          {
             if (menuIndex == 0) { currentState = STATE_DEFAULT; lastActivityTime = now; update = true; }
             else if (menuIndex == 1) { 
                 currentState = STATE_SUBMENU; 
                 submenuMaxItems=3; 
                 submenuIndex=(int)currentHomeMode; 
                 update = true;
             }
             else if (menuIndex == 2) { 
                 currentState = STATE_SUBMENU; 
                 submenuMaxItems=4; 
                 submenuIndex=(int)currentModule; 
                 update = true;
             }
             else if (menuIndex == 3) { 
                 currentState = STATE_SUBMENU; 
                 submenuMaxItems=2; 
                 submenuIndex=backlightEnabled?0:1; 
                 update = true;
             }
             else if (menuIndex == 4) { 
                 currentState = STATE_SUBMENU; 
                 submenuMaxItems=6; 
                 submenuIndex=screenSaverDelayIndex; 
                 update = true;
             }
             else if (menuIndex == 5) { 
                 currentState = STATE_CALIBRATION; 
                 calibStep = 0; 
                 calibWaitingRelease = true; // wait for release of any btn
                 update = true; 
             } 
          }
          else if (currentState == STATE_SUBMENU)
          {
              if (menuIndex == 1)
                currentHomeMode = (HomeMode)submenuIndex;
              else if (menuIndex == 2)
              {
                currentModule = (ModuleType)submenuIndex;
                setupExtModule();
              }
              else if (menuIndex == 3)
                backlightEnabled = (submenuIndex == 0);
              else if (menuIndex == 4)
                screenSaverDelayIndex = submenuIndex;
              saveSettings();
              currentState = STATE_MENU;
              update = true;
          }
       }
       btnPressed = false;
    }
  }

  // Encoder Rotation
  long diff = encoderValue - lastEncoderValue;
  if (currentState == STATE_DEFAULT && diff != 0)
  {
    lastUserInputTime = now;
    strcpy(mainAction, (diff > 0) ? "Enc Right" : "Enc Left");
    lastActionTime = now;
    lastEncoderValue = encoderValue;
    update = true;
  }
  else if (currentState != STATE_DEFAULT && abs(diff) >= MENU_ENC_SENSITIVITY)
  {
      lastUserInputTime = now;
      int dir = (diff > 0) ? 1 : -1;
      if (currentState == STATE_MENU) {
          menuIndex += dir;
          if (menuIndex >= MENU_ITEMS) menuIndex = 0;
          if (menuIndex < 0) menuIndex = MENU_ITEMS - 1;
      } else {
          submenuIndex += dir;
          if (submenuIndex >= submenuMaxItems) submenuIndex = 0;
          if (submenuIndex < 0) submenuIndex = submenuMaxItems - 1;
      }
      lastEncoderValue = encoderValue;
      update = true;
  }

  // --- OUTPUT GENERATION (DEFAULT STATE) ---
  if (currentState == STATE_DEFAULT)
  {
     matrixActive = false;
     for (int i = 0; i < 9; i++) mainBtnStates[i] = 0;
     // Use first scan result (pressedPhysicalId) — no second scan, so press is sent sooner
     if (pressedPhysicalId >= 0 && pressedPhysicalId < 9) {
       int mapped_id = btnMap[pressedPhysicalId];
       if (mapped_id >= 0 && mapped_id < 9) {
         mainBtnStates[mapped_id] = 1;
         char newStr[8];
         strcpy(newStr, "BTN ");
         char numStr[2];
         itoa(mapped_id + 1, numStr, 10);
         strcat(newStr, numStr);
         if (strcmp(mainAction, newStr) != 0) {
           strcpy(mainAction, newStr);
           update = true;
         }
         lastActionTime = now;
         matrixActive = true;
       }
     }

     if (!matrixActive && strcmp(mainAction, "Ready") != 0)
     {
       if (now - lastActionTime > 500)
       {
         strcpy(mainAction, "Ready");
         update = true;
       }
     }
     
     // Sample external modules at a small fixed interval so button latency stays low.
     if (currentModule != MOD_NONE && (now - lastModuleReadTime >= MODULE_READ_INTERVAL_MS)) {
       char prevExt[20];
       strcpy(prevExt, extAction);
       bool prevConn = moduleConnected;
       readExtModule();
       if (strcmp(prevExt, extAction) != 0 || prevConn != moduleConnected) {
         update = true;
         lastUserInputTime = now;
       }
       lastModuleReadTime = now;
     }

     // SERIAL PRINTS - OPTIMIZED
     // Only send if something changed or every 50ms heartbeat
     static unsigned long lastSerialTime = 0;
     static int lastSentBtnStates[9] = {0};
     static int lastSentExtBtnStates[6] = {0};
     static long lastSentEnc = -999;
     static int lastSentSer1 = -1;
     static int lastSentSer2 = -1;
     
     bool dataChanged = false;
     
     // Check Main Buttons
     for(int i=0; i<9; i++) {
         if(mainBtnStates[i] != lastSentBtnStates[i]) {
             dataChanged = true; 
             break;
         }
     }
     
     // Check Encoder
     if(encoderValue != lastSentEnc || digitalRead(PIN_ENC_SW) == LOW) {
         dataChanged = true;
     }

     // Activity = "output not idle": based on the state you send (like the serial string)
     // Idle = no button pressed, encoder not pressed or rotated, module with no input
     bool outputIsIdle = true;
     for (int i = 0; i < 9; i++) { if (mainBtnStates[i] != 0) { outputIsIdle = false; break; } }
     if (digitalRead(PIN_ENC_SW) == LOW) outputIsIdle = false;
     if (encoderValue != lastSentEnc) outputIsIdle = false;  // encoder rotation (e.g. volume)
     if (currentModule == MOD_EXT_BTNS) {
       for (int i = 0; i < 6; i++) { if (extBtnStates[i] != 0) { outputIsIdle = false; break; } }
     }
     if (!outputIsIdle) {
         lastActivityTime = now;
         if (screenSaverActive) screenSaverActive = false;
     }
     // Screen saver: after inactivity turn off screen (full black)
     if (!screenSaverActive && screenSaverDelayIndex != 5 && SCREEN_SAVER_DELAY_MS[screenSaverDelayIndex] != 0
         && (now - lastActivityTime >= SCREEN_SAVER_DELAY_MS[screenSaverDelayIndex])) {
       screenSaverActive = true;
       update = true;
       lastDisplayUpdate = 0;  // force next redraw to show black screen
     }

     // Check Module
     if(currentModule == MOD_EXT_BTNS) {
         for(int i=0; i<6; i++) {
             if(extBtnStates[i] != lastSentExtBtnStates[i]) { dataChanged = true; lastUserInputTime = now; break; }
         }
     } else if(currentModule == MOD_SLIDERS || currentModule == MOD_KNOBS) {
         if(abs(serVal1 - lastSentSer1) > 1 || abs(serVal2 - lastSentSer2) > 1) { // 1% deadband
             dataChanged = true;
             lastUserInputTime = now;
         }
     }

     // Build one line and write it in one shot. This is faster than many Serial.print() calls
     // and only requires enough TX space for the actual line length, not a fully empty buffer.
     if (dataChanged || (now - lastSerialTime > 10))
     {
         char outBuf[80];
         int len = 0;

         for (int i = 0; i < 9 && len < (int)sizeof(outBuf) - 2; i++) {
             outBuf[len++] = mainBtnStates[i] ? '1' : '0';
             outBuf[len++] = ';';
         }

         len += snprintf(outBuf + len, sizeof(outBuf) - len, "%d;%ld;%d",
                         !digitalRead(PIN_ENC_SW), encoderValue, (int)currentModule);

         if (currentModule != MOD_NONE && len < (int)sizeof(outBuf) - 1) {
             if (currentModule == MOD_EXT_BTNS) {
                 len += snprintf(outBuf + len, sizeof(outBuf) - len, ";%d;%d;%d;%d;%d;%d",
                                 extBtnStates[0], extBtnStates[1], extBtnStates[2],
                                 extBtnStates[3], extBtnStates[4], extBtnStates[5]);
             } else {
                 len += snprintf(outBuf + len, sizeof(outBuf) - len, ";%d;%d", serVal1, serVal2);
             }
         }

         if (len > 0 && len < (int)sizeof(outBuf) - 1) {
             outBuf[len++] = '\n';
             if (Serial.availableForWrite() >= len) {
                 Serial.write((const uint8_t*)outBuf, len);
                 lastSerialTime = now;
                 lastSentEnc = encoderValue;
                 lastSentSer1 = serVal1;
                 lastSentSer2 = serVal2;
                 for (int i = 0; i < 9; i++) lastSentBtnStates[i] = mainBtnStates[i];
                 for (int i = 0; i < 6; i++) lastSentExtBtnStates[i] = extBtnStates[i];
             }
         }
     }
  }

  if (backlightEnabled) digitalWrite(PIN_LED, HIGH);
  else digitalWrite(PIN_LED, matrixActive ? HIGH : LOW);
  
  // Throttle display updates so the loop stays responsive (e.g. when Python is not running)
  if (update) pendingDisplayUpdate = true;

  bool inMenuLikeState = (currentState != STATE_DEFAULT);
  unsigned long displayInterval = DISPLAY_UPDATE_INTERVAL_MS;
  if (DISPLAY_PERFORMANCE_MODE) {
    if (inMenuLikeState) {
      // In menus we prioritize UI fluidity (no action burst to host).
      displayInterval = DISPLAY_MENU_INTERVAL_MS;
    } else {
      displayInterval = ((now - lastUserInputTime) < DISPLAY_INPUT_BURST_WINDOW_MS)
          ? DISPLAY_ACTIVE_INTERVAL_MS
          : DISPLAY_IDLE_INTERVAL_MS;
    }
  }

  bool forceDisplay = (currentState != lastRenderedState) || (screenSaverActive != lastRenderedScreenSaver);
  bool inputBurstActive = ((now - lastUserInputTime) < DISPLAY_HARD_BLOCK_WINDOW_MS);
  bool renderBlocked = DISPLAY_STRICT_INPUT_PRIORITY && !inMenuLikeState && inputBurstActive;

  if (ENABLE_DISPLAY && pendingDisplayUpdate && !renderBlocked &&
      (forceDisplay || (now - lastDisplayUpdate >= displayInterval))) {
    lastDisplayUpdate = now;
    updateDisplay();
    lastRenderedState = currentState;
    lastRenderedScreenSaver = screenSaverActive;
    pendingDisplayUpdate = false;
  }
}
