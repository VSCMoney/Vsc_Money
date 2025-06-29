//import UIKit
//import Flutter
//
//@main
//@objc class AppDelegate: FlutterAppDelegate {
//  override func application(
//    _ application: UIApplication,
//    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//  ) -> Bool {
//
//    // Safely unwrap the registrar
//    if let registrar = self.registrar(forPlugin: "YAMNetPlugin") {
//        YAMNetPlugin.register(with: registrar)
//        print("✅ YAMNetPlugin registered successfully")
//    } else {
//        print("⚠️ Failed to get registrar for YAMNetPlugin")
//    }
//
//    GeneratedPluginRegistrant.register(with: self)
//    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
//  }
//}
//
//
//
//
//



import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // sab plugins ka registration (including shared_preferences)
        GeneratedPluginRegistrant.register(with: self)
        YamnetVADBridge.register(with: self.registrar(forPlugin: "yamnet_channel")!)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
