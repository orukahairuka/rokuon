import SwiftUI
import Combine


struct ContentView: View {
    @StateObject private var audioToInstrument = AudioToInstrument()
    @State private var isRunning = false

    var body: some View {
        VStack(spacing: 20) {
            Text("🎵 オブジェクトバンド")
                .font(.largeTitle)
                .bold()

            Text("現在の周波数: \(Int(audioToInstrument.detectedPitch)) Hz")
                .font(.headline)
                .foregroundColor(.blue)

            HStack {
                Button(action: {
                    if isRunning {
                        audioToInstrument.stop()
                    } else {
                        audioToInstrument.start()
                    }
                    isRunning.toggle()
                }) {
                    Text(isRunning ? "停止" : "開始")
                        .font(.title)
                        .frame(width: 120, height: 50)
                        .background(isRunning ? Color.red : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
    }
}


