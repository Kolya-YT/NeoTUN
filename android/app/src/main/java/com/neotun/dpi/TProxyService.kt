package com.neotun.dpi

object TProxyService {
    var loadError: String? = null

    init {
        try {
            System.loadLibrary("hev-socks5-tunnel")
        } catch (e: UnsatisfiedLinkError) {
            loadError = e.message
            android.util.Log.e("NeoTUN", "Failed to load hev-socks5-tunnel", e)
        }
    }

    external fun TProxyStartService(configPath: String, fd: Int)
    external fun TProxyStopService()

    fun startService(configPath: String, fd: Int) = TProxyStartService(configPath, fd)
    fun stopService() = TProxyStopService()
}
