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
            when {
                uri.startsWith("vmess://") -> parseVMessUri(uri)
                uri.startsWith("vless://") -> parseVLessUri(uri)
                uri.startsWith("trojan://") -> parseTrojanUri(uri)
                uri.startsWith("ss://") -> parseShadowsocksUri(uri)
                else -> null
            }
        } catch (e: Exception) {
            null
        }
    }
    
    private fun parseVMessUri(uri: String): VpnProfile? {
        val base64Data = uri.removePrefix("vmess://")
        val jsonString = String(Base64.getDecoder().decode(base64Data))
        
        // Parse VMess JSON format
        val json = Json { ignoreUnknownKeys = true }
        val vmessData = json.decodeFromString<VMessUriData>(jsonString)
        
        return VpnProfile(
            name = vmessData.ps ?: "VMess Server",
            protocol = VpnProtocol.VMESS,
            server = vmessData.add,
            port = vmessData.port.toInt(),
            credentials = VpnCredentials.VMess(
                userId = vmessData.id,
                alterId = vmessData.aid,
                security = vmessData.scy ?: "auto"
            ),
            settings = VpnSettings(
                network = vmessData.net ?: "tcp",
                security = vmessData.tls ?: "none",
                tlsSettings = if (vmessData.tls == "tls") {
                    TlsSettings(serverName = vmessData.sni)
                } else null,
                wsSettings = if (vmessData.net == "ws") {
                    WebSocketSettings(
                        path = vmessData.path ?: "/",
                        headers = vmessData.host?.let { mapOf("Host" to it) } ?: emptyMap()
                    )
                } else null
            )
        )
    }
    
    private fun parseVLessUri(uri: String): VpnProfile? {
        val parsedUri = URI(uri)
        val userId = parsedUri.userInfo
        val server = parsedUri.host
        val port = parsedUri.port
        
        val params = parseQueryParams(parsedUri.query ?: "")
        val fragment = URLDecoder.decode(parsedUri.fragment ?: "VLess Server", "UTF-8")
        
        return VpnProfile(
            name = fragment,
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