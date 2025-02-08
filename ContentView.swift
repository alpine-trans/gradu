//
//  ContentView.swift
//  controller
//
//  Created by Takayama on 2025/01/08.
//

import SwiftUI
import CoreBluetooth

struct ContentView: View {
    @State private var stickPosition = CGSize.zero
    @State private var sliderPosition = 0.0
    let dragLimit: CGFloat = 75.0
    let slideLimit = 120.0
    
    @State var isShowConnectView = false
    @ObservedObject var bleManager = BLEManager()
    
    var body: some View {
        VStack {
            Spacer()
            
            Text("Controller")
                .font(.largeTitle)
                .foregroundStyle(.blue)
            
            Spacer()
            
            ZStack{
                Circle()
                    .fill(.gray)
                    .frame(width: 150, height: 150)
                Circle()
                    .fill(.blue)
                    .frame(width: 50, height: 50)
                    .offset(x:stickPosition.width , y: stickPosition.height)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let tmp = value.translation
                                let Edistance = sqrt(pow(tmp.width,2)+pow(tmp.height,2))
                                if Edistance <= dragLimit{
                                    self.stickPosition = value.translation
                                }
                                else{
                                    self.stickPosition = CGSize(
                                        width: tmp.width*dragLimit/Edistance,
                                        height: tmp.height*dragLimit/Edistance
                                    )
                                }
                                sendCoordinates()
                            }
                            .onEnded{ _ in
                                withAnimation(.spring()){
                                    self.stickPosition = .zero
                                }
                            }
                    )
            }
            Text("stick   x: \(stickPosition.width/dragLimit), y: \(stickPosition.height/dragLimit)")
                .padding()
            
            Spacer()
            
            ZStack{
                Rectangle()
                    .fill(.gray)
                    .frame(width: 240, height: 10)
                    .cornerRadius(10)
                Circle()
                    .fill(.blue)
                    .frame(width: 50, height: 50)
                    .offset(x: sliderPosition)
                    .gesture(
                        DragGesture()
                            .onChanged{ value in
                                self.sliderPosition = min(abs(value.translation.width),slideLimit)*sign(value:value.translation.width)
                                sendCoordinates()
                            }
                            .onEnded{ _ in
                                withAnimation(.spring()){
                                    self.sliderPosition = .zero
                                }
                            }
                    )
            }
            Text("slider   \(sliderPosition/slideLimit)")
                .padding()
            
            Spacer()
            
            HStack{
                Button(action: {
                    isShowConnectView = !bleManager.isConnected
                    if !bleManager.isConnected{
                        bleManager.disconnectFromPeripheral()
                    }
                }){
                    Text(!bleManager.isConnected ? "接続する":"接続を解除する")
                        .font(.title)
                }
                .buttonStyle(.bordered)
                .sheet(isPresented: $isShowConnectView){
                    connectView()
                }
            }
            
            Spacer()
        }
    }
    
        
    //
    func sendCoordinates() {
        let coordinates = [Float(stickPosition.width),Float(stickPosition.height),Float(sliderPosition)]
        if let characteristic = bleManager.characteristicData {
            bleManager.writeValue(coordinates, for: characteristic)
        }
    }
    
    func sign(value: Double) -> Double {
        return abs(value)/value
    }
    
}


#Preview {
    ContentView()
}
