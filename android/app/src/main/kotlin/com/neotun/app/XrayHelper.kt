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
    private var isLibraryLoaded = false
    
    init {
        try {
            // libv2ray.aar использует имя "v2ray", а не "xray"
            System.loadLibrary("v2ray")
            isLibraryLoaded = true
            Log.i(TAG, "✓ libv2ray.so loaded successfully")
        } catch (e: UnsatisfiedLinkError) {
            Log.e(TAG, "✗ Failed to load libv2ray.so: ${e.message}", e)
            isLibraryLoaded = false
        }
    }
    
    /**
     * Запускает Xray с указанной конфигурацией
     */
    fun runXray(configPath: String, assetPath: String, fd: Int): Int {
        if (!isLibraryLoaded) {
            Log.e(TAG, "Library not loaded, cannot run Xray")
            return -1
        }
        
        return try {
            Log.i(TAG, "Starting Xray: config=$configPath, assets=$assetPath, fd=$fd")
            runXrayNative(configPath, assetPath, fd)
        } catch (e: UnsatisfiedLinkError) {
            Log.e(TAG, "Native method not found: ${e.message}", e)
            -2
        } catch (e: Exception) {
            Log.e(TAG, "Error running Xray: ${e.message}", e)
            -3
        }
    }
    
    /**
     * Останавливает Xray
     */
    fun stopXray(): Int {
        if (!isLibraryLoaded) {
            Log.w(TAG, "Library not loaded, nothing to stop")
            return 0
        }
        
        return try {
            Log.i(TAG, "Stopping Xray...")
            stopXrayNative()
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping Xray: ${e.message}", e)
            0 // Не критично если не удалось остановить
        }
    }
    
    /**
     * Получает версию Xray
     */
    fun xrayVersion(): String {
        if (!isLibraryLoaded) {
            return "Library not loaded"
        }
        
        return try {
            xrayVersionNative()
        } catch (e: Exception) {
            Log.e(TAG, "Error getting version: ${e.message}", e)
            "Unknown"
        }
    }
    
    // Native методы
    @JvmStatic
    private external fun runXrayNative(configPath: String, assetPath: String, fd: Int): Int
    
    @JvmStatic
    private external fun stopXrayNative(): Int
    
    @JvmStatic
    private external fun xrayVersionNative(): String
}
