using System.Text;
using System.Text.Json;
using NeoTUN.Core.Models;

namespace NeoTUN.Core.Config;

public class UriParser
{
    public VpnProfile? ParseUri(string uri)
    {
        try
        {
            return uri switch
            {
                var u when u.StartsWith("vmess://") => ParseVMessUri(u),
                var u when u.StartsWith("vless://") => ParseVLessUri(u),
                var u when u.StartsWith("trojan://") => ParseTrojanUri(u),
                var u when u.StartsWith("ss://") => ParseShadowsocksUri(u),
                _ => null
            };
        }
        catch
        {
            return null;
        }
    }

    private VpnProfile? ParseVMessUri(string uri)
    {
        var base64Data = uri["vmess://".Length..];
        var jsonBytes = Convert.FromBase64String(base64Data);
        var jsonString = Encoding.UTF8.GetString(jsonBytes);

        var vmessData = JsonSerializer.Deserialize<VMessUriData>(jsonString);
        if (vmessData == null) return null;

        return new VpnProfile(
            Guid.NewGuid().ToString(),
            vmessData.Ps ?? "VMess Server",
            VpnProtocol.VMess,
            vmessData.Add,
            int.Parse(vmessData.Port),
            new VpnCredentials.VMess(
                vmessData.Id,
                vmessData.Aid,
                vmessData.Scy ?? "auto"
            ),
            new VpnSettings(
                vmessData.Net ?? "tcp",
                vmessData.Tls ?? "none",
                vmessData.Tls == "tls" ? new TlsSettings(vmessData.Sni) : null,
                vmessData.Net == "ws" ? new WebSocketSettings(
                    vmessData.Path ?? "/",
                    string.IsNullOrEmpty(vmessData.Host) ? null : new Dictionary<string, string> { ["Host"] = vmessData.Host }
                ) : null
            ),
            DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()
        );
    }

    private VpnProfile? ParseVLessUri(string uri)
    {
        var parsedUri = new Uri(uri);
        var userId = parsedUri.UserInfo;
        var server = parsedUri.Host;
        var port = parsedUri.Port;

        var queryParams = ParseQueryParams(parsedUri.Query);
        var fragment = Uri.UnescapeDataString(parsedUri.Fragment?.TrimStart('#') ?? "VLess Server");

        return new VpnProfile(
            Guid.NewGuid().ToString(),
            fragment,
            VpnProtocol.VLess,
            server,
            port,
            new VpnCredentials.VLess(
                userId,
                queryParams.GetValueOrDefault("flow"),
                queryParams.GetValueOrDefault("encryption", "none")
            ),
            new VpnSettings(
                queryParams.GetValueOrDefault("type", "tcp"),
                queryParams.GetValueOrDefault("security", "none"),
                queryParams.GetValueOrDefault("security") == "tls" ? new TlsSettings(queryParams.GetValueOrDefault("sni")) : null,
                null,
                queryParams.GetValueOrDefault("security") == "reality" ? new RealitySettings(
                    queryParams.GetValueOrDefault("pbk", ""),
                    queryParams.GetValueOrDefault("sid", ""),
                    queryParams.GetValueOrDefault("sni", ""),
                    queryParams.GetValueOrDefault("fp", "chrome")
                ) : null
            ),
            DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()
        );
    }

    private VpnProfile? ParseTrojanUri(string uri)
    {
        var parsedUri = new Uri(uri);
        var password = parsedUri.UserInfo;
        var server = parsedUri.Host;
        var port = parsedUri.Port;

        var queryParams = ParseQueryParams(parsedUri.Query);
        var fragment = Uri.UnescapeDataString(parsedUri.Fragment?.TrimStart('#') ?? "Trojan Server");

        return new VpnProfile(
            Guid.NewGuid().ToString(),
            fragment,
            VpnProtocol.Trojan,
            server,
            port,
            new VpnCredentials.Trojan(password),
            new VpnSettings(
                queryParams.GetValueOrDefault("type", "tcp"),
                queryParams.GetValueOrDefault("security", "tls"),
                new TlsSettings(
                    queryParams.GetValueOrDefault("sni", server),
                    queryParams.GetValueOrDefault("allowInsecure") == "1"
                )
            ),
            DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()
        );
    }

    private VpnProfile? ParseShadowsocksUri(string uri)
    {
        var parsedUri = new Uri(uri);
        var userInfoBytes = Convert.FromBase64String(parsedUri.UserInfo);
        var userInfo = Encoding.UTF8.GetString(userInfoBytes);
        var parts = userInfo.Split(':', 2);

        if (parts.Length != 2) return null;

        var method = parts[0];
        var password = parts[1];
        var server = parsedUri.Host;
        var port = parsedUri.Port;
        var fragment = Uri.UnescapeDataString(parsedUri.Fragment?.TrimStart('#') ?? "Shadowsocks Server");

        return new VpnProfile(
            Guid.NewGuid().ToString(),
            fragment,
            VpnProtocol.Shadowsocks,
            server,
            port,
            new VpnCredentials.Shadowsocks(method, password),
            new VpnSettings(),
            DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()
        );
    }

    private Dictionary<string, string> ParseQueryParams(string query)
    {
        var result = new Dictionary<string, string>();
        
        if (string.IsNullOrEmpty(query)) return result;
        
        query = query.TrimStart('?');
        
        foreach (var param in query.Split('&'))
        {
            var parts = param.Split('=', 2);
            if (parts.Length == 2)
            {
                var key = Uri.UnescapeDataString(parts[0]);
                var value = Uri.UnescapeDataString(parts[1]);
                result[key] = value;
            }
        }

        return result;
    }

    private class VMessUriData
    {
        public string? V { get; set; }
        public string? Ps { get; set; }
        public string Add { get; set; } = "";
        public string Port { get; set; } = "";
        public string Id { get; set; } = "";
        public int Aid { get; set; }
        public string? Scy { get; set; }
        public string? Net { get; set; }
        public string? Type { get; set; }
        public string? Host { get; set; }
        public string? Path { get; set; }
        public string? Tls { get; set; }
        public string? Sni { get; set; }
    }
}