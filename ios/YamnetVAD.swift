import Foundation
import TensorFlowLite

class YamnetVAD {
    private var interpreter: Interpreter?
    private var speechLabelIndex: Int = 0 // Usually 0
    private let threshold: Float

    init?(threshold: Float = 0.4) {
        self.threshold = threshold

        // Load model
        guard let modelPath = Bundle.main.path(forResource: "yamnet", ofType: "tflite") else {
            print("❌ yamnet.tflite not found")
            return nil
        }
        do {
            interpreter = try Interpreter(modelPath: modelPath)
            try interpreter?.allocateTensors()
            print("✅ YamnetVAD TFLite initialized")
        } catch {
            print("❌ Error: \(error)")
            return nil
        }
    }

    private func convertToFloat32(_ pcm: [Int16]) -> [Float32] {
        return pcm.map { Float32($0) / 32768.0 }
    }

    func predict(pcm: [Int16]) -> Bool {
        guard let interpreter = interpreter else { return false }
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

        // Convert [Float32] to Data for TensorFlowLite
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
