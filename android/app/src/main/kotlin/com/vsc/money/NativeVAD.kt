//package com.ai.vitty
//
//import android.media.AudioFormat
//import android.media.AudioRecord
//import android.media.MediaRecorder
//import android.os.Handler
//import android.os.Looper
//import io.flutter.plugin.common.EventChannel
//import io.flutter.plugin.common.MethodCall
//import io.flutter.plugin.common.MethodChannel
//import java.util.concurrent.atomic.AtomicBoolean
//import kotlin.concurrent.thread
//
//class NativeVAD : MethodChannel.MethodCallHandler {
//    companion object {
//        init {
//            System.loadLibrary("native_vad")
//        }
//
//        @JvmStatic
//        external fun detectVoice(audioBuffer: ShortArray): Boolean
//    }
//
//    private val isListening = AtomicBoolean(false)
//    private var recordThread: Thread? = null
//    private var eventSink: EventChannel.EventSink? = null
//    private val handler = Handler(Looper.getMainLooper())
//
//    fun setEventSink(sink: EventChannel.EventSink?) {
//        this.eventSink = sink
//    }
//
//    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
//        when (call.method) {
//            "startVAD" -> {
//                startRecording()
//                result.success(true)
//            }
//
//            "stopVAD" -> {
//                stopRecording()
//                result.success(true)
//            }
//
//            else -> result.notImplemented()
//        }
//    }
//
//    private fun startRecording() {
//        if (isListening.get()) return
//        isListening.set(true)
//
//        val sampleRate = 16000
//        val bufferSize = AudioRecord.getMinBufferSize(
//            sampleRate,
//            AudioFormat.CHANNEL_IN_MONO,
//            AudioFormat.ENCODING_PCM_16BIT
//        )
//
//        val audioRecord = AudioRecord(
//            MediaRecorder.AudioSource.MIC,
//            sampleRate,
//            AudioFormat.CHANNEL_IN_MONO,
//            AudioFormat.ENCODING_PCM_16BIT,
//            bufferSize
//        )
//
//        val buffer = ShortArray(bufferSize)
//        audioRecord.startRecording()
//
//        recordThread = thread(start = true) {
//            while (isListening.get()) {
//                val read = audioRecord.read(buffer, 0, buffer.size)
//                if (read > 0) {
//                    val isVoice = detectVoice(buffer)
//                    handler.post {
//                        eventSink?.success(isVoice)
//                    }
//                }
//            }
//            audioRecord.stop()
//            audioRecord.release()
//        }
//    }
//
//    private fun stopRecording() {
//        isListening.set(false)
//        recordThread?.join()
//        recordThread = null
//    }
//}





package com.ai.vitty

import android.media.*
import android.os.*
import io.flutter.plugin.common.*
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.concurrent.thread
import kotlin.math.sqrt
import android.util.Log


class NativeVAD : MethodChannel.MethodCallHandler {
    private var eventSink: EventChannel.EventSink? = null
    private val isRecording = AtomicBoolean(false)
    private var recordThread: Thread? = null

    companion object {
        init {
            System.loadLibrary("native_vad")
        }

        @JvmStatic
        external fun detectVoice(audioBuffer: ShortArray): Boolean
    }

    fun setEventSink(sink: EventChannel.EventSink?) {
        eventSink = sink
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startVAD" -> {
                startRecording()
                result.success(true)
            }
            "stopVAD" -> {
                stopRecording()
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    private fun startRecording() {
        if (isRecording.get()) return
        isRecording.set(true)

        val sampleRate = 16000
        val vadFrameSize = 160 // 10ms
        val bufferSize = AudioRecord.getMinBufferSize(
            sampleRate,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT
        ).coerceAtLeast(vadFrameSize * 2)

        val audioRecord = AudioRecord(
            MediaRecorder.AudioSource.MIC,
            sampleRate,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT,
            bufferSize
        )

        val readBuffer = ShortArray(bufferSize)
        audioRecord.startRecording()

        recordThread = thread(start = true) {
            while (isRecording.get()) {
                val read = audioRecord.read(readBuffer, 0, readBuffer.size)
                if (read > vadFrameSize) {
                    var offset = 0
                    while (offset + vadFrameSize <= read) {
                        val frame = readBuffer.copyOfRange(offset, offset + vadFrameSize)

                        val isSpeechRaw = detectVoice(frame)
                        val rms = calculateRMS(frame)

                        // 🎯 Filter: Only send if above RMS threshold
                        val isSpeech = isSpeechRaw && rms > 300.0

                        Log.d("NativeVAD", "🧠 isSpeech=$isSpeech | 🎚️ rms=$rms")

                        Handler(Looper.getMainLooper()).post {
                            eventSink?.success(
                                mapOf(
                                    "isSpeech" to isSpeech,
                                    "rms" to rms
                                )
                            )
                        }

                        offset += vadFrameSize
                    }
                }
            }

            audioRecord.stop()
            audioRecord.release()
        }
    }

    private fun stopRecording() {
        isRecording.set(false)
        recordThread?.join()
        recordThread = null
    }

    private fun calculateRMS(buffer: ShortArray): Double {
        var sum = 0.0
        for (sample in buffer) {
            sum += sample * sample
        }
        return sqrt(sum / buffer.size)
    }
}



