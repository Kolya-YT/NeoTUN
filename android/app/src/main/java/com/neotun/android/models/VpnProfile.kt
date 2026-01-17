package com.neotun.android.models

import kotlinx.serialization.Serializable

@Serializable
data class VpnProfile(
    val id: String = generateId(),
    val name: String,
    val protocol: VpnProtocol,
    val server: String,
    val port: Int,
    val credentials: VpnCredentials,
    val settings: VpnSettings = VpnSettings(),
    val createdAt: Long = System.currentTimeMillis(),
    val lastUsed: Long? = null
)

private fun generateId(): String {
    return "profile_${System.currentTimeMillis()}_${(1000..9999).random()}"
}

@Serializable
enum class VpnProtocol {
    VMESS,
    VLESS,
    TROJAN,
    SHADOWSOCKS
}

@Serializable
sealed class VpnCredentials {
    @Serializable
    data class VMess(
        val userId: String,
        val alterId: Int = 0,
        val security: String = "auto"
    ) : VpnCredentials()
    
    @Serializable
    data class VLess(
        val userId: String,
        val flow: String? = null,
        val encryption: String = "none"
    ) : VpnCredentials()
    
    @Serializable
    data class Trojan(
        val password: String
    ) : VpnCredentials()
    
    @Serializable
    data class Shadowsocks(
        val method: String,
        val password: String
    ) : VpnCredentials()
}

@Serializable
data class VpnSettings(
    val network: String = "tcp",
    val security: String = "none",
    val tlsSettings: TlsSettings? = null,
    val wsSettings: WebSocketSettings? = null,
    val realitySettings: RealitySettings? = null
)

@Serializable
data class TlsSettings(
    val serverName: String? = null,
    val allowInsecure: Boolean = false,
    val alpn: List<String> = emptyList()
)

@Serializable
data class WebSocketSettings(
    val path: String = "/",
    val headers: Map<String, String> = emptyMap()
)

@Serializable
data class RealitySettings(
    val publicKey: String,
    val shortId: String,
    val serverName: String,
    val fingerprint: String = "chrome"
)