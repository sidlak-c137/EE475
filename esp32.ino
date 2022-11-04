//
//#if defined(ARDUINO) && ARDUINO >= 100
//#include "Arduino.h"
//#else
//#include "WProgram.h"
//#endif
//
//#include "EMGFilters.h"
//
//#define TIMING_DEBUG 1
//
//#define SensorInputPin0 A0 // input pin number
//#define SensorInputPin1 A1 // input pin number
//#define SensorInputPin2 A2 // input pin number
//
//EMGFilters myFilter;
//
//SAMPLE_FREQUENCY sampleRate = SAMPLE_FREQ_1000HZ;
//NOTCH_FREQUENCY humFreq = NOTCH_FREQ_50HZ;
//static int Threshold = 0;
//
//unsigned long timeStamp;
//unsigned long timeBudget;
//
//void setup() {
//  /* add setup code here */
//  myFilter.init(sampleRate, humFreq, true, true, true);
//
//  // open serial
//  Serial.begin(115200);
//
//  // setup for time cost measure
//  // using micros()
//  timeBudget = 1e6 / sampleRate;
//  // micros will overflow and auto return to zero every 70 minutes
//}
//
//void loop() {
//  /* add main program code here */
//  // In order to make sure the ADC sample frequence on arduino,
//  // the time cost should be measured each loop
//  /*------------start here-------------------*/
//  timeStamp = micros();
//
//  int Value0 = analogRead(SensorInputPin0);
//  int Value1 = analogRead(SensorInputPin1);
//  int Value2 = analogRead(SensorInputPin2);
//
//  // filter processing
//  int DataAfterFilter0 = myFilter.update(Value0);
//  int DataAfterFilter1 = myFilter.update(Value1);
//  int DataAfterFilter2 = myFilter.update(Value2);
//
//  int envlope0 = sq(DataAfterFilter0);
//  int envlope1 = sq(DataAfterFilter1);
//  int envlope2 = sq(DataAfterFilter2);
//  // any value under threshold will be set to zero
//  envlope0 = (envlope0 > Threshold) ? envlope0 : 0;
//  envlope1 = (envlope1 > Threshold) ? envlope1 : 0;
//  envlope2 = (envlope2 > Threshold) ? envlope2 : 0;
//
//  timeStamp = micros() - timeStamp;
//  if (TIMING_DEBUG) {
//    // Serial.print("Read Data: "); Serial.println(Value);
//    // Serial.print("Filtered Data: ");Serial.println(DataAfterFilter);
//    Serial.print("Sensor 0: ");
//    Serial.println(envlope0);
//    Serial.print("Sensor 1: ");
//    Serial.println(envlope1);
//    Serial.print("Sensor 2: ");
//    Serial.println(envlope2);
//    // Serial.print("Filters cost time: "); Serial.println(timeStamp);
//    // the filter cost average around 520 us
//  }
//
//  /*------------end here---------------------*/
//  // if less than timeBudget, then you still have (timeBudget - timeStamp) to
//  // do your work
//  delayMicroseconds(500);
//  // if more than timeBudget, the sample rate need to reduce to
//  // SAMPLE_FREQ_500HZ
//}

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

#if defined(ARDUINO) && ARDUINO >= 100
#include "Arduino.h"
#else
#include "WProgram.h"
#endif

#include "EMGFilters.h"

#define TIMING_DEBUG 1

#define SensorInputPin0 A0 // input pin number
#define SensorInputPin1 A1 // input pin number
#define SensorInputPin2 A2 // input pin number

EMGFilters myFilter;

SAMPLE_FREQUENCY sampleRate = SAMPLE_FREQ_1000HZ;
NOTCH_FREQUENCY humFreq = NOTCH_FREQ_50HZ;
static int Threshold = 0;

unsigned long timeStamp;
unsigned long timeBudget;

BLEServer *pServer = NULL;
BLECharacteristic * pTxCharacteristic;
bool deviceConnected = false;
bool oldDeviceConnected = false;
std::string txValue = "start connection";

// See the following for generating UUIDs:
// https://www.uuidgenerator.net/

#define SERVICE_UUID           "df09126e-f70b-403d-91ad-8031b7b1985a" // UART service UUID
#define CHARACTERISTIC_UUID_RX "df09126e-f70b-403d-91ad-8031b7b1985a"
#define CHARACTERISTIC_UUID_TX "df09126e-f70b-403d-91ad-8031b7b1985a"


class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
    };

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
    }
};

class MyCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      std::string rxValue = pCharacteristic->getValue();

      if (rxValue.length() > 0) {
        Serial.println("*********");
        Serial.print("Received Value: ");
        for (int i = 0; i < rxValue.length(); i++)
          Serial.print(rxValue[i]);

        Serial.println();
        Serial.println("*********");
      }
    }
};


void setup() {
  myFilter.init(sampleRate, humFreq, true, true, true);
  
  Serial.begin(115200);

  // Create the BLE Device
  BLEDevice::init("UART Service");

  // Create the BLE Server
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  // Create the BLE Service
  BLEService *pService = pServer->createService(SERVICE_UUID);

  // Create a BLE Characteristic
  pTxCharacteristic = pService->createCharacteristic(
                    CHARACTERISTIC_UUID_TX,
                    BLECharacteristic::PROPERTY_NOTIFY
                  );
                      
  pTxCharacteristic->addDescriptor(new BLE2902());

  BLECharacteristic * pRxCharacteristic = pService->createCharacteristic(
                       CHARACTERISTIC_UUID_RX,
                      BLECharacteristic::PROPERTY_WRITE
                    );

  pRxCharacteristic->setCallbacks(new MyCallbacks());

  // Start the service
  pService->start();

  // Start advertising
  pServer->getAdvertising()->start();
  Serial.println("Waiting a client connection to notify...");
}

void loop() {

    if (deviceConnected) {
//        uint *array = &txValue[0];
        pTxCharacteristic->setValue(txValue);
        pTxCharacteristic->notify();
        pTxCharacteristic->setReadProperty(true);
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
        Serial.print("Sensor 0: ");
        Serial.println(envlope0);
//        Serial.print("Sensor 1: ");
//        Serial.println(envlope1);
//        Serial.print("Sensor 2: ");
//        Serial.println(envlope2);
        // any value under threshold will be set to zero
        envlope0 = (envlope0 > Threshold) ? envlope0 : 0;
        envlope1 = (envlope1 > Threshold) ? envlope1 : 0;
        envlope2 = (envlope2 > Threshold) ? envlope2 : 0;
        txValue = std::to_string(envlope0) + " " + std::to_string(envlope1) + " " + std::to_string(envlope2);
        delay(10); // bluetooth stack will go into congestion, if too many packets are sent
  }

    // disconnecting
    if (!deviceConnected && oldDeviceConnected) {
        delay(500); // give the bluetooth stack the chance to get things ready
        pServer->startAdvertising(); // restart advertising
        Serial.println("start advertising");
        oldDeviceConnected = deviceConnected;
    }
    // connecting
    if (deviceConnected && !oldDeviceConnected) {
    // do stuff here on connecting
        oldDeviceConnected = deviceConnected;
    }
}
