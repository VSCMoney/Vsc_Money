//import Foundation
//import AVFoundation
//
//class OpenMicProvider {
//    static let shared = OpenMicProvider()
//
//    private var vad: YamnetVAD?
//    private var audioEngine: AVAudioEngine?
//    private var buffer: [Int16] = []
//    private let modelSampleLength = 15600 // Yamnet expects 15600 samples @ 16kHz
//
//    private var isRecording = false
//
//    private init() {}
//
//    func startRecord(
//        type: VADType,
//        sampleRate: SampleRate,
//        frameSize: FrameSize,
//        quality: VADQuality,
//        completion: @escaping (VADState) -> Void
//    ) {
//        print("🎤 OpenMicProvider startRecord - Yamnet TFLite only")
//
//        // Only support Yamnet
//        guard type == .yamnet else {
//            print("⚠️ Only Yamnet VAD is supported")
//            return
//        }
//        guard sampleRate.rawValue > 0 && sampleRate.rawValue < 100_000 else {
//            print("❌ Invalid sample rate: \(sampleRate.rawValue)")
//            return
//        }
//        guard frameSize.rawValue > 0 && frameSize.rawValue < 100_000 else {
//            print("❌ Invalid frame size: \(frameSize.rawValue)")
//            return
//        }
//
//        vad = YamnetVAD(threshold: 0.4) // threshold tune as needed
//        buffer = []
//
//        audioEngine = AVAudioEngine()
//        guard let inputNode = audioEngine?.inputNode else {
//            print("❌ Failed to get input node")
//            return
//        }
//        let format = inputNode.outputFormat(forBus: 0)
//        inputNode.installTap(onBus: 0, bufferSize: AVAudioFrameCount(frameSize.rawValue), format: format) { [weak self] (buffer, _) in
//            guard let self = self else { return }
//            let floatData = buffer.floatChannelData?[0]
//            let frameLength = Int(buffer.frameLength)
//            guard let channel = floatData else { return }
//            for i in 0..<frameLength {
//                let clamped = min(max(channel[i], -1.0), 1.0)
//                let sample = Int16(clamped * 32767.0)
//                self.buffer.append(sample)
//            }
//            // Once enough for Yamnet model, predict!
//            if self.buffer.count >= self.modelSampleLength {
//                let input = Array(self.buffer.prefix(self.modelSampleLength))
//                let isSpeech = self.vad?.predict(pcm: input) ?? false
//                DispatchQueue.main.async {
//                    if isSpeech {
//                        completion(.speeching)
//                    } else {
//                        completion(.silence)
//                    }
//                }
//                // Sliding window: 50% overlap for smooth detection
//                self.buffer.removeFirst(self.modelSampleLength / 2)
//            }
//        }
//        audioEngine?.prepare()
//        do {
//            try audioEngine?.start()
//            isRecording = true
//            print("✅ Audio engine started")
//        } catch {
//            print("❌ Failed to start audio engine: \(error)")
//        }
//    }
//
//    func stopRecord() {
//        print("🛑 OpenMicProvider stopRecord")
//        audioEngine?.stop()
//        audioEngine?.inputNode.removeTap(onBus: 0)
//        audioEngine = nil
//        vad = nil
//        buffer = []
//        isRecording = false
//    }
//
//    func isCurrentlyRecording() -> Bool {
//        return isRecording
//    }
//}




import Foundation
import AVFoundation

class OpenMicProvider {
    static let shared = OpenMicProvider()

    private var vad: YamnetVAD?
    private var audioEngine: AVAudioEngine?
    private var buffer: [Int16] = []
    private let modelSampleLength = 15600 // Yamnet expects 15600 samples @ 16kHz

    private var isRecording = false

    // ✅ Track if prediction is in progress
    private var isPredicting = false

    private init() {}

    func startRecord(
        type: VADType,
        sampleRate: SampleRate,
        frameSize: FrameSize,
        quality: VADQuality,
        completion: @escaping (VADState) -> Void
    ) {
        print("🎤 OpenMicProvider startRecord - Yamnet TFLite only")

        // Only support Yamnet
        guard type == .yamnet else {
            print("⚠️ Only Yamnet VAD is supported")
            return
        }
        guard sampleRate.rawValue > 0 && sampleRate.rawValue < 100_000 else {
            print("❌ Invalid sample rate: \(sampleRate.rawValue)")
            return
        }
        guard frameSize.rawValue > 0 && frameSize.rawValue < 100_000 else {
            print("❌ Invalid frame size: \(frameSize.rawValue)")
            return
        }

        vad = YamnetVAD(threshold: 0.4)
        buffer = []
        isPredicting = false

        audioEngine = AVAudioEngine()
        guard let inputNode = audioEngine?.inputNode else {
            print("❌ Failed to get input node")
            return
        }
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: AVAudioFrameCount(frameSize.rawValue), format: format) { [weak self] (buffer, _) in
            guard let self = self else { return }
            let floatData = buffer.floatChannelData?[0]
            let frameLength = Int(buffer.frameLength)
            guard let channel = floatData else { return }

            for i in 0..<frameLength {
                let clamped = min(max(channel[i], -1.0), 1.0)
                let sample = Int16(clamped * 32767.0)
                self.buffer.append(sample)
            }

            // ✅ ASYNC PREDICTION: Only if enough buffer AND not already predicting
            if self.buffer.count >= self.modelSampleLength && !self.isPredicting {
                let input = Array(self.buffer.prefix(self.modelSampleLength))
                self.buffer.removeFirst(self.modelSampleLength / 2)

                self.isPredicting = true

                // ✅ Use async predict with completion handler
                self.vad?.predict(pcm: input) { [weak self] isSpeech in
                    guard let self = self else { return }

                    self.isPredicting = false

                    DispatchQueue.main.async {
                        if isSpeech {
                            completion(.speeching)
                        } else {
                            completion(.silence)
                        }
                    }
                }
            }
        }

        audioEngine?.prepare()
        do {
            try audioEngine?.start()
            isRecording = true
            print("✅ Audio engine started")
        } catch {
            print("❌ Failed to start audio engine: \(error)")
        }
    }

    func stopRecord() {
        print("🛑 OpenMicProvider stopRecord")
        isRecording = false
        isPredicting = false

        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil
        vad = nil
        buffer = []
    }

    func isCurrentlyRecording() -> Bool {
        return isRecording
    }
}