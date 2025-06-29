//import Flutter
//import AVFoundation
//
//@objc public class YamnetVADBridge: NSObject, FlutterPlugin, FlutterStreamHandler {
//    var methodChannel: FlutterMethodChannel?
//    var eventSink: FlutterEventSink?
//
//    var audioEngine: AVAudioEngine?
//    var vad: YamnetVAD?
//    var buffer: [Int16] = []
//    let modelSampleLength = 15600  // Yamnet wants 15600 samples @16kHz
//    var isRunning = false
//
//    // MARK: - Plugin registration
//    public static func register(with registrar: FlutterPluginRegistrar) {
//        let methodChannel = FlutterMethodChannel(name: "yamnet_channel", binaryMessenger: registrar.messenger())
//        let eventChannel = FlutterEventChannel(name: "yamnet_event_channel", binaryMessenger: registrar.messenger())
//
//        let instance = YamnetVADBridge()
//        instance.methodChannel = methodChannel
//
//        registrar.addMethodCallDelegate(instance, channel: methodChannel)
//        eventChannel.setStreamHandler(instance)
//    }
//
//    // MARK: - Handle Flutter method calls
//    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
//        switch call.method {
//        case "start":
//            startYamnet()
//            result("started")
//        case "stop":
//            stopYamnet()
//            result("stopped")
//        default:
//            result(FlutterMethodNotImplemented)
//        }
//    }
//
//    // MARK: - EventChannel handlers
//    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
//        print("📡 EventChannel attached")
//        self.eventSink = events
//        return nil
//    }
//
//    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
//        print("❌ EventChannel detached")
//        self.eventSink = nil
//        return nil
//    }
//
//    // MARK: - Start Yamnet VAD
//    func startYamnet() {
//        if isRunning {
//            print("⚠️ Already running!")
//            return
//        }
//
//        print("🎯 Starting Yamnet VAD")
//        vad = YamnetVAD(threshold: 0.4)
//        buffer = []
//        isRunning = true
//
//        // Audio session
//        let audioSession = AVAudioSession.sharedInstance()
//        do {
//            try audioSession.setCategory(.record)
//            try audioSession.setActive(true)
//        } catch {
//            print("❌ Audio session error: \(error)")
//            isRunning = false
//            return
//        }
//
//        // Audio engine
//        audioEngine = AVAudioEngine()
//        guard let inputNode = audioEngine?.inputNode else {
//            print("❌ No input node!")
//            isRunning = false
//            return
//        }
//
//        let hwFormat = inputNode.inputFormat(forBus: 0)
//        let hwSampleRate = Int(hwFormat.sampleRate)
//        let wantedSampleRate = 16000
//
//        inputNode.installTap(onBus: 0, bufferSize: 1024, format: hwFormat) { [weak self] (buffer, _) in
//            guard let self = self else { return }
//
//            guard let floatChannelData = buffer.floatChannelData else { return }
//            let channelCount = Int(hwFormat.channelCount)
//            let frameLength = Int(buffer.frameLength)
//
//            // Downmix to mono
//            var mono: [Float] = []
//            for i in 0..<frameLength {
//                var sum: Float = 0
//                for ch in 0..<channelCount {
//                    sum += floatChannelData[ch][i]
//                }
//                mono.append(sum / Float(channelCount))
//            }
//
//            // Downsample to 16kHz
//            let downsampleFactor = Double(hwSampleRate) / Double(wantedSampleRate)
//            var downsampled: [Int16] = []
//            var idx = 0.0
//            while Int(idx) < mono.count {
//                let sample = mono[Int(idx)]
//                let clamped = min(max(sample, -1.0), 1.0)
//                downsampled.append(Int16(clamped * 32767.0))
//                idx += downsampleFactor
//            }
//
//            self.buffer.append(contentsOf: downsampled)
//
//            // RMS calculation
//            let rms: Float = mono.isEmpty ? 0 : sqrt(mono.reduce(0) { $0 + $1 * $1 } / Float(mono.count))
//
//            // Prediction
//            if self.buffer.count >= self.modelSampleLength {
//                let input = Array(self.buffer.prefix(self.modelSampleLength))
//                let isSpeech = self.vad?.predict(pcm: input) ?? false
//
//                DispatchQueue.main.async {
//                    self.eventSink?([
//                        "state": isSpeech ? "speech_detected" : "silence",
//                        "confidence": isSpeech ? 1.0 : 0.0,
//                        "timestamp": Date().timeIntervalSince1970,
//                        "vadType": "yamnet",
//                        "rms": rms
//                    ])
//                }
//
//                self.buffer.removeFirst(self.modelSampleLength / 2)
//            }
//        }
//
//        audioEngine?.prepare()
//        do {
//            try audioEngine?.start()
//            print("✅ Audio engine started")
//        } catch {
//            print("❌ Failed to start engine: \(error)")
//            isRunning = false
//        }
//    }
//
//    // MARK: - Stop Yamnet
//    func stopYamnet() {
//        print("🛑 Stopping Yamnet VAD")
//        isRunning = false
//        if let engine = audioEngine {
//            engine.stop()
//            engine.inputNode.removeTap(onBus: 0)
//        }
//        audioEngine = nil
//        vad = nil
//        buffer = []
//    }
//}







import Flutter
import AVFoundation

@objc public class YamnetVADBridge: NSObject, FlutterPlugin, FlutterStreamHandler {
    var methodChannel: FlutterMethodChannel?
    var eventSink: FlutterEventSink?

    var audioEngine: AVAudioEngine?
    var vad: YamnetVAD?
    var buffer: [Int16] = []
    let modelSampleLength = 15600  // 0.975s @ 16kHz
    var isRunning = false

    public static func register(with registrar: FlutterPluginRegistrar) {
        let methodChannel = FlutterMethodChannel(name: "yamnet_channel", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "yamnet_event_channel", binaryMessenger: registrar.messenger())

        let instance = YamnetVADBridge()
        instance.methodChannel = methodChannel

        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        eventChannel.setStreamHandler(instance)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "start":
            startYamnet()
            result("started")
        case "stop":
            stopYamnet()
            result("stopped")
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        print("📡 EventChannel attached")
        self.eventSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        print("❌ EventChannel detached")
        self.eventSink = nil
        return nil
    }

    func startYamnet() {
        if isRunning {
            print("⚠️ Already running!")
            return
        }

        print("🎯 Starting Yamnet VAD")
        vad = YamnetVAD(threshold: 0.4)
        buffer = []
        isRunning = true

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record)
            try audioSession.setActive(true)
        } catch {
            print("❌ Audio session error: \(error)")
            isRunning = false
            return
        }

        audioEngine = AVAudioEngine()
        guard let inputNode = audioEngine?.inputNode else {
            print("❌ No input node!")
            isRunning = false
            return
        }

        let hwFormat = inputNode.inputFormat(forBus: 0)
        let hwSampleRate = Int(hwFormat.sampleRate)
        let wantedSampleRate = 16000

        inputNode.installTap(onBus: 0, bufferSize: 64, format: hwFormat) { [weak self] (buffer, _) in
            guard let self = self else { return }
            guard let floatChannelData = buffer.floatChannelData else { return }

            let channelCount = Int(hwFormat.channelCount)
            let frameLength = Int(buffer.frameLength)

            // Downmix to mono
            var mono: [Float] = []
            for i in 0..<frameLength {
                var sum: Float = 0
                for ch in 0..<channelCount {
                    sum += floatChannelData[ch][i]
                }
                mono.append(sum / Float(channelCount))
            }

            // Downsample to 16kHz
            let downsampleFactor = Double(hwSampleRate) / Double(wantedSampleRate)
            var downsampled: [Int16] = []
            var idx = 0.0
            while Int(idx) < mono.count {
                let sample = mono[Int(idx)]
                let clamped = min(max(sample, -1.0), 1.0)
                downsampled.append(Int16(clamped * 32767.0))
                idx += downsampleFactor
            }

            self.buffer.append(contentsOf: downsampled)

            // RMS calculation
            let rms: Float = mono.isEmpty ? 0 : sqrt(mono.reduce(0) { $0 + $1 * $1 } / Float(mono.count))

            // Do speech prediction only if enough buffer
            var isSpeech = false
            if self.buffer.count >= self.modelSampleLength {
                let input = Array(self.buffer.prefix(self.modelSampleLength))
                isSpeech = self.vad?.predict(pcm: input) ?? false
                self.buffer.removeFirst(self.modelSampleLength / 4)
            }

            // Filter low RMS
            let isFinalSpeech = isSpeech && rms > 0.001

            DispatchQueue.main.async {
                self.eventSink?([
                    "isSpeech": isFinalSpeech,
                    "rms": rms
                ])
            }
        }

        audioEngine?.prepare()
        do {
            try audioEngine?.start()
            print("✅ Audio engine started")
        } catch {
            print("❌ Failed to start engine: \(error)")
            isRunning = false
        }
    }

    func stopYamnet() {
        print("🛑 Stopping Yamnet VAD")
        isRunning = false
        if let engine = audioEngine {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
        }
        audioEngine = nil
        vad = nil
        buffer = []
    }
}
