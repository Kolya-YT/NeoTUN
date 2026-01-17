package com.neotun.android.service

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import androidx.core.app.NotificationCompat
import com.neotun.android.MainActivity
import com.neotun.android.R
import com.neotun.core.config.XrayConfigGenerator
import com.neotun.core.models.ConnectionState
import com.neotun.core.models.VpnProfile
import kotlinx.coroutines.*
import java.io.FileInputStream
import java.io.FileOutputStream
import java.nio.ByteBuffer

class NeoTunVpnService : VpnService() {
    
    companion object {
        const val ACTION_CONNECT = "com.neotun.android.CONNECT"
        const val ACTION_DISCONNECT = "com.neotun.android.DISCONNECT"
        const val EXTRA_PROFILE = "profile"
        private const val NOTIFICATION_ID = 1
        private const val CHANNEL_ID = "neotun_vpn"
    }
    
    private var vpnInterface: ParcelFileDescriptor? = null
    private var xrayProcess: Process? = null
    private val serviceScope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private val configGenerator = XrayConfigGenerator()
    
    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_CONNECT -> {
                val profile = intent.getSerializableExtra(EXTRA_PROFILE) as? VpnProfile
                profile?.let { connect(it) }
            }
            ACTION_DISCONNECT -> {
                disconnect()
            }
        }
        return START_STICKY
    }
    
    private fun connect(profile: VpnProfile) {
        serviceScope.launch {
            try {
                // Update connection state
                updateConnectionState(ConnectionState.CONNECTING)
                
                // Start Xray process
                startXrayProcess(profile)
                
                // Setup VPN interface
                setupVpnInterface(profile)
                
                // Start packet forwarding
                startPacketForwarding()
                
                // Show notification
                startForeground(NOTIFICATION_ID, createNotification(profile))
                
                // Update connection state
                updateConnectionState(ConnectionState.CONNECTED)
                
            } catch (e: Exception) {
                updateConnectionState(ConnectionState.ERROR)
                stopSelf()
            }
        }
    }
    
    private fun disconnect() {
        serviceScope.launch {
            updateConnectionState(ConnectionState.DISCONNECTING)
            
            // Stop packet forwarding
            serviceScope.coroutineContext.cancelChildren()
            
            // Close VPN interface
            vpnInterface?.close()
            vpnInterface = null
            
            // Stop Xray process
            xrayProcess?.destroy()
            xrayProcess = null
            
            updateConnectionState(ConnectionState.DISCONNECTED)
            stopForeground(true)
            stopSelf()
        }
    }
    
    private suspend fun startXrayProcess(profile: VpnProfile) = withContext(Dispatchers.IO) {
        val configJson = configGenerator.generateConfig(profile)
        val configFile = createTempFile("xray_config", ".json", cacheDir)
        configFile.writeText(configJson)
        
        val xrayBinary = extractXrayBinary()
        
        val processBuilder = ProcessBuilder(
            xrayBinary.absolutePath,
            "-config", configFile.absolutePath
        )
        
        xrayProcess = processBuilder.start()
        
        // Monitor process output
        launch {
            xrayProcess?.inputStream?.bufferedReader()?.useLines { lines ->
                lines.forEach { line ->
                    // Log Xray output
                    android.util.Log.d("NeoTun", "Xray: $line")
                }
            }
        }
        
        // Wait for Xray to start
        delay(2000)
        
        if (xrayProcess?.isAlive != true) {
            throw RuntimeException("Failed to start Xray process")
        }
    }
    
    private fun setupVpnInterface(profile: VpnProfile) {
        val builder = Builder()
            .setSession("NeoTUN")
            .addAddress("10.0.0.2", 24)
            .addDnsServer("8.8.8.8")
            .addDnsServer("8.8.4.4")
            .addRoute("0.0.0.0", 0)
            .setMtu(1500)
        
        // Exclude local addresses
        builder.addDisallowedApplication(packageName)
        
        vpnInterface = builder.establish()
            ?: throw RuntimeException("Failed to establish VPN interface")
    }
    
    private fun startPacketForwarding() {
        val vpnInput = FileInputStream(vpnInterface!!.fileDescriptor)
        val vpnOutput = FileOutputStream(vpnInterface!!.fileDescriptor)
        
        serviceScope.launch {
            val buffer = ByteBuffer.allocate(32767)
            
            while (isActive) {
                try {
                    val length = vpnInput.channel.read(buffer)
                    if (length > 0) {
                        // Forward packet to Xray via SOCKS proxy
                        // This is a simplified example - real implementation would
                        // need proper packet parsing and forwarding
                        buffer.flip()
                        
                        // Process packet here
                        processPacket(buffer)
                        
                        buffer.clear()
                    }
                } catch (e: Exception) {
                    if (isActive) {
                        android.util.Log.e("NeoTun", "Packet forwarding error", e)
                    }
                    break
                }
            }
        }
    }
    
    private suspend fun processPacket(packet: ByteBuffer) {
        // Simplified packet processing
        // Real implementation would parse IP packets and forward to SOCKS proxy
        // This requires implementing a full TCP/UDP stack or using a library like lwIP
    }
    
    private fun extractXrayBinary(): java.io.File {
        val xrayFile = java.io.File(filesDir, "xray")
        
        if (!xrayFile.exists()) {
            assets.open("xray").use { input ->
                xrayFile.outputStream().use { output ->
                    input.copyTo(output)
                }
            }
            xrayFile.setExecutable(true)
        }
        
        return xrayFile
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
    
    private fun createNotification(profile: VpnProfile): Notification {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("NeoTUN Connected")
            .setContentText("Connected to ${profile.name}")
            .setSmallIcon(R.drawable.ic_vpn)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()
    }
    
    private fun updateConnectionState(state: ConnectionState) {
        // Broadcast connection state change
        val intent = Intent("com.neotun.CONNECTION_STATE_CHANGED")
        intent.putExtra("state", state.name)
        sendBroadcast(intent)
    }
    
    override fun onDestroy() {
        super.onDestroy()
        serviceScope.cancel()
        disconnect()
    }
}