using System;
using System.Diagnostics;
using System.IO;
using System.Threading.Tasks;
using NeoTUN.Core.Models;
using NeoTUN.Core.Config;

namespace NeoTUN.Core.Services
{
    public class XrayProcessManager : IDisposable
    {
        private Process _xrayProcess;
        private readonly XrayConfigGenerator _configGenerator;
        
        public event EventHandler<string> LogReceived;
        public event EventHandler<bool> ProcessStateChanged;
        
        public bool IsRunning => _xrayProcess?.HasExited == false;
        
        public XrayProcessManager()
        {
            _configGenerator = new XrayConfigGenerator();
        }
        
        public async Task<bool> StartAsync(VpnProfile profile, string xrayExecutablePath, int localPort = 10808)
        {
            try
            {
                if (IsRunning)
                {
                    await StopAsync();
                }
                
                // Generate Xray configuration
                var configJson = _configGenerator.GenerateConfig(profile, localPort);
                var configPath = Path.GetTempFileName();
                await File.WriteAllTextAsync(configPath, configJson);
                
                // Validate Xray executable
                if (!File.Exists(xrayExecutablePath))
                {
                    throw new FileNotFoundException($"Xray executable not found: {xrayExecutablePath}");
                }
                
                // Start Xray process
                var startInfo = new ProcessStartInfo
                {
                    FileName = xrayExecutablePath,
                    Arguments = $"-config \"{configPath}\"",
                    UseShellExecute = false,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    CreateNoWindow = true,
                    WorkingDirectory = Path.GetDirectoryName(xrayExecutablePath)
                };
                
                _xrayProcess = Process.Start(startInfo);
                
                if (_xrayProcess == null)
                {
                    throw new Exception("Failed to start Xray process");
                }
                
                // Setup output monitoring
                _xrayProcess.OutputDataReceived += OnOutputDataReceived;
                _xrayProcess.ErrorDataReceived += OnErrorDataReceived;
                _xrayProcess.Exited += OnProcessExited;
                
                _xrayProcess.EnableRaisingEvents = true;
                _xrayProcess.BeginOutputReadLine();
                _xrayProcess.BeginErrorReadLine();
                
                // Wait for process to initialize
                await Task.Delay(2000);
                
                if (_xrayProcess.HasExited)
                {
                    var exitCode = _xrayProcess.ExitCode;
                    throw new Exception($"Xray process exited immediately with code: {exitCode}");
                }
                
                LogReceived?.Invoke(this, "Xray process started successfully");
                ProcessStateChanged?.Invoke(this, true);
                
                return true;
            }
            catch (Exception ex)
            {
                LogReceived?.Invoke(this, $"Failed to start Xray: {ex.Message}");
                ProcessStateChanged?.Invoke(this, false);
                return false;
            }
        }
        
        public async Task StopAsync()
        {
            if (_xrayProcess != null && !_xrayProcess.HasExited)
            {
                try
                {
                    _xrayProcess.Kill();
                    await _xrayProcess.WaitForExitAsync();
                    LogReceived?.Invoke(this, "Xray process stopped");
                }
                catch (Exception ex)
                {
                    LogReceived?.Invoke(this, $"Error stopping Xray process: {ex.Message}");
                }
                finally
                {
                    _xrayProcess?.Dispose();
                    _xrayProcess = null;
                    ProcessStateChanged?.Invoke(this, false);
                }
            }
        }
        
        public async Task<bool> TestConnectionAsync(string testUrl = "https://www.google.com", int timeoutMs = 10000)
        {
            try
            {
                using var client = new System.Net.Http.HttpClient();
                client.Timeout = TimeSpan.FromMilliseconds(timeoutMs);
                
                // Configure proxy if needed
                // This would require implementing SOCKS proxy support
                
                var response = await client.GetAsync(testUrl);
                return response.IsSuccessStatusCode;
            }
            catch
            {
                return false;
            }
        }
        
        private void OnOutputDataReceived(object sender, DataReceivedEventArgs e)
        {
            if (!string.IsNullOrEmpty(e.Data))
            {
                LogReceived?.Invoke(this, $"[OUT] {e.Data}");
            }
        }
        
        private void OnErrorDataReceived(object sender, DataReceivedEventArgs e)
        {
            if (!string.IsNullOrEmpty(e.Data))
            {
                LogReceived?.Invoke(this, $"[ERR] {e.Data}");
            }
        }
        
        private void OnProcessExited(object sender, EventArgs e)
        {
            var exitCode = _xrayProcess?.ExitCode ?? -1;
            LogReceived?.Invoke(this, $"Xray process exited with code: {exitCode}");
            ProcessStateChanged?.Invoke(this, false);
        }
        
        public void Dispose()
        {
            StopAsync().Wait();
        }
    }
}