//
//  ContentView.swift
//  lock
//
//  Created by Takayama on 2025/02/08.
//


import SwiftUI

struct ContentView: View {
    
    @State var isShowControlView = false
    
    var body: some View {
        VStack {
            
            Spacer()
            
            Text("ロックシステム")
                .font(.largeTitle)
                .fontWeight(.black)
                .foregroundStyle(.blue)
            
            Spacer()
            
            Button("ここをタップしてスタート") {
                isShowControlView = true
            }
            .font(.title)
            .foregroundStyle(.blue)
            .buttonStyle(PlainButtonStyle())
            .fullScreenCover(isPresented: $isShowControlView){
                ControlView()
            }
            
            Spacer()
            
        }
    }
    
    
}



#Preview {
    ContentView()
}
