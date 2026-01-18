package com.neotun.android.viewmodels

import android.app.Application
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.VpnService
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.neotun.android.models.ConnectionState
import com.neotun.android.models.VpnProfile
import com.neotun.android.service.NeoTunVpnService
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class MainViewModel(application: Application) : AndroidViewModel(application) {
    
    private val _connectionState = MutableStateFlow(ConnectionState.DISCONNECTED)
    val connectionState: StateFlow<ConnectionState> = _connectionState.asStateFlow()
    
    private val _profiles = MutableStateFlow<List<VpnProfile>>(emptyList())
    val profiles: StateFlow<List<VpnProfile>> = _profiles.asStateFlow()
    
    private val _activeProfile = MutableStateFlow<VpnProfile?>(null)
    val activeProfile: StateFlow<VpnProfile?> = _activeProfile.asStateFlow()
    
    private val _logs = MutableStateFlow<List<String>>(emptyList())
    val logs: StateFlow<List<String>> = _logs.asStateFlow()
    
    private val vpnStateReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                "com.neotun.android.VPN_STATE_CHANGED" -> {
                    val connected = intent.getBooleanExtra("connected", false)
                    val error = intent.getStringExtra("error")
                    
                    if (error != null) {
                        _connectionState.value = ConnectionState.ERROR
                        addLog("❌ VPN Error: $error")
                    } else if (connected) {
                        _connectionState.value = ConnectionState.CONNECTED
                        addLog("✅ VPN Connected Successfully!")
                        addLog("🔒 All traffic is now encrypted and routed through VPN")
                    } else {
                        _connectionState.value = ConnectionState.DISCONNECTED
                        addLog("🔌 VPN Disconnected")
                    }
                }
            }
        }
    }
    
    init {
        // Register broadcast receiver for VPN state changes
        val filter = IntentFilter("com.neotun.android.VPN_STATE_CHANGED")
        getApplication<Application>().registerReceiver(vpnStateReceiver, filter)
    }
    
    fun selectProfile(profile: VpnProfile) {
        _activeProfile.value = profile
    }
    
    fun addProfile(profile: VpnProfile) {
        try {
            val currentProfiles = _profiles.value.toMutableList()
            currentProfiles.add(profile)
            _profiles.value = currentProfiles
            
            // Set as active if it's the first profile
            if (_activeProfile.value == null) {
                _activeProfile.value = profile
            }
            
            addLog("📋 Profile '${profile.name}' added successfully")
        } catch (e: Exception) {
            addLog("❌ Failed to add profile: ${e.message}")
            android.util.Log.e("MainViewModel", "Failed to add profile", e)
        }
    }
    
    fun updateProfile(profile: VpnProfile) {
        try {
            val currentProfiles = _profiles.value.toMutableList()
            val index = currentProfiles.indexOfFirst { it.id == profile.id }
            if (index >= 0) {
                currentProfiles[index] = profile
                _profiles.value = currentProfiles
                
                // Update active profile if it's the same one
                if (_activeProfile.value?.id == profile.id) {
                    _activeProfile.value = profile
                }
                
                addLog("✏️ Profile '${profile.name}' updated")
            }
        } catch (e: Exception) {
            addLog("❌ Failed to update profile: ${e.message}")
            android.util.Log.e("MainViewModel", "Failed to update profile", e)
        }
    }
    
    fun deleteProfile(profile: VpnProfile) {
        try {
            val currentProfiles = _profiles.value.toMutableList()
            currentProfiles.removeAll { it.id == profile.id }
            _profiles.value = currentProfiles
            
            // If deleted profile was active, select another one
            if (_activeProfile.value?.id == profile.id) {
                _activeProfile.value = currentProfiles.firstOrNull()
            }
            
            addLog("🗑️ Profile '${profile.name}' deleted")
        } catch (e: Exception) {
            addLog("❌ Failed to delete profile: ${e.message}")
            android.util.Log.e("MainViewModel", "Failed to delete profile", e)
        }
    }
    
    fun connect() {
        val profile = _activeProfile.value ?: return
        
        viewModelScope.launch {
            try {
                // Check VPN permission
                val intent = VpnService.prepare(getApplication())
                if (intent != null) {
                    addLog("⚠️ VPN permission required - please grant permission")
                    // Permission will be requested by the activity
                    return@launch
                }
                
                _connectionState.value = ConnectionState.CONNECTING
                addLog("🚀 Starting REAL VPN connection...")
                addLog("📡 Profile: ${profile.name}")
                addLog("🌐 Server: ${profile.server}:${profile.port}")
                addLog("🔐 Protocol: ${profile.protocol}")
                addLog("⚙️ Initializing VPN service...")
                
                // Start VPN service
                val context = getApplication<Application>()
                val serviceIntent = Intent(context, NeoTunVpnService::class.java).apply {
                    action = NeoTunVpnService.ACTION_CONNECT
                    putExtra(NeoTunVpnService.EXTRA_PROFILE, profile)
                }
                
                context.startForegroundService(serviceIntent)
                addLog("🔄 VPN service started, establishing connection...")
                
            } catch (e: Exception) {
                _connectionState.value = ConnectionState.ERROR
                addLog("❌ Failed to start VPN: ${e.message}")
                android.util.Log.e("MainViewModel", "VPN connection failed", e)
            }
        }
    }
    
    fun disconnect() {
        _connectionState.value = ConnectionState.DISCONNECTING
        
        viewModelScope.launch {
            try {
                addLog("🔌 Disconnecting VPN...")
                
                // Stop VPN service
                val context = getApplication<Application>()
                val serviceIntent = Intent(context, NeoTunVpnService::class.java).apply {
                    action = NeoTunVpnService.ACTION_DISCONNECT
                }
                
                context.startService(serviceIntent)
                addLog("⏹️ VPN service stopping...")
                
            } catch (e: Exception) {
                addLog("⚠️ Disconnection error: ${e.message}")
                _connectionState.value = ConnectionState.DISCONNECTED
                android.util.Log.e("MainViewModel", "VPN disconnection failed", e)
            }
        }
    }
    
    private fun addLog(message: String) {
        try {
            val timestamp = java.text.SimpleDateFormat("HH:mm:ss", java.util.Locale.getDefault())
                .format(java.util.Date())
            val logEntry = "[$timestamp] $message"
            
            val currentLogs = _logs.value.toMutableList()
            currentLogs.add(logEntry)
            
            // Keep only last 100 log entries
            if (currentLogs.size > 100) {
                _logs.value = currentLogs.takeLast(100)
            } else {
                _logs.value = currentLogs
            }
        } catch (e: Exception) {
            android.util.Log.e("MainViewModel", "Failed to add log", e)
        }
    }
    
    fun clearLogs() {
        _logs.value = emptyList()
    }
    
    override fun onCleared() {
        super.onCleared()
        try {
            getApplication<Application>().unregisterReceiver(vpnStateReceiver)
        } catch (e: Exception) {
            android.util.Log.e("MainViewModel", "Failed to unregister receiver", e)
        }
    }
}