package com.neotun.app

import android.content.Context
import android.util.Log
import libv2ray.Libv2ray
import libv2ray.V2RayPoint
import libv2ray.V2RayVPNServiceSupportsSet

class XrayHelper(private val context: Context) {
    private var v2rayPoint: V2RayPoint? = null
    private var isRunning = false

    companion object {
        private const val TAG = "XrayHelper"
        
        init {
            try {
                System.loadLibrary("v2ray")
                Log.d(TAG, "v2ray library loaded successfully")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to load v2ray library", e)
            }
        }
    }

    fun start(configContent: String): Boolean {
        try {
            if (isRunning) {
                stop()
            }

            v2rayPoint = Libv2ray.newV2RayPoint(object : V2RayVPNServiceSupportsSet {
                override fun onEmitStatus(status: String?) {
                    Log.d(TAG, "Status: $status")
                }

                override fun protect(fd: Long): Boolean {
                    // For non-VPN mode, just return true
                    return true
                }

                override fun prepare(): Long {
                    return 0
                }

                override fun shutdown(): Boolean {
                    return true
                }
            }, false)

            val result = v2rayPoint?.configureFileContent(configContent) ?: false
            if (!result) {
                Log.e(TAG, "Failed to configure v2ray")
                return false
            }

            v2rayPoint?.runLoop(false)
            isRunning = true
            Log.d(TAG, "Xray started successfully")
            return true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start Xray", e)
            return false
        }
    }

    fun stop() {
        try {
            v2rayPoint?.stopLoop()
            v2rayPoint = null
            isRunning = false
            Log.d(TAG, "Xray stopped")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop Xray", e)
        }
    }

    fun getRunning(): Boolean = isRunning
}
