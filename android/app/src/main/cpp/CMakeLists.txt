cmake_minimum_required(VERSION 3.22.1)
project(neotun_bypass C)

set(CMAKE_C_STANDARD 11)

# All core files are copied locally into this directory
add_library(neotun_bypass SHARED
    proxy_jni.c
    bypass.c
    socks5.c
    utils.c
)

target_include_directories(neotun_bypass PRIVATE .)
target_compile_options(neotun_bypass PRIVATE -O2 -Wall -Wno-unused-parameter)
target_compile_definitions(neotun_bypass PRIVATE ANDROID_APP)

find_library(log-lib log)
target_link_libraries(neotun_bypass ${log-lib})
