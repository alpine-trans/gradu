import SwiftUI

struct LargeToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack {
            configuration.label
                .font(.largeTitle)  // ラベルのフォントサイズを大きくする
                .fontWeight(.heavy)
            
            
            ZStack {
                RoundedRectangle(cornerRadius: 50)
                    .fill(configuration.isOn ? Color.green : Color.gray)
                    .frame(width: 200, height: 100)  // Toggleの大きさを変更
                    .animation(.easeInOut, value: configuration.isOn)
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 80, height: 80)  // トグルハンドルの大きさを変更
                    .offset(x: configuration.isOn ? 50 : -50)  // ハンドルの位置を調整
                    .animation(.easeInOut, value: configuration.isOn)
                    .gesture(
                        TapGesture()
                            .onEnded {
                                configuration.isOn.toggle()
                            }
                    )
                Text(configuration.isOn ? "閉じる" : "開く")
                    .font(.title)
                    .foregroundStyle(Color.white)
                    .offset(x: configuration.isOn ? -50 : 50)
            }
        }
        .padding()
    }
}

struct CoontentView: View {
    @State private var isOpen = false
    
    var body: some View {
        Toggle(isOn: $isOpen) {
            Text(isOpen ? "解錠中" : "施錠中")
        }
        .toggleStyle(LargeToggleStyle())
        .padding()
    }
}

struct CoontentView_Previews: PreviewProvider {
    static var previews: some View {
        CoontentView()
    }
}
