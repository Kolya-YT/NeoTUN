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
        const val TAG = "NeoTUN"
        const val ACTION_START = "com.neotun.dpi.START"
        const val ACTION_STOP  = "com.neotun.dpi.STOP"
        const val NOTIF_ID     = 1
        const val CHANNEL_ID   = "neotun_channel"

        var isRunning = false
            private set

        init {
            System.loadLibrary("neotun_bypass")
        }
    }

    private var tunInterface: ParcelFileDescriptor? = null

    // JNI: наш SOCKS5 bypass прокси
    external fun nativeStartProxy(splitPos: Int, disorder: Int, tlsrecSplit: Int, oob: Int): Int
    external fun nativeStopProxy()

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> startBypass()
            ACTION_STOP  -> stopBypass()
        }
        return START_STICKY
    }

    private fun startBypass() {
        if (isRunning) return

        createNotificationChannel()
        startForeground(NOTIF_ID, buildNotification("Работает"))

        // 1. Запускаем наш SOCKS5 bypass прокси на 127.0.0.1:1080
        val proxyResult = nativeStartProxy(
            splitPos    = 2,
            disorder    = 0,
            tlsrecSplit = 1,
            oob         = 1
        )
        if (proxyResult != 0) {
            Log.e(TAG, "nativeStartProxy failed: $proxyResult")
            stopSelf()
            return
        }

        // 2. Создаём TUN интерфейс
        val builder = Builder()
            .setSession("NeoTUN DPI")
            .addAddress("10.10.10.10", 32)
            .addRoute("0.0.0.0", 0)
            .addAddress("fd00::1", 128)
            .addRoute("::", 0)
            .addDnsServer("8.8.8.8")
            .addDnsServer("8.8.4.4")
            .setMtu(8500)
            .setBlocking(true)

        try { builder.addDisallowedApplication(packageName) } catch (_: Exception) {}

        tunInterface = builder.establish()
        val fd = tunInterface?.fd ?: run {
            Log.e(TAG, "Failed to establish VPN interface")
            nativeStopProxy()
            stopSelf()
            return
        }

        // 3. Запускаем hev-socks5-tunnel: TUN fd → SOCKS5 127.0.0.1:1080
        val config = buildTun2SocksConfig()
        val configFile = File.createTempFile("neotun_cfg", ".yml", cacheDir)
        configFile.writeText(config)

        TProxyService.TProxyStartService(configFile.absolutePath, fd)

        isRunning = true
        Log.i(TAG, "DPI bypass started, tun_fd=$fd")
        sendBroadcast(Intent("com.neotun.dpi.STATUS").putExtra("running", true))
    }

    private fun stopBypass() {
        TProxyService.TProxyStopService()
        nativeStopProxy()
        tunInterface?.close()
        tunInterface = null
        isRunning = false
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
        Log.i(TAG, "DPI bypass stopped")
        sendBroadcast(Intent("com.neotun.dpi.STATUS").putExtra("running", false))
    }

    override fun onDestroy() {
        stopBypass()
        super.onDestroy()
    }

    private fun buildTun2SocksConfig(): String = """
tunnel:
  mtu: 8500

misc:
  task-stack-size: 81920

socks5:
  address: 127.0.0.1
  port: 1080
  udp: udp
""".trimIndent()

    private fun buildNotification(status: String): Notification {
        val pi = PendingIntent.getActivity(
            this, 0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE
        )
        return Notification.Builder(this, CHANNEL_ID)
            .setContentTitle("NeoTUN")
            .setContentText(status)
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setContentIntent(pi)
            .setOngoing(true)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val ch = NotificationChannel(
                CHANNEL_ID, "NeoTUN DPI",
                NotificationManager.IMPORTANCE_LOW
            )
            getSystemService(NotificationManager::class.java)
                .createNotificationChannel(ch)
        }
    }
}
