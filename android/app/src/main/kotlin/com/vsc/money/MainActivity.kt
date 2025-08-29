//
//
//package com.ai.vitty
//
//import android.os.Bundle
//import com.ai.vitty.vad.VadMicrophone
//import io.flutter.embedding.android.FlutterActivity
//import io.flutter.embedding.engine.FlutterEngine
//import io.flutter.plugin.common.MethodChannel
//import io.flutter.plugin.common.EventChannel
//
//class MainActivity : FlutterActivity() {
//
//    private var vadMicrophone: VadMicrophone? = null
//    private var eventSink: EventChannel.EventSink? = null
//
//    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
//        super.configureFlutterEngine(flutterEngine)
//
//        // ✅ Event channel to stream VAD updates to Flutter
//        val eventChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, "native_vad/events")
//        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
//            override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
//                eventSink = sink
//                vadMicrophone = VadMicrophone(this@MainActivity, eventSink!!)
//            }
//
//            override fun onCancel(arguments: Any?) {
//                vadMicrophone?.stop()
//                eventSink = null
//            }
//        })
//
//        // ✅ Method channel for Flutter to trigger start/stop
//        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "native_vad")
//            .setMethodCallHandler { call, result ->
//                when (call.method) {
//                    "start" -> {
//                        vadMicrophone?.start()
//                        result.success(true)
//                    }
//                    "stop" -> {
//                        vadMicrophone?.stop()
//                        result.success(true)
//                    }
//                    else -> result.notImplemented()
//                }
//            }
//    }
//
//    override fun onDestroy() {
//        super.onDestroy()
//        vadMicrophone?.stop()
//    }
//}


package com.ai.vitty

import android.os.Bundle
import com.ai.vitty.vad.VadMicrophone
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel

// ✅ Must extend FlutterFragmentActivity for local_auth / BiometricPrompt
class MainActivity : FlutterFragmentActivity() {

    private var vadMicrophone: VadMicrophone? = null
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ✅ Event channel to stream VAD updates to Flutter
        val eventChannel = EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "native_vad/events"
        )
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                eventSink = sink
                // 'this@MainActivity' still works with FragmentActivity
                vadMicrophone = VadMicrophone(this@MainActivity, eventSink!!)
            }

            override fun onCancel(arguments: Any?) {
                vadMicrophone?.stop()
                eventSink = null
            }
        })

        // ✅ Method channel for Flutter to trigger start/stop
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "native_vad")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> {
                        vadMicrophone?.start()
                        result.success(true)
                    }
                    "stop" -> {
                        vadMicrophone?.stop()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        // stop first, then super
        vadMicrophone?.stop()
        super.onDestroy()
    }
}
