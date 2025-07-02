//#include "webrtc_vad.h"
//#include <stdint.h>
//#include <stdlib.h>
//#include <android/log.h>
//#define LOG_TAG "NativeVAD"
//#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, VA_ARGS)
//
//extern "C" {
//
//// Create a new VAD instance and return a pointer
//void* vad_create() {
//    return WebRtcVad_Create();
//}
//
//// Initialize VAD with a given sample rate (8000, 16000, 32000, 48000)
//int vad_init(void* instance, int sample_rate) {
//    if (!instance) return -1;
//    if (WebRtcVad_Init(static_cast<VadInst*>(instance)) != 0) return -1;
//    return WebRtcVad_set_mode(static_cast<VadInst*>(instance), 0); // mode 0 = least aggressive
//}
//
//// Set VAD aggressiveness mode (0–3)
//int vad_set_mode(void* instance, int mode) {
//    if (!instance) return -1;
//    return WebRtcVad_set_mode(static_cast<VadInst*>(instance), mode);
//}
//
//// Process a frame of audio
//// frame: 16-bit mono PCM; length must match 10/20/30ms at sampleRate
//int vad_process(void* instance, int sample_rate, const int16_t* audio_frame, int length) {
//    LOGI("📣 Called vad_process() from Dart");
//    if (!instance || !audio_frame) return -1;
//    return WebRtcVad_Process(static_cast<VadInst*>(instance), sample_rate, audio_frame, length);
//}
//
//// Free VAD instance
//void vad_free(void* instance) {
//    if (instance) {
//        WebRtcVad_Free(static_cast<VadInst*>(instance));
//    }
//}
//
//}

#include <jni.h>
#include <stdlib.h>
#include <stdint.h>
#include <android/log.h>

#include "webrtc_vad.h"

#define LOG_TAG "NativeVAD"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)


extern "C" {

// Create a new VAD instance
void* vad_create() {
    LOGI("🛠️ Creating WebRTC VAD instance...");
    return WebRtcVad_Create();
}

// Initialize VAD instance
int vad_init(void* instance, int sample_rate) {
    if (!instance) {
        LOGE("❌ VAD instance is null during init.");
        return -1;
    }


    int result = WebRtcVad_Init(static_cast<VadInst*>(instance));
    if (result != 0) {
        LOGE("❌ WebRtcVad_Init failed with code %d", result);
    } else {
        LOGI("✅ WebRTC VAD initialized with sample rate: %d", sample_rate);
    }
    return result;
}

// Set VAD aggressiveness mode (0 = least aggressive, 3 = most)
int vad_set_mode(void* instance, int mode) {
    if (!instance) {
        LOGE("❌ VAD instance is null during set_mode.");
        return -1;
    }


    int result = WebRtcVad_set_mode(static_cast<VadInst*>(instance), mode);
    LOGI("🛠️ VAD mode set to %d → result: %d", mode, result);
    return result;
}

// Process a frame of audio data (10/20/30 ms frames)
int vad_process(void* instance, int sample_rate, const int16_t* audio_frame, size_t frame_length) {
    if (!instance || !audio_frame) {
        LOGE("❌ Invalid input to vad_process");
        return -1;
    }


    int result = WebRtcVad_Process(static_cast<VadInst*>(instance), sample_rate, audio_frame, static_cast<int>(frame_length));
    LOGI("📣 vad_process: sampleRate=%d, frameLen=%zu, result=%d", sample_rate, frame_length, result);
    return result;
}

// Free the VAD instance
void vad_free(void* instance) {
    if (instance) {
        WebRtcVad_Free(static_cast<VadInst*>(instance));
        LOGI("🧹 VAD instance freed.");
    }
}

}

//#include "webrtc_vad.h"
//#include <stdlib.h>
//#include <stdint.h>
//
//extern "C" {
//
//// Create a new VAD instance
//void* vad_create() {
//    return WebRtcVad_Create();
//}
//
//// Initialize VAD with sample rate
//int vad_init(void* instance, int sample_rate) {
//    if (!instance) {
//        return -1;
//    }
//
//
//    int init_result = WebRtcVad_Init(static_cast<VadInst*>(instance));
//    if (init_result != 0) {
//
//        return init_result;
//    }
//
//
//    return 0;
//}
//
//// Set VAD aggressiveness mode (0–3)
//int vad_set_mode(void* instance, int mode) {
//    if (!instance) {
//
//        return -1;
//    }
//
//
//    int result = WebRtcVad_set_mode(static_cast<VadInst*>(instance), mode);
//    return result;
//}
//
//// Process a single frame
//int vad_process(void* instance, int sample_rate, const int16_t* audio_frame, size_t frame_length) {
//    if (!instance || !audio_frame) {
//        return -1;
//    }
//
//
//    int result = WebRtcVad_Process(static_cast<VadInst*>(instance), sample_rate, audio_frame, static_cast<int>(frame_length));
//
//    return result;
//}
//
//// Free the VAD instance
//void vad_free(void* instance) {
//    if (instance) {
//        WebRtcVad_Free(static_cast<VadInst*>(instance));
//    }
//}
//
//}