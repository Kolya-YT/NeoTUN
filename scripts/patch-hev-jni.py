#!/usr/bin/env python3
"""Patch hev-jni.c to fix JNI_OnLoad crash when FindClass returns NULL."""
import sys

path = "android/app/src/main/jni/hev-socks5-tunnel/src/hev-jni.c"

try:
    src = open(path).read()
except FileNotFoundError:
    print(f"ERROR: {path} not found")
    sys.exit(1)

changed = False

# 1. Null-check FindClass in JNI_OnLoad
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

# 2. Add standard JNI name-mangled exports before #endif /* ANDROID */
exports = r"""
/* Standard JNI name-mangled exports — fallback when RegisterNatives fails */
JNIEXPORT void JNICALL
Java_com_neotun_dpi_TProxyService_TProxyStartService (JNIEnv *env, jobject thiz,
                                                       jstring config_path, jint fd)
{
    native_start_service (env, thiz, config_path, fd);
}

JNIEXPORT void JNICALL
Java_com_neotun_dpi_TProxyService_TProxyStopService (JNIEnv *env, jobject thiz)
{
    native_stop_service (env, thiz);
}

JNIEXPORT jlongArray JNICALL
Java_com_neotun_dpi_TProxyService_TProxyGetStats (JNIEnv *env, jobject thiz)
{
    return native_get_stats (env, thiz);
}

"""
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
    open(path, "w").write(src)
    print("Done — file written")
else:
    print("Done — no changes needed")
