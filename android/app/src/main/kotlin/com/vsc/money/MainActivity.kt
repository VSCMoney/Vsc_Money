//
//
//
//
//package com.vitty.ai
//
//import android.os.Bundle
//import com.vitty.ai.vad.VadMicrophone
//import io.flutter.embedding.android.FlutterActivity
//import io.flutter.embedding.engine.FlutterEngine
//import io.flutter.plugin.common.EventChannel
//
//class MainActivity : FlutterActivity() {
//
//    private var vadMicrophone: VadMicrophone? = null
//
//    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
//        super.configureFlutterEngine(flutterEngine)
//
//        // 🔗 Stream VAD results to Flutter
//        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "vad_stream")
//            .setStreamHandler(object : EventChannel.StreamHandler {
//                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
//                    events?.let {
//                        vadMicrophone = VadMicrophone(applicationContext, it)
//                        vadMicrophone?.start()
//                    }
//                }
//
//                override fun onCancel(arguments: Any?) {
//                    vadMicrophone?.stop()
//                    vadMicrophone = null
//                }
//            })
//    }
//}



package com.vitty.ai

import android.os.Bundle
import com.vitty.ai.vad.VadMicrophone
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {

    private var vadMicrophone: VadMicrophone? = null
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ✅ Event channel to stream VAD updates to Flutter
        val eventChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, "native_vad/events")
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                eventSink = sink
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
        super.onDestroy()
        vadMicrophone?.stop()
    }
}
