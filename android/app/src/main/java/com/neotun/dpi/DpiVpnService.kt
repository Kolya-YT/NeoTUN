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
    private var workerThread: Thread? = null

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
        startForeground(NOTIF_ID, buildNotification("Запуск..."))

        // Run everything in a background thread — never block the service main thread
        workerThread = Thread({
            doStart()
        }, "neotun-worker").also { it.start() }
    }

    private fun doStart() {
        // 1. Start SOCKS5 bypass proxy on 127.0.0.1:1080
        val proxyResult = try {
            nativeStartProxy(splitPos = 2, disorder = 0, tlsrecSplit = 1, oob = 1)
        } catch (e: Exception) {
            Log.e(TAG, "nativeStartProxy exception: ${e.message}")
            -1
        }

        if (proxyResult != 0) {
            Log.e(TAG, "nativeStartProxy failed: $proxyResult")
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            return
        }
        Log.i(TAG, "SOCKS5 proxy started on :1080")

        // 2. Create TUN interface (must be called from service thread, not worker)
        val pfd = try {
            Builder()
                .setSession("NeoTUN")
                .addAddress("10.10.10.10", 32)
                .addRoute("0.0.0.0", 0)
                .addAddress("fd00::1", 128)
                .addRoute("::", 0)
                .addDnsServer("8.8.8.8")
                .addDnsServer("8.8.4.4")
                .setMtu(8500)
                .apply {
                    try { addDisallowedApplication(packageName) } catch (_: Exception) {}
                }
                .establish()
        } catch (e: Exception) {
            Log.e(TAG, "VPN establish exception: ${e.message}")
            null
        }

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

        // 3. Write config and start hev-socks5-tunnel
        val config = buildTun2SocksConfig()
        val configFile = try {
            File.createTempFile("neotun_cfg", ".yml", cacheDir).also {
                it.writeText(config)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Config write failed: ${e.message}")
            nativeStopProxy()
            pfd.close()
            tunInterface = null
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            return
        }

        Log.i(TAG, "Starting hev-socks5-tunnel with fd=$fd")
        try {
            TProxyService.startService(configFile.absolutePath, fd)
        } catch (e: Exception) {
            Log.e(TAG, "TProxyService.startService failed: ${e.message}")
            nativeStopProxy()
            pfd.close()
            tunInterface = null
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            return
        }

        isRunning = true
        updateNotification("Работает")
        Log.i(TAG, "DPI bypass started successfully")
        sendBroadcast(Intent("com.neotun.dpi.STATUS").putExtra("running", true))
    }

    private fun stopBypass() {
        if (!isRunning && tunInterface == null) return
        isRunning = false

        try { TProxyService.stopService() } catch (e: Exception) { Log.e(TAG, "TProxyService stop: ${e.message}") }
        try { nativeStopProxy() } catch (e: Exception) { Log.e(TAG, "nativeStopProxy: ${e.message}") }
        try { tunInterface?.close() } catch (e: Exception) { Log.e(TAG, "tun close: ${e.message}") }
        tunInterface = null

        workerThread?.interrupt()
        workerThread = null

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

    private fun updateNotification(status: String) {
        val nm = getSystemService(NotificationManager::class.java)
        nm.notify(NOTIF_ID, buildNotification(status))
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
