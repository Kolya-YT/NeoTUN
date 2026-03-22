package com.neotun.dpi

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log
import java.io.File

class DpiVpnService : VpnService() {

    companion object {
        const val TAG          = "NeoTUN"
        const val ACTION_START = "com.neotun.dpi.START"
        const val ACTION_STOP  = "com.neotun.dpi.STOP"
        const val NOTIF_ID     = 1
        const val CHANNEL_ID   = "neotun_vpn"

        @Volatile var isRunning = false
        @Volatile var lastError = ""
    }

    // neotun_bypass JNI — loaded lazily
    private external fun nativeStartProxy(splitPos: Int, disorder: Int, tlsrecSplit: Int, oob: Int): Int
    private external fun nativeStopProxy()

    // hev-socks5-tunnel JNI — loaded lazily
    private external fun TProxyStartService(configPath: String, fd: Int)
    private external fun TProxyStopService()

    private var tunFd: ParcelFileDescriptor? = null
    private var bypassLoaded = false
    private var tunnelLoaded = false

    override fun onCreate() {
        super.onCreate()
        bypassLoaded = loadLib("neotun_bypass")
        tunnelLoaded = loadLib("hev-socks5-tunnel")
    }

    private fun loadLib(name: String): Boolean = try {
        System.loadLibrary(name)
        Log.i(TAG, "$name loaded OK")
        true
    } catch (e: Throwable) {
        Log.e(TAG, "Failed to load $name: $e")
        false
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.i(TAG, "onStartCommand: ${intent?.action}")
        when (intent?.action) {
            ACTION_START -> doStart()
            ACTION_STOP  -> doStop()
        }
        return START_NOT_STICKY
    }

    private fun doStart() {
        if (isRunning) return

        createNotificationChannel()
        startForeground(NOTIF_ID, buildNotification("Запуск..."))

        // 1. Start SOCKS5 bypass proxy on :1080
        if (!bypassLoaded) {
            fail("neotun_bypass не загружен")
            return
        }
        val proxyResult = try {
            nativeStartProxy(2, 0, 1, 1)
        } catch (e: Throwable) {
            fail("nativeStartProxy: $e")
            return
        }
        if (proxyResult != 0) {
            fail("proxy start failed: $proxyResult")
            return
        }
        Log.i(TAG, "SOCKS5 proxy started on :1080")

        // 2. Create TUN interface
        val pfd = try {
            Builder()
                .setSession("NeoTUN")
                .addAddress("10.10.10.1", 24)
                .addRoute("0.0.0.0", 0)
                .addDnsServer("8.8.8.8")
                .addDnsServer("1.1.1.1")
                .setMtu(1500)
                .apply {
                    try { addDisallowedApplication(packageName) } catch (_: Throwable) {}
                }
                .establish()
        } catch (e: Throwable) {
            nativeStopProxy()
            fail("TUN establish: $e")
            return
        }

        if (pfd == null) {
            nativeStopProxy()
            fail("TUN establish returned null — нет разрешения VPN?")
            return
        }
        tunFd = pfd
        Log.i(TAG, "TUN fd=${pfd.fd}")

        // 3. Start hev-socks5-tunnel (routes TUN → SOCKS5 :1080)
        if (!tunnelLoaded) {
            nativeStopProxy()
            pfd.close()
            fail("hev-socks5-tunnel не загружен")
            return
        }

        val cfg = File(cacheDir, "neotun.yml")
        cfg.writeText(buildConfig())

        try {
            TProxyStartService(cfg.absolutePath, pfd.fd)
        } catch (e: Throwable) {
            nativeStopProxy()
            pfd.close()
            fail("TProxyStartService: $e")
            return
        }

        isRunning = true
        lastError = ""
        updateNotification("Работает")
        broadcast(true)
        Log.i(TAG, "VPN started OK")
    }

    private fun doStop() {
        if (!isRunning && tunFd == null) return
        isRunning = false
        Log.i(TAG, "doStop")

        if (tunnelLoaded) {
            try { TProxyStopService() } catch (e: Throwable) { Log.e(TAG, "TProxyStop: $e") }
        }
        if (bypassLoaded) {
            try { nativeStopProxy() } catch (e: Throwable) { Log.e(TAG, "proxyStop: $e") }
        }
        try { tunFd?.close() } catch (_: Throwable) {}
        tunFd = null

        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
        broadcast(false)
    }

    override fun onDestroy() {
        doStop()
        super.onDestroy()
    }

    private fun fail(msg: String) {
        Log.e(TAG, "FAIL: $msg")
        lastError = msg
        isRunning = false
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
        broadcast(false, msg)
    }

    private fun buildConfig() = """
tunnel:
  mtu: 1500

misc:
  task-stack-size: 81920

socks5:
  address: 127.0.0.1
  port: 1080
  udp: udp
""".trimIndent()

    private fun broadcast(running: Boolean, error: String = "") =
        sendBroadcast(
            Intent("com.neotun.dpi.STATUS")
                .putExtra("running", running)
                .putExtra("error", error)
        )

    private fun buildNotification(text: String): Notification {
        val pi = PendingIntent.getActivity(
            this, 0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE
        )
        return Notification.Builder(this, CHANNEL_ID)
            .setContentTitle("NeoTUN")
            .setContentText(text)
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setContentIntent(pi)
            .setOngoing(true)
            .build()
    }

    private fun updateNotification(text: String) =
        getSystemService(NotificationManager::class.java)
            .notify(NOTIF_ID, buildNotification(text))

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            getSystemService(NotificationManager::class.java)
                .createNotificationChannel(
                    NotificationChannel(
                        CHANNEL_ID,
                        "NeoTUN VPN",
                        NotificationManager.IMPORTANCE_LOW
                    )
                )
        }
    }
}
