#!/usr/bin/env python3
"""Patch hev-jni.c and Android.mk to fix JNI compilation on Android."""
import sys

# ── 1. Patch Android.mk — add -DANDROID flag ─────────────────────────────────
mk_path = "android/app/src/main/jni/hev-socks5-tunnel/Android.mk"
try:
    mk = open(mk_path).read()
    old_flags = "LOCAL_CFLAGS += -DFD_SET_DEFINED -DSOCKLEN_T_DEFINED -DENABLE_LIBRARY"
    new_flags = "LOCAL_CFLAGS += -DFD_SET_DEFINED -DSOCKLEN_T_DEFINED -DENABLE_LIBRARY -DANDROID"
    if "-DANDROID" in mk:
        print("Skip: -DANDROID already in Android.mk")
    elif old_flags in mk:
        mk = mk.replace(old_flags, new_flags)
        open(mk_path, "w").write(mk)
        print("Patched: added -DANDROID to Android.mk")
    else:
        print("WARNING: could not find LOCAL_CFLAGS line in Android.mk")
except FileNotFoundError:
    print(f"WARNING: {mk_path} not found")

# ── 2. Patch hev-jni.c ───────────────────────────────────────────────────────
jni_path = "android/app/src/main/jni/hev-socks5-tunnel/src/hev-jni.c"
try:
    src = open(jni_path).read()
except FileNotFoundError:
    print(f"ERROR: {jni_path} not found")
    sys.exit(1)

changed = False

# Null-check FindClass in JNI_OnLoad
old1 = (
    '    klass = (*env)->FindClass (env, STR (PKGNAME) "/" STR (CLSNAME));\n'
    '    (*env)->RegisterNatives (env, klass, native_methods,\n'
    '                             N_ELEMENTS (native_methods));\n'
    '    (*env)->DeleteLocalRef (env, klass);'
)
new1 = (
    '    klass = (*env)->FindClass (env, STR (PKGNAME) "/" STR (CLSNAME));\n'
    '    if (klass) {\n'
    '        (*env)->RegisterNatives (env, klass, native_methods,\n'
    '                                 N_ELEMENTS (native_methods));\n'
    '        (*env)->DeleteLocalRef (env, klass);\n'
    '    } else {\n'
    '        (*env)->ExceptionClear (env);\n'
    '    }'
)
if old1 in src:
    src = src.replace(old1, new1)
    print("Patched: JNI_OnLoad null-check")
    changed = True
else:
    print("Skip: JNI_OnLoad patch already applied or pattern not found")

# Add standard JNI name-mangled exports before #endif /* ANDROID */
exports = (
    "\n"
    "/* Standard JNI name-mangled exports - fallback when RegisterNatives fails */\n"
    "JNIEXPORT void JNICALL\n"
    "Java_com_neotun_dpi_TProxyService_TProxyStartService (JNIEnv *env, jobject thiz,\n"
    "                                                       jstring config_path, jint fd)\n"
    "{\n"
    "    native_start_service (env, thiz, config_path, fd);\n"
    "}\n"
    "\n"
    "JNIEXPORT void JNICALL\n"
    "Java_com_neotun_dpi_TProxyService_TProxyStopService (JNIEnv *env, jobject thiz)\n"
    "{\n"
    "    native_stop_service (env, thiz);\n"
    "}\n"
    "\n"
    "JNIEXPORT jlongArray JNICALL\n"
    "Java_com_neotun_dpi_TProxyService_TProxyGetStats (JNIEnv *env, jobject thiz)\n"
    "{\n"
    "    return native_get_stats (env, thiz);\n"
    "}\n"
    "\n"
)
marker = "#endif /* ANDROID */"
if "Java_com_neotun_dpi_TProxyService_TProxyStartService" in src:
    print("Skip: standard JNI exports already present")
elif marker in src:
    src = src.replace(marker, exports + marker)
    print("Patched: added standard JNI exports")
    changed = True
else:
    print("WARNING: #endif /* ANDROID */ marker not found")

if changed:
    open(jni_path, "w").write(src)
    print("Done - hev-jni.c written")
else:
    print("Done - no changes to hev-jni.c")
