//
//#include <jni.h>
//#include <cmath>
//
//extern "C" JNIEXPORT jboolean JNICALL
//Java_com_vsc_money_NativeVAD_detectVoice(JNIEnv *env, jobject thiz, jshortArray audioBuffer) {
//    jsize length = env->GetArrayLength(audioBuffer);
//    jshort *samples = env->GetShortArrayElements(audioBuffer, 0);
//
//    double sum = 0;
//    for (int i = 0; i < length; ++i) {
//        sum += std::abs(samples[i]);
//    }
//    double avgAmplitude = sum / length;
//
//    env->ReleaseShortArrayElements(audioBuffer, samples, 0);
//
//    return avgAmplitude > 500;  // tweak this threshold as needed
//}




#include <jni.h>
#include <cmath>

extern "C"
JNIEXPORT jboolean JNICALL
Java_com_vsc_money_NativeVAD_00024Companion_detectVoice(JNIEnv *env, jobject thiz, jshortArray audioBuffer) {
    jsize length = env->GetArrayLength(audioBuffer);
    jshort *samples = env->GetShortArrayElements(audioBuffer, 0);

    double sum = 0;
    for (int i = 0; i < length; ++i) {
        sum += std::abs(samples[i]);
    }
    double avgAmplitude = sum / length;

    env->ReleaseShortArrayElements(audioBuffer, samples, 0);

    return avgAmplitude > 500; // Threshold
}
