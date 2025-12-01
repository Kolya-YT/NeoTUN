package com.neotun.app

import android.util.Log

object V2rayCore {
    private const val TAG = "V2rayCore"
    private var isLoaded = false
    
    init {
        try {
            // Пробуем загрузить наш libxray.so
            System.loadLibrary("xray")
            isLoaded = true
            Log.i(TAG, "libxray.so loaded successfully")
        } catch (e: UnsatisfiedLinkError) {
            try {
                // Fallback на libv2ray.so если есть
                System.loadLibrary("v2ray")
                isLoaded = true
                Log.i(TAG, "libv2ray.so loaded successfully")
            } catch (e2: UnsatisfiedLinkError) {
                Log.e(TAG, "Failed to load native library", e2)
                isLoaded = false
            }
        }
    }
    
    fun isAvailable(): Boolean = isLoaded
    
    // JNI methods - будут реализованы в libv2ray.so
    external fun runConfig(configPath: String): Long
    external fun stopInstance(instanceId: Long): Boolean
    external fun queryStats(tag: String, direct: String): Long
}
