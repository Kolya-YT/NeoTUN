package com.neotun.app

import android.util.Log

/**
 * XrayHelper - обертка для libxray.so
 * Архитектура как в v2rayNG - прямой вызов JNI методов
 * 
 * Основано на: https://github.com/2dust/v2rayNG
 * Использует: https://github.com/2dust/AndroidLibXrayLite
 */
object XrayHelper {
    
    private const val TAG = "XrayHelper"
    
    init {
        try {
            System.loadLibrary("xray")
            Log.i(TAG, "✓ libxray.so loaded successfully")
        } catch (e: UnsatisfiedLinkError) {
            Log.e(TAG, "✗ Failed to load libxray.so", e)
        }
    }
    
    /**
     * Запускает Xray с указанной конфигурацией
     * 
     * @param configPath путь к файлу конфигурации
     * @param assetPath путь к директории assets
     * @param fd file descriptor VPN интерфейса
     * @return 0 при успехе, иначе код ошибки
     */
    @JvmStatic
    external fun runXray(configPath: String, assetPath: String, fd: Int): Int
    
    /**
     * Останавливает Xray
     * 
     * @return 0 при успехе, иначе код ошибки
     */
    @JvmStatic
    external fun stopXray(): Int
    
    /**
     * Получает версию Xray
     * 
     * @return строка с версией
     */
    @JvmStatic
    external fun xrayVersion(): String
    
    /**
     * Тестирует конфигурацию
     * 
     * @param configPath путь к файлу конфигурации
     * @return 0 если конфигурация валидна, иначе код ошибки
     */
    @JvmStatic
    external fun testConfig(configPath: String): Int
    
    /**
     * Получает статистику трафика
     * 
     * @return JSON строка со статистикой
     */
    @JvmStatic
    external fun queryStats(): String
}
