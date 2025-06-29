cmake_minimum_required(VERSION 3.4.1)

add_library(native_vad SHARED
        native_vad.cpp)

find_library(log-lib log)

target_link_libraries(native_vad
        ${log-lib})
