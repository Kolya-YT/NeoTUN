using System.Windows;
using NeoTUN.Windows.ViewModels;

namespace NeoTUN.Windows.Views;

public partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
        DataContext = new MainViewModel();
    }
}