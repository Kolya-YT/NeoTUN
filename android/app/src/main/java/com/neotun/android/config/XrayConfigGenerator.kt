package com.neotun.android.config

import com.neotun.android.models.*
import kotlinx.serialization.json.*

class XrayConfigGenerator {
    
    fun generateConfig(profile: VpnProfile, localPort: Int = 10808): String {
        val config = buildJsonObject {
            put("log", buildJsonObject {
                put("loglevel", "info")
            })
            
            put("inbounds", buildJsonArray {
                add(buildJsonObject {
                    put("tag", "socks-in")
                    put("protocol", "socks")
                    put("listen", "127.0.0.1")
                    put("port", localPort)
                    put("settings", buildJsonObject {
                        put("udp", true)
                    })
                })
                
                add(buildJsonObject {
                    put("tag", "http-in")
                    put("protocol", "http")
                    put("listen", "127.0.0.1")
                    put("port", localPort + 1)
                })
            })
            
            put("outbounds", buildJsonArray {
                add(generateOutbound(profile))
                
                add(buildJsonObject {
                    put("tag", "direct")
                    put("protocol", "freedom")
                })
                
                add(buildJsonObject {
                    put("tag", "blocked")
                    put("protocol", "blackhole")
                })
            })
            
            put("routing", buildJsonObject {
                put("rules", buildJsonArray {
                    add(buildJsonObject {
                        put("type", "field")
                        put("ip", buildJsonArray {
                            add("geoip:private")
                        })
                        put("outboundTag", "direct")
                    })
                })
            })
        }
        
        return Json { prettyPrint = true }.encodeToString(JsonObject.serializer(), config)
    }
    
    private fun generateOutbound(profile: VpnProfile): JsonObject {
        return buildJsonObject {
            put("tag", "proxy")
            put("protocol", profile.protocol.name.lowercase())
            
            put("settings", when (profile.protocol) {
                VpnProtocol.VMESS -> generateVMessSettings(profile)
                VpnProtocol.VLESS -> generateVLessSettings(profile)
                VpnProtocol.TROJAN -> generateTrojanSettings(profile)
                VpnProtocol.SHADOWSOCKS -> generateShadowsocksSettings(profile)
            })
            
            put("streamSettings", generateStreamSettings(profile.settings))
        }
    }
    
    private fun generateVMessSettings(profile: VpnProfile): JsonObject {
        val credentials = profile.credentials as VpnCredentials.VMess
        
        return buildJsonObject {
            put("vnext", buildJsonArray {
                add(buildJsonObject {
                    put("address", profile.server)
                    put("port", profile.port)
                    put("users", buildJsonArray {
                        add(buildJsonObject {
                            put("id", credentials.userId)
                            put("alterId", credentials.alterId)
                            put("security", credentials.security)
                        })
                    })
                })
            })
        }
    }
    
    private fun generateVLessSettings(profile: VpnProfile): JsonObject {
        val credentials = profile.credentials as VpnCredentials.VLess
        
        return buildJsonObject {
            put("vnext", buildJsonArray {
                add(buildJsonObject {
                    put("address", profile.server)
                    put("port", profile.port)
                    put("users", buildJsonArray {
                        add(buildJsonObject {
                            put("id", credentials.userId)
                            put("encryption", credentials.encryption)
                            credentials.flow?.let { put("flow", it) }
                        })
                    })
                })
            })
        }
    }
    
    private fun generateTrojanSettings(profile: VpnProfile): JsonObject {
        val credentials = profile.credentials as VpnCredentials.Trojan
        
        return buildJsonObject {
            put("servers", buildJsonArray {
                add(buildJsonObject {
                    put("address", profile.server)
                    put("port", profile.port)
                    put("password", credentials.password)
                })
            })
        }
    }
    
    private fun generateShadowsocksSettings(profile: VpnProfile): JsonObject {
        val credentials = profile.credentials as VpnCredentials.Shadowsocks
        
        return buildJsonObject {
            put("servers", buildJsonArray {
                add(buildJsonObject {
                    put("address", profile.server)
                    put("port", profile.port)
                    put("method", credentials.method)
                    put("password", credentials.password)
                })
            })
        }
    }
    
    private fun generateStreamSettings(settings: VpnSettings): JsonObject {
        return buildJsonObject {
            put("network", settings.network)
            
            if (settings.security != "none") {
                put("security", settings.security)
                
                when (settings.security) {
                    "tls" -> settings.tlsSettings?.let { 
                        put("tlsSettings", generateTlsSettings(it))
                    }
                    "reality" -> settings.realitySettings?.let {
                        put("realitySettings", generateRealitySettings(it))
                    }
                }
            }
            
            when (settings.network) {
                "ws" -> settings.wsSettings?.let {
                    put("wsSettings", generateWebSocketSettings(it))
                }
            }
        }
    }
    
    private fun generateTlsSettings(tls: TlsSettings): JsonObject {
        return buildJsonObject {
            tls.serverName?.let { put("serverName", it) }
            put("allowInsecure", tls.allowInsecure)
            if (tls.alpn.isNotEmpty()) {
                put("alpn", buildJsonArray {
                    tls.alpn.forEach { add(it) }
                })
            }
        }
    }
    
    private fun generateRealitySettings(reality: RealitySettings): JsonObject {
        return buildJsonObject {
            put("publicKey", reality.publicKey)
            put("shortId", reality.shortId)
            put("serverName", reality.serverName)
            put("fingerprint", reality.fingerprint)
        }
    }
    
    private fun generateWebSocketSettings(ws: WebSocketSettings): JsonObject {
        return buildJsonObject {
            put("path", ws.path)
            if (ws.headers.isNotEmpty()) {
                put("headers", buildJsonObject {
                    ws.headers.forEach { (key, value) ->
                        put(key, value)
                    }
                })
            }
        }
    }
}