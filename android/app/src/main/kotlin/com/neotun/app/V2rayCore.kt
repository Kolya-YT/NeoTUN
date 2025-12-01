package com.neotun.app

import android.util.Log
import go.Seq

object V2rayCore {
    private const val TAG = "V2rayCore"
    private var isLoaded = false
    private var instanceId: Long = -1
    
    init {
        try {
            // Инициализируем Go runtime из AndroidLibXrayLite
            Seq.setContext(null)
            isLoaded = true
            Log.i(TAG, "AndroidLibXrayLite initialized successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize AndroidLibXrayLite", e)
            isLoaded = false
        }
    }
    
    fun isAvailable(): Boolean = isLoaded
    
    fun runConfig(configContent: String): Boolean {
        if (!isLoaded) return false
        
        try {
            // Используем libv2ray из AndroidLibXrayLite
            val libv2ray = libv2ray.Libv2ray()
            instanceId = libv2ray.newV2RayInstance()
            
            val result = libv2ray.startV2Ray(instanceId, configContent)
            Log.i(TAG, "Xray started with result: $result")
            return result == 0L
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start Xray", e)
            return false
        }
    }
    
    fun stopInstance(): Boolean {
        if (!isLoaded || instanceId < 0) return false
        
        try {
            val libv2ray = libv2ray.Libv2ray()
            libv2ray.stopV2Ray(instanceId)
            instanceId = -1
            Log.i(TAG, "Xray stopped")
            return true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop Xray", e)
            return false
        }
    }
    
    fun queryStats(tag: String, direct: String): Long {
        if (!isLoaded || instanceId < 0) return 0
        
        try {
            val libv2ray = libv2ray.Libv2ray()
            return libv2ray.queryStats(instanceId, tag, direct)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to query stats", e)
            return 0
        }
    }
}
