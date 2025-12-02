package com.neotun.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log
import androidx.core.app.NotificationCompat
import kotlinx.coroutines.*
import java.io.File

/**
 * V2rayVpnService - VPN сервис для Xray
 * Архитектура полностью как в v2rayNG:
 * - Использует libxray.aar через JNI
 * - VPN интерфейс с TUN
 * - Корутины для асинхронных операций
 * 
 * Основано на: https://github.com/2dust/v2rayNG
 */
class V2rayVpnService : VpnService() {
    
    companion object {
        private const val TAG = "V2rayVpnService"
        private const val CHANNEL_ID = "neotun_vpn_channel"
        private const val NOTIFICATION_ID = 1
        
        const val ACTION_START = "com.neotun.app.START_VPN"
        const val ACTION_STOP = "com.neotun.app.STOP_VPN"
        const val EXTRA_CONFIG_PATH = "config_path"
        
        var isRunning = false
            private set
    }
    
    private var vpnInterface: ParcelFileDescriptor? = null
    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    
    override fun onCreate() {
        super.onCreate()
        Log.i(TAG, "Service created")
        createNotificationChannel()
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                val configPath = intent.getStringExtra(EXTRA_CONFIG_PATH)
                if (configPath != null) {
                    startVpn(configPath)
                } else {
                    Log.e(TAG, "Config path is null")
                    stopSelf()
                }
            }
            ACTION_STOP -> {
                stopVpn()
            }
        }
        return START_STICKY
    }
    
    private fun startVpn(configPath: String) {
        serviceScope.launch {
            try {
                Log.i(TAG, "=== Starting VPN ===")
                Log.i(TAG, "Config path: $configPath")
                
                // Проверяем конфигурацию
                val configFile = File(configPath)
                if (!configFile.exists()) {
                    Log.e(TAG, "✗ Config file not found: $configPath")
                    stopSelf()
                    return@launch
                }
                Log.i(TAG, "✓ Config file exists, size: ${configFile.length()} bytes")
                
                // Показываем уведомление
                startForeground(NOTIFICATION_ID, createNotification("Connecting..."))
                Log.i(TAG, "✓ Foreground notification shown")
                
                // Настраиваем VPN интерфейс как в v2rayNG
                Log.i(TAG, "Building VPN interface...")
                val builder = Builder()
                    .setSession("NeoTUN")
                    .setMtu(1500)
                    .addAddress("172.19.0.1", 30)
                    .addRoute("0.0.0.0", 0)
                    .addDnsServer("1.1.1.1")
                    .addDnsServer("8.8.8.8")
                    .setBlocking(false)
                
                // Исключаем наше приложение из VPN
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    try {
                        builder.addDisallowedApplication(packageName)
                        Log.i(TAG, "✓ App excluded from VPN")
                    } catch (e: Exception) {
                        Log.w(TAG, "⚠ Failed to exclude app from VPN: ${e.message}")
                    }
                }
                
                Log.i(TAG, "Establishing VPN interface...")
                vpnInterface = builder.establish()
                
                if (vpnInterface == null) {
                    Log.e(TAG, "✗ Failed to establish VPN interface - user may have denied permission")
                    stopSelf()
                    return@launch
                }
                
                val fd = vpnInterface!!.fd
                Log.i(TAG, "✓ VPN interface established, fd: $fd")
                
                // Защищаем сокет от VPN (важно для работы)
                if (protect(fd)) {
                    Log.i(TAG, "✓ Socket protected")
                } else {
                    Log.w(TAG, "⚠ Failed to protect socket")
                }
                
                // Запускаем Xray через libv2ray как в v2rayNG
                val assetPath = applicationContext.filesDir.absolutePath
                Log.i(TAG, "Asset path: $assetPath")
                Log.i(TAG, "Starting Xray core...")
                
                val result = withContext(Dispatchers.IO) {
                    XrayHelper.runXray(configPath, assetPath, fd)
                }
                
                if (result == 0) {
                    isRunning = true
                    updateNotification("Connected")
                    Log.i(TAG, "✓✓✓ VPN started successfully ✓✓✓")
                } else {
                    Log.e(TAG, "✗✗✗ Xray failed with code: $result ✗✗✗")
                    stopVpn()
                }
                
            } catch (e: Exception) {
                Log.e(TAG, "✗✗✗ Error starting VPN: ${e.message}", e)
                e.printStackTrace()
                stopVpn()
            }
        }
    }
    
    private fun stopVpn() {
        serviceScope.launch {
            try {
                Log.i(TAG, "Stopping VPN...")
                
                // Останавливаем Xray
                withContext(Dispatchers.IO) {
                    XrayHelper.stopXray()
                }
                
                // Закрываем VPN интерфейс
                vpnInterface?.close()
                vpnInterface = null
                
                isRunning = false
                
                Log.i(TAG, "✓ VPN stopped")
                
                stopForeground(true)
                stopSelf()
                
            } catch (e: Exception) {
                Log.e(TAG, "Error stopping VPN: ${e.message}", e)
            }
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        Log.i(TAG, "Service destroyed")
        stopVpn()
        serviceScope.cancel()
    }
    
    override fun onRevoke() {
        super.onRevoke()
        Log.i(TAG, "VPN permission revoked")
        stopVpn()
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "NeoTUN VPN",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "NeoTUN VPN Service"
                setShowBadge(false)
            }
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    private fun createNotification(status: String): Notification {
        val intent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("NeoTUN")
            .setContentText(status)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()
    }
    
    private fun updateNotification(status: String) {
        val notificationManager = getSystemService(NotificationManager::class.java)
        notificationManager.notify(NOTIFICATION_ID, createNotification(status))
    }
}
