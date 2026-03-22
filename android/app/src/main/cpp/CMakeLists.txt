cmake_minimum_required(VERSION 3.22.1)
project(neotun_bypass C)

set(CMAKE_C_STANDARD 11)

add_library(neotun_bypass SHARED
    bypass_jni.c
    bypass.c
    tun_engine.c
)

target_include_directories(neotun_bypass PRIVATE .)

find_library(log-lib log)
target_link_libraries(neotun_bypass ${log-lib})
