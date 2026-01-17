using NeoTUN.Core.Models;

namespace NeoTUN.Core.Interfaces;

public interface ITunnelService : IDisposable
{
    event EventHandler<ConnectionState>? ConnectionStateChanged;
    event EventHandler<string>? LogReceived;
    
    ConnectionState CurrentState { get; }
    
    Task<bool> ConnectAsync(VpnProfile profile);
    Task DisconnectAsync();
}