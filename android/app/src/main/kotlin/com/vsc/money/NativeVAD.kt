
package com.vsc.money

import android.media.AudioRecord
import android.media.MediaRecorder
import android.media.AudioFormat
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import kotlin.concurrent.thread

class NativeVAD : MethodChannel.MethodCallHandler {
    init {
        System.loadLibrary("native_vad")
    }

    private var eventSink: EventChannel.EventSink? = null
    private var isListening = false
    private var recordThread: Thread? = null
    private val handler = Handler(Looper.getMainLooper())

    external fun detectVoice(audioBuffer: ShortArray): Boolean

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
        if (isListening) return
        isListening = true

        val sampleRate = 16000
        val bufferSize = AudioRecord.getMinBufferSize(sampleRate,
            AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT)

        val audioRecord = AudioRecord(
            MediaRecorder.AudioSource.MIC,
            sampleRate,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT,
            bufferSize
        )

        val buffer = ShortArray(bufferSize)

        audioRecord.startRecording()

        recordThread = thread(start = true) {
            while (isListening) {
                val read = audioRecord.read(buffer, 0, buffer.size)
                if (read > 0) {
                    val isVoice = detectVoice(buffer)
                    handler.post {
                        eventSink?.success(isVoice)
                    }
                }
            }
            audioRecord.stop()
            audioRecord.release()
        }
    }

    private fun stopRecording() {
        isListening = false
        recordThread?.join()
    }
}
