package com.neotun.android

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build

class NeoTunApplication : Application() {
    
    companion object {
        const val VPN_NOTIFICATION_CHANNEL_ID = "vpn_service_channel"
        const val VPN_NOTIFICATION_CHANNEL_NAME = "VPN Service"
    }
    
    override fun onCreate() {
        super.onCreate()
        createNotificationChannels()
    }
    
    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(NotificationManager::class.java)
            
            // VPN Service notification channel
            val vpnChannel = NotificationChannel(
                VPN_NOTIFICATION_CHANNEL_ID,
                VPN_NOTIFICATION_CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Notifications for VPN service status"
                setShowBadge(false)
            }
            
            notificationManager.createNotificationChannel(vpnChannel)
        }
    }
}