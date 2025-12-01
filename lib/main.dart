import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'screens/qr_scanner_screen.dart';
import 'services/core_manager.dart';
import 'services/config_storage.dart';
import 'services/update_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    print('Initializing CoreManager...');
    await CoreManager.instance.init();
    print('CoreManager initialized');
    
    print('Initializing ConfigStorage...');
    await ConfigStorage.instance.init();
    print('ConfigStorage initialized');
    
    print('Initializing UpdateService...');
    await UpdateService.instance.init();
    print('UpdateService initialized');
  } catch (e, stackTrace) {
    print('Initialization error: $e');
    print('Stack trace: $stackTrace');
    // Продолжаем работу даже при ошибке инициализации
  }
  
  print('Starting app...');
  runApp(const NeoTunApp());
}

class NeoTunApp extends StatefulWidget {
  const NeoTunApp({super.key});

  @override
  State<NeoTunApp> createState() => _NeoTunAppState();
}

class _NeoTunAppState extends State<NeoTunApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('dark_mode') ?? false;
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void updateThemeMode(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeoTUN',
      themeMode: _themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: HomeScreen(onThemeChanged: updateThemeMode),
      routes: {
        '/qr_scanner': (context) => const QRScannerScreen(),
      },
    );
  }
}
