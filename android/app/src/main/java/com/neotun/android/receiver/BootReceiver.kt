package com.neotun.android.receiver

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "BootReceiver"
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_PACKAGE_REPLACED -> {
                Log.d(TAG, "Boot completed or package replaced: ${intent.action}")
                
                // TODO: Check if auto-start is enabled in preferences
                // TODO: Start VPN service if needed
                
                // For now, just log the event
                Log.i(TAG, "NeoTUN boot receiver triggered")
            }
        }
    }
}