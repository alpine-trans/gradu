
// includes
#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>
#include <Preferences.h>
#include <ESP32Servo.h>

// 定数s
#define SERVICE_UUID "6c5bfad3-2c9c-e0df-f2b7-ac012c891ae0"
#define CHARACTERISTIC_UUID "111fd564-b21a-1f83-a479-1e4b6eea0687"
#define BLE_DEVICE_NAME "lock_system_01"
#define SERVO_PIN 13


// 変数s
//about BLE
BLEServer* pServer;
BLEService* pService;
BLECharacteristic* pCharacteristic;
bool deviceConnected = false;
bool characteristic_data = false;
bool isOpen = false;
// about フラッシュメモリ
Preferences preferences;
std::string savedCentralAddress = "";
// about サーボ
Servo myservo;

// プロトタイプ宣言
void open_lock();
void close_lock();

// コールバック
class MyServerCallbacks: public BLEServerCallbacks{

  // 接続時
  void onConnect(BLEServer *pServer, esp_ble_gatts_cb_param_t *param){
    // central addressの取得
    BLEAddress centralAddress(param->connect.remote_bda);
    String centralAddress_now = centralAddress.toString();
    // セントラルアドレスを記録していないか、セントラルアドレスと記録アドレスが同じなら 接続維持
    if(!preferences.isKey("centralAddress") || centralAddress_now == preferences.getString("centralAddress", "")){
      deviceConnected = true;
      Serial.println("onConnect");
      // 記録が空なら記録
      if(!preferences.isKey("centralAddress")){
        preferences.putString("centralAddress", centralAddress_now);
        Serial.println("saved central address");
      }
      //でないなら削除
      else{
        preferences.remove("centralAddress");
        Serial.println("remove central address");
      }
      //解錠
      open_lock();
    }
    // 違うなら切断
    else{
      Serial.println("no macthed");
      pServer->disconnect(param->connect.conn_id);
    }
  }

  //切断時
  void onDisconnect(BLEServer *pServer){
    close_lock();
    deviceConnected = false;
    Serial.println("onDisconnect");
    delay(500);
    pServer->startAdvertising();
    Serial.println("restart Advertising");
    myservo.writeMicroseconds(1500);
    delay(100);
  }

};


// 関数s
void setup(){

  // 初期化
  Serial.begin(115200);
  preferences.begin("my-app", false);
  BLEDevice::init(BLE_DEVICE_NAME);
  String centralAddressStr = preferences.getString("centralAddress", "");
  savedCentralAddress = std::string(centralAddressStr.c_str());


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
  pCharacteristic->setValue((uint8_t*)&isOpen,sizeof(isOpen));

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
  // preferences.remove("centralAddress");
  // Serial.println("remove central address");
}


void loop(){  
  // read & display キャラクタリスティック
  String value = pCharacteristic->getValue();
  characteristic_data = (value[0]==1);
  Serial.println(characteristic_data);
  // Serial.println(preferences.getString("centralAddress", ""));

  if(deviceConnected && !characteristic_data){
    close_lock();
  }
  if(deviceConnected && characteristic_data){
    open_lock();
  }

  delay(50);
}


void open_lock(){
  if(isOpen) return;
  isOpen = true;
  pCharacteristic->setValue((uint8_t*)&isOpen,sizeof(isOpen));
  pCharacteristic->notify();
  Serial.println("open");
  myservo.writeMicroseconds(2000);
  delay(500);
  myservo.writeMicroseconds(1500);
}


void close_lock(){
  if(!isOpen) return;
  isOpen = false;
  pCharacteristic->setValue((uint8_t*)&isOpen,sizeof(isOpen));
  pCharacteristic->notify();
  Serial.println("close");
  myservo.writeMicroseconds(1750);
  delay(500);
  myservo.writeMicroseconds(1500);
  }

