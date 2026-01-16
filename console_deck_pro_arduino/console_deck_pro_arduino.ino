#include <Arduino.h>
#include <U8g2lib.h>
#include <Wire.h>
#include <EEPROM.h>
#include "dashboard_graphics.h"

const char *FIRMWARE_VERSION = "v1.1.0";

enum ModuleType
{
  MOD_NONE,
  MOD_EXT_BTNS,
  MOD_SLIDERS,
  MOD_KNOBS
};
ModuleType currentModule = MOD_SLIDERS;

enum ScreenState
{
  STATE_DEFAULT,
  STATE_MENU,
  STATE_SUBMENU,
  STATE_CALIBRATION // New State
};
ScreenState currentState = STATE_DEFAULT;

enum HomeMode
{
  HOME_BASIC,
  HOME_ADVANCE,
  HOME_SPLASH,
  HOME_TESTING
};
HomeMode currentHomeMode = HOME_TESTING;

bool backlightEnabled = true;
const unsigned long LONG_PRESS_MS = 800;
const int MENU_ENC_SENSITIVITY = 2;

const int EEPROM_ADDR_MAGIC = 0;
const int EEPROM_ADDR_HOME = 1;
const int EEPROM_ADDR_MOD = 2;
const int EEPROM_ADDR_LIGHT = 3;
const byte MAGIC_NUMBER = 0x42;

// --- NEW VARIABLES FOR CALIBRATION ---
uint8_t btnMap[9] = {0, 1, 2, 3, 4, 5, 6, 7, 8};
const int EEPROM_ADDR_MAP = 10;
int calibStep = 0;
bool calibWaitingRelease = false;

U8G2_SH1107_SEEED_128X128_1_HW_I2C u8g2(U8G2_R2, U8X8_PIN_NONE);

int cpuUsage = 45;
int gpuUsage = 32;
float memFree = 8.4;
float totalRAM = 16.0;
int pcTemp = 62;
int tempGPU = 58;
float netDown = 12.5;
float netUp = 4.2;

const uint8_t PIN_ENC_CLK = 2;
const uint8_t PIN_ENC_DT = 3;
const uint8_t PIN_ENC_SW = 4;
const uint8_t PIN_ROW_1 = 5;
const uint8_t PIN_ROW_2 = 6;
const uint8_t PIN_ROW_3 = 7;
const uint8_t PIN_COL_1 = 8;
const uint8_t PIN_LED = 9;
const uint8_t PIN_COL_2 = 10;
const uint8_t PIN_COL_3 = 11;
const uint8_t EXT_A0 = A0;
const uint8_t EXT_A1 = A1;
const uint8_t EXT_A2 = A2;
const uint8_t EXT_A3 = A3;
const uint8_t EXT_A6 = A6;
const uint8_t EXT_A7 = A7;

volatile long encoderValue = 0;
long lastEncoderValue = 0;
volatile int lastCLKState;
unsigned long lastActionTime = 0;
unsigned long btnPressStartTime = 0;
bool btnPressed = false;
bool longPressTriggered = false;
int menuIndex = 1;
const int MENU_ITEMS = 5; // Updated to 5
int submenuIndex = 0;
int submenuMaxItems = 0;

const char *subItemsHome[] = {"PC STATS", "PC STATS+", "SPLASH IMAGE", "TESTING"};
const char *subItemsModules[] = {"NONE", "BUTTONS", "SLIDERS", "KNOBS"};
const char *subItemsBacklight[] = {"YES", "NO"};

char mainAction[16] = "Ready";
char extAction[24] = "";
const int rows[] = {PIN_ROW_1, PIN_ROW_2, PIN_ROW_3};
const int cols[] = {PIN_COL_1, PIN_COL_2, PIN_COL_3};
const int NUM_READINGS = 16;
bool moduleConnected = false;
unsigned long disconnectTimer = 0;
bool matrixActive = false;

// Variabili per Serial Data
int mainBtnStates[9] = {0};
int extBtnStates[6] = {0};
int serVal1 = 0;
int serVal2 = 0;

void loadSettings()
{
  if (EEPROM.read(EEPROM_ADDR_MAGIC) == MAGIC_NUMBER)
  {
    currentHomeMode = (HomeMode)EEPROM.read(EEPROM_ADDR_HOME);
    currentModule = (ModuleType)EEPROM.read(EEPROM_ADDR_MOD);
    backlightEnabled = (bool)EEPROM.read(EEPROM_ADDR_LIGHT);
    
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
}
void saveBtnMap() {
  for(int i=0; i<9; i++) {
    EEPROM.update(EEPROM_ADDR_MAP + i, btnMap[i]);
  }
}

void drawBackIcon(int x, int y)
{
  u8g2.drawTriangle(x - 16, y, x - 4, y - 10, x - 4, y + 10);
  u8g2.drawBox(x - 4, y - 4, 16, 8);
  u8g2.drawBox(x + 12, y - 4, 4, 14);
}
void drawHomeIcon(int x, int y)
{
  u8g2.drawTriangle(x, y - 26, x - 24, y, x + 24, y);
  u8g2.drawBox(x - 18, y, 36, 20);
  u8g2.setColorIndex(0);
  u8g2.drawBox(x - 6, y + 8, 12, 12);
  u8g2.setColorIndex(1);
}
void drawModulesIcon(int x, int y)
{
  u8g2.drawRFrame(x - 28, y - 22, 56, 44, 4);
  u8g2.drawLine(x - 14, y - 15, x - 14, y + 15);
  u8g2.drawBox(x - 19, y - 4, 10, 8);
  int btnSize = 6;
  int gap = 12;
  int startX = x + 4;
  int startY = y - 10;
  u8g2.drawBox(startX, startY, btnSize, btnSize);
  u8g2.drawBox(startX + gap, startY, btnSize, btnSize);
  u8g2.drawBox(startX, startY + gap + 4, btnSize, btnSize);
  u8g2.drawBox(startX + gap, startY + gap + 4, btnSize, btnSize);
}
void drawBacklightIcon(int x, int y)
{
  u8g2.drawCircle(x, y, 16);
  u8g2.drawBox(x - 9, y + 14, 18, 5);
  u8g2.drawHLine(x - 7, y + 20, 14);
  u8g2.drawLine(x, y - 20, x, y - 28);
  u8g2.drawLine(x - 20, y, x - 28, y);
  u8g2.drawLine(x + 20, y, x + 28, y);
  u8g2.drawLine(x - 14, y - 14, x - 20, y - 20);
  u8g2.drawLine(x + 14, y - 14, x + 20, y - 20);
}

void drawSettingsIcon(int x, int y)
{
  // Simple Gear
  u8g2.drawDisc(x, y, 12);
  u8g2.drawBox(x-16, y-3, 32, 6);
  u8g2.drawBox(x-3, y-16, 6, 32);
  // Diagonals
  u8g2.drawLine(x-10, y-10, x+10, y+10);
  u8g2.drawLine(x-11, y-10, x+9, y+10); 
  u8g2.drawLine(x+10, y-10, x-10, y+10);
  u8g2.drawLine(x+9, y-10, x-11, y+10); 
  
  u8g2.setColorIndex(0);
  u8g2.drawDisc(x, y, 6); 
  u8g2.setColorIndex(1);
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

int readSmooth(int pin)
{
  long sum = 0;
  for (int i = 0; i < NUM_READINGS; i++)
  {
    sum += analogRead(pin);
    delayMicroseconds(20);
  }
  return sum / NUM_READINGS;
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

void drawCenteredStr(int y, const char *str)
{
  int w = u8g2.getStrWidth(str);
  u8g2.drawStr((128 - w) / 2, y, str);
}

void drawDefaultScreen()
{
  if (currentHomeMode == HOME_BASIC)
  {
    drawSimpleLayout(u8g2, cpuUsage, pcTemp, memFree);
  }
  else if (currentHomeMode == HOME_ADVANCE)
  {
    drawAdvancedLayout(u8g2, cpuUsage, gpuUsage, memFree, totalRAM, pcTemp, tempGPU, netDown, netUp);
  }
  else if (currentHomeMode == HOME_SPLASH)
  {
    u8g2.setFont(u8g2_font_ncenB10_tr);
    drawCenteredStr(55, "CONSOLE");
    drawCenteredStr(75, "DECK PRO");
    u8g2.setFont(u8g2_font_6x10_tr);
    drawCenteredStr(92, FIRMWARE_VERSION);
  }
  else
  {
    char buf[32];
    u8g2.setFont(u8g2_font_ncenB08_tr);
    drawCenteredStr(25, "TESTING MODE");
    u8g2.setFont(u8g2_font_6x10_tr);
    sprintf(buf, "Enc: %ld", encoderValue);
    drawCenteredStr(45, buf);
    if (currentModule == MOD_NONE)
      sprintf(buf, "Mod: NONE");
    else if (!moduleConnected)
      sprintf(buf, "Mod: DISCONN.");
    else if (currentModule == MOD_SLIDERS)
      sprintf(buf, "Mod: SLIDERS");
    else if (currentModule == MOD_KNOBS)
      sprintf(buf, "Mod: KNOBS");
    else
      sprintf(buf, "Mod: BUTTONS");
    drawCenteredStr(65, buf);
    drawCenteredStr(85, mainAction);
    u8g2.drawHLine(44, 95, 40);
    if (currentModule != MOD_NONE && moduleConnected)
    {
      drawCenteredStr(110, extAction);
    }
    else
    {
      drawCenteredStr(110, "- NO DATA -");
    }
  }
}

void drawMenuScreen()
{
  int centerX = 64;
  int iconY = 50;
  int textY = 110;
  u8g2.setFont(u8g2_font_ncenB10_tr);

  if (menuIndex == 0)
  {
    drawBackIcon(centerX, iconY);
    drawCenteredStr(textY, "EXIT MENU");
  }
  else if (menuIndex == 1)
  {
    drawHomeIcon(centerX, iconY);
    drawCenteredStr(textY, "HOME");
  }
  else if (menuIndex == 2)
  {
    drawModulesIcon(centerX, iconY);
    drawCenteredStr(textY, "MODULES");
  }
  else if (menuIndex == 3)
  {
    drawBacklightIcon(centerX, iconY);
    drawCenteredStr(textY, "BACKLIGHT");
  }
  else if (menuIndex == 4)
  {
    drawSettingsIcon(centerX, iconY);
    drawCenteredStr(textY, "CALIBRATION");
  }
  u8g2.setFont(u8g2_font_open_iconic_arrow_2x_t);
  if (menuIndex > 0)
    u8g2.drawGlyph(6, iconY + 5, 60);
  if (menuIndex < MENU_ITEMS - 1)
    u8g2.drawGlyph(112, iconY + 5, 61);
}

void drawSubmenuScreen()
{
  u8g2.setFont(u8g2_font_ncenB08_tr);
  int startY = 20;
  int lineHeight = 16;
  const char **items;
  if (menuIndex == 1)
    items = subItemsHome;
  else if (menuIndex == 2)
    items = subItemsModules;
  else
    items = subItemsBacklight;
  for (int i = 0; i < submenuMaxItems; i++)
  {
    int y = startY + (i * lineHeight);
    if (i == submenuIndex)
      u8g2.drawStr(5, y, ">");
    u8g2.drawStr(20, y, items[i]);
  }
}

void drawCalibrationScreen() {
    u8g2.setFont(u8g2_font_ncenB10_tr);
    drawCenteredStr(30, "CALIBRATION");
    
    char buf[32];
    sprintf(buf, "PRESS BTN %d", calibStep + 1);
    u8g2.setFont(u8g2_font_ncenB14_tr);
    drawCenteredStr(70, buf);
    
    u8g2.setFont(u8g2_font_6x10_tr);
    drawCenteredStr(100, "(Scan Matrix)");
}

void updateDisplay()
{
  u8g2.firstPage();
  do
  {
    if (currentState == STATE_DEFAULT)
      drawDefaultScreen();
    else if (currentState == STATE_MENU)
      drawMenuScreen();
    else if (currentState == STATE_SUBMENU)
      drawSubmenuScreen();
    else if (currentState == STATE_CALIBRATION)
      drawCalibrationScreen();
  } while (u8g2.nextPage());
}

void readExtModule()
{
  if (currentModule == MOD_NONE)
    return;
  if (currentModule == MOD_SLIDERS || currentModule == MOD_KNOBS)
  {
    int raw1 = readSmooth(EXT_A0);
    int raw2 = readSmooth(EXT_A1);

    if (raw1 > 1018 && raw2 > 1018)
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

    int p1 = rawToPercent(raw1);
    int p2 = rawToPercent(raw2);

    // Update Serial Vars
    serVal1 = p1;
    serVal2 = p2;

    static int lp1 = -1, lp2 = -1;
    if (p1 != lp1 || p2 != lp2 || extAction[0] == '\0')
    {
      sprintf(extAction, "S1:%d%% S2:%d%%", p1, p2);
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
    if (digitalRead(EXT_A0) == LOW) { strcpy(extAction, "Ext Btn 1"); extBtnStates[0] = 1; }
    if (digitalRead(EXT_A1) == LOW) { strcpy(extAction, "Ext Btn 2"); extBtnStates[1] = 1; }
    if (digitalRead(EXT_A2) == LOW) { strcpy(extAction, "Ext Btn 3"); extBtnStates[2] = 1; }
    if (digitalRead(EXT_A3) == LOW) { strcpy(extAction, "Ext Btn 4"); extBtnStates[3] = 1; }

    // Buttons 5-6 (Analog, External Pullup 20k to 5V, Button to GND)
    if (analogRead(EXT_A6) < 500) { strcpy(extAction, "Ext Btn 5"); extBtnStates[4] = 1; }
    if (analogRead(EXT_A7) < 500) { strcpy(extAction, "Ext Btn 6"); extBtnStates[5] = 1; }
  }
}

void setup()
{
  Serial.begin(115200); // SERIAL INIT
  u8g2.begin();
  u8g2.setFontMode(1);
  pinMode(PIN_LED, OUTPUT);
  digitalWrite(PIN_LED, LOW);
  pinMode(PIN_ENC_CLK, INPUT);
  pinMode(PIN_ENC_DT, INPUT);
  pinMode(PIN_ENC_SW, INPUT_PULLUP);
  for (int i = 0; i < 3; i++)
  {
    pinMode(rows[i], OUTPUT);
    digitalWrite(rows[i], HIGH);
    pinMode(cols[i], INPUT_PULLUP);
  }
  loadSettings();
  setupExtModule();
  lastCLKState = digitalRead(PIN_ENC_CLK);
  attachInterrupt(digitalPinToInterrupt(PIN_ENC_CLK), handleEncoder, CHANGE);
  updateDisplay();
}

void loop()
{
  bool update = false;
  unsigned long now = millis();

  // MATRIX SCANNING LOGIC WITH CALIBRATION SUPPORT
  matrixActive = false;
  
  // We scan matrix *always* to detect presses for calibration or normal usage
  // Temporarily store which physical button is pressed
  int pressedPhysicalId = -1;

  for (int r = 0; r < 3; r++)
  {
      digitalWrite(rows[r], LOW);
      for (int c = 0; c < 3; c++)
      {
        if (digitalRead(cols[c]) == LOW)
        {
           pressedPhysicalId = (c * 3) + r;
           matrixActive = true;
        }
      }
      digitalWrite(rows[r], HIGH);
  }

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
      
      if (update) updateDisplay();
      return; // Skip the rest of loop in calibration mode
  }
  
  // --- NORMAL LOOP ---

  if (digitalRead(PIN_ENC_SW) == LOW)
  {
    if (!btnPressed)
    {
      btnPressed = true;
      btnPressStartTime = now;
      longPressTriggered = false;
    }
    else if (!longPressTriggered && (now - btnPressStartTime > LONG_PRESS_MS))
    {
      longPressTriggered = true;
      currentState = (currentState == STATE_DEFAULT) ? STATE_MENU : STATE_DEFAULT;
      menuIndex = 1;
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
             if (menuIndex == 0) { currentState = STATE_DEFAULT; update = true; }
             else if (menuIndex == 1) { 
                 // Home actions
                 currentState = STATE_SUBMENU; 
                 submenuMaxItems=4; 
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
              {
                backlightEnabled = (submenuIndex == 0);
              }
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
    strcpy(mainAction, (diff > 0) ? "Enc Right" : "Enc Left");
    lastActionTime = now;
    lastEncoderValue = encoderValue;
    update = true;
  }
  else if (currentState != STATE_DEFAULT && abs(diff) >= MENU_ENC_SENSITIVITY)
  {
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
     // Reset keys
     for(int i=0; i<9; i++) mainBtnStates[i] = 0;
     
     // USE MAPPING: Scan -> p_id -> btnMap[p_id] -> mainBtnStates
     // Re-scan matrix for logic safety (or reuse pressedPhysicalId from start of loop)
     // To be robust against bouncing, we use the same scan logic we did at start of loop 
     // but we need to iterate all rows/cols again if we didn't save full state.
     
     matrixActive = false;
     for (int r = 0; r < 3; r++)
     {
      digitalWrite(rows[r], LOW);
      for (int c = 0; c < 3; c++)
      {
        if (digitalRead(cols[c]) == LOW)
        {
          int p_id = (c * 3) + r;
          int mapped_id = btnMap[p_id];
          
          if(mapped_id >= 0 && mapped_id < 9) {
             mainBtnStates[mapped_id] = 1; 
             sprintf(mainAction, "BTN %d", mapped_id + 1);
          }
          
          lastActionTime = now;
          matrixActive = true;
          update = true;
        }
      }
      digitalWrite(rows[r], HIGH);
     }
     
     if (!matrixActive && strcmp(mainAction, "Ready") != 0)
     {
       if (now - lastActionTime > 500)
       {
         strcpy(mainAction, "Ready");
         update = true;
       }
     }
     
     // Ext Module Read
     char prevExt[24];
     strcpy(prevExt, extAction);
     bool prevConn = moduleConnected;
     readExtModule();
     if (strcmp(prevExt, extAction) != 0 || prevConn != moduleConnected) update = true;

     // SERIAL PRINTS
     for (int i = 0; i < 9; i++) { Serial.print(mainBtnStates[i]); Serial.print(";"); }
     Serial.print(!digitalRead(PIN_ENC_SW)); Serial.print(";");
     Serial.print(encoderValue); Serial.print(";");
     Serial.print((int)currentModule);
     if (currentModule != MOD_NONE) {
        Serial.print(";");
        if (currentModule == MOD_EXT_BTNS) {
           for(int i=0; i<6; i++) { Serial.print(extBtnStates[i]); if(i<5) Serial.print(";"); }
        } else {
           Serial.print(serVal1); Serial.print(";"); Serial.print(serVal2);
        }
     }
     Serial.println();
  }

  if (backlightEnabled) digitalWrite(PIN_LED, HIGH);
  else digitalWrite(PIN_LED, matrixActive ? HIGH : LOW);
  
  if (update) updateDisplay();
}