//import Foundation
//import TensorFlowLite
//
//class YamnetVAD {
//    private var interpreter: Interpreter?
//    private var speechLabelIndex: Int = 0 // Usually 0
//    private let threshold: Float
//
//    init?(threshold: Float = 0.4) {
//        self.threshold = threshold
//
//        // Load model
//        guard let modelPath = Bundle.main.path(forResource: "yamnet", ofType: "tflite") else {
//            print("❌ yamnet.tflite not found")
//            return nil
//        }
//        do {
//            interpreter = try Interpreter(modelPath: modelPath)
//            try interpreter?.allocateTensors()
//            print("✅ YamnetVAD TFLite initialized")
//        } catch {
//            print("❌ Error: \(error)")
//            return nil
//        }
//    }
//
//    private func convertToFloat32(_ pcm: [Int16]) -> [Float32] {
//        return pcm.map { Float32($0) / 32768.0 }
//    }
//
//    func predict(pcm: [Int16]) -> Bool {
//        guard let interpreter = interpreter else { return false }
//        let floatData = convertToFloat32(pcm)
//        let wantedSize = 15600
//        let input: [Float32]
//        if floatData.count > wantedSize {
//            input = Array(floatData.prefix(wantedSize))
//        } else if floatData.count < wantedSize {
//            input = floatData + [Float32](repeating: 0, count: wantedSize - floatData.count)
//        } else {
//            input = floatData
//        }
//
//        // Convert [Float32] to Data for TensorFlowLite
//        let inputData = Data(buffer: UnsafeBufferPointer(start: input, count: input.count))
//        do {
//            try interpreter.copy(inputData, toInputAt: 0)
//            try interpreter.invoke()
//            let outputTensor = try interpreter.output(at: 0)
//            let outputData = outputTensor.data.toArray(type: Float32.self)
//            let labelCount = 521
//            var speechScores: [Float32] = []
//            let N = outputData.count / labelCount
//            for i in 0..<N {
//                let idx = i * labelCount + speechLabelIndex
//                speechScores.append(outputData[idx])
//            }
//            let avgSpeech = speechScores.reduce(0, +) / Float32(speechScores.count)
//            print("🟢 Yamnet speech score: \(avgSpeech)")
//            return avgSpeech > threshold
//        } catch {
//            print("❌ TFLite predict error: \(error)")
//            return false
//        }
//    }
//}
//
//// Helper extension for Data → [Float32]
//extension Data {
//    func toArray<T>(type: T.Type) -> [T] {
//        let count = self.count / MemoryLayout<T>.stride
//        return self.withUnsafeBytes { buf in
//            Array(buf.bindMemory(to: T.self))
//        }
//    }
//}





import Foundation
import TensorFlowLite

class YamnetVAD {
    private var interpreter: Interpreter?
    private var speechLabelIndex: Int = 0
    private let threshold: Float

    // ✅ Background queue for heavy operations
    private let processingQueue = DispatchQueue(label: "com.yourapp.yamnet", qos: .userInitiated)

    init?(threshold: Float = 0.4) {
        self.threshold = threshold

        // ✅ Load model on background thread (non-blocking)
        processingQueue.async { [weak self] in
            guard let self = self else { return }

            guard let modelPath = Bundle.main.path(forResource: "yamnet", ofType: "tflite") else {
                print("❌ yamnet.tflite not found")
                return
            }

            do {
                self.interpreter = try Interpreter(modelPath: modelPath)
                try self.interpreter?.allocateTensors()
                print("✅ YamnetVAD TFLite initialized on background thread")
            } catch {
                print("❌ Error initializing TFLite: \(error)")
            }
        }
    }

    private func convertToFloat32(_ pcm: [Int16]) -> [Float32] {
        return pcm.map { Float32($0) / 32768.0 }
    }

    // ✅ NEW: Async predict method (public API)
    func predict(pcm: [Int16], completion: @escaping (Bool) -> Void) {
        processingQueue.async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }

            // Run prediction on background queue
            let result = self.predictSync(pcm: pcm)

            // Return result on main thread
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }

    // ✅ PRIVATE: Synchronous prediction (runs on background queue only)
    private func predictSync(pcm: [Int16]) -> Bool {
        guard let interpreter = interpreter else {
            print("⚠️ Interpreter not ready yet")
            return false
        }

        let floatData = convertToFloat32(pcm)
        let wantedSize = 15600

        let input: [Float32]
        if floatData.count > wantedSize {
            input = Array(floatData.prefix(wantedSize))
        } else if floatData.count < wantedSize {
            input = floatData + [Float32](repeating: 0, count: wantedSize - floatData.count)
        } else {
            input = floatData
        }

        let inputData = Data(buffer: UnsafeBufferPointer(start: input, count: input.count))

        do {
            try interpreter.copy(inputData, toInputAt: 0)
            try interpreter.invoke()

            let outputTensor = try interpreter.output(at: 0)
            let outputData = outputTensor.data.toArray(type: Float32.self)
            let labelCount = 521

            var speechScores: [Float32] = []
            let N = outputData.count / labelCount

            for i in 0..<N {
                let idx = i * labelCount + speechLabelIndex
                speechScores.append(outputData[idx])
            }

            let avgSpeech = speechScores.reduce(0, +) / Float32(speechScores.count)
            print("🟢 Yamnet speech score: \(avgSpeech)")

            return avgSpeech > threshold
        } catch {
            print("❌ TFLite predict error: \(error)")
            return false
        }
    }
}

// Helper extension for Data → [Float32]
extension Data {
    func toArray<T>(type: T.Type) -> [T] {
        let count = self.count / MemoryLayout<T>.stride
        return self.withUnsafeBytes { buf in
            Array(buf.bindMemory(to: T.self))
        }
    }
}