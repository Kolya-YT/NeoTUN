#pragma once
#include <stdint.h>
#include <jni.h>

/*
 * Передать JVM и объект сервиса для вызова protect() через JNI.
 * Вызывать до tun_engine_start().
 */
void tun_engine_set_jvm(JavaVM *jvm, jobject service);

/*
 * Запустить bypass-прокси.
 * tun_fd    — fd TUN интерфейса (от VpnService)
 * fake_ttl  — TTL для fake-пакетов (5)
 * disorder  — disorder mode (1)
 * Возвращает 0 при успехе.
 */
int tun_engine_start(int tun_fd, int fake_ttl, int disorder);
void tun_engine_stop(void);
