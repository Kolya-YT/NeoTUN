package com.neotun.core.models

import kotlinx.serialization.Serializable

@Serializable
enum class ConnectionState {
    DISCONNECTED,
    CONNECTING,
    CONNECTED,
    DISCONNECTING,
    ERROR
}

@Serializable
data class ConnectionStatus(
    val state: ConnectionState,
    val profile: VpnProfile? = null,
    val connectedAt: Long? = null,
    val bytesReceived: Long = 0,
    val bytesSent: Long = 0,
    val errorMessage: String? = null
)

@Serializable
data class ConnectionStats(
    val uptime: Long,
    val bytesReceived: Long,
    val bytesSent: Long,
    val speed: ConnectionSpeed
)

@Serializable
data class ConnectionSpeed(
    val downloadSpeed: Long, // bytes per second
    val uploadSpeed: Long    // bytes per second
)