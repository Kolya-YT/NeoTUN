package com.neotun.app

import android.util.Log

/**
 * XrayHelper - обертка для libv2ray.aar
 * Использует JNI методы напрямую через System.loadLibrary
 * 
 * Основано на: https://github.com/2dust/v2rayNG
 * Использует: https://github.com/2dust/AndroidLibXrayLite
 */
object XrayHelper {
    
    private const val TAG = "XrayHelper"
    private var isRunning = false
    
    init {
        try {
            // Загружаем нативную библиотеку
            System.loadLibrary("gojni")
            Log.i(TAG, "✓ Native library loaded")
        } catch (e: Exception) {
            Log.e(TAG, "✗ Failed to load native library: ${e.message}", e)
        }
    }
    
    /**
     * Запускает Xray с указанной конфигурацией
     * Использует JNI метод напрямую
     */
    fun runXray(configPath: String, assetPath: String, fd: Int): Int {
        return try {
            Log.i(TAG, "Starting Xray: config=$configPath, assets=$assetPath, fd=$fd")
            
            // Проверяем файл конфигурации
            val configFile = java.io.File(configPath)
            if (!configFile.exists()) {
                Log.e(TAG, "Config file not found: $configPath")
                return -1
            }
            
            // Читаем конфигурацию
            val configContent = configFile.readText()
            Log.d(TAG, "Config size: ${configContent.length} bytes")
            
            // Запускаем через JNI
            val result = startV2Ray(configContent, assetPath, fd)
            
            if (result == 0) {
                isRunning = true
                Log.i(TAG, "✓ Xray started successfully")
            } else {
                Log.e(TAG, "✗ Xray failed with code: $result")
            }
            
            result
            
        } catch (e: Exception) {
            Log.e(TAG, "Error running Xray: ${e.message}", e)
            e.printStackTrace()
            -1
        }
    }
    
    /**
     * Останавливает Xray
     */
    fun stopXray(): Int {
        return try {
            if (isRunning) {
                Log.i(TAG, "Stopping Xray...")
                stopV2Ray()
                isRunning = false
                Log.i(TAG, "✓ Xray stopped")
            }
            0
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping Xray: ${e.message}", e)
            0
        }
    }
    
    /**
     * Получает версию Xray
     */
    fun xrayVersion(): String {
        return try {
            getVersion()
        } catch (e: Exception) {
            Log.e(TAG, "Error getting version: ${e.message}", e)
            "Unknown"
        }
    }
    
    // JNI методы
    private external fun startV2Ray(config: String, assetPath: String, fd: Int): Int
    private external fun stopV2Ray(): Int
    private external fun getVersion(): String
}
