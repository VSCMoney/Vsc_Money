//
//
//
//
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
//    let modelSampleLength = 15600  // 0.975s @ 16kHz
//    var isRunning = false
//
//    // ✅ Background queue for audio processing
//    private let audioQueue = DispatchQueue(label: "com.yourapp.audioprocessing", qos: .userInitiated)
//
//    // ✅ Track if prediction is in progress (prevent queue buildup)
//    private var isPredicting = false
//
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
//        isPredicting = false
//
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
//        inputNode.installTap(onBus: 0, bufferSize: 64, format: hwFormat) { [weak self] (buffer, _) in
//            guard let self = self else { return }
//            guard let floatChannelData = buffer.floatChannelData else { return }
//
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
//            // RMS calculation (fast, keep in audio thread)
//            let rms: Float = mono.isEmpty ? 0 : sqrt(mono.reduce(0) { $0 + $1 * $1 } / Float(mono.count))
//
//            // ✅ ASYNC PREDICTION: Only if buffer is full AND no prediction in progress
//            if self.buffer.count >= self.modelSampleLength && !self.isPredicting {
//                let input = Array(self.buffer.prefix(self.modelSampleLength))
//                self.buffer.removeFirst(self.modelSampleLength / 4)
//
//                self.isPredicting = true
//
//                // ✅ Use async predict with completion handler (non-blocking)
//                self.vad?.predict(pcm: input) { [weak self] isSpeech in
//                    guard let self = self else { return }
//
//                    // ✅ Mark prediction complete
//                    self.isPredicting = false
//
//                    // Filter low RMS
//                    let isFinalSpeech = isSpeech && rms > 0.001
//
//                    // Send to Flutter on main thread
//                    DispatchQueue.main.async {
//                        self.eventSink?([
//                            "isSpeech": isFinalSpeech,
//                            "rms": rms
//                        ])
//                    }
//                }
//            } else if self.buffer.count < self.modelSampleLength {
//                // ✅ Still collecting samples - send RMS only
//                DispatchQueue.main.async {
//                    self.eventSink?([
//                        "isSpeech": false,
//                        "rms": rms
//                    ])
//                }
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
//    func stopYamnet() {
//        print("🛑 Stopping Yamnet VAD")
//        isRunning = false
//        isPredicting = false
//
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
    let modelSampleLength = 15600
    var isRunning = false

    private var isPredicting = false

    // ✅ Background queue for audio setup
    private let setupQueue = DispatchQueue(label: "com.yourapp.audiosetup", qos: .userInitiated)

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
            // ✅ Return immediately, do heavy work in background
            result("started")
            startYamnet()
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

        isRunning = true

        // ✅ Do ALL heavy setup on background queue
        setupQueue.async { [weak self] in
            guard let self = self else { return }

            print("🎯 Starting Yamnet VAD on background thread")

            self.vad = YamnetVAD(threshold: 0.4)
            self.buffer = []
            self.isPredicting = false

            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setCategory(.record)
                try audioSession.setActive(true)
            } catch {
                print("❌ Audio session error: \(error)")
                self.isRunning = false
                return
            }

            self.audioEngine = AVAudioEngine()
            guard let inputNode = self.audioEngine?.inputNode else {
                print("❌ No input node!")
                self.isRunning = false
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

                var mono: [Float] = []
                for i in 0..<frameLength {
                    var sum: Float = 0
                    for ch in 0..<channelCount {
                        sum += floatChannelData[ch][i]
                    }
                    mono.append(sum / Float(channelCount))
                }

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

                let rms: Float = mono.isEmpty ? 0 : sqrt(mono.reduce(0) { $0 + $1 * $1 } / Float(mono.count))

                if self.buffer.count >= self.modelSampleLength && !self.isPredicting {
                    let input = Array(self.buffer.prefix(self.modelSampleLength))
                    self.buffer.removeFirst(self.modelSampleLength / 4)

                    self.isPredicting = true

                    self.vad?.predict(pcm: input) { [weak self] isSpeech in
                        guard let self = self else { return }

                        self.isPredicting = false

                        let isFinalSpeech = isSpeech && rms > 0.001

                        DispatchQueue.main.async {
                            self.eventSink?([
                                "isSpeech": isFinalSpeech,
                                "rms": rms
                            ])
                        }
                    }
                } else if self.buffer.count < self.modelSampleLength {
                    DispatchQueue.main.async {
                        self.eventSink?([
                            "isSpeech": false,
                            "rms": rms
                        ])
                    }
                }
            }

            self.audioEngine?.prepare()
            do {
                try self.audioEngine?.start()
                print("✅ Audio engine started on background thread")
            } catch {
                print("❌ Failed to start engine: \(error)")
                self.isRunning = false
            }
        }
    }

    func stopYamnet() {
        print("🛑 Stopping Yamnet VAD")
        isRunning = false
        isPredicting = false

        if let engine = audioEngine {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
        }
        audioEngine = nil
        vad = nil
        buffer = []
    }
}