//
//  ControlView.swift
//  lock
//
//  Created by Takayama on 2025/02/12.
//



import SwiftUI
import CoreBluetooth

struct ControlView: View {
    
    @State var isShowConnectView = false
    @ObservedObject var bleManager = BLEManager.shared
    
    var body: some View {
        VStack {
            
            Spacer()
            
            HStack{
                if let text = UserDefaults.standard.string(forKey: bleManager.PeripheralKey) {
                    Text("登録UUID：\(text)")
                    Button("記録を削除する"){
                        bleManager.deletePeripheralUUID()
                    }
                    .fontWeight(.bold)
                    .buttonStyle(.bordered)
                }
            }
            
            Spacer()
            
            
            VStack {
                
                HStack{
                    if !bleManager.isConnected {
                        Text("現在、接続されていません")
                            .font(.title)
                            .foregroundStyle(.blue)
                    }
                    else {
                        Image(systemName: bleManager.isOpen ? "lock.open" : "lock.fill")
                            .font(.largeTitle)
                        Text(bleManager.isOpen ? "解" : "施")
                            .font(.largeTitle)  // ラベルのフォントサイズを大きくする
                            .fontWeight(.heavy)
                            .foregroundStyle(bleManager.isOpen ? Color.mint : Color.red)
                        + Text("錠中")
                            .font(.largeTitle)  // ラベルのフォントサイズを大きくする
                            .fontWeight(.bold)
                            .foregroundStyle(Color.secondary)
                    }
                }
                
                
                ZStack {
                    RoundedRectangle(cornerRadius: 50)
                        .fill(bleManager.isOpen ? Color.green : Color.gray)
                        .frame(width: 200, height: 100)  // Toggleの大きさを変更
                        .animation(.easeInOut, value: bleManager.isOpen)
                    
                    if bleManager.isConnected {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 80, height: 80)  // トグルハンドルの大きさを変更
                            .offset(x: bleManager.isOpen ? 50 : -50)  // ハンドルの位置を調整
                            .animation(.easeInOut, value: bleManager.isOpen)
                            .gesture(
                                TapGesture()
                                    .onEnded {
                                        if bleManager.isConnected {
                                            bleManager.isOpen.toggle()
                                            sendLockState(value: bleManager.isOpen)
                                        }
                                    }
                            )
                        Text(bleManager.isOpen ? "閉じる" : "開く")
                            .font(.title)
                            .foregroundStyle(Color.white)
                            .offset(x: bleManager.isOpen ? -50 : 50)
                    }
                }
            }
            .padding()
            
            
            Spacer()
            
            
            HStack{
                Button(action: {
                    isShowConnectView = !bleManager.isConnected
                    if bleManager.isConnected{
                        bleManager.disconnectFromPeripheral()
                    }
                }){
                    Text(!bleManager.isConnected ? "接続する":"接続を解除する")
                        .font(.title)
                        .fontWeight(.bold)
                }
                .buttonStyle(.bordered)
                .sheet(isPresented: $isShowConnectView){
                    ConnectView()
                }
            }
            
            Spacer()
        }
    }
    
    
    //
    func sendLockState(value: Bool) {
        if let characteristic = bleManager.characteristicData {
            bleManager.writeBoolValue(bleManager.isOpen, for: characteristic)
        }
    }
    
    func sign(value: Double) -> Double {
        return abs(value)/value
    }
    
}



#Preview {
    ControlView()
}
