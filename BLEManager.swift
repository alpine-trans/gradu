//
//  bleclass.swift
//  controller
//
//  Created by Takayama on 2025/01/14.
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
    @Published var receivedData: String = ""
    
    //初期
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    //接続
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
    //任意のペリフェラルと接続
    func connectToPeripheral(_ peripheral: CBPeripheral) {
        centralManager.stopScan()  //スキャン停止
        centralManager.connect(peripheral, options: nil)  //接続
    }
    //ペリフェラルとの接続を解除
    func disconnectFromPeripheral() {
        if let peripheral = connectedPeripheral {  //connectedPeripheralがnilでないなら
            centralManager.cancelPeripheralConnection(peripheral)  //接続解除
        }
    }
    //接続状態(電源のオンオフ等)が変化したら、
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        isPoweredOn = central.state == .poweredOn
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
    //ペリフェラルと接続したら、サービスの検索
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectedPeripheral = peripheral  //接続したペリフェラルを記録
        peripheral.delegate = self
        peripheral.discoverServices(nil)  //サービスの検索
        isConnected = true
    }
    //ペリフェラルと接続を絶ったら、
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectedPeripheral = nil  //接続していたペリフェラルを削除
        isConnected = false
    }
    
    //通信
    //サービスを発見したら、キャラクタリスティックを検索
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?){
        if let services = peripheral.services {  //Serviceが存在するなら
            for service in services {
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
                    peripheral.setNotifyValue(true, for: characteristic)  //任意のnotifyオン設定
                }
            }
        }
    }
    //キャラクタリスティックの値が変化したら、receivedDataに記録
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let value = characteristic.value, let string = String(data: value, encoding: .utf8) {  //値が存在するなら
            receivedData = string
        }
    }
    //値をwrite
    func writeValue(_ values: [Float], for characteristic: CBCharacteristic) {
        var data = Data()
        for value in values {
            withUnsafeBytes(of: value) { valueBytes in
                data.append(contentsOf: valueBytes)
            }
        }
        if let peripheral = connectedPeripheral {
            peripheral.writeValue(data, for: characteristic, type: .withoutResponse)  //write
        }
    }
    
}

