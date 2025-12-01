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
    private var useNativeLib = true // Use AndroidLibXrayLite by default

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
            // Check if this is Xray and use native library
            if (useNativeLib && corePath.contains("xray", ignoreCase = true)) {
                android.util.Log.d("VpnService", "Using AndroidLibXrayLite for Xray")
                startXrayNative(configPath)
                return
            }
            
            // Fallback to process execution for other cores
            val coreFile = File(corePath)
            if (!coreFile.exists()) {
                throw Exception("Core file not found: $corePath")
            }
            
            android.util.Log.d("VpnService", "Core path: $corePath")
            
            // Copy to /data/local/tmp which usually has exec permissions
            val tmpCore = File("/data/local/tmp/${coreFile.name}")
            try {
                coreFile.copyTo(tmpCore, overwrite = true)
                Runtime.getRuntime().exec(arrayOf("chmod", "755", tmpCore.absolutePath)).waitFor()
                android.util.Log.d("VpnService", "Copied to tmp: ${tmpCore.absolutePath}")
            } catch (e: Exception) {
                android.util.Log.w("VpnService", "Failed to copy to tmp, using original path", e)
                Runtime.getRuntime().exec(arrayOf("chmod", "755", corePath)).waitFor()
            }
            
            val execPath = if (tmpCore.exists()) tmpCore.absolutePath else corePath

            // Build command
            val command = mutableListOf<String>()
            command.add(execPath)
            command.addAll(args)
            command.add(configPath)
            
            android.util.Log.d("VpnService", "Starting: ${command.joinToString(" ")}")

            // Start process
            val runtime = Runtime.getRuntime()
            coreProcess = runtime.exec(
                command.toTypedArray(),
                arrayOf("PATH=/system/bin:/system/xbin"),
                File(execPath).parentFile
            )
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

    private fun startXrayNative(configPath: String) {
        try {
            val configFile = File(configPath)
            if (!configFile.exists()) {
                throw Exception("Config file not found: $configPath")
            }
            
            val configContent = configFile.readText()
            android.util.Log.d("VpnService", "Starting Xray with native library")
            
            val success = xrayHelper?.start(configContent) ?: false
            if (success) {
                isRunning = true
                startForeground(NOTIFICATION_ID, createNotification("Proxy Connected"))
            } else {
                throw Exception("Failed to start Xray native library")
            }
        } catch (e: Exception) {
            android.util.Log.e("VpnService", "Failed to start Xray native", e)
            stopSelf()
        }
    }

    private fun stopCore() {
        try {
            if (xrayHelper?.getRunning() == true) {
                xrayHelper?.stop()
            }
            coreProcess?.destroy()
            coreProcess?.waitFor()
            coreProcess = null
            isRunning = false
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
