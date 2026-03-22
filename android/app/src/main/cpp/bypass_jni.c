#include <jni.h>
#include "tun_engine.h"

/* Called when the library is loaded — store JVM for protect() calls */
JNIEXPORT jint JNI_OnLoad(JavaVM *vm, void *reserved) {
    (void)reserved;
    /* Store JVM; service object will be set in nativeStart */
    tun_engine_set_jvm(vm, NULL);
    return JNI_VERSION_1_6;
}

JNIEXPORT jint JNICALL
Java_com_neotun_dpi_DpiVpnService_nativeStart(JNIEnv *env, jobject thiz,
                                               jint tun_fd,
                                               jint fake_ttl,
                                               jint disorder)
{
    JavaVM *jvm = NULL;
    (*env)->GetJavaVM(env, &jvm);
    /* Pass global ref to service so protect() can be called from threads */
    jobject service_ref = (*env)->NewGlobalRef(env, thiz);
    tun_engine_set_jvm(jvm, service_ref);
    return tun_engine_start((int)tun_fd, (int)fake_ttl, (int)disorder);
}

JNIEXPORT void JNICALL
Java_com_neotun_dpi_DpiVpnService_nativeStop(JNIEnv *env, jobject thiz)
{
    (void)env; (void)thiz;
    tun_engine_stop();
}
