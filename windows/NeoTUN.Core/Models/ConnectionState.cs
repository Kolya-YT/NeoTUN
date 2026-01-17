using System.Text.Json.Serialization;

namespace NeoTUN.Core.Models;

[JsonConverter(typeof(JsonStringEnumConverter))]
public enum ConnectionState
{
    Disconnected,
    Connecting,
    Connected,
    Disconnecting,
    Error
}

public record ConnectionStatus(
    ConnectionState State,
    VpnProfile? Profile = null,
    long? ConnectedAt = null,
    long BytesReceived = 0,
    long BytesSent = 0,
    string? ErrorMessage = null
);

public record ConnectionStats(
    long Uptime,
    long BytesReceived,
    long BytesSent,
    ConnectionSpeed Speed
);

public record ConnectionSpeed(
    long DownloadSpeed, // bytes per second
    long UploadSpeed    // bytes per second
);