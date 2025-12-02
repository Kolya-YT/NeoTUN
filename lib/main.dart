import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/qr_scanner_screen.dart';
import 'services/core_manager.dart';
import 'services/config_storage.dart';
import 'services/update_service.dart';
import 'services/traffic_stats.dart';

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
    
    print('Initializing TrafficStats...');
    await TrafficStats.instance.init();
    print('TrafficStats initialized');
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
  Locale _locale = const Locale('en');

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeMode = prefs.getString('theme_mode') ?? 'system';
    final languageCode = prefs.getString('language') ?? 'en';
    
    setState(() {
      _themeMode = themeMode == 'dark' 
          ? ThemeMode.dark 
          : themeMode == 'light' 
              ? ThemeMode.light 
              : ThemeMode.system;
      _locale = Locale(languageCode);
    });
  }

  void updateThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  void updateLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeoTUN',
      themeMode: _themeMode,
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ru'),
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        // Если выбранная локаль поддерживается, используем её
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == _locale.languageCode) {
            return _locale;
          }
        }
        // Иначе возвращаем первую поддерживаемую
        return supportedLocales.first;
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[50],
        cardColor: Colors.white,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardColor: const Color(0xFF1E293B),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Color(0xFF1E293B),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Color(0xFF0F172A),
        ),
      ),
      home: HomeScreen(
        onThemeChanged: updateThemeMode,
        onLocaleChanged: updateLocale,
      ),
      routes: {
        '/qr_scanner': (context) => const QRScannerScreen(),
      },
    );
  }
}
