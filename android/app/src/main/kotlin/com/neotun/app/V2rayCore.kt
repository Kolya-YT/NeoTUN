package com.neotun.app

import android.util.Log

object V2rayCore {
    private const val TAG = "V2rayCore"
    private var isLoaded = false
    
    init {
        try {
            System.loadLibrary("v2ray")
            isLoaded = true
            Log.i(TAG, "libv2ray.so loaded successfully")
        } catch (e: UnsatisfiedLinkError) {
            Log.e(TAG, "Failed to load libv2ray.so", e)
            isLoaded = false
        }
    }
    
    fun isAvailable(): Boolean = isLoaded
    
    // JNI methods - будут реализованы в libv2ray.so
    external fun runConfig(configPath: String): Long
    external fun stopInstance(instanceId: Long): Boolean
    external fun queryStats(tag: String, direct: String): Long
}
