package com.neotun.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import java.io.BufferedReader
import java.io.File
import java.io.InputStreamReader

class VpnService : Service() {
    private var coreProcess: Process? = null
    private var xrayHelper: XrayHelper? = null
    private var isRunning = false
    private var useNativeXray = false

    companion object {
        const val CHANNEL_ID = "neotun_vpn_channel"
        const val NOTIFICATION_ID = 1
        const val ACTION_START = "com.neotun.app.START"
        const val ACTION_STOP = "com.neotun.app.STOP"
        const val EXTRA_CORE_PATH = "core_path"
        const val EXTRA_CONFIG_PATH = "config_path"
        const val EXTRA_ARGS = "args"
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        xrayHelper = XrayHelper(applicationContext)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                val corePath = intent.getStringExtra(EXTRA_CORE_PATH)
                val configPath = intent.getStringExtra(EXTRA_CONFIG_PATH)
                val args = intent.getStringArrayExtra(EXTRA_ARGS)
                
                if (corePath != null && configPath != null) {
                    startCore(corePath, configPath, args ?: emptyArray())
                }
            }
            ACTION_STOP -> {
                stopCore()
                stopSelf()
            }
        }
        return START_STICKY
    }

    private fun startCore(corePath: String, configPath: String, args: Array<String>) {
        if (isRunning) {
            stopCore()
        }

        try {
            // Определяем тип ядра по пути
            val isXray = corePath.contains("xray", ignoreCase = true)
            
            // Для Xray используем нативную библиотеку AndroidLibXrayLite
            if (isXray && xrayHelper != null) {
                android.util.Log.i("VpnService", "Using native AndroidLibXrayLite")
                useNativeXray = true
                
                val success = xrayHelper!!.start(configPath)
                if (!success) {
                    throw Exception("Failed to start Xray via native library")
                }
                
                isRunning = true
                startForeground(NOTIFICATION_ID, createNotification("VPN Connected (Native Xray)"))
                
                android.util.Log.i("VpnService", "✓ Native Xray started successfully")
                android.util.Log.i("VpnService", "Xray version: ${xrayHelper!!.getVersion()}")
                return
            }
            
            // Для других ядер (sing-box, hysteria2) используем старый метод
            android.util.Log.i("VpnService", "Using process execution for non-Xray core")
            useNativeXray = false
            
            val coreFile = File(corePath)
            if (!coreFile.exists()) {
                throw Exception("Core file not found: $corePath")
            }
            
            android.util.Log.d("VpnService", "Core path: $corePath")
            
            // Build command string
            val commandStr = buildString {
                append(corePath)
                args.forEach { arg ->
                    append(" ")
                    if (arg.contains(" ")) {
                        append("\"$arg\"")
                    } else {
                        append(arg)
                    }
                }
                append(" \"$configPath\"")
            }
            
            android.util.Log.d("VpnService", "Command: $commandStr")
            
            // Try with su if available, otherwise regular exec
            var process: Process? = null
            try {
                // Try root first
                Runtime.getRuntime().exec(arrayOf("chmod", "777", corePath)).waitFor()
                process = Runtime.getRuntime().exec(arrayOf("su", "-c", commandStr))
                android.util.Log.d("VpnService", "Started with su (root)")
            } catch (e: Exception) {
                android.util.Log.w("VpnService", "Root not available, trying regular exec", e)
                // Fallback to regular exec
                Runtime.getRuntime().exec(arrayOf("chmod", "755", corePath)).waitFor()
                process = Runtime.getRuntime().exec(arrayOf("sh", "-c", commandStr))
                android.util.Log.d("VpnService", "Started with sh")
            }
            
            coreProcess = process
            isRunning = true

            // Start foreground service
            startForeground(NOTIFICATION_ID, createNotification("VPN Connected"))

            // Monitor process output
            Thread {
                try {
                    val reader = BufferedReader(InputStreamReader(coreProcess?.inputStream))
                    var line: String?
                    while (reader.readLine().also { line = it } != null) {
                        android.util.Log.d("VpnService", "Core: $line")
                    }
                } catch (e: Exception) {
                    android.util.Log.e("VpnService", "Error reading core output", e)
                }
            }.start()
            
            // Monitor process errors
            Thread {
                try {
                    val reader = BufferedReader(InputStreamReader(coreProcess?.errorStream))
                    var line: String?
                    while (reader.readLine().also { line = it } != null) {
                        android.util.Log.e("VpnService", "Core Error: $line")
                    }
                } catch (e: Exception) {
                    android.util.Log.e("VpnService", "Error reading core errors", e)
                }
            }.start()

        } catch (e: Exception) {
            android.util.Log.e("VpnService", "Failed to start core", e)
            stopSelf()
        }
    }

    private fun stopCore() {
        try {
            // Если использовали нативный Xray
            if (useNativeXray && xrayHelper != null) {
                xrayHelper!!.stop()
                android.util.Log.i("VpnService", "✓ Native Xray stopped")
            }
            
            // Останавливаем процесс если был запущен
            coreProcess?.destroy()
            coreProcess?.waitFor()
            coreProcess = null
            
            isRunning = false
            useNativeXray = false
        } catch (e: Exception) {
            android.util.Log.e("VpnService", "Error stopping core", e)
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "VPN Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "NeoTUN VPN Service"
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(text: String): Notification {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("NeoTUN")
            .setContentText(text)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentIntent(pendingIntent)
            .build()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        stopCore()
        super.onDestroy()
    }
}
