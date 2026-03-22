package com.neotun.dpi

import android.util.Log

object TProxyService {
    var loadError: String? = null
        private set

    private var loaded = false

    init {
        try {
            System.loadLibrary("hev-socks5-tunnel")
            loaded = true
        } catch (e: UnsatisfiedLinkError) {
            loadError = "hev-socks5-tunnel: ${e.message}"
            Log.e("NeoTUN", "Failed to load hev-socks5-tunnel: ${e.message}")
        }
    }

    fun startService(configPath: String, fd: Int) {
        if (!loaded) { Log.e("NeoTUN", "hev-socks5-tunnel not loaded, skipping start"); return }
        TProxyStartService(configPath, fd)
    }

    fun stopService() {
        if (!loaded) return
        TProxyStopService()
    }

    @JvmStatic private external fun TProxyStartService(configPath: String, fd: Int)
    @JvmStatic private external fun TProxyStopService()
}
