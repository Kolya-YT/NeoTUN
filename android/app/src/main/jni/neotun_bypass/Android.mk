LOCAL_PATH := $(call my-dir)
CPP_PATH   := $(LOCAL_PATH)/../../cpp

include $(CLEAR_VARS)
LOCAL_MODULE    := neotun_bypass
LOCAL_SRC_FILES := \
    $(CPP_PATH)/proxy_jni.c \
    $(CPP_PATH)/bypass.c \
    $(CPP_PATH)/socks5.c \
    $(CPP_PATH)/utils.c
LOCAL_C_INCLUDES := $(CPP_PATH)
LOCAL_CFLAGS     := -O2 -Wall -Wno-unused-parameter -DANDROID_APP
LOCAL_LDLIBS     := -llog
include $(BUILD_SHARED_LIBRARY)
