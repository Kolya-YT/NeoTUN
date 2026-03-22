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

        @Volatile var isRunning = false

        init {
            try {
                System.loadLibrary("neotun_bypass")
                Log.i(TAG, "neotun_bypass loaded")
            } catch (e: UnsatisfiedLinkError) {
                Log.e(TAG, "Failed to load neotun_bypass: ${e.message}")
            }
        }
    }

    private var tunInterface: ParcelFileDescriptor? = null

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

        // 1. Запускаем SOCKS5 bypass прокси на 127.0.0.1:1080
        val proxyResult = nativeStartProxy(
            splitPos    = 2,
            disorder    = 0,
            tlsrecSplit = 1,
            oob         = 1
        )
        if (proxyResult != 0) {
            Log.e(TAG, "nativeStartProxy failed: $proxyResult")
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            return
        }
        Log.i(TAG, "SOCKS5 proxy started on :1080")

        // 2. Создаём TUN интерфейс
        val builder = Builder()
            .setSession("NeoTUN")
            .addAddress("10.10.10.10", 32)
            .addRoute("0.0.0.0", 0)
            .addAddress("fd00::1", 128)
            .addRoute("::", 0)
            .addDnsServer("8.8.8.8")
            .addDnsServer("8.8.4.4")
            .setMtu(8500)
            .setBlocking(false)  // non-blocking — hev-socks5-tunnel expects this

        try { builder.addDisallowedApplication(packageName) } catch (_: Exception) {}

        val pfd = builder.establish()
        if (pfd == null) {
            Log.e(TAG, "Failed to establish VPN interface")
            nativeStopProxy()
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            return
        }
        tunInterface = pfd
        val fd = pfd.fd
        Log.i(TAG, "TUN established, fd=$fd")

        // 3. Запускаем hev-socks5-tunnel: TUN → SOCKS5 127.0.0.1:1080
        val config = buildTun2SocksConfig()
        val configFile = File.createTempFile("neotun_cfg", ".yml", cacheDir)
        configFile.writeText(config)
        Log.i(TAG, "Config: ${configFile.absolutePath}")

        TProxyService.startService(configFile.absolutePath, fd)

        isRunning = true
        Log.i(TAG, "DPI bypass started")
        sendBroadcast(Intent("com.neotun.dpi.STATUS").putExtra("running", true))
    }

    private fun stopBypass() {
        if (!isRunning && tunInterface == null) return
        isRunning = false

        TProxyService.stopService()
        nativeStopProxy()
        tunInterface?.close()
        tunInterface = null

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
                CHANNEL_ID, "NeoTUN",
                NotificationManager.IMPORTANCE_LOW
            )
            getSystemService(NotificationManager::class.java)
                .createNotificationChannel(ch)
        }
    }
}
