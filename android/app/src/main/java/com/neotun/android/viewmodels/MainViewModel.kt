package com.neotun.android.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.neotun.android.models.ConnectionState
import com.neotun.android.models.VpnProfile
import com.neotun.android.repository.ProfileRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class MainViewModel(
    private val profileRepository: ProfileRepository
) : ViewModel() {
    
    private val _connectionState = MutableStateFlow(ConnectionState.DISCONNECTED)
    val connectionState: StateFlow<ConnectionState> = _connectionState.asStateFlow()
    
    private val _profiles = MutableStateFlow<List<VpnProfile>>(emptyList())
    val profiles: StateFlow<List<VpnProfile>> = _profiles.asStateFlow()
    
    private val _activeProfile = MutableStateFlow<VpnProfile?>(null)
    val activeProfile: StateFlow<VpnProfile?> = _activeProfile.asStateFlow()
    
    private val _logs = MutableStateFlow<List<String>>(emptyList())
    val logs: StateFlow<List<String>> = _logs.asStateFlow()
    
    init {
        loadProfiles()
    }
    
    private fun loadProfiles() {
        viewModelScope.launch {
            profileRepository.getAllProfiles().collect { profileList ->
                _profiles.value = profileList
                
                // Set first profile as active if none selected
                if (_activeProfile.value == null && profileList.isNotEmpty()) {
                    _activeProfile.value = profileList.first()
                }
            }
        }
    }
    
    fun selectProfile(profile: VpnProfile) {
        _activeProfile.value = profile
    }
    
    fun addProfile(profile: VpnProfile) {
        viewModelScope.launch {
            profileRepository.insertProfile(profile)
        }
    }
    
    fun updateProfile(profile: VpnProfile) {
        viewModelScope.launch {
            profileRepository.updateProfile(profile)
        }
    }
    
    fun deleteProfile(profile: VpnProfile) {
        viewModelScope.launch {
            profileRepository.deleteProfile(profile)
            
            // If deleted profile was active, select another one
            if (_activeProfile.value?.id == profile.id) {
                val remainingProfiles = _profiles.value.filter { it.id != profile.id }
                _activeProfile.value = remainingProfiles.firstOrNull()
            }
        }
    }
    
    fun connect() {
        val profile = _activeProfile.value ?: return
        
        _connectionState.value = ConnectionState.CONNECTING
        
        viewModelScope.launch {
            try {
                // TODO: Start VPN service with profile
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
                // TODO: Stop VPN service
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
        val timestamp = java.text.SimpleDateFormat("HH:mm:ss", java.util.Locale.getDefault())
            .format(java.util.Date())
        val logEntry = "[$timestamp] $message"
        
        _logs.value = _logs.value + logEntry
        
        // Keep only last 100 log entries
        if (_logs.value.size > 100) {
            _logs.value = _logs.value.takeLast(100)
        }
    }
    
    fun clearLogs() {
        _logs.value = emptyList()
    }
}