#include <string.h>
#include "signal_processing_library.h"

void WebRtcSpl_CopyFromEndW16(const int16_t* in_vector,
                              size_t length,
                              size_t samples,
                              int16_t* out_vector) {
    memcpy(out_vector, in_vector + length - samples, samples * sizeof(int16_t));
}