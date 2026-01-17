using System.Text.Json.Serialization;

namespace NeoTUN.Core.Models;

public record VpnProfile(
    string Id,
    string Name,
    VpnProtocol Protocol,
    string Server,
    int Port,
    VpnCredentials Credentials,
    VpnSettings Settings,
    long CreatedAt,
    long? LastUsed = null
)
{
    public VpnProfile() : this(
        Guid.NewGuid().ToString(),
        string.Empty,
        VpnProtocol.VMess,
        string.Empty,
        0,
        new VpnCredentials.VMess(string.Empty, 0, "auto"),
        new VpnSettings(),
        DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()
    ) { }
}

[JsonConverter(typeof(JsonStringEnumConverter))]
public enum VpnProtocol
{
    VMess,
    VLess,
    Trojan,
    Shadowsocks
}

[JsonPolymorphic(TypeDiscriminatorPropertyName = "type")]
[JsonDerivedType(typeof(VMess), "vmess")]
[JsonDerivedType(typeof(VLess), "vless")]
[JsonDerivedType(typeof(Trojan), "trojan")]
[JsonDerivedType(typeof(Shadowsocks), "shadowsocks")]
public abstract record VpnCredentials
{
    public record VMess(
        string UserId,
        int AlterId = 0,
        string Security = "auto"
    ) : VpnCredentials;

    public record VLess(
        string UserId,
        string? Flow = null,
        string Encryption = "none"
    ) : VpnCredentials;

    public record Trojan(
        string Password
    ) : VpnCredentials;

    public record Shadowsocks(
        string Method,
        string Password
    ) : VpnCredentials;
}

public record VpnSettings(
    string Network = "tcp",
    string Security = "none",
    TlsSettings? TlsSettings = null,
    WebSocketSettings? WsSettings = null,
    RealitySettings? RealitySettings = null
);

public record TlsSettings(
    string? ServerName = null,
    bool AllowInsecure = false,
    string[]? Alpn = null
)
{
    public TlsSettings() : this(null, false, Array.Empty<string>()) { }
}

public record WebSocketSettings(
    string Path = "/",
    Dictionary<string, string>? Headers = null
)
{
    public WebSocketSettings() : this("/", new Dictionary<string, string>()) { }
}

public record RealitySettings(
    string PublicKey,
    string ShortId,
    string ServerName,
    string Fingerprint = "chrome"
);