package com.example.vscmoney

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Handler
import android.os.Looper
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import kotlin.math.abs

class VoiceActivityDetectorPlugin : FlutterPlugin, MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler, ActivityAware {

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private var context: Context? = null
    private var activity: android.app.Activity? = null

    private var audioRecord: AudioRecord? = null
    private var isRecording = false
    private var recordingJob: Job? = null

    private var sampleRate = 16000
    private var bufferSize = 1024
    private var silenceThreshold = 0.01
    private var voiceThreshold = 0.05
    private var minSilenceDuration = 500L
    private var minVoiceDuration = 100L

    private var isVoiceActive = false
    private var currentAudioLevel = 0.0
    private var voiceStartTime = 0L
    private var silenceStartTime = 0L

    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext

        methodChannel = MethodChannel(binding.binaryMessenger, "voice_activity_detector")
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(binding.binaryMessenger, "voice_activity_detector/events")
        eventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startDetection" -> startDetection(result)
            "stopDetection" -> stopDetection(result)
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    private fun startDetection(result: MethodChannel.Result) {
        if (!hasPermission()) {
            result.error("PERMISSION_DENIED", "Mic permission not granted", null)
            return
        }

        if (isRecording) {
            result.success(true)
            return
        }

        val minBuffer = AudioRecord.getMinBufferSize(
            sampleRate, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT
        )
        val actualBufferSize = maxOf(minBuffer, bufferSize)

        audioRecord = AudioRecord(
            MediaRecorder.AudioSource.MIC,
            sampleRate,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT,
            actualBufferSize
        )

        if (audioRecord?.state != AudioRecord.STATE_INITIALIZED) {
            result.error("INIT_FAILED", "AudioRecord failed to initialize", null)
            return
        }

        audioRecord?.startRecording()
        isRecording = true
        recordingJob = CoroutineScope(Dispatchers.IO).launch { processAudio() }

        result.success(true)
    }

    private fun stopDetection(result: MethodChannel.Result) {
        isRecording = false
        recordingJob?.cancel()
        audioRecord?.stop()
        audioRecord?.release()
        audioRecord = null
        result.success(true)
    }

    private fun processAudio() {
        val buffer = ShortArray(bufferSize)

        while (isRecording) {
            val read = audioRecord?.read(buffer, 0, buffer.size) ?: 0
            if (read > 0) {
                val level = calculateAudioLevel(buffer, read)
                currentAudioLevel = level
                detectVoiceState(level)
                sendEvent("audioLevel", level)
            }
        }
    }

    private fun calculateAudioLevel(buffer: ShortArray, length: Int): Double {
        var sum = 0.0
        for (i in 0 until length) {
            sum += abs(buffer[i].toDouble())
        }
        return (sum / length / Short.MAX_VALUE).coerceIn(0.0, 1.0)
    }

    private fun detectVoiceState(level: Double) {
        val time = System.currentTimeMillis()
        val isVoice = level > voiceThreshold
        val isSilence = level < silenceThreshold

        if (isVoice && !isVoiceActive) {
            if (voiceStartTime == 0L) {
                voiceStartTime = time
            } else if (time - voiceStartTime >= minVoiceDuration) {
                isVoiceActive = true
                voiceStartTime = 0L
                sendEvent("voiceStart", level)
            }
        }

        if (isSilence && isVoiceActive) {
            if (silenceStartTime == 0L) {
                silenceStartTime = time
            } else if (time - silenceStartTime >= minSilenceDuration) {
                isVoiceActive = false
                silenceStartTime = 0L
                sendEvent("voiceEnd", level)
            }
        }

        if (!isVoice) voiceStartTime = 0L
        if (!isSilence) silenceStartTime = 0L
    }

    private fun sendEvent(type: String, level: Double) {
        mainHandler.post {
            eventSink?.success(mapOf("type" to type, "audioLevel" to level))
        }
    }

    private fun hasPermission(): Boolean {
        return context?.let {
            ContextCompat.checkSelfPermission(it, Manifest.permission.RECORD_AUDIO)
        } == PackageManager.PERMISSION_GRANTED
    }
}
