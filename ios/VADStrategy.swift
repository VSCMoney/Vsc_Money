import Foundation

protocol VADStrategy {
    func setup(sampleRate: SampleRate, frameSize: FrameSize, quality: VADQuality, silenceTriggerDurationMs: Int64, speechTriggerDurationMs: Int64)
    func checkVAD(pcm: [Int16], handler: @escaping (VADState) -> Void)
    func currentState() -> VADState
    
    // Additional methods for compatibility
    func startRecord(completion: @escaping (VADState) -> Void)
    func stop()
}

// Default implementations for compatibility
extension VADStrategy {
    func startRecord(completion: @escaping (VADState) -> Void) {
        // Default implementation using checkVAD
        // This can be overridden by specific strategies
    }
    
    func stop() {
        // Default stop implementation
    }
}
