package com.neotun.dpi

import android.util.Log

object TProxyService {
    private const val TAG = "NeoTUN"
    private var loaded = false

    init {
        try {
            System.loadLibrary("hev-socks5-tunnel")
            loaded = true
            Log.i(TAG, "hev-socks5-tunnel loaded")
        } catch (e: UnsatisfiedLinkError) {
            Log.e(TAG, "Failed to load hev-socks5-tunnel: ${e.message}")
        }
    }

    external fun TProxyStartService(configPath: String, fd: Int)
    external fun TProxyStopService()

    fun startService(configPath: String, fd: Int) {
        if (!loaded) throw IllegalStateException("hev-socks5-tunnel library not loaded")
        TProxyStartService(configPath, fd)
    }

    fun stopService() {
        if (!loaded) return
        TProxyStopService()
    }
}
