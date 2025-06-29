////package com.vsc.money
////
////import io.flutter.embedding.android.FlutterFragmentActivity
////
////class MainActivity: FlutterFragmentActivity()
//
//
//
//
//// android/app/src/main/kotlin/com/example/yourapp/VoiceActivityDetectorPlugin.kt
//package com.example.vscmoney
//
//import android.Manifest
//import android.content.Context
//import android.content.pm.PackageManager
//import android.media.AudioFormat
//import android.media.AudioRecord
//import android.media.MediaRecorder
//import android.os.Handler
//import android.os.Looper
//import androidx.core.app.ActivityCompat
//import androidx.core.content.ContextCompat
//import io.flutter.embedding.engine.plugins.FlutterPlugin
//import io.flutter.embedding.engine.plugins.activity.ActivityAware
//import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
//import io.flutter.plugin.common.EventChannel
//import io.flutter.plugin.common.MethodCall
//import io.flutter.plugin.common.MethodChannel
//import io.flutter.plugin.common.PluginRegistry
//import kotlin.math.abs
//import kotlin.math.sqrt
//import kotlinx.coroutines.*
//
//class VoiceActivityDetectorPlugin : FlutterPlugin, MethodChannel.MethodCallHandler,
//    EventChannel.StreamHandler, ActivityAware, PluginRegistry.RequestPermissionsResultListener {
//
//    private lateinit var methodChannel: MethodChannel
//    private lateinit var eventChannel: EventChannel
//    private var eventSink: EventChannel.EventSink? = null
//    private var context: Context? = null
//    private var activity: android.app.Activity? = null
//
//    // Audio recording components
//    private var audioRecord: AudioRecord? = null
//    private var isRecording = false
//    private var recordingJob: Job? = null
//
//    // VAD parameters
//    private var sampleRate = 16000
//    private var bufferSize = 1024
//    private var silenceThreshold = 0.01
//    private var voiceThreshold = 0.05
//    private var minSilenceDuration = 500L // milliseconds
//    private var minVoiceDuration = 100L   // milliseconds
//
//    // VAD state
//    private var isVoiceActive = false
//    private var currentAudioLevel = 0.0
//    private var lastVoiceTime = 0L
//    private var lastSilenceTime = 0L
//    private var voiceStartTime = 0L
//    private var silenceStartTime = 0L
//
//    // Handler for main thread
//    private val mainHandler = Handler(Looper.getMainLooper())
//
//    companion object {
//        private const val CHANNEL_NAME = "voice_activity_detector"
//        private const val EVENT_CHANNEL_NAME = "voice_activity_detector/events"
//        private const val PERMISSION_REQUEST_CODE = 1001
//    }
//
//    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
//        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
//        methodChannel.setMethodCallHandler(this)
//
//        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, EVENT_CHANNEL_NAME)
//        eventChannel.setStreamHandler(this)
//
//        context = flutterPluginBinding.applicationContext
//    }
//
//    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
//        methodChannel.setMethodCallHandler(null)
//        eventChannel.setStreamHandler(null)
//    }
//
//    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
//        activity = binding.activity
//        binding.addRequestPermissionsResultListener(this)
//    }
//
//    override fun onDetachedFromActivity() {
//        activity = null
//    }
//
//    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
//        activity = binding.activity
//        binding.addRequestPermissionsResultListener(this)
//    }
//
//    override fun onDetachedFromActivityForConfigChanges() {
//        activity = null
//    }
//
//    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
//        when (call.method) {
//            "initialize" -> {
//                val params = call.arguments as Map<String, Any>
//                initialize(params, result)
//            }
//            "startDetection" -> startDetection(result)
//            "stopDetection" -> stopDetection(result)
//            "updateParameters" -> {
//                val params = call.arguments as Map<String, Any>
//                updateParameters(params, result)
//            }
//            "getCurrentAudioLevel" -> result.success(currentAudioLevel)
//            "hasPermission" -> result.success(hasAudioPermission())
//            "requestPermission" -> requestAudioPermission(result)
//            "dispose" -> {
//                dispose()
//                result.success(null)
//            }
//            else -> result.notImplemented()
//        }
//    }
//
//    private fun initialize(params: Map<String, Any>, result: MethodChannel.Result) {
//        try {
//            sampleRate = params["sampleRate"] as? Int ?: 16000
//            bufferSize = params["bufferSize"] as? Int ?: 1024
//            silenceThreshold = (params["silenceThreshold"] as? Double) ?: 0.01
//            voiceThreshold = (params["voiceThreshold"] as? Double) ?: 0.05
//            minSilenceDuration = (params["minSilenceDuration"] as? Int)?.toLong() ?: 500L
//            minVoiceDuration = (params["minVoiceDuration"] as? Int)?.toLong() ?: 100L
//
//            result.success(true)
//        } catch (e: Exception) {
//            result.error("INITIALIZATION_ERROR", "Failed to initialize VAD: ${e.message}", null)
//        }
//    }
//
//    private fun startDetection(result: MethodChannel.Result) {
//        if (!hasAudioPermission()) {
//            result.error("PERMISSION_ERROR", "Audio permission not granted", null)
//            return
//        }
//
//        try {
//            if (isRecording) {
//                result.success(true)
//                return
//            }
//
//            val channelConfig = AudioFormat.CHANNEL_IN_MONO
//            val audioFormat = AudioFormat.ENCODING_PCM_16BIT
//            val minBufferSize = AudioRecord.getMinBufferSize(sampleRate, channelConfig, audioFormat)
//            val actualBufferSize = maxOf(bufferSize, minBufferSize)
//
//            audioRecord = AudioRecord(
//                MediaRecorder.AudioSource.MIC,
//                sampleRate,
//                channelConfig,
//                audioFormat,
//                actualBufferSize
//            )
//
//            if (audioRecord?.state != AudioRecord.STATE_INITIALIZED) {
//                result.error("AUDIO_RECORD_ERROR", "Failed to initialize AudioRecord", null)
//                return
//            }
//
//            audioRecord?.startRecording()
//            isRecording = true
//
//            recordingJob = CoroutineScope(Dispatchers.IO).launch {
//                processAudioData()
//            }
//
//            result.success(true)
//        } catch (e: Exception) {
//            result.error("START_ERROR", "Failed to start detection: ${e.message}", null)
//        }
//    }
//
//    private fun stopDetection(result: MethodChannel.Result) {
//        try {
//            isRecording = false
//            recordingJob?.cancel()
//            audioRecord?.stop()
//            audioRecord?.release()
//            audioRecord = null
//
//            // Reset state
//            isVoiceActive = false
//            currentAudioLevel = 0.0
//
//            result.success(true)
//        } catch (e: Exception) {
//            result.error("STOP_ERROR", "Failed to stop detection: ${e.message}", null)
//        }
//    }
//
//    private fun updateParameters(params: Map<String, Any>, result: MethodChannel.Result) {
//        try {
//            params["silenceThreshold"]?.let { silenceThreshold = it as Double }
//            params["voiceThreshold"]?.let { voiceThreshold = it as Double }
//            params["minSilenceDuration"]?.let { minSilenceDuration = (it as Int).toLong() }
//            params["minVoiceDuration"]?.let { minVoiceDuration = (it as Int).toLong() }
//
//            result.success(true)
//        } catch (e: Exception) {
//            result.error("UPDATE_ERROR", "Failed to update parameters: ${e.message}", null)
//        }
//    }
//
//    private suspend fun processAudioData() {
//        val buffer = ShortArray(bufferSize)
//
//        while (isRecording && audioRecord != null) {
//            try {
//                val bytesRead = audioRecord?.read(buffer, 0, bufferSize) ?: 0
//
//                if (bytesRead > 0) {
//                    val audioLevel = calculateAudioLevel(buffer, bytesRead)
//                    currentAudioLevel = audioLevel
//
//                    // Send audio level update
//                    sendEvent("audioLevel", audioLevel)
//
//                    // Process voice activity detection
//                    processVoiceActivity(audioLevel)
//                }
//
//                // Small delay to prevent excessive CPU usage
//                delay(10)
//            } catch (e: Exception) {
//                sendError("Audio processing error: ${e.message}")
//                break
//            }
//        }
//    }
//
//    private fun calculateAudioLevel(buffer: ShortArray, length: Int): Double {
//        var sum = 0.0
//        for (i in 0 until length) {
//            sum += abs(buffer[i].toDouble())
//        }
//        val mean = sum / length
//        return (mean / Short.MAX_VALUE).coerceIn(0.0, 1.0)
//    }
//
//    private fun processVoiceActivity(audioLevel: Double) {
//        val currentTime = System.currentTimeMillis()
//
//        val isCurrentlyVoice = audioLevel > voiceThreshold
//        val isCurrentlySilence = audioLevel < silenceThreshold
//
//        when {
//            isCurrentlyVoice && !isVoiceActive -> {
//                if (voiceStartTime == 0L) {
//                    voiceStartTime = currentTime
//                } else if (currentTime - voiceStartTime >= minVoiceDuration) {
//                    isVoiceActive = true
//                    voiceStartTime = 0L
//                    lastVoiceTime = currentTime
//                    sendEvent("voiceStart", audioLevel)
//                }
//            }
//
//            isCurrentlySilence && isVoiceActive -> {
//                if (silenceStartTime == 0L) {
//                    silenceStartTime = currentTime
//                } else if (currentTime - silenceStartTime >= minSilenceDuration) {
//                    isVoiceActive = false
//                    silenceStartTime = 0L
//                    lastSilenceTime = currentTime
//                    sendEvent("voiceEnd", audioLevel)
//                }
//            }
//        }
//
//        if (!isCurrentlyVoice) voiceStartTime = 0L
//        if (!isCurrentlySilence) silenceStartTime = 0L
//    }
//
//
//    private fun sendEvent(type: String, audioLevel: Double, error: String? = null) {
//        mainHandler.post {
//            eventSink?.let { sink ->
//                val event = mapOf(
//                    "type" to type,
//                    "audioLevel" to audioLevel,
//                    "timestamp" to System.currentTimeMillis(),
//                    "error" to error
//                )
//                sink.success(event)
//            }
//        }
//    }
//
//    private fun sendError(message: String) {
//        sendEvent("error", currentAudioLevel, message)
//    }
//
//    private fun hasAudioPermission(): Boolean {
//        return context?.let {
//            ContextCompat.checkSelfPermission(it, Manifest.permission.RECORD_AUDIO) ==
//                    PackageManager.PERMISSION_GRANTED
//        } ?: false
//    }
//
//    private fun requestAudioPermission(result: MethodChannel.Result) {
//        activity?.let {
//            ActivityCompat.requestPermissions(
//                it,
//                arrayOf(Manifest.permission.RECORD_AUDIO),
//                PERMISSION_REQUEST_CODE
//            )
//            // Store the result for later use
//            pendingPermissionResult = result
//        } ?: result.error("NO_ACTIVITY", "No activity available for permission request", null)
//    }
//
//    private var pendingPermissionResult: MethodChannel.Result? = null
//
//    override fun onRequestPermissionsResult(
//        requestCode: Int,
//        permissions: Array<out String>,
//        grantResults: IntArray
//    ): Boolean {
//        if (requestCode == PERMISSION_REQUEST_CODE) {
//            val granted = grantResults.isNotEmpty() &&
//                    grantResults[0] == PackageManager.PERMISSION_GRANTED
//            pendingPermissionResult?.success(granted)
//            pendingPermissionResult = null
//            return true
//        }
//        return false
//    }
//
//    private fun dispose() {
//        stopDetection(object : MethodChannel.Result {
//            override fun success(result: Any?) {}
//            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {}
//            override fun notImplemented() {}
//        })
//    }
//
//    // EventChannel.StreamHandler implementation
//    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
//        eventSink = events
//    }
//
//    override fun onCancel(arguments: Any?) {
//        eventSink = null
//    }
//}
//
//// android/app/src/main/kotlin/com/example/yourapp/MainActivity.kt
//package com.example.yourapp
//
//import io.flutter.embedding.android.FlutterActivity
//import io.flutter.embedding.engine.FlutterEngine
//
//class MainActivity: FlutterActivity() {
//    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
//        super.configureFlutterEngine(flutterEngine)
//        flutterEngine.plugins.add(VoiceActivityDetectorPlugin())
//    }
//}


package com.example.vscmoney

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity()
