package com.neotun.app

import android.content.Context
import android.util.Log
import java.io.File

/**
 * Wrapper для работы с AndroidLibXrayLite
 * Использует нативную библиотеку libxray.so вместо исполняемых файлов
 */
class XrayHelper(private val context: Context) {
    
    companion object {
        private const val TAG = "XrayHelper"
        
        // Загружаем нативную библиотеку
        init {
            try {
                System.loadLibrary("xray")
                Log.i(TAG, "✓ Xray native library loaded")
            } catch (e: UnsatisfiedLinkError) {
                Log.e(TAG, "✗ Failed to load Xray library", e)
            }
        }
        
        // Native методы из AndroidLibXrayLite
        @JvmStatic
        external fun runXray(configPath: String, assetPath: String): Int
        
        @JvmStatic
        external fun stopXray(): Int
        
        @JvmStatic
        external fun xrayVersion(): String
        
        @JvmStatic
        external fun testConfig(configPath: String): Int
    }
    
    private var isRunning = false
    private var xrayThread: Thread? = null
    
    /**
     * Запускает Xray с указанной конфигурацией
     */
    fun start(configPath: String): Boolean {
        if (isRunning) {
            Log.w(TAG, "Xray already running, stopping first")
            stop()
        }
        
        try {
            val configFile = File(configPath)
            if (!configFile.exists()) {
                Log.e(TAG, "Config file not found: $configPath")
                return false
            }
            
            // Проверяем конфигурацию
            val testResult = testConfig(configPath)
            if (testResult != 0) {
                Log.e(TAG, "Config test failed with code: $testResult")
                return false
            }
            
            Log.i(TAG, "Starting Xray with config: $configPath")
            
            // Запускаем Xray в отдельном потоке
            xrayThread = Thread {
                try {
                    val assetPath = context.filesDir.absolutePath
                    val result = runXray(configPath, assetPath)
                    
                    if (result == 0) {
                        Log.i(TAG, "✓ Xray started successfully")
                        isRunning = true
                    } else {
                        Log.e(TAG, "✗ Xray failed with code: $result")
                        isRunning = false
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error running Xray", e)
                    isRunning = false
                }
            }
            
            xrayThread?.start()
            
            // Даем время на запуск и проверяем результат
            Thread.sleep(1000)
            
            Log.i(TAG, "Xray start result: isRunning=$isRunning")
            return true  // Возвращаем true сразу, проверка будет в потоке
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start Xray", e)
            return false
        }
    }
    
    /**
     * Останавливает Xray
     */
    fun stop(): Boolean {
        if (!isRunning) {
            Log.w(TAG, "Xray not running")
            return true
        }
        
        try {
            Log.i(TAG, "Stopping Xray...")
            
            val result = stopXray()
            
            xrayThread?.interrupt()
            xrayThread?.join(2000)
            xrayThread = null
            
            isRunning = false
            
            if (result == 0) {
                Log.i(TAG, "✓ Xray stopped successfully")
                return true
            } else {
                Log.w(TAG, "Xray stop returned code: $result")
                return true // Считаем успехом даже если код не 0
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping Xray", e)
            return false
        }
    }
    
    /**
     * Получает версию Xray
     */
    fun getVersion(): String {
        return try {
            xrayVersion()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get version", e)
            "Unknown"
        }
    }
    
    /**
     * Проверяет, запущен ли Xray
     */
    fun isXrayRunning(): Boolean = isRunning
}
