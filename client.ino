
// includes
#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>

#include <ESP32Servo.h>

// constants
#define SERVICE_UUID "e7949142-2785-53dc-1994-1deb54135003"
#define CHARACTERISTIC_UUID "3b5122d3-4703-7453-ad58-73a8ebdafb7b"
#define BLE_DEVICE_NAME "ESP32_Bluetooth_Server"

#define SERVO_PIN 13


// variables
BLEServer* pServer;
BLEService* pService;
BLECharacteristic* pCharacteristic;
bool deviceConnected = false;
bool preDeviceConnected = false;

bool isDetected = false;

Servo myservo;


// callbacks
class MyServerCallbacks: public BLEServerCallbacks{
  void onConnect(BLEServer *pServer){
    deviceConnected = true;
    Serial.println("onConnect");
  }
  void onDisconnect(BLEServer *pServer){
    deviceConnected = false;
    Serial.println("onDisconnect");
  }
};


// functions
void setup(){
  Serial.begin(115200);

  // BLEの初期化
  BLEDevice::init(BLE_DEVICE_NAME);

  // サーバー,サービス,キャラクタリスティック,コールバックの作成・設定
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());
  pService = pServer->createService(SERVICE_UUID);
  pCharacteristic = pService->createCharacteristic(
      CHARACTERISTIC_UUID,
      BLECharacteristic::PROPERTY_NOTIFY |
      BLECharacteristic::PROPERTY_READ   |
      BLECharacteristic::PROPERTY_WRITE  |
      BLECharacteristic::PROPERTY_WRITE_NR
  );

  // キャラクタリスティックの初期値
  pCharacteristic->setValue((uint8_t*)&isDetected,sizeof(isDetected));

  //サービスの開始
  pService->start();

  //アドバタイジングの設定
  BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);  //スキャンレスポンスの有効化
  pAdvertising->setMinPreferred(0x06);  //最小の接続間隔
  pAdvertising->setMaxPreferred(0x12);  //最大の接続間隔
  // アドバタイジングの開始(繰り返される)
  BLEDevice::startAdvertising();

  Serial.println("Characteristic defined");

  myservo.attach(SERVO_PIN);
}


void loop(){
  
  String value = pCharacteristic->getValue();
  float *data = (float*)value.c_str();
  int dataSize = value.length()/sizeof(float);
  for(int i = 0; i < dataSize; i++){
    Serial.print(data[i]);
    Serial.print(" ");
  }
  Serial.println();


  // disconnecting
  if(!deviceConnected && preDeviceConnected){
    delay(500);
    pServer->startAdvertising();
    Serial.println("restartAdvertising");
    preDeviceConnected = deviceConnected;
    pCharacteristic->setValue((uint8_t*)&isDetected,sizeof(isDetected));
    myservo.writeMicroseconds(1500);
    delay(100);
  }  
  // connecting
  if(deviceConnected && !preDeviceConnected){
    preDeviceConnected = deviceConnected;
  }


  if(deviceConnected){  // 接続後
    myservo.writeMicroseconds(1500+min(data[1]+data[2],float(1.0))*500);
    delay(100);
  }


  delay(50);
}