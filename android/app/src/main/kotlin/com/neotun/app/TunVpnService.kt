package com.neotun.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import androidx.core.app.NotificationCompat
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.nio.ByteBuffer

class TunVpnService : VpnService() {
    private var vpnInterface: ParcelFileDescriptor? = null
    private var coreProcess: Process? = null
    private var xrayHelper: XrayHelper? = null
    private var isRunning = false
    private var tunThread: Thread? = null
    private var useNativeXray = false

    companion object {
        const val CHANNEL_ID = "neotun_tun_channel"
        const val NOTIFICATION_ID = 2
        const val ACTION_START = "com.neotun.app.TUN_START"
        const val ACTION_STOP = "com.neotun.app.TUN_STOP"
        const val EXTRA_CORE_TYPE = "core_type"
        const val EXTRA_CONFIG_PATH = "config_path"
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        xrayHelper = XrayHelper(applicationContext)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                val coreType = intent.getStringExtra(EXTRA_CORE_TYPE)
                val configPath = intent.getStringExtra(EXTRA_CONFIG_PATH)
                
                if (coreType != null && configPath != null) {
                    startTun(coreType, configPath)
                }
            }
            ACTION_STOP -> {
                stopTun()
                stopSelf()
            }
        }
        return START_STICKY
    }

    private fun startTun(coreType: String, configPath: String) {
        if (isRunning) {
            stopTun()
        }

        try {
            android.util.Log.i("TunVpnService", "Starting TUN mode for $coreType")
            
            // Создаем VPN интерфейс
            val builder = Builder()
                .setSession("NeoTUN")
                .addAddress("172.19.0.1", 30)
                .addRoute("0.0.0.0", 0)
                .addDnsServer("8.8.8.8")
                .addDnsServer("8.8.4.4")
                .setMtu(9000)
                .setBlocking(false)

            // Исключаем собственное приложение из VPN
            try {
                builder.addDisallowedApplication(packageName)
                android.util.Log.d("TunVpnService", "Excluded own package from VPN")
            } catch (e: Exception) {
                android.util.Log.w("TunVpnService", "Could not exclude own package: ${e.message}")
            }

            // Устанавливаем VPN интерфейс
            vpnInterface = builder.establish()

            if (vpnInterface == null) {
                android.util.Log.e("TunVpnService", "Failed to establish VPN interface - permission denied?")
                stopSelf()
                return
            }

            android.util.Log.i("TunVpnService", "✓ VPN interface established")

            // Запускаем foreground service сразу
            startForeground(NOTIFICATION_ID, createNotification("Starting TUN Mode..."))

            // Запускаем ядро с TUN конфигурацией
            startCore(coreType, configPath)

            // Запускаем обработку пакетов
            startPacketForwarding()

            isRunning = true
            
            // Обновляем уведомление
            val notification = createNotification("TUN Mode Active")
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager?.notify(NOTIFICATION_ID, notification)

            android.util.Log.i("TunVpnService", "✓ TUN VPN started successfully")

        } catch (e: Exception) {
            android.util.Log.e("TunVpnService", "Failed to start TUN: ${e.message}", e)
            e.printStackTrace()
            stopSelf()
        }
    }

    private fun startCore(coreType: String, configPath: String) {
        try {
            android.util.Log.i("TunVpnService", "startCore called: coreType=$coreType, configPath=$configPath")
            android.util.Log.i("TunVpnService", "xrayHelper is null: ${xrayHelper == null}")
            
            // Для Xray используем нативную библиотеку
            if (coreType == "xray" && xrayHelper != null) {
                android.util.Log.i("TunVpnService", "Using native AndroidLibXrayLite for TUN")
                useNativeXray = true
                
                android.util.Log.i("TunVpnService", "Calling xrayHelper.start with config: $configPath")
                val success = xrayHelper!!.start(configPath)
                android.util.Log.i("TunVpnService", "xrayHelper.start returned: $success")
                
                if (!success) {
                    throw Exception("Failed to start Xray via native library - check config file")
                }
                
                android.util.Log.i("TunVpnService", "✓ Native Xray started in TUN mode")
                android.util.Log.i("TunVpnService", "Xray version: ${xrayHelper!!.getVersion()}")
                return
            }
            
            // Для других ядер используем процессы
            android.util.Log.i("TunVpnService", "Using process execution for non-Xray core")
            useNativeXray = false
            
            val corePath = when (coreType) {
                "xray" -> "${applicationContext.filesDir}/cores/xray"
                "singbox" -> "${applicationContext.filesDir}/cores/sing-box"
                "hysteria2" -> "${applicationContext.filesDir}/cores/hysteria2"
                else -> return
            }

            val coreFile = File(corePath)
            coreFile.setExecutable(true, false)

            // Для sing-box используем TUN режим
            val args = if (coreType == "singbox") {
                listOf(corePath, "run", "-c", configPath)
            } else {
                listOf(corePath, "run", "-c", configPath)
            }

            val processBuilder = ProcessBuilder(args)
            processBuilder.redirectErrorStream(true)
            
            // Передаем file descriptor TUN интерфейса
            vpnInterface?.let { vpn ->
                processBuilder.environment()["TUN_FD"] = vpn.fd.toString()
            }

            coreProcess = processBuilder.start()

            // Мониторинг вывода
            Thread {
                try {
                    coreProcess?.inputStream?.bufferedReader()?.use { reader ->
                        reader.lineSequence().forEach { line ->
                            android.util.Log.d("TunCore", line)
                        }
                    }
                } catch (e: Exception) {
                    android.util.Log.e("TunCore", "Error reading output", e)
                }
            }.start()

        } catch (e: Exception) {
            android.util.Log.e("TunVpnService", "Failed to start core", e)
        }
    }

    private fun startPacketForwarding() {
        tunThread = Thread {
            try {
                val vpn = vpnInterface ?: return@Thread
                val inputStream = FileInputStream(vpn.fileDescriptor)
                val outputStream = FileOutputStream(vpn.fileDescriptor)
                val buffer = ByteBuffer.allocate(32767)

                while (isRunning && !Thread.currentThread().isInterrupted) {
                    val length = inputStream.channel.read(buffer)
                    if (length > 0) {
                        buffer.flip()
                        
                        // Здесь можно добавить обработку пакетов
                        // Пока просто пропускаем через ядро
                        
                        outputStream.channel.write(buffer)
                        buffer.clear()
                    }
                }
            } catch (e: Exception) {
                if (isRunning) {
                    android.util.Log.e("TunVpnService", "Packet forwarding error", e)
                }
            }
        }
        tunThread?.start()
    }

    private fun stopTun() {
        try {
            isRunning = false
            
            tunThread?.interrupt()
            tunThread = null

            // Останавливаем нативный Xray если использовался
            if (useNativeXray && xrayHelper != null) {
                xrayHelper!!.stop()
                android.util.Log.i("TunVpnService", "✓ Native Xray stopped")
            }

            coreProcess?.destroy()
            coreProcess?.waitFor()
            coreProcess = null

            vpnInterface?.close()
            vpnInterface = null
            
            useNativeXray = false

            android.util.Log.i("TunVpnService", "✓ TUN VPN stopped")
        } catch (e: Exception) {
            android.util.Log.e("TunVpnService", "Error stopping TUN", e)
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "TUN VPN Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "NeoTUN TUN Mode"
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
            .setContentTitle("NeoTUN - TUN Mode")
            .setContentText(text)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    override fun onDestroy() {
        stopTun()
        super.onDestroy()
    }
}
