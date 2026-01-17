package com.neotun.android.config

import com.neotun.android.models.*
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import java.net.URI
import java.net.URLDecoder
import java.util.Base64

class UriParser {
    
    fun parseUri(uri: String): VpnProfile? {
        return try {
            if (uri.isBlank()) return null
            
            when {
                uri.startsWith("vmess://") -> parseVMessUri(uri)
                uri.startsWith("vless://") -> parseVLessUri(uri)
                uri.startsWith("trojan://") -> parseTrojanUri(uri)
                uri.startsWith("ss://") -> parseShadowsocksUri(uri)
                else -> null
            }
        } catch (e: Exception) {
            // Log error but don't crash
            android.util.Log.e("UriParser", "Failed to parse URI: ${e.message}", e)
            null
        }
    }
    
    private fun parseVMessUri(uri: String): VpnProfile? {
        return try {
            val base64Data = uri.removePrefix("vmess://")
            if (base64Data.isBlank()) return null
            
            val jsonString = String(Base64.getDecoder().decode(base64Data))
            if (jsonString.isBlank()) return null
            
            // Parse VMess JSON format
            val json = Json { 
                ignoreUnknownKeys = true
                isLenient = true
            }
            val vmessData = json.decodeFromString<VMessUriData>(jsonString)
            
            VpnProfile(
                name = vmessData.ps?.takeIf { it.isNotBlank() } ?: "VMess Server",
                protocol = VpnProtocol.VMESS,
                server = vmessData.add.takeIf { it.isNotBlank() } ?: return null,
                port = vmessData.port.toIntOrNull() ?: return null,
                credentials = VpnCredentials.VMess(
                    userId = vmessData.id.takeIf { it.isNotBlank() } ?: return null,
                    alterId = vmessData.aid,
                    security = vmessData.scy?.takeIf { it.isNotBlank() } ?: "auto"
                ),
                settings = VpnSettings(
                    network = vmessData.net?.takeIf { it.isNotBlank() } ?: "tcp",
                    security = vmessData.tls?.takeIf { it.isNotBlank() } ?: "none",
                    tlsSettings = if (vmessData.tls == "tls") {
                        TlsSettings(serverName = vmessData.sni?.takeIf { it.isNotBlank() })
                    } else null,
                    wsSettings = if (vmessData.net == "ws") {
                        WebSocketSettings(
                            path = vmessData.path?.takeIf { it.isNotBlank() } ?: "/",
                            headers = vmessData.host?.takeIf { it.isNotBlank() }?.let { 
                                mapOf("Host" to it) 
                            } ?: emptyMap()
                        )
                    } else null
                )
            )
        } catch (e: Exception) {
            android.util.Log.e("UriParser", "Failed to parse VMess URI", e)
            null
        }
    }
    
    private fun parseVLessUri(uri: String): VpnProfile? {
        return try {
            val parsedUri = URI(uri)
            val userId = parsedUri.userInfo?.takeIf { it.isNotBlank() } ?: return null
            val server = parsedUri.host?.takeIf { it.isNotBlank() } ?: return null
            val port = if (parsedUri.port > 0) parsedUri.port else return null
            
            val params = parseQueryParams(parsedUri.query ?: "")
            val fragment = try {
                URLDecoder.decode(parsedUri.fragment ?: "VLess Server", "UTF-8")
            } catch (e: Exception) {
                "VLess Server"
            }
            
            VpnProfile(
                name = fragment.takeIf { it.isNotBlank() } ?: "VLess Server",
                protocol = VpnProtocol.VLESS,
                server = server,
                port = port,
                credentials = VpnCredentials.VLess(
                    userId = userId,
                    flow = params["flow"],
                    encryption = params["encryption"] ?: "none"
                ),
                settings = VpnSettings(
                    network = params["type"] ?: "tcp",
                    security = params["security"] ?: "none",
                    tlsSettings = if (params["security"] == "tls") {
                        TlsSettings(serverName = params["sni"])
                    } else null,
                    realitySettings = if (params["security"] == "reality") {
                        RealitySettings(
                            publicKey = params["pbk"] ?: "",
                            shortId = params["sid"] ?: "",
                            serverName = params["sni"] ?: "",
                            fingerprint = params["fp"] ?: "chrome"
                        )
                    } else null
                )
            )
        } catch (e: Exception) {
            android.util.Log.e("UriParser", "Failed to parse VLess URI", e)
            null
        }
    }
    
    private fun parseTrojanUri(uri: String): VpnProfile? {
        val parsedUri = URI(uri)
        val password = parsedUri.userInfo
        val server = parsedUri.host
        val port = parsedUri.port
        
        val params = parseQueryParams(parsedUri.query ?: "")
        val fragment = URLDecoder.decode(parsedUri.fragment ?: "Trojan Server", "UTF-8")
        
        return VpnProfile(
            name = fragment,
            protocol = VpnProtocol.TROJAN,
            server = server,
            port = port,
            credentials = VpnCredentials.Trojan(password = password),
            settings = VpnSettings(
                network = params["type"] ?: "tcp",
                security = params["security"] ?: "tls",
                tlsSettings = TlsSettings(
                    serverName = params["sni"] ?: server,
                    allowInsecure = params["allowInsecure"] == "1"
                )
            )
        )
    }
    
    private fun parseShadowsocksUri(uri: String): VpnProfile? {
        val parsedUri = URI(uri)
        val userInfo = String(Base64.getDecoder().decode(parsedUri.userInfo))
        val parts = userInfo.split(":")
        
        if (parts.size != 2) return null
        
        val method = parts[0]
        val password = parts[1]
        val server = parsedUri.host
        val port = parsedUri.port
        val fragment = URLDecoder.decode(parsedUri.fragment ?: "Shadowsocks Server", "UTF-8")
        
        return VpnProfile(
            name = fragment,
            protocol = VpnProtocol.SHADOWSOCKS,
            server = server,
            port = port,
            credentials = VpnCredentials.Shadowsocks(
                method = method,
                password = password
            )
        )
    }
    
    private fun parseQueryParams(query: String): Map<String, String> {
        return query.split("&")
            .mapNotNull { param ->
                val parts = param.split("=", limit = 2)
                if (parts.size == 2) {
                    URLDecoder.decode(parts[0], "UTF-8") to URLDecoder.decode(parts[1], "UTF-8")
                } else null
            }
            .toMap()
    }
}

@Serializable
private data class VMessUriData(
    val v: String? = null,
    val ps: String? = null,
    val add: String,
    val port: String,
    val id: String,
    val aid: Int = 0,
    val scy: String? = null,
    val net: String? = null,
    val type: String? = null,
    val host: String? = null,
    val path: String? = null,
    val tls: String? = null,
    val sni: String? = null
)