#if defined(ARDUINO) && ARDUINO >= 100
#include "Arduino.h"
#else
#include "WProgram.h"
#endif

#include "EMGFilters.h"
#include <bluefruit.h>

#define TIMING_DEBUG 1
#define FILTER 50

#define SensorInputPin0 A1 // Forearm
#define SensorInputPin1 A2 // Bicept
#define SensorInputPin2 A3 // Tricept

#include <vector>
#include <algorithm>
#include <unordered_map>
#include <cmath>
#include <iterator>
#include <numeric>

using namespace std;

EMGFilters myFilter;

SAMPLE_FREQUENCY sampleRate = SAMPLE_FREQ_1000HZ;
NOTCH_FREQUENCY humFreq = NOTCH_FREQ_50HZ;
static int Threshold0 = 0;
static int Sum0 = 0;
static int Count = 0;
static int Threshold1 = 0;
static int Sum1 = 0;
static int Threshold2 = 0;
static int Sum2 = 0;
static int pastVals0 [FILTER];
static int pastVals1 [FILTER];
static int pastVals2 [FILTER];
static int pastValsAvg [FILTER];
static int idx = 0;
static int pastVals0Sum = 0;
static int pastVals1Sum = 0;
static int pastVals2Sum = 0;
static int pc = 0;
static int rep_count = 0;
static int since_last = 0;
static char c0 = 0;
static char c1 = 0;
static char c2 = 0;

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
  armc.setFixedLen( 4 *sizeof(int));
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

//  Serial.print("Disconnected, reason = 0x"); Serial.println(reason, HEX);
//  Serial.println("Advertising!");
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

//  Serial.print("Connected to ");
//  Serial.println(central_name);
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

//   open serial
  Serial.begin(115200);
//
//  Serial.println("Bluefruit52 Start");
//  Serial.println("-----------------------\n");
  Bluefruit.begin();
  Bluefruit.Periph.setConnectCallback(connect_callback);
  Bluefruit.Periph.setDisconnectCallback(disconnect_callback);

//  Serial.println("Configuring the Armory Service");
  setupARM();

  startAdv();
//  Serial.println("Advertising...");

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

  pastVals0Sum += envlope0 - pastVals0[idx];
  pastVals0[idx] = envlope0;
  pastVals1Sum += envlope1 - pastVals1[idx];
  pastVals1[idx] = envlope1;
  pastVals2Sum += envlope2 - pastVals2[idx];
  pastVals2[idx] = envlope2;

  envlope0 = pastVals0Sum / FILTER;
  envlope1 = pastVals1Sum / FILTER;
  envlope2 = pastVals2Sum / FILTER;
  idx = (idx + 1) % FILTER;

  int value = (envlope0 + envlope1 + envlope2 ) / 3;

  pastValsAvg[idx] = ( pastVals0[idx] + pastVals1[idx] + pastVals2[idx] ) / 3;
  
  std::vector<double> pastValsAvgVector(std::begin(pastValsAvg), std::end(pastValsAvg));
  
  double r_sum = std::accumulate(pastValsAvgVector.begin(), pastValsAvgVector.end(), 0.0);
  double rolling_average = r_sum / FILTER;
  std::vector<double> diff(FILTER);
  std::transform(pastValsAvgVector.begin(), pastValsAvgVector.end(), diff.begin(), [rolling_average](long double x) { return x - rolling_average; });
  double r_sq_sum = std::inner_product(diff.begin(), diff.end(), diff.begin(), 0.0);
  double rolling_std = std::sqrt(r_sq_sum / FILTER);

  int max_num = 0;
  int current_max = 0;
  
  if (abs(value - rolling_average) > rolling_std) {
    for ( int j = 0; j < FILTER; j++) {
        if (pastVals0[j] > max_num) {
          max_num = pastVals0[j];
          current_max = 0;
        }
        if (pastVals1[j] > max_num) {
          max_num = pastVals1[j];
          current_max = 1;
        }
        if (pastVals2[j] > max_num) {
          max_num = pastVals2[j];
          current_max = 2;
        }
     }
    if (value > 350 && since_last > 230) {
        since_last = 0;
        rep_count++;
        if (current_max == 0) {
          c0++;
        } else if (current_max == 1) {
          c1++;
        }else {
          c2++;
        }
    }
  }
  since_last++;
  
  if (Bluefruit.connected()) {
    if (armw.read8() == 0x32 && cal == 1) {
//      Serial.println("Done Calibrating...");
      Threshold0 = Sum0 / Count;
      Threshold1 = Sum1 / Count;
      Threshold2 = Sum2 / Count;
      cal = 0;
      Sum0 = 0;
      Count = 0;
      Sum1 = 0;
      Sum2 = 0;
    } else if (armw.read8() == 0x31 || cal == 1) {
//      Serial.println("Calibrating...");
      Sum0 += (envlope0 > 0) ? envlope0 : 0;
      Sum1 += (envlope1 > 0) ? envlope1 : 0;
      Sum2 += (envlope2 > 0) ? envlope2 : 0;
      Count++;
      cal = 1;
    } else {
      // any value under threshold will be set to zero
      envlope0 = (envlope0 > Threshold0) ? envlope0 - Threshold0 : 0;
      envlope1 = (envlope1 > Threshold1) ? envlope1 - Threshold1 : 0;
      envlope2 = (envlope2 > Threshold2) ? envlope2 - Threshold2 : 0;
      int armdata[4] = {envlope2, envlope0, envlope1, (c2 << 24) | (c0 << 16) | (c1 << 8)};
      if ( pc % FILTER == 0 ) {
//        Serial.print("Sensor 0: ");
//        Serial.print(envlope0);
//        Serial.print(" ");
//        Serial.print(envlope1);
//        Serial.print(" ");  
//        Serial.println(envlope2);
        armc.notify(armdata, sizeof(armdata));
      }
    }
  
  }
  pc++;
  delayMicroseconds(2000);
}
