package com.neotun.android.database

import androidx.room.Entity
import androidx.room.PrimaryKey
import com.neotun.android.models.*
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

@Entity(tableName = "profiles")
data class ProfileEntity(
    @PrimaryKey
    val id: String,
    val name: String,
    val protocol: String,
    val server: String,
    val port: Int,
    val credentialsJson: String,
    val settingsJson: String,
    val createdAt: Long,
    val lastUsed: Long?
) {
    companion object {
        fun fromVpnProfile(profile: VpnProfile): ProfileEntity {
            return ProfileEntity(
                id = profile.id,
                name = profile.name,
                protocol = profile.protocol.name,
                server = profile.server,
                port = profile.port,
                credentialsJson = Json.encodeToString(profile.credentials),
                settingsJson = Json.encodeToString(profile.settings),
                createdAt = profile.createdAt,
                lastUsed = profile.lastUsed
            )
        }
    }
    
    fun toVpnProfile(): VpnProfile {
        val protocol = VpnProtocol.valueOf(this.protocol)
        val credentials = when (protocol) {
            VpnProtocol.VMESS -> Json.decodeFromString<VpnCredentials.VMess>(credentialsJson)
            VpnProtocol.VLESS -> Json.decodeFromString<VpnCredentials.VLess>(credentialsJson)
            VpnProtocol.TROJAN -> Json.decodeFromString<VpnCredentials.Trojan>(credentialsJson)
            VpnProtocol.SHADOWSOCKS -> Json.decodeFromString<VpnCredentials.Shadowsocks>(credentialsJson)
        }
        val settings = Json.decodeFromString<VpnSettings>(settingsJson)
        
        return VpnProfile(
            id = id,
            name = name,
            protocol = protocol,
            server = server,
            port = port,
            credentials = credentials,
            settings = settings,
            createdAt = createdAt,
            lastUsed = lastUsed
        )
    }
}