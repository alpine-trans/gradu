//
//  BLEManager.swift
//  lock
//
//  Created by Takayama on 2025/02/08.
//

//  フロー
//  接続：接続ボタンの押下 → スキャンの開始 → 発見したらリストに表示 → 選択したペリフェラルと接続 → スキャンの終了
//  通信：キャラクタリスティックの更新
//

import CoreBluetooth

class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    static let shared = BLEManager()
    private var centralManager: CBCentralManager!
    @Published var discoveredPeripherals: [(peripheral:CBPeripheral,rssi:Int)] = []
    @Published var connectedPeripheral: CBPeripheral?
    @Published var characteristicData: CBCharacteristic?
    @Published var isPoweredOn = false
    @Published var isScanning = false
    @Published var isConnected = false
    @Published var hasConnected = false
    @Published var receivedData: String = ""
    @Published var isOpen = false
    @Published var PeripheralKey = "PeripheralUUID"
    @Published var ServiseUUID = ""
    
    //初期
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    //接続
    //接続状態(電源のオンオフ等)が変化したら、
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        isPoweredOn = central.state == .poweredOn
    }
    //スキャン開始
    func startScan() {
        if centralManager.state == .poweredOn {
            isScanning = true
            discoveredPeripherals.removeAll()  //前回発見したペリフェラルをクリア 意味ない
            centralManager.scanForPeripherals(withServices: nil, options: nil)  //スキャン
        }
    }
    //スキャン終了
    func stopScan() {
        isScanning = false
        centralManager.stopScan()  //スキャン停止
        discoveredPeripherals.removeAll()  //発見したペリフェラルをクリア
    }
    //再接続
    func reconnectToPeripheral() {
        if let UUIDString = UserDefaults.standard.string(forKey: PeripheralKey){
            if let savedPeripheralUUID = UUID(uuidString: UUIDString) {
                let peripheralUUID = CBUUID(nsuuid: savedPeripheralUUID)
                centralManager.scanForPeripherals(withServices: [peripheralUUID], options: nil)
            }
        }
    }
    //ペリフェラルを発見したら、ペリフェラルsに追加
    func centralManager(_ central: CBCentralManager,  didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber){
        let RSSI_Int = RSSI.intValue
        if !discoveredPeripherals.contains(where: {$0.peripheral.identifier == peripheral.identifier}) {  //discoveredPeripheralsに存在しないペリフェラルならば
            discoveredPeripherals.append((peripheral:peripheral,rssi:RSSI_Int))  //追加
        }
        else{
            if let index = discoveredPeripherals.firstIndex(where: {$0.peripheral.identifier == peripheral.identifier}){
                discoveredPeripherals[index].rssi = RSSI_Int
            }
        }
        discoveredPeripherals.sort(by: {$0.rssi > $1.rssi})
    }
    //任意のペリフェラルと接続
    func connectToPeripheral(_ peripheral: CBPeripheral) {
        centralManager.stopScan()  //スキャン停止
        centralManager.connect(peripheral, options: nil)  //接続
//        discoveredPeripherals.removeAll()
    }
    //ペリフェラルとの接続を解除
    func disconnectFromPeripheral() {
        if let peripheral = connectedPeripheral {  //connectedPeripheralがnilでないなら
            centralManager.cancelPeripheralConnection(peripheral)  //接続解除
        }
        discoveredPeripherals.removeAll()
    }
    //ペリフェラルと接続したら、サービスの検索
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectedPeripheral = peripheral  //接続したペリフェラルを記録
        peripheral.delegate = self
        peripheral.discoverServices(nil)  //サービスの検索
        isConnected = true
    }
    //ペリフェラルと接続を絶ったら、
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isOpen = false
        
        //ペリフェラルの保存、削除
        if UserDefaults.standard.string(forKey: PeripheralKey) != nil {
            deletePeripheralUUID()
        }
        else {
            savePeripheralUUID(ServiseUUID)
        }
        
        connectedPeripheral = nil  //接続していたペリフェラルを削除
        isConnected = false
        hasConnected = true
    }
    //保存
    func savePeripheralUUID(_ uuid: String) {
        UserDefaults.standard.set(uuid, forKey: PeripheralKey)
    }
    //削除
    func deletePeripheralUUID() {
        UserDefaults.standard.removeObject(forKey: PeripheralKey)
    }

    
    //通信
    //サービスを発見したら、キャラクタリスティックを検索
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?){
        if let services = peripheral.services {  //Serviceが存在するなら
            for service in services {
                ServiseUUID = service.uuid.uuidString
                peripheral.discoverCharacteristics(nil, for: service)  //キャラクタリスティックの検索
            }
        }
    }
    //キャラクタリスティックを発見したら、キャラクタリスティックを記録
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {  //キャラクタリスティックが存在するなら
            for characteristic in characteristics {
                if characteristic.properties.contains(.read) || characteristic.properties.contains(.notify) {  //キャラクタリスティックの属性にreadとnotifyが含まれるのなら
                    characteristicData = characteristic
                    peripheral.readValue(for: characteristic)
                    peripheral.setNotifyValue(true, for: characteristic)  //任意のnotifyオン設定
                }
            }
        }
    }
    //キャラクタリスティックの値が変化したら、receivedDataに記録
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let value = characteristic.value {  //値が存在するなら
            isOpen = value.first == 1
        }
    }
    //Bool値をwrite
    func writeBoolValue(_ value: Bool, for characteristic: CBCharacteristic) {
        let data = Data([value ? 1 : 0])
        if let peripheral = connectedPeripheral {
            peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
        }
    }
    
}

