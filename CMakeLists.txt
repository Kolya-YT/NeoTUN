cmake_minimum_required(VERSION 3.15)
project(neotun C)

set(CMAKE_C_STANDARD 11)

set(SOURCES
    core/main.c
    core/socks5.c
    core/bypass.c
    core/utils.c
)

if(WIN32)
    set(WINDIVERT_DIR "${CMAKE_SOURCE_DIR}/vendor/windivert" CACHE PATH "Path to WinDivert SDK")

    if(EXISTS "${WINDIVERT_DIR}/include/windivert.h")
        message(STATUS "WinDivert found at ${WINDIVERT_DIR}")
        list(APPEND SOURCES core/windivert_engine.c)
        set(HAVE_WINDIVERT 1)
    else()
        message(WARNING "WinDivert not found. Place SDK into vendor/windivert/")
        set(HAVE_WINDIVERT 0)
    endif()
endif()

add_executable(neotun ${SOURCES})

target_include_directories(neotun PRIVATE core)

if(WIN32)
    target_link_libraries(neotun ws2_32)

    if(HAVE_WINDIVERT)
        if(CMAKE_SIZEOF_VOID_P EQUAL 8)
            set(WD_ARCH "x64")
            set(WD_SYS  "WinDivert64.sys")
        else()
            set(WD_ARCH "x86")
            set(WD_SYS  "WinDivert32.sys")
        endif()

        target_include_directories(neotun PRIVATE "${WINDIVERT_DIR}/include")
        target_compile_definitions(neotun PRIVATE HAVE_WINDIVERT=1)
        target_link_libraries(neotun "${WINDIVERT_DIR}/${WD_ARCH}/WinDivert.lib")

        add_custom_command(TARGET neotun POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${WINDIVERT_DIR}/${WD_ARCH}/WinDivert.dll"
                "$<TARGET_FILE_DIR:neotun>/WinDivert.dll"
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${WINDIVERT_DIR}/${WD_ARCH}/${WD_SYS}"
                "$<TARGET_FILE_DIR:neotun>/${WD_SYS}"
            COMMENT "Copying WinDivert runtime files"
        )
    endif()
else()
    target_link_libraries(neotun pthread)
endif()

if(CMAKE_BUILD_TYPE STREQUAL "Release")
    target_compile_options(neotun PRIVATE -O2)
endif()
