#include <jni.h>
#include "tun_engine.h"

JNIEXPORT jint JNICALL
Java_com_neotun_dpi_DpiVpnService_nativeStart(JNIEnv *env, jobject thiz,
                                               jint tun_fd,
                                               jint fake_ttl,
                                               jint disorder)
{
    (void)env; (void)thiz;
    return tun_engine_start((int)tun_fd, (int)fake_ttl, (int)disorder);
}

JNIEXPORT void JNICALL
Java_com_neotun_dpi_DpiVpnService_nativeStop(JNIEnv *env, jobject thiz)
{
    (void)env; (void)thiz;
    tun_engine_stop();
}
