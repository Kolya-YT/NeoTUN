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

    external fun nativeStart(tunFd: Int, fakeTtl: Int, disorder: Int): Int
    external fun nativeStop()

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

        val builder = Builder()
            .setSession("NeoTUN DPI")
            .addAddress("10.0.0.1", 32)
            .addRoute("0.0.0.0", 0)
            .setMtu(1500)
            .setBlocking(true)

        /* Исключаем само приложение чтобы не было петли */
        try { builder.addDisallowedApplication(packageName) } catch (_: Exception) {}

        tunInterface = builder.establish()
        val fd = tunInterface?.fd ?: run {
            Log.e(TAG, "Failed to establish VPN interface")
            stopSelf()
            return
        }

        val result = nativeStart(fd, fakeTtl = 5, disorder = 1)
        if (result != 0) {
            Log.e(TAG, "nativeStart failed: $result")
            tunInterface?.close()
            stopSelf()
            return
        }

        isRunning = true
        Log.i(TAG, "DPI bypass started, tun_fd=$fd")
        sendBroadcast(Intent("com.neotun.dpi.STATUS").putExtra("running", true))
    }

    private fun stopBypass() {
        nativeStop()
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

    private fun buildNotification(status: String): Notification {
        val pi = PendingIntent.getActivity(
            this, 0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE
        )
        return Notification.Builder(this, CHANNEL_ID)
            .setContentTitle("NeoTUN - DPI")
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
