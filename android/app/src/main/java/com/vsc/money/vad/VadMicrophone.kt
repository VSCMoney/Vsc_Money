//package com.ai.vitty.vad
//
//import android.media.AudioFormat
//import android.media.AudioRecord
//import android.media.MediaRecorder
//import android.content.Context
//import com.ai.vitty.vad.config.FrameSize
//import com.ai.vitty.vad.config.Mode
//import com.ai.vitty.vad.config.SampleRate
//import io.flutter.plugin.common.EventChannel
//import kotlinx.coroutines.*
//
//class VadMicrophone(
//    private val context: Context,
//    private val eventSink: EventChannel.EventSink
//) {
//    private var audioRecord: AudioRecord? = null
//    private var vad: VadYamnet? = null
//    private var isRecording = false
//    private var job: Job? = null
//
//    fun start() {
//        val sampleRate = 16000
//        val frameSize = FrameSize.FRAME_SIZE_487
//        val bufferSize = AudioRecord.getMinBufferSize(
//            sampleRate,
//            AudioFormat.CHANNEL_IN_MONO,
//            AudioFormat.ENCODING_PCM_16BIT
//        )
//
//        audioRecord = AudioRecord(
//            MediaRecorder.AudioSource.MIC,
//            sampleRate,
//            AudioFormat.CHANNEL_IN_MONO,
//            AudioFormat.ENCODING_PCM_16BIT,
//            bufferSize
//        )
//
//        vad = VadYamnet(
//            context,
//            SampleRate.SAMPLE_RATE_16K,
//            frameSize,
//            Mode.NORMAL
//        )
//
//        val chunk = ByteArray(frameSize.value * 2) // 2 bytes per sample
//
//        audioRecord?.startRecording()
//        isRecording = true
//
//        job = CoroutineScope(Dispatchers.IO).launch {
//            while (isRecording) {
//                val read = audioRecord?.read(chunk, 0, chunk.size) ?: 0
//                if (read > 0) {
//                    val isSpeech = vad?.isSpeech(chunk, read) == true
//                    withContext(Dispatchers.Main) {
//                        eventSink.success(isSpeech)
//                    }
//                }
//            }
//        }
//    }
//
//    fun stop() {
//        isRecording = false
//        job?.cancel()
//        audioRecord?.stop()
//        audioRecord?.release()
//        vad?.close()
//    }
//
//}



package com.ai.vitty.vad

import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.content.Context
import com.ai.vitty.vad.config.FrameSize
import com.ai.vitty.vad.config.Mode
import com.ai.vitty.vad.config.SampleRate
import io.flutter.plugin.common.EventChannel
import kotlinx.coroutines.*
import kotlin.math.pow
import kotlin.math.sqrt

class VadMicrophone(
    private val context: Context,
    private var eventSink: EventChannel.EventSink?
) {
    private var audioRecord: AudioRecord? = null
    private var vad: VadYamnet? = null
    private var isRecording = false
    private var job: Job? = null

    fun start() {
        if (isRecording) return // prevent double start
        isRecording = true

        val sampleRate = 16000
        val frameSize = FrameSize.FRAME_SIZE_487
        val bufferSize = AudioRecord.getMinBufferSize(
            sampleRate,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT
        )

        audioRecord = AudioRecord(
            MediaRecorder.AudioSource.MIC,
            sampleRate,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT,
            bufferSize
        )

        vad = VadYamnet(
            context,
            SampleRate.SAMPLE_RATE_16K,
            frameSize,
            Mode.NORMAL
        )

        val chunk = ByteArray(frameSize.value * 2) // 2 bytes per sample

        audioRecord?.startRecording()

        job = CoroutineScope(Dispatchers.IO).launch {
            while (isRecording) {
                val read = audioRecord?.read(chunk, 0, chunk.size) ?: 0
                if (read > 0) {
                    val isSpeech = vad?.isSpeech(chunk, read) == true
                    val rms = calculateRms(chunk, read)

                    withContext(Dispatchers.Main) {
                        eventSink?.success(
                            mapOf(
                                "isSpeech" to isSpeech,
                                "rms" to rms
                            )
                        )
                    }
                }
            }
        }
    }

    fun stop() {
        if (!isRecording) return
        isRecording = false
        job?.cancel()
        audioRecord?.stop()
        audioRecord?.release()
        vad?.close()
        eventSink = null // reset event sink for safety
    }

    private fun calculateRms(buffer: ByteArray, length: Int): Double {
        var sum = 0.0
        for (i in 0 until length step 2) {
            val low = buffer[i].toInt() and 0xFF
            val high = buffer[i + 1].toInt()
            val sample = (high shl 8) or low
            sum += sample.toDouble().pow(2)
        }
        val mean = sum / (length / 2)
        return sqrt(mean).coerceIn(0.0, 32768.0) / 32768.0
    }
}
