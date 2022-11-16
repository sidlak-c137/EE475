#if defined(ARDUINO) && ARDUINO >= 100
#include "Arduino.h"
#else
#include "WProgram.h"
#endif

#include "EMGFilters.h"
#include <bluefruit.h>

#define TIMING_DEBUG 1

#define SensorInputPin0 A0 // Forearm
#define SensorInputPin1 A1 // Bicept
#define SensorInputPin2 A2 // Tricept

EMGFilters myFilter;

SAMPLE_FREQUENCY sampleRate = SAMPLE_FREQ_1000HZ;
NOTCH_FREQUENCY humFreq = NOTCH_FREQ_50HZ;
static int Threshold0 = 0;
static int64_t Sum0 = 0;
static int Count = 0;
static int Threshold1 = 0;
static int64_t Sum1 = 0;
static int Threshold2 = 0;
static int64_t Sum2 = 0;

unsigned long timeStamp;
unsigned long timeBudget;
static bool cal = 0;

BLEService arms = BLEService(0x1234);
BLECharacteristic armc = BLECharacteristic(0x5678);
BLECharacteristic armw = BLECharacteristic(0xABCD);

void startAdv(void)
{
  // Advertising packet
  Bluefruit.Advertising.addFlags(BLE_GAP_ADV_FLAGS_LE_ONLY_GENERAL_DISC_MODE);
  Bluefruit.Advertising.addTxPower();

  // Include HRM Service UUID
  Bluefruit.Advertising.addService(arms);

  // Include Name
  Bluefruit.setName("Armory Device");
  Bluefruit.Advertising.addName();

  /* Start Advertising
     - Enable auto advertising if disconnected
     - Interval:  fast mode = 20 ms, slow mode = 152.5 ms
     - Timeout for fast mode is 30 seconds
     - Start(timeout) with timeout = 0 will advertise forever (until connected)

     For recommended advertising interval
     https://developer.apple.com/library/content/qa/qa1931/_index.html
  */
  Bluefruit.Advertising.restartOnDisconnect(true);
  Bluefruit.Advertising.setInterval(32, 244);    // in unit of 0.625 ms
  Bluefruit.Advertising.setFastTimeout(30);      // number of seconds in fast mode
  Bluefruit.Advertising.start(0);                // 0 = Don't stop advertising after n seconds
}

void setupARM(void)
{
  arms.begin();
  armc.setProperties(CHR_PROPS_NOTIFY);
  armc.setPermission(SECMODE_OPEN, SECMODE_OPEN);
  armc.setFixedLen(3 * sizeof(int));
  armc.begin();
  armw.setProperties(CHR_PROPS_WRITE);
  armw.setPermission(SECMODE_OPEN, SECMODE_OPEN);
  armw.setFixedLen(sizeof(uint8_t));
  armw.begin();
}

void disconnect_callback(uint16_t conn_handle, uint8_t reason)
{
  (void) conn_handle;
  (void) reason;

  Serial.print("Disconnected, reason = 0x"); Serial.println(reason, HEX);
  Serial.println("Advertising!");
  cal = 0;
  Threshold0 = 0;
  Sum0 = 0;
  Count = 0;
  Threshold1 = 0;
  Sum1 = 0;
  Threshold2 = 0;
  Sum2 = 0;
}

void connect_callback(uint16_t conn_handle)
{
  // Get the reference to current connection
  BLEConnection* connection = Bluefruit.Connection(conn_handle);

  char central_name[32] = { 0 };
  connection->getPeerName(central_name, sizeof(central_name));

  Serial.print("Connected to ");
  Serial.println(central_name);
  cal = 0;
  Threshold0 = 0;
  Sum0 = 0;
  Count = 0;
  Threshold1 = 0;
  Sum1 = 0;
  Threshold2 = 0;
  Sum2 = 0;
}



void setup() {
  /* add setup code here */
  myFilter.init(sampleRate, humFreq, true, true, true);

  // open serial
  Serial.begin(115200);

  Serial.println("Bluefruit52 Start");
  Serial.println("-----------------------\n");
  Bluefruit.begin();
  Bluefruit.Periph.setConnectCallback(connect_callback);
  Bluefruit.Periph.setDisconnectCallback(disconnect_callback);

  Serial.println("Configuring the Armory Service");
  setupARM();

  startAdv();
  Serial.println("Advertising...");

  // setup for time cost measure
  // using micros()
  timeBudget = 1e6 / sampleRate;
  // micros will overflow and auto return to zero every 70 minutes
  cal = 0;
  Threshold0 = 0;
  Sum0 = 0;
  Count = 0;
  Threshold1 = 0;
  Sum1 = 0;
  Threshold2 = 0;
  Sum2 = 0;
  
}

void loop() {
  timeStamp = micros();

  if (Bluefruit.connected()) {
    if (armw.read8() == 0x32 && cal == 1) {
      Serial.println("Done Calibrating...");
      Threshold0 = Count > 0 ? (int) (Sum0 / Count) : 0;
      Threshold1 = Count > 0 ? (int) (Sum1 / Count) : 0;
      Threshold2 = Count > 0 ? (int) (Sum2 / Count) : 0;
      cal = 0;
      Threshold0 = 0;
      Sum0 = 0;
      Count = 0;
      Threshold1 = 0;
      Sum1 = 0;
      Threshold2 = 0;
      Sum2 = 0;
    } else if (armw.read8() == 0x31 || cal == 1) {
      Serial.println("Calibrating...");
      int Value0 = analogRead(SensorInputPin0);
      int Value1 = analogRead(SensorInputPin1);
      int Value2 = analogRead(SensorInputPin2);

      // filter processing
      int DataAfterFilter0 = myFilter.update(Value0);
      int DataAfterFilter1 = myFilter.update(Value1);
      int DataAfterFilter2 = myFilter.update(Value2);

      int envlope0 = sq(DataAfterFilter0);
      int envlope1 = sq(DataAfterFilter1);
      int envlope2 = sq(DataAfterFilter2);
      Sum0 += (envlope0 > 0) ? envlope0 : 0;
      Sum1 += (envlope1 > 0) ? envlope1 : 0;
      Sum2 += (envlope2 > 0) ? envlope2 : 0;
      Count++;
      cal = 1;
    } else {
      int Value0 = analogRead(SensorInputPin0);
      int Value1 = analogRead(SensorInputPin1);
      int Value2 = analogRead(SensorInputPin2);

      // filter processing
      int DataAfterFilter0 = myFilter.update(Value0);
      int DataAfterFilter1 = myFilter.update(Value1);
      int DataAfterFilter2 = myFilter.update(Value2);

      int envlope0 = sq(DataAfterFilter0);
      int envlope1 = sq(DataAfterFilter1);
      int envlope2 = sq(DataAfterFilter2);
      // any value under threshold will be set to zero
      envlope0 = (envlope0 > Threshold0) ? envlope0 - Threshold0 : 0;
      envlope1 = (envlope1 > Threshold1) ? envlope1 - Threshold1 : 0;
      envlope2 = (envlope2 > Threshold2) ? envlope2 - Threshold2 : 0;
      int armdata[3] = {envlope0, envlope1, envlope2};
      Serial.print("Sensor 0: ");
      Serial.println(envlope0);
      Serial.print("Sensor 1: ");
      Serial.println(envlope1);
      Serial.print("Sensor 2: ");
      Serial.println(envlope2);
      armc.notify(armdata, sizeof(armdata));
    }

  }
  delayMicroseconds(1000);
}
