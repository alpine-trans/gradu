//
//  connectView.swift
//  controller
//
//  Created by Takayama on 2025/01/14.
//


import SwiftUI


struct connectView: View {
    @ObservedObject var bleManager = BLEManager.shared
    @State var messageAboutOff = ""
    
    var body: some View {
        VStack {
            Text("接続可能なデバイス")
                .font(.largeTitle)
                .foregroundStyle(.blue)
                .padding()
            
            Button(action: {
                if bleManager.isPoweredOn {
                    if bleManager.isScanning {
                        bleManager.stopScan()
                    }
                    else{
                        bleManager.startScan()
                    }
//                    bleManager.startScan()
                    messageAboutOff = ""
                }
                else{
                    messageAboutOff = "Bluetooth機能がオフになっているようです。"
                }
            }) {
                Text(bleManager.isScanning ? "検索の終了" : "デバイスの検索")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            Text(messageAboutOff)
                .font(.title3)
                .frame(width: 400, height: 50)
//                .border(Color.black,width: 2)
            
            List(bleManager.discoveredPeripherals, id: \.peripheral.identifier) { item in
                HStack {
                    Text(item.peripheral.name ?? "Unknown   ")
                    Text("   RSSI: \(item.rssi) dBm")
                    Spacer()
                    if bleManager.connectedPeripheral?.identifier == item.peripheral.identifier {
                        Text("接続完了")
                            .foregroundColor(.green)
                    }
                    else{
                        Button(action: {
                            bleManager.connectToPeripheral(item.peripheral)
                        }) {
                            Text("接続")
                                .padding()
                                .background(Color.gray)
                                .cornerRadius(5)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        }
        .padding()
    }
    
    
}


#Preview {
    connectView()
}
