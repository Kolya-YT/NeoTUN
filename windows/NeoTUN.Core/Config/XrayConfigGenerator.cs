using System.Text.Json;
using System.Text.Json.Nodes;
using NeoTUN.Core.Models;

namespace NeoTUN.Core.Config;

public class XrayConfigGenerator
{
    public string GenerateConfig(VpnProfile profile, int localPort = 10808)
    {
        var config = new JsonObject
        {
            ["log"] = new JsonObject
            {
                ["loglevel"] = "info"
            },
            ["inbounds"] = new JsonArray
            {
                new JsonObject
                {
                    ["tag"] = "socks-in",
                    ["protocol"] = "socks",
                    ["listen"] = "127.0.0.1",
                    ["port"] = localPort,
                    ["settings"] = new JsonObject
                    {
                        ["udp"] = true
                    }
                },
                new JsonObject
                {
                    ["tag"] = "http-in",
                    ["protocol"] = "http",
                    ["listen"] = "127.0.0.1",
                    ["port"] = localPort + 1
                }
            },
            ["outbounds"] = new JsonArray
            {
                GenerateOutbound(profile),
                new JsonObject
                {
                    ["tag"] = "direct",
                    ["protocol"] = "freedom"
                },
                new JsonObject
                {
                    ["tag"] = "blocked",
                    ["protocol"] = "blackhole"
                }
            },
            ["routing"] = new JsonObject
            {
                ["rules"] = new JsonArray
                {
                    new JsonObject
                    {
                        ["type"] = "field",
                        ["ip"] = new JsonArray { "geoip:private" },
                        ["outboundTag"] = "direct"
                    }
                }
            }
        };

        return JsonSerializer.Serialize(config, new JsonSerializerOptions { WriteIndented = true });
    }

    private JsonObject GenerateOutbound(VpnProfile profile)
    {
        var outbound = new JsonObject
        {
            ["tag"] = "proxy",
            ["protocol"] = profile.Protocol.ToString().ToLowerInvariant()
        };

        outbound["settings"] = profile.Protocol switch
        {
            VpnProtocol.VMess => GenerateVMessSettings(profile),
            VpnProtocol.VLess => GenerateVLessSettings(profile),
            VpnProtocol.Trojan => GenerateTrojanSettings(profile),
            VpnProtocol.Shadowsocks => GenerateShadowsocksSettings(profile),
            _ => throw new ArgumentException($"Unsupported protocol: {profile.Protocol}")
        };

        outbound["streamSettings"] = GenerateStreamSettings(profile.Settings);

        return outbound;
    }

    private JsonObject GenerateVMessSettings(VpnProfile profile)
    {
        var credentials = (VpnCredentials.VMess)profile.Credentials;
        
        return new JsonObject
        {
            ["vnext"] = new JsonArray
            {
                new JsonObject
                {
                    ["address"] = profile.Server,
                    ["port"] = profile.Port,
                    ["users"] = new JsonArray
                    {
                        new JsonObject
                        {
                            ["id"] = credentials.UserId,
                            ["alterId"] = credentials.AlterId,
                            ["security"] = credentials.Security
                        }
                    }
                }
            }
        };
    }

    private JsonObject GenerateVLessSettings(VpnProfile profile)
    {
        var credentials = (VpnCredentials.VLess)profile.Credentials;
        
        var user = new JsonObject
        {
            ["id"] = credentials.UserId,
            ["encryption"] = credentials.Encryption
        };

        if (!string.IsNullOrEmpty(credentials.Flow))
        {
            user["flow"] = credentials.Flow;
        }

        return new JsonObject
        {
            ["vnext"] = new JsonArray
            {
                new JsonObject
                {
                    ["address"] = profile.Server,
                    ["port"] = profile.Port,
                    ["users"] = new JsonArray { user }
                }
            }
        };
    }

    private JsonObject GenerateTrojanSettings(VpnProfile profile)
    {
        var credentials = (VpnCredentials.Trojan)profile.Credentials;
        
        return new JsonObject
        {
            ["servers"] = new JsonArray
            {
                new JsonObject
                {
                    ["address"] = profile.Server,
                    ["port"] = profile.Port,
                    ["password"] = credentials.Password
                }
            }
        };
    }

    private JsonObject GenerateShadowsocksSettings(VpnProfile profile)
    {
        var credentials = (VpnCredentials.Shadowsocks)profile.Credentials;
        
        return new JsonObject
        {
            ["servers"] = new JsonArray
            {
                new JsonObject
                {
                    ["address"] = profile.Server,
                    ["port"] = profile.Port,
                    ["method"] = credentials.Method,
                    ["password"] = credentials.Password
                }
            }
        };
    }

    private JsonObject GenerateStreamSettings(VpnSettings settings)
    {
        var streamSettings = new JsonObject
        {
            ["network"] = settings.Network
        };

        if (settings.Security != "none")
        {
            streamSettings["security"] = settings.Security;

            switch (settings.Security)
            {
                case "tls" when settings.TlsSettings != null:
                    streamSettings["tlsSettings"] = GenerateTlsSettings(settings.TlsSettings);
                    break;
                case "reality" when settings.RealitySettings != null:
                    streamSettings["realitySettings"] = GenerateRealitySettings(settings.RealitySettings);
                    break;
            }
        }

        if (settings.Network == "ws" && settings.WsSettings != null)
        {
            streamSettings["wsSettings"] = GenerateWebSocketSettings(settings.WsSettings);
        }

        return streamSettings;
    }

    private JsonObject GenerateTlsSettings(TlsSettings tls)
    {
        var tlsSettings = new JsonObject
        {
            ["allowInsecure"] = tls.AllowInsecure
        };

        if (!string.IsNullOrEmpty(tls.ServerName))
        {
            tlsSettings["serverName"] = tls.ServerName;
        }

        if (tls.Alpn?.Length > 0)
        {
            var alpnArray = new JsonArray();
            foreach (var alpn in tls.Alpn)
            {
                alpnArray.Add(alpn);
            }
            tlsSettings["alpn"] = alpnArray;
        }

        return tlsSettings;
    }

    private JsonObject GenerateRealitySettings(RealitySettings reality)
    {
        return new JsonObject
        {
            ["publicKey"] = reality.PublicKey,
            ["shortId"] = reality.ShortId,
            ["serverName"] = reality.ServerName,
            ["fingerprint"] = reality.Fingerprint
        };
    }

    private JsonObject GenerateWebSocketSettings(WebSocketSettings ws)
    {
        var wsSettings = new JsonObject
        {
            ["path"] = ws.Path
        };

        if (ws.Headers?.Count > 0)
        {
            var headers = new JsonObject();
            foreach (var (key, value) in ws.Headers)
            {
                headers[key] = value;
            }
            wsSettings["headers"] = headers;
        }

        return wsSettings;
    }
}