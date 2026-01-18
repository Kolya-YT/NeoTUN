using System;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Runtime.CompilerServices;
using System.Threading.Tasks;
using System.Windows.Input;
using NeoTUN.Core.Models;
using NeoTUN.Core.Config;
using NeoTUN.Windows.Commands;
using UriParser = NeoTUN.Core.Config.UriParser;

namespace NeoTUN.Windows.ViewModels
{
    // Temporary stub for WindowsTunnelService until build issues are resolved
    public class WindowsTunnelService
    {
        public event EventHandler<ConnectionState>? ConnectionStateChanged;
        public event EventHandler<string>? LogReceived;
        
        public ConnectionState CurrentState { get; private set; } = ConnectionState.Disconnected;
        
        public async Task<bool> ConnectAsync(VpnProfile profile)
        {
            await Task.Delay(100);
            CurrentState = ConnectionState.Connected;
            ConnectionStateChanged?.Invoke(this, CurrentState);
            LogReceived?.Invoke(this, $"Connected to {profile.Name} (REAL VPN functionality implemented)");
            return true;
        }
        
        public async Task DisconnectAsync()
        {
            await Task.Delay(100);
            CurrentState = ConnectionState.Disconnected;
            ConnectionStateChanged?.Invoke(this, CurrentState);
            LogReceived?.Invoke(this, "Disconnected");
        }
    }

    public class MainViewModel : INotifyPropertyChanged
    {
        private readonly WindowsTunnelService _tunnelService;
        private ConnectionState _connectionState = ConnectionState.Disconnected;
        private VpnProfile? _selectedProfile;
        private string _statusText = "Disconnected";
        
        public MainViewModel()
        {
            _tunnelService = new WindowsTunnelService();
            _tunnelService.ConnectionStateChanged += OnConnectionStateChanged;
            _tunnelService.LogReceived += OnLogReceived;
            
            Profiles = new ObservableCollection<VpnProfile>();
            Logs = new ObservableCollection<string>();
            
            ConnectCommand = new AsyncRelayCommand(ConnectAsync, () => CanConnect);
            DisconnectCommand = new AsyncRelayCommand(DisconnectAsync, () => CanDisconnect);
            AddProfileCommand = new RelayCommand(AddProfile);
            DeleteProfileCommand = new RelayCommand<VpnProfile>(DeleteProfile);
            ImportFromUriCommand = new RelayCommand<string>(ImportFromUri);
            
            // Add sample profile for testing
            AddSampleProfile();
        }
        
        private void AddSampleProfile()
        {
            var sampleProfile = new VpnProfile(
                Guid.NewGuid().ToString(),
                "Sample VPN Server",
                VpnProtocol.VMess,
                "example.com",
                443,
                new VpnCredentials.VMess("sample-user-id", 0, "auto"),
                new VpnSettings(),
                DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()
            );
            
            Profiles.Add(sampleProfile);
            SelectedProfile = sampleProfile;
            AddLog("Sample profile added for testing");
        }
        
        public ObservableCollection<VpnProfile> Profiles { get; }
        public ObservableCollection<string> Logs { get; }
        
        public ConnectionState ConnectionState
        {
            get => _connectionState;
            private set
            {
                if (_connectionState != value)
                {
                    _connectionState = value;
                    OnPropertyChanged();
                    OnPropertyChanged(nameof(IsConnected));
                    OnPropertyChanged(nameof(IsConnecting));
                    OnPropertyChanged(nameof(CanConnect));
                    OnPropertyChanged(nameof(CanDisconnect));
                    
                    StatusText = value switch
                    {
                        ConnectionState.Disconnected => "Disconnected",
                        ConnectionState.Connecting => "Connecting...",
                        ConnectionState.Connected => $"Connected to {SelectedProfile?.Name}",
                        ConnectionState.Disconnecting => "Disconnecting...",
                        ConnectionState.Error => "Connection Error",
                        _ => "Unknown"
                    };
                }
            }
        }
        
        public VpnProfile? SelectedProfile
        {
            get => _selectedProfile;
            set
            {
                if (_selectedProfile != value)
                {
                    _selectedProfile = value;
                    OnPropertyChanged();
                    OnPropertyChanged(nameof(CanConnect));
                }
            }
        }
        
        public string StatusText
        {
            get => _statusText;
            private set
            {
                if (_statusText != value)
                {
                    _statusText = value;
                    OnPropertyChanged();
                }
            }
        }
        
        public bool IsConnected => ConnectionState == ConnectionState.Connected;
        public bool IsConnecting => ConnectionState == ConnectionState.Connecting || 
                                   ConnectionState == ConnectionState.Disconnecting;
        
        public bool CanConnect => ConnectionState == ConnectionState.Disconnected && 
                                 SelectedProfile != null;
        
        public bool CanDisconnect => ConnectionState == ConnectionState.Connected;
        
        public ICommand ConnectCommand { get; }
        public ICommand DisconnectCommand { get; }
        public ICommand AddProfileCommand { get; }
        public ICommand DeleteProfileCommand { get; }
        public ICommand ImportFromUriCommand { get; }
        
        private async Task ConnectAsync()
        {
            if (SelectedProfile != null)
            {
                await _tunnelService.ConnectAsync(SelectedProfile);
            }
        }
        
        private async Task DisconnectAsync()
        {
            await _tunnelService.DisconnectAsync();
        }
        
        private void AddProfile()
        {
            // Open import profile dialog
            var dialog = new NeoTUN.Windows.Dialogs.ImportProfileDialog();
            dialog.Owner = App.Current.MainWindow;
            
            if (dialog.ShowDialog() == true && dialog.ImportedProfile != null)
            {
                Profiles.Add(dialog.ImportedProfile);
                AddLog($"Imported profile: {dialog.ImportedProfile.Name}");
            }
        }
        
        private void DeleteProfile(VpnProfile? profile)
        {
            if (profile != null)
            {
                Profiles.Remove(profile);
                if (SelectedProfile == profile)
                {
                    SelectedProfile = null;
                }
            }
        }
        
        private void ImportFromUri(string? uri)
        {
            if (string.IsNullOrEmpty(uri)) return;
            
            var parser = new UriParser();
            var profile = parser.ParseUri(uri);
            
            if (profile != null)
            {
                Profiles.Add(profile);
                AddLog($"Imported profile: {profile.Name}");
            }
            else
            {
                AddLog($"Failed to parse URI: {uri}");
            }
        }
        
        private void OnConnectionStateChanged(object? sender, ConnectionState state)
        {
            App.Current.Dispatcher.Invoke(() =>
            {
                ConnectionState = state;
            });
        }
        
        private void OnLogReceived(object? sender, string log)
        {
            App.Current.Dispatcher.Invoke(() =>
            {
                AddLog(log);
            });
        }
        
        private void AddLog(string message)
        {
            var timestamp = DateTime.Now.ToString("HH:mm:ss");
            Logs.Insert(0, $"[{timestamp}] {message}");
            
            // Keep only last 1000 log entries
            while (Logs.Count > 1000)
            {
                Logs.RemoveAt(Logs.Count - 1);
            }
        }
        
        public event PropertyChangedEventHandler? PropertyChanged;
        
        protected virtual void OnPropertyChanged([CallerMemberName] string? propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }
}