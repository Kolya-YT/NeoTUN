cmake_minimum_required(VERSION 3.22.1)
project(neotun C)

set(CMAKE_C_STANDARD 11)

# ── paths ──────────────────────────────────────────────────────────────────────
set(HEV_DIR "${CMAKE_SOURCE_DIR}/../jni/hev-socks5-tunnel")
set(LWIP_DIR "${HEV_DIR}/third-part/lwip")
set(YAML_DIR "${HEV_DIR}/third-part/yaml")
set(TASK_DIR "${HEV_DIR}/third-part/hev-task-system")

# ── collect sources helper ─────────────────────────────────────────────────────
file(GLOB_RECURSE LWIP_SRCS "${LWIP_DIR}/src/*.c" "${LWIP_DIR}/src/*.S")
file(GLOB_RECURSE YAML_SRCS "${YAML_DIR}/src/*.c")
file(GLOB_RECURSE TASK_SRCS "${TASK_DIR}/src/*.c" "${TASK_DIR}/src/*.S")
file(GLOB_RECURSE HEV_SRCS  "${HEV_DIR}/src/*.c")

# ── lwip ───────────────────────────────────────────────────────────────────────
add_library(lwip STATIC ${LWIP_SRCS})
target_include_directories(lwip PUBLIC
    "${LWIP_DIR}/src/include"
    "${LWIP_DIR}/src/ports/include")
target_compile_definitions(lwip PRIVATE FD_SET_DEFINED SOCKLEN_T_DEFINED)
target_compile_options(lwip PRIVATE -O2 -w)

# ── yaml ───────────────────────────────────────────────────────────────────────
add_library(yaml STATIC ${YAML_SRCS})
target_include_directories(yaml PUBLIC "${YAML_DIR}/include")
target_compile_definitions(yaml PRIVATE HAVE_CONFIG_H=1)
target_compile_options(yaml PRIVATE -O2 -w)

# ── hev-task-system ────────────────────────────────────────────────────────────
add_library(hev-task-system STATIC ${TASK_SRCS})
target_include_directories(hev-task-system PUBLIC
    "${TASK_DIR}/include"
    "${TASK_DIR}/src")
target_compile_options(hev-task-system PRIVATE -O2 -w -fvisibility=hidden)

# ── hev-socks5-tunnel ──────────────────────────────────────────────────────────
add_library(hev-socks5-tunnel SHARED ${HEV_SRCS})
target_include_directories(hev-socks5-tunnel PRIVATE
    "${HEV_DIR}/src"
    "${HEV_DIR}/src/misc"
    "${HEV_DIR}/src/core/include"
    "${LWIP_DIR}/src/include"
    "${LWIP_DIR}/src/ports/include"
    "${YAML_DIR}/include"
    "${TASK_DIR}/include"
    "${TASK_DIR}/src")
target_compile_definitions(hev-socks5-tunnel PRIVATE
    FD_SET_DEFINED SOCKLEN_T_DEFINED ENABLE_LIBRARY)
target_compile_options(hev-socks5-tunnel PRIVATE -O2 -w)
target_link_libraries(hev-socks5-tunnel
    lwip yaml hev-task-system
    log android)
target_link_options(hev-socks5-tunnel PRIVATE
    -Wl,-z,max-page-size=16384
    -Wl,-z,common-page-size=16384)

# ── neotun_bypass (our SOCKS5 proxy) ──────────────────────────────────────────
add_library(neotun_bypass SHARED
    proxy_jni.c
    bypass.c
    socks5.c
    utils.c)
target_include_directories(neotun_bypass PRIVATE .)
target_compile_definitions(neotun_bypass PRIVATE ANDROID_APP)
target_compile_options(neotun_bypass PRIVATE -O2 -Wall -Wno-unused-parameter)
find_library(log-lib log)
target_link_libraries(neotun_bypass ${log-lib})
