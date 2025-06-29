//import Foundation
//import AVFoundation
//
//class YamnetVADStrategy: VADStrategy {
//    private var yamnetVAD: YamnetVADS?
//    private var state: VADState = .silence
//    private var handler: ((VADState) -> Void)?
//    private var sampleRate: Int = 0
//    private var audioEngine: AVAudioEngine?
//    private var inputNode: AVAudioInputNode?
//    private var isRecording = false
//    
//    func setup(sampleRate: SampleRate, frameSize: FrameSize, quality: VADQuality, silenceTriggerDurationMs: Int64, speechTriggerDurationMs: Int64) {
//        
//        // Validate and clamp values to prevent overflow
//        let clampedSampleRate = max(8000, min(48000, sampleRate.rawValue))
//        let clampedFrameSize = max(80, min(2048, frameSize.rawValue))
//        let clampedThreshold = max(0.1, min(500000.0, /* <-- yaha manually set kar */ 100000.0))
//        
//        print("🔧 Clamped values - SR: \(clampedSampleRate), FS: \(clampedFrameSize), Threshold: \(clampedThreshold)")
//        
//        self.sampleRate = clampedSampleRate
//        
//        // Safe YamnetVAD initialization with bounds checking
//        yamnetVAD = YamnetVADS(
//            sampleRate: Int64(clampedSampleRate),
//            sliceSize: Int64(clampedFrameSize),
//            threshold: clampedThreshold,
//            silenceTriggerDurationMs: max(100, min(5000, silenceTriggerDurationMs)),
//            speechTriggerDurationMs: max(10, min(1000, speechTriggerDurationMs))
//        )
//        yamnetVAD?.delegate = self
//        setupAudioSession()
//    }
//    
//    func checkVAD(pcm: [Int16], handler: @escaping (VADState) -> Void) {
//        self.handler = handler
//        yamnetVAD?.predict(data: pcm)
//    }
//    
//    func startRecord(completion: @escaping (VADState) -> Void) {
//        print("🎤 YamnetVADStrategy start recording")
//        self.handler = completion
//        startAudioEngine()
//    }
//    
//    func stop() {
//        print("🛑 YamnetVADStrategy stop")
//        stopAudioEngine()
//        handler = nil
//    }
//    
//    func currentState() -> VADState {
//        return state
//    }
//    
//    private func setupAudioSession() {
//        do {
//            let session = AVAudioSession.sharedInstance()
//            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
//            try session.setActive(true)
//        } catch {
//            print("❌ Failed to setup audio session: \(error)")
//        }
//    }
//    
//    private func startAudioEngine() {
//        audioEngine = AVAudioEngine()
//        inputNode = audioEngine?.inputNode
//        
//        guard let inputNode = inputNode else {
//            print("❌ Failed to get input node")
//            return
//        }
//        
//        let recordingFormat = inputNode.outputFormat(forBus: 0)
//        
//        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
//            self?.processAudioBuffer(buffer)
//        }
//        
//        do {
//            try audioEngine?.start()
//            isRecording = true
//            yamnetVAD?.start()
//            print("✅ Audio engine started")
//        } catch {
//            print("❌ Failed to start audio engine: \(error)")
//        }
//    }
//    
//    private func stopAudioEngine() {
//        audioEngine?.stop()
//        inputNode?.removeTap(onBus: 0)
//        audioEngine = nil
//        inputNode = nil
//        isRecording = false
//        yamnetVAD?.stop()
//    }
//    
//    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
//        guard let channelData = buffer.floatChannelData?[0] else { return }
//        let frameLength = Int(buffer.frameLength)
//        var int16Data: [Int16] = []
//        for i in 0..<frameLength {
//            let sample = channelData[i]
//            // Fix: Clamp between -1.0 and 1.0
//            let clamped = min(max(sample, -1.0), 1.0)
//            let int16Sample = Int16(clamped * 32767.0)
//            int16Data.append(int16Sample)
//        }
//        yamnetVAD?.predict(data: int16Data)
//    }
//}
//
//extension YamnetVADStrategy: YamnetVADDelegate {
//    func yamnetVADDidDetectSpeechStart() {
//        state = .start
//        handler?(.start)
//    }
//
//    func yamnetVADDidDetectSpeechEnd() {
//        state = .end
//        handler?(.end)
//    }
//
//    func yamnetVADDidDetectSilence() {
//        state = .silence
//        handler?(.silence)
//    }
//
//    func yamnetVADDidDetectSpeeching() {
//        state = .speeching
//        handler?(.speeching)
//    }
//}
