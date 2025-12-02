package com.neotun.app

import android.util.Log
import libv2ray.Libv2ray
import libv2ray.CoreController

/**
 * XrayHelper - обертка для libv2ray.aar
 * Использует CoreController из AndroidLibXrayLite
 * 
 * Основано на: https://github.com/2dust/v2rayNG
 * Использует: https://github.com/2dust/AndroidLibXrayLite
 */
object XrayHelper {
    
    private const val TAG = "XrayHelper"
    private var coreController: CoreController? = null
    private var isRunning = false
    
    /**
     * Запускает Xray с указанной конфигурацией
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
            
            // Создаем CoreController если еще не создан
            if (coreController == null) {
                coreController = Libv2ray.newCoreController()
                Log.d(TAG, "CoreController created")
            }
            
            // Запускаем Xray через CoreController
            val result = coreController?.startXray(configContent, assetPath, fd.toLong())
            
            if (result == 0L) {
                isRunning = true
                Log.i(TAG, "✓ Xray started successfully")
                return 0
            } else {
                Log.e(TAG, "✗ Xray failed with code: $result")
                return result?.toInt() ?: -1
            }
            
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
            if (isRunning && coreController != null) {
                Log.i(TAG, "Stopping Xray...")
                coreController?.stopXray()
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
            Libv2ray.xrayVersion() ?: "Unknown"
        } catch (e: Exception) {
            Log.e(TAG, "Error getting version: ${e.message}", e)
            "Unknown"
        }
    }
}
