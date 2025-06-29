//import Foundation
//
//// YamnetVADDelegate protocol
//protocol YamnetVADDelegate: AnyObject {
//    func yamnetVADDidDetectSpeechStart()
//    func yamnetVADDidDetectSpeechEnd()
//    func yamnetVADDidDetectSilence()
//    func yamnetVADDidDetectSpeeching()
//}
//
//// Basic YamnetVAD class
//class YamnetVADS {
//    weak var delegate: YamnetVADDelegate?
//    
//    private let sampleRate: Int64
//    private let sliceSize: Int64
//    private let threshold: Double
//    private let silenceTriggerDurationMs: Int64
//    private let speechTriggerDurationMs: Int64
//    
//    private var isDetecting = false
//    private var currentState: VADState = .silence
//    private var lastStateChangeTime: TimeInterval = 0
//    
//    init(sampleRate: Int64, sliceSize: Int64, threshold: Double, silenceTriggerDurationMs: Int64, speechTriggerDurationMs: Int64) {
//        self.sampleRate = sampleRate
//        self.sliceSize = sliceSize
//        self.threshold = threshold
//        self.silenceTriggerDurationMs = silenceTriggerDurationMs
//        self.speechTriggerDurationMs = speechTriggerDurationMs
//        
//        print("🔧 YamnetVAD initialized - SR: \(sampleRate), Slice: \(sliceSize), Threshold: \(threshold)")
//    }
//    
//    func predict(data: [Int16]) {
//        // Simulate VAD prediction
//        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
//            self?.processAudioData(data)
//        }
//    }
//    
//    private func processAudioData(_ data: [Int16]) {
//        // Calculate simple energy-based VAD
//        let energy = calculateEnergy(data: data)
//        let isVoiceDetected = energy > threshold
//        
//        let currentTime = Date().timeIntervalSince1970
//        
//        if isVoiceDetected && currentState == .silence {
//            // Potential speech start
//            if currentTime - lastStateChangeTime > Double(speechTriggerDurationMs) / 1000.0 {
//                currentState = .start
//                lastStateChangeTime = currentTime
//                DispatchQueue.main.async { [weak self] in
//                    self?.delegate?.yamnetVADDidDetectSpeechStart()
//                }
//            }
//        } else if isVoiceDetected && (currentState == .start || currentState == .speeching) {
//            // Continuing speech
//            if currentState != .speeching {
//                currentState = .speeching
//                DispatchQueue.main.async { [weak self] in
//                    self?.delegate?.yamnetVADDidDetectSpeeching()
//                }
//            }
//        } else if !isVoiceDetected && (currentState == .start || currentState == .speeching) {
//            // Potential speech end
//            if currentTime - lastStateChangeTime > Double(silenceTriggerDurationMs) / 1000.0 {
//                currentState = .end
//                lastStateChangeTime = currentTime
//                DispatchQueue.main.async { [weak self] in
//                    self?.delegate?.yamnetVADDidDetectSpeechEnd()
//                }
//                
//                // Transition to silence after a brief delay
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
//                    self?.currentState = .silence
//                    self?.delegate?.yamnetVADDidDetectSilence()
//                }
//            }
//        } else if !isVoiceDetected && currentState != .silence {
//            // Silence detected
//            currentState = .silence
//            lastStateChangeTime = currentTime
//            DispatchQueue.main.async { [weak self] in
//                self?.delegate?.yamnetVADDidDetectSilence()
//            }
//        }
//    }
//    
//    private func calculateEnergy(data: [Int16]) -> Double {
//        guard !data.isEmpty else {
//            print("[YamnetVAD] ⚠️ Received empty data array!")
//            return 0.0
//        }
//        let sum = data.reduce(0.0) { result, sample in
//            let sampleAsDouble = Double(sample)
//            return result + (sampleAsDouble * sampleAsDouble)
//        }
//        let energy = sum / Double(data.count)
//        print("[YamnetVAD] Calculated energy: \(energy)")
//        return energy
//    }
//
//
//    
//    func start() {
//        isDetecting = true
//        print("🎤 YamnetVAD started")
//    }
//    
//    func stop() {
//        isDetecting = false
//        currentState = .silence
//        print("🛑 YamnetVAD stopped")
//    }
//}
