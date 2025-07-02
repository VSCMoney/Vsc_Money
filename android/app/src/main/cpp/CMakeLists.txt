cmake_minimum_required(VERSION 3.4.1)

set(WEBRTC_ROOT ${CMAKE_SOURCE_DIR}/webrtc_vad)

include_directories(
        ${WEBRTC_ROOT}/common_audio
        ${WEBRTC_ROOT}/common_audio/vad
        ${WEBRTC_ROOT}/common_audio/vad/include
        ${WEBRTC_ROOT}/common_audio/signal_processing
        ${WEBRTC_ROOT}/common_audio/signal_processing/include
        ${WEBRTC_ROOT}/headers
)


set(SOURCES
        native_vad.cpp

        # VAD
        ${WEBRTC_ROOT}/common_audio/vad/vad_core.c
        ${WEBRTC_ROOT}/common_audio/vad/vad_filterbank.c
        ${WEBRTC_ROOT}/common_audio/vad/vad_gmm.c
        ${WEBRTC_ROOT}/common_audio/vad/vad_sp.c
        ${WEBRTC_ROOT}/common_audio/vad/webrtc_vad.c

        # Signal Processing
        ${WEBRTC_ROOT}/common_audio/signal_processing/energy.c
        ${WEBRTC_ROOT}/common_audio/signal_processing/spl_init.c
        ${WEBRTC_ROOT}/common_audio/signal_processing/spl_sqrt_floor.c
        ${WEBRTC_ROOT}/common_audio/signal_processing/vector_scaling_operations.c
        ${WEBRTC_ROOT}/common_audio/signal_processing/resample_by_2_internal.c
        ${WEBRTC_ROOT}/common_audio/signal_processing/resample_48khz.c
        ${WEBRTC_ROOT}/common_audio/signal_processing/division_operations.c
        ${WEBRTC_ROOT}/common_audio/signal_processing/get_scaling_square.c
        ${WEBRTC_ROOT}/common_audio/signal_processing/resample_by_2.c
        ${WEBRTC_ROOT}/common_audio/signal_processing/resample_fractional.c
        ${WEBRTC_ROOT}/common_audio/signal_processing/resample.c
        ${WEBRTC_ROOT}/common_audio/signal_processing/min_max_operations.c
        ${WEBRTC_ROOT}/common_audio/signal_processing/cross_correlation.c
        ${WEBRTC_ROOT}/common_audio/signal_processing/downsample_fast.c
        ${WEBRTC_ROOT}/common_audio/signal_processing/filter_ar.c
        ${WEBRTC_ROOT}/common_audio/signal_processing/filter_ar_fast_q12.c
        ${WEBRTC_ROOT}/common_audio/signal_processing/spl_sqrt.c
        ${WEBRTC_ROOT}/common_audio/signal_processing/spl_inl.c
        ${WEBRTC_ROOT}/common_audio/signal_processing/copy_from_end.c
)



add_library(native_vad SHARED ${SOURCES})

find_library(log-lib log)

target_link_libraries(native_vad ${log-lib})
