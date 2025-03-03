import SwiftUI
import Combine

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


import AudioKit
import AudioKitUI
import AVFoundation

import AudioKit
import AudioKitUI
import AVFoundation

class AudioAnalyzer: ObservableObject {
    private var engine = AudioEngine()
    private var mic: AudioEngine.InputNode?
    private var tracker: PitchTap!
    private var mixer = Mixer()
    private let smoother = FrequencySmoother()  // スムージング用
    private var synthesizer: SoundSynthesizer

    @Published var detectedPitch: Float = 0.0

    init(synth: SoundSynthesizer) {
        synthesizer = synth

        guard let input = engine.input else {
            fatalError("❌ マイク入力が取得できません。`NSMicrophoneUsageDescription` を `Info.plist` に追加しましたか？")
        }
        mic = input
        engine.output = mixer

        // ✅ マイクのサンプルレートを取得し統一
        let sampleRate = AVAudioSession.sharedInstance().sampleRate
        print("🎤 マイクのサンプルレート: \(sampleRate) Hz")

        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                   sampleRate: sampleRate,  // ✅ 48000Hzに統一
                                   channels: 1,
                                   interleaved: false)

        // ✅ `installTap` のサンプルレートを統一
        input.avAudioNode.installTap(onBus: 0, bufferSize: 1024, format: format) { _, _ in }

        // ✅ `PitchTap` のフォーマットをマイクと統一
        tracker = PitchTap(input) { pitch, amplitudes in
            DispatchQueue.main.async {
                let detected = pitch.first ?? 0.0
                let amplitude = amplitudes.first ?? 0.0

                if detected > 80 && detected < 1000 && amplitude > 0.01 {
                    let smoothedFreq = self.smoother.smooth(detected)
                    self.detectedPitch = smoothedFreq
                    self.synthesizer.updateFrequency(smoothedFreq)
                    print("🎵 リアルタイム周波数: \(smoothedFreq) Hz, 音量: \(amplitude)")
                }
            }
        }
    }

    func start() {
        do {
            try engine.start()
            tracker.start()
            print("🎤 マイク入力 & ピッチ検出開始")
        } catch {
            print("❌ AudioEngine の起動に失敗: \(error.localizedDescription)")
        }
    }

    func stop() {
        tracker.stop()
        engine.stop()
    }
}

import AudioKit
import SoundpipeAudioKit
import AVFoundation

class SoundSynthesizer: ObservableObject {
    private var engine = AudioEngine()
    private var oscillator: DynamicOscillator

    init() {
        oscillator = DynamicOscillator()
        oscillator.amplitude = 0.3  // 音量調整
        engine.output = oscillator
    }

    func updateFrequency(_ frequency: Float) {
        DispatchQueue.main.async {
            if frequency > 80 && frequency < 1000 {  // ノイズ除去
                self.oscillator.frequency = frequency
            }
        }
    }

    func start() {
        do {
            try engine.start()
            oscillator.start()
        } catch {
            print("❌ AudioEngine の起動に失敗: \(error.localizedDescription)")
        }
    }

    func stop() {
        oscillator.stop()
        engine.stop()
    }
}

class FrequencySmoother {
    private var lastFrequency: Float = 440.0
    private let smoothingFactor: Float = 0.1  // 0.1 〜 0.3 くらいで調整

    func smooth(_ newFrequency: Float) -> Float {
        lastFrequency = (smoothingFactor * newFrequency) + ((1 - smoothingFactor) * lastFrequency)
        return lastFrequency
    }
}

import AudioKit
import Combine

class AudioToInstrument: ObservableObject {
    let analyzer: AudioAnalyzer
    private let synthesizer: SoundSynthesizer
    private var cancellables = Set<AnyCancellable>()

    @Published var detectedPitch: Float = 0.0

    init() {
        self.synthesizer = SoundSynthesizer()
        self.analyzer = AudioAnalyzer(synth: synthesizer)

        analyzer.$detectedPitch
            .sink { pitch in
                if pitch > 50 {  // 低すぎるノイズは無視
                    self.synthesizer.updateFrequency(pitch)
                }
            }
            .store(in: &cancellables)
    }

    func start() {
        analyzer.start()
        synthesizer.start()
    }

    func stop() {
        analyzer.stop()
        synthesizer.stop()
    }
}
