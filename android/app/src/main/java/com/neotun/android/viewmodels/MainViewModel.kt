package com.neotun.android.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.neotun.android.models.ConnectionState
import com.neotun.android.models.VpnProfile
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class MainViewModel : ViewModel() {
    
    private val _connectionState = MutableStateFlow(ConnectionState.DISCONNECTED)
    val connectionState: StateFlow<ConnectionState> = _connectionState.asStateFlow()
    
    private val _profiles = MutableStateFlow<List<VpnProfile>>(emptyList())
    val profiles: StateFlow<List<VpnProfile>> = _profiles.asStateFlow()
    
    private val _activeProfile = MutableStateFlow<VpnProfile?>(null)
    val activeProfile: StateFlow<VpnProfile?> = _activeProfile.asStateFlow()
    
    private val _logs = MutableStateFlow<List<String>>(emptyList())
    val logs: StateFlow<List<String>> = _logs.asStateFlow()
    
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
            
            addLog("Profile '${profile.name}' added successfully")
        } catch (e: Exception) {
            addLog("Failed to add profile: ${e.message}")
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
                
                addLog("Profile '${profile.name}' updated")
            }
        } catch (e: Exception) {
            addLog("Failed to update profile: ${e.message}")
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
            
            addLog("Profile '${profile.name}' deleted")
        } catch (e: Exception) {
            addLog("Failed to delete profile: ${e.message}")
            android.util.Log.e("MainViewModel", "Failed to delete profile", e)
        }
    }
    
    fun connect() {
        val profile = _activeProfile.value ?: return
        
        _connectionState.value = ConnectionState.CONNECTING
        
        viewModelScope.launch {
            try {
                addLog("Connecting to ${profile.name}...")
                addLog("Server: ${profile.server}:${profile.port}")
                addLog("Protocol: ${profile.protocol}")
                
                // Simulate connection process
                kotlinx.coroutines.delay(2000)
                
                _connectionState.value = ConnectionState.CONNECTED
                addLog("Connected successfully!")
                
            } catch (e: Exception) {
                _connectionState.value = ConnectionState.ERROR
                addLog("Connection failed: ${e.message}")
            }
        }
    }
    
    fun disconnect() {
        _connectionState.value = ConnectionState.DISCONNECTING
        
        viewModelScope.launch {
            try {
                addLog("Disconnecting...")
                
                // Simulate disconnection process
                kotlinx.coroutines.delay(1000)
                
                _connectionState.value = ConnectionState.DISCONNECTED
                addLog("Disconnected")
                
            } catch (e: Exception) {
                addLog("Disconnection error: ${e.message}")
                _connectionState.value = ConnectionState.DISCONNECTED
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
}