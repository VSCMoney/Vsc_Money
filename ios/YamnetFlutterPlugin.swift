//import Foundation
//import UIKit
//import AVFoundation
//
//// Method Channel Implementation without OpenMicProvider
//@objc public class YAMNetPlugin: NSObject {
//    private var yamnetStrategy: YamnetVADStrategy?
//    private var isRecording = false
//    private var methodChannel: Any?
//
//    @objc public static func register(with registrar: Any) {
//        guard let flutterRegistrar = registrar as? NSObjectProtocol else {
//            print("❌ Invalid registrar")
//            return
//        }
//
//        // Create method channel using reflection safely
//        let binaryMessengerSelector = NSSelectorFromString("messenger")
//        guard flutterRegistrar.responds(to: binaryMessengerSelector),
//              let binaryMessenger = flutterRegistrar.perform(binaryMessengerSelector)?.takeUnretainedValue() else {
//            print("❌ Failed to get binary messenger")
//            return
//        }
//
//        guard let channelClass = NSClassFromString("FlutterMethodChannel") as? NSObject.Type else {
//            print("❌ FlutterMethodChannel class not found")
//            return
//        }
//
//        let channelSelector = NSSelectorFromString("methodChannelWithName:binaryMessenger:")
//        guard channelClass.responds(to: channelSelector),
//              let channel = channelClass.perform(channelSelector, with: "yamnet_channel", with: binaryMessenger)?.takeUnretainedValue() else {
//            print("❌ Failed to create method channel")
//            return
//        }
//
//        let instance = YAMNetPlugin()
//        instance.methodChannel = channel
//
//        // Set method call handler
//        let setHandlerSelector = NSSelectorFromString("setMethodCallHandler:")
//        if let channelObject = channel as? NSObject, channelObject.responds(to: setHandlerSelector) {
//            _ = channelObject.perform(setHandlerSelector, with: instance.handleMethodCall)
//            print("✅ YAMNetPlugin registered successfully")
//        } else {
//            print("❌ Failed to set method call handler")
//        }
//    }
//
//    @objc private func handleMethodCall(_ call: Any, result: @escaping (Any?) -> Void) {
//        guard let methodCall = call as? NSObject,
//              let method = methodCall.value(forKey: "method") as? String else {
//            result("FlutterMethodNotImplemented")
//            return
//        }
//
//        switch method {
//        case "startYAMNet":
//            let startResult = startYAMNet()
//            result(startResult)
//        case "stopYAMNet":
//            let stopResult = stopYAMNet()
//            result(stopResult)
//        case "checkPermission":
//            let permissionResult = checkPermission()
//            result(permissionResult)
//        default:
//            result("FlutterMethodNotImplemented")
//        }
//    }
//
//    @objc public func startYAMNet() -> String {
//        print("🎯 Starting YAMNet...")
//
//        // Check microphone permission
//        let permission = AVAudioSession.sharedInstance().recordPermission
//        guard permission == .granted else {
//            return "Permission denied"
//        }
//
//        // Use YAMNet-only OpenMicProvider
//        OpenMicProvider.shared.startRecord(
//            type: .yamnet,               // Only YAMNet
//            sampleRate: .rate_15K,       // YAMNet sample rate
//            frameSize: .size_15600,      // YAMNet frame size
//            quality: VADQuality.allCases.first!, // First available quality
//            completion: { [weak self] vadState in
//                self?.handleVADResult(vadState)
//            }
//        )
//
//        isRecording = true
//        return "YAMNet started successfully"
//    }
//
//    @objc public func stopYAMNet() -> String {
//        print("🛑 Stopping YAMNet...")
//        yamnetStrategy?.stop()
//        yamnetStrategy = nil
//        isRecording = false
//        return "YAMNet stopped"
//    }
//
//    @objc public func checkPermission() -> String {
//        let permission = AVAudioSession.sharedInstance().recordPermission
//        switch permission {
//        case .granted:
//            return "granted"
//        case .denied:
//            return "denied"
//        case .undetermined:
//            return "undetermined"
//        @unknown default:
//            return "unknown"
//        }
//    }
//
//    private func handleVADResult(_ vadState: VADState) {
//        guard isRecording else { return }
//
//        let stateString: String
//        switch vadState {
//        case .start:
//            stateString = "speech_start"
//        case .speeching:
//            stateString = "speech_detected"
//        case .end:
//            stateString = "speech_end"
//        case .silence:
//            stateString = "silence"
//        @unknown default:
//            stateString = "unknown"
//        }
//
//        print("🎤 VAD State: \(stateString)")
//
//        let vadResult = [
//            "state": stateString,
//            "confidence": 0.85,
//            "timestamp": Date().timeIntervalSince1970,
//            "vadType": "yamnet"
//        ] as [String: Any]
//
//        DispatchQueue.main.async { [weak self] in
//            guard let channel = self?.methodChannel as? NSObject else { return }
//            let invokeSelector = NSSelectorFromString("invokeMethod:arguments:")
//            _ = channel.perform(invokeSelector, with: "onVADResult", with: vadResult)
//        }
//    }
//}



import Foundation
import UIKit
import AVFoundation

#if canImport(Flutter)
import Flutter

@objc public class YAMNetPlugin: NSObject, FlutterPlugin {
    private var channel: FlutterMethodChannel?
    private var isRecording = false
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "yamnet_channel", binaryMessenger: registrar.messenger())
        let instance = YAMNetPlugin()
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
        print("✅ YAMNetPlugin registered with Flutter")
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startYAMNet":
            let startResult = startYAMNet()
            result(startResult)
        case "stopYAMNet":
            let stopResult = stopYAMNet()
            result(stopResult)
        case "checkPermission":
            let permissionResult = checkPermission()
            result(permissionResult)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    @objc public func startYAMNet() -> String {
        print("🎯 Starting YAMNet...")
        
        // Setup audio session first
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: [])
            try audioSession.setActive(true)
            print("✅ Audio session configured")
        } catch {
            print("❌ Audio session error: \(error)")
            return "Audio session setup failed"
        }
        
        // Check microphone permission
        checkMicrophonePermission { [weak self] granted in
            guard let self = self else { return }
            
            if granted {
                print("✅ Permission granted - Starting audio recording")
                
                // Use safer parameters to prevent overflow
                let safeSampleRate: SampleRate = .rate_16k  // Use 16kHz instead of 15.6kHz
                let safeFrameSize: FrameSize = .size_512    // Use 512 instead of 15600
                
                print("🔧 Using safe parameters - SR: \(safeSampleRate.rawValue), FS: \(safeFrameSize.rawValue)")
                
                do {
                    // Safe YAMNet start with validated parameters
                    OpenMicProvider.shared.startRecord(
                        type: .yamnet,
                        sampleRate: safeSampleRate,
                        frameSize: safeFrameSize,
                        quality: VADQuality.allCases.first!,
                        completion: { [weak self] vadState in
                            DispatchQueue.main.async {
                                self?.handleVADResult(vadState)
                            }
                        }
                    )
                    self.isRecording = true
                    print("✅ YAMNet recording started with safe parameters")
                } catch {
                    print("❌ YAMNet start error: \(error)")
                    self.sendError("Failed to start YAMNet: \(error.localizedDescription)")
                }
                
            } else {
                print("❌ Permission denied")
                self.sendError("Microphone permission denied")
            }
        }
        
        return "YAMNet starting..."
    }
    
    @objc public func stopYAMNet() -> String {
        print("🛑 Stopping YAMNet...")
        
        // Safe stop with error handling
        do {
            OpenMicProvider.shared.stopRecord()
            isRecording = false
            
            // Deactivate audio session
            try AVAudioSession.sharedInstance().setActive(false)
            print("✅ YAMNet stopped safely")
        } catch {
            print("❌ Stop error: \(error)")
        }
        
        return "YAMNet stopped"
    }
    
    @objc public func checkPermission() -> String {
        let permission = AVAudioSession.sharedInstance().recordPermission
        switch permission {
        case .granted:
            return "granted"
        case .denied:
            return "denied"
        case .undetermined:
            return "undetermined"
        @unknown default:
            return "unknown"
        }
    }
    
    private func checkMicrophonePermission(completion: @escaping (Bool) -> Void) {
        #if targetEnvironment(simulator)
        print("🔧 Simulator detected - using real mic input (no mock)")
        completion(true)
        return
        #endif
        
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            completion(true)
        case .denied:
            completion(false)
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        @unknown default:
            completion(false)
        }
    }
    
    private func handleVADResult(_ vadState: VADState) {
        guard isRecording else {
            print("⚠️ Received VAD result but not recording")
            return
        }
        
        let stateString: String
        switch vadState {
        case .start:
            stateString = "speech_start"
        case .speeching:
            stateString = "speech_detected"
        case .end:
            stateString = "speech_end"
        case .silence:
            stateString = "silence"
        @unknown default:
            stateString = "unknown"
        }
        
        print("🎤 VAD State: \(stateString)")
        
        // Safe result creation
        let vadResult = [
            "state": stateString,
            "confidence": 0.85,
            "timestamp": Date().timeIntervalSince1970,
            "vadType": "yamnet"
        ] as [String: Any]
        
        // Main thread mein safely send karo
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let channel = self.channel else {
                print("⚠️ Channel not available")
                return
            }
            channel.invokeMethod("onVADResult", arguments: vadResult)
        }
    }
    
    private func sendError(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            self?.channel?.invokeMethod("onError", arguments: message)
        }
    }
}

#else
@objc public class YAMNetPlugin: NSObject {
    @objc public static func register(with registrar: Any) {
        print("⚠️ YAMNetPlugin registered without Flutter")
    }
}
#endif
