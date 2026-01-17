using System;
using System.Windows;
using NeoTUN.Core.Models;
using UriParser = NeoTUN.Core.Config.UriParser;

namespace NeoTUN.Windows.Dialogs
{
    public partial class ImportProfileDialog : Window
    {
        public VpnProfile? ImportedProfile { get; private set; }
        
        private readonly UriParser _uriParser;
        
        public ImportProfileDialog()
        {
            InitializeComponent();
            _uriParser = new UriParser();
        }
        
        private void ImportButton_Click(object sender, RoutedEventArgs e)
        {
            var uri = UriTextBox.Text.Trim();
            
            if (string.IsNullOrEmpty(uri))
            {
                ShowStatus("Please enter a URI", true);
                return;
            }
            
            try
            {
                ImportedProfile = _uriParser.ParseUri(uri);
                
                if (ImportedProfile == null)
                {
                    ShowStatus("Invalid URI format or unsupported protocol", true);
                    return;
                }
                
                ShowStatus($"Successfully parsed {ImportedProfile.Protocol} profile: {ImportedProfile.Name}", false);
                
                // Close dialog after a short delay to show success message
                var timer = new System.Windows.Threading.DispatcherTimer
                {
                    Interval = TimeSpan.FromSeconds(1)
                };
                timer.Tick += (s, args) =>
                {
                    timer.Stop();
                    DialogResult = true;
                    Close();
                };
                timer.Start();
            }
            catch (Exception ex)
            {
                ShowStatus($"Error parsing URI: {ex.Message}", true);
            }
        }
        
        private void CancelButton_Click(object sender, RoutedEventArgs e)
        {
            DialogResult = false;
            Close();
        }
        
        private void ShowStatus(string message, bool isError)
        {
            StatusTextBlock.Text = message;
            StatusTextBlock.Foreground = isError ? 
                System.Windows.Media.Brushes.Red : 
                System.Windows.Media.Brushes.Green;
            StatusTextBlock.Visibility = Visibility.Visible;
        }
    }
}