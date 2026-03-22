#!/usr/bin/env python3
"""
Patch hev-socks5-tunnel for NeoTUN:
1. Android.mk: add -DANDROID flag so hev-jni.c is compiled
2. hev-jni.c: replace RegisterNatives with direct JNI exports for DpiVpnService
"""
import sys, re

# ── 1. Android.mk ─────────────────────────────────────────────────────────────
mk_path = "android/app/src/main/jni/hev-socks5-tunnel/Android.mk"
try:
    mk = open(mk_path).read()
    if "-DANDROID" not in mk:
        mk = mk.replace(
            "LOCAL_CFLAGS += -DFD_SET_DEFINED -DSOCKLEN_T_DEFINED -DENABLE_LIBRARY",
            "LOCAL_CFLAGS += -DFD_SET_DEFINED -DSOCKLEN_T_DEFINED -DENABLE_LIBRARY -DANDROID"
        )
        open(mk_path, "w").write(mk)
        print("Patched Android.mk: added -DANDROID")
    else:
        print("Android.mk already has -DANDROID")
except FileNotFoundError:
    print(f"WARNING: {mk_path} not found")

# ── 2. hev-jni.c ──────────────────────────────────────────────────────────────
jni_path = "android/app/src/main/jni/hev-socks5-tunnel/src/hev-jni.c"
try:
    src = open(jni_path).read()
except FileNotFoundError:
    print(f"ERROR: {jni_path} not found"); sys.exit(1)

if "Java_com_neotun_dpi_DpiVpnService_TProxyStartService" in src:
    print("hev-jni.c already patched"); sys.exit(0)

# Replace the entire JNI_OnLoad (which crashes on null FindClass) with a no-op,
# and add direct exports matching DpiVpnService.TProxyStartService etc.
new_jni_onload = """\
jint
JNI_OnLoad (JavaVM *vm, void *reserved)
{
    JNIEnv *env = NULL;

    java_vm = vm;
    if (JNI_OK != (*vm)->GetEnv (vm, (void **)&env, JNI_VERSION_1_4))
        return 0;

    pthread_key_create (&current_jni_env, detach_current_thread);
    pthread_mutex_init (&mutex, NULL);

    return JNI_VERSION_1_4;
}"""

# Replace old JNI_OnLoad
src = re.sub(
    r'jint\s*\nJNI_OnLoad\s*\(.*?\)\s*\{.*?\}',
    new_jni_onload,
    src,
    flags=re.DOTALL
)

# Add exports before #endif /* ANDROID */
exports = """\

/* Direct JNI exports for com.neotun.dpi.DpiVpnService */
JNIEXPORT void JNICALL
Java_com_neotun_dpi_DpiVpnService_TProxyStartService (JNIEnv *env, jobject thiz,
                                                       jstring config_path, jint fd)
{
    native_start_service (env, thiz, config_path, fd);
}

JNIEXPORT void JNICALL
Java_com_neotun_dpi_DpiVpnService_TProxyStopService (JNIEnv *env, jobject thiz)
{
    native_stop_service (env, thiz);
}

"""

src = src.replace("#endif /* ANDROID */", exports + "#endif /* ANDROID */")
open(jni_path, "w").write(src)
print("Patched hev-jni.c: replaced JNI_OnLoad + added DpiVpnService exports")
