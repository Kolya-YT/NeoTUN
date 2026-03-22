package com.neotun.dpi

import android.util.Log

object TProxyService {
    init {
        System.loadLibrary("hev-socks5-tunnel")
        Log.i("NeoTUN", "hev-socks5-tunnel loaded")
    }

    external fun TProxyStartService(configPath: String, fd: Int)
    external fun TProxyStopService()

    fun startService(configPath: String, fd: Int) = TProxyStartService(configPath, fd)
    fun stopService() = TProxyStopService()
}
