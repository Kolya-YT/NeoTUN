import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'NeoTUN'**
  String get appName;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @cores.
  ///
  /// In en, this message translates to:
  /// **'Cores'**
  String get cores;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @disconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get disconnected;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @proxyMode.
  ///
  /// In en, this message translates to:
  /// **'Proxy Mode'**
  String get proxyMode;

  /// No description provided for @tunMode.
  ///
  /// In en, this message translates to:
  /// **'TUN Mode'**
  String get tunMode;

  /// No description provided for @noConfigurations.
  ///
  /// In en, this message translates to:
  /// **'No configurations'**
  String get noConfigurations;

  /// No description provided for @tapToAddConfig.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add a new config'**
  String get tapToAddConfig;

  /// No description provided for @addConfig.
  ///
  /// In en, this message translates to:
  /// **'Add Configuration'**
  String get addConfig;

  /// No description provided for @editConfig.
  ///
  /// In en, this message translates to:
  /// **'Edit Configuration'**
  String get editConfig;

  /// No description provided for @deleteConfig.
  ///
  /// In en, this message translates to:
  /// **'Delete Configuration'**
  String get deleteConfig;

  /// No description provided for @deleteConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this configuration?'**
  String get deleteConfirmation;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @configName.
  ///
  /// In en, this message translates to:
  /// **'Config Name'**
  String get configName;

  /// No description provided for @coreType.
  ///
  /// In en, this message translates to:
  /// **'Core Type'**
  String get coreType;

  /// No description provided for @jsonConfig.
  ///
  /// In en, this message translates to:
  /// **'JSON Config'**
  String get jsonConfig;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @currentSession.
  ///
  /// In en, this message translates to:
  /// **'Current Session'**
  String get currentSession;

  /// No description provided for @totalStatistics.
  ///
  /// In en, this message translates to:
  /// **'Total Statistics'**
  String get totalStatistics;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @totalUpload.
  ///
  /// In en, this message translates to:
  /// **'Total Upload'**
  String get totalUpload;

  /// No description provided for @totalDownload.
  ///
  /// In en, this message translates to:
  /// **'Total Download'**
  String get totalDownload;

  /// No description provided for @totalTraffic.
  ///
  /// In en, this message translates to:
  /// **'Total Traffic'**
  String get totalTraffic;

  /// No description provided for @resetStatistics.
  ///
  /// In en, this message translates to:
  /// **'Reset Statistics'**
  String get resetStatistics;

  /// No description provided for @resetConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reset all statistics?'**
  String get resetConfirmation;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @statisticsReset.
  ///
  /// In en, this message translates to:
  /// **'Statistics reset successfully'**
  String get statisticsReset;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark Theme'**
  String get darkTheme;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light Theme'**
  String get lightTheme;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System Theme'**
  String get systemTheme;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @checkUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for Updates'**
  String get checkUpdates;

  /// No description provided for @importConfig.
  ///
  /// In en, this message translates to:
  /// **'Import Config'**
  String get importConfig;

  /// No description provided for @exportConfig.
  ///
  /// In en, this message translates to:
  /// **'Export Config'**
  String get exportConfig;

  /// No description provided for @qrScanner.
  ///
  /// In en, this message translates to:
  /// **'QR Scanner'**
  String get qrScanner;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @updateCores.
  ///
  /// In en, this message translates to:
  /// **'Update Cores'**
  String get updateCores;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @failedToStart.
  ///
  /// In en, this message translates to:
  /// **'Failed to start'**
  String get failedToStart;

  /// No description provided for @coreNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'Core not installed'**
  String get coreNotInstalled;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @network.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get network;

  /// No description provided for @advanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advanced;

  /// No description provided for @autoUpdate.
  ///
  /// In en, this message translates to:
  /// **'Auto Update'**
  String get autoUpdate;

  /// No description provided for @autoUpdateDescription.
  ///
  /// In en, this message translates to:
  /// **'Automatically check for updates on startup'**
  String get autoUpdateDescription;

  /// No description provided for @clearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get clearCache;

  /// No description provided for @clearCacheDescription.
  ///
  /// In en, this message translates to:
  /// **'Clear application cache'**
  String get clearCacheDescription;

  /// No description provided for @dataDirectory.
  ///
  /// In en, this message translates to:
  /// **'Data Directory'**
  String get dataDirectory;

  /// No description provided for @openDataDirectory.
  ///
  /// In en, this message translates to:
  /// **'Open Data Directory'**
  String get openDataDirectory;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @russian.
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get russian;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @selectTheme.
  ///
  /// In en, this message translates to:
  /// **'Select Theme'**
  String get selectTheme;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @appInfo.
  ///
  /// In en, this message translates to:
  /// **'App Info'**
  String get appInfo;

  /// No description provided for @checkingForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Checking for updates...'**
  String get checkingForUpdates;

  /// No description provided for @upToDate.
  ///
  /// In en, this message translates to:
  /// **'You\'re up to date!'**
  String get upToDate;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get updateAvailable;

  /// No description provided for @downloadUpdate.
  ///
  /// In en, this message translates to:
  /// **'Download Update'**
  String get downloadUpdate;

  /// No description provided for @noUpdateAvailable.
  ///
  /// In en, this message translates to:
  /// **'No updates available'**
  String get noUpdateAvailable;

  /// No description provided for @enterConfigName.
  ///
  /// In en, this message translates to:
  /// **'Enter configuration name'**
  String get enterConfigName;

  /// No description provided for @enterJsonConfig.
  ///
  /// In en, this message translates to:
  /// **'Enter JSON configuration'**
  String get enterJsonConfig;

  /// No description provided for @invalidJson.
  ///
  /// In en, this message translates to:
  /// **'Invalid JSON format'**
  String get invalidJson;

  /// No description provided for @configSaved.
  ///
  /// In en, this message translates to:
  /// **'Configuration saved'**
  String get configSaved;

  /// No description provided for @configDeleted.
  ///
  /// In en, this message translates to:
  /// **'Configuration deleted'**
  String get configDeleted;

  /// No description provided for @pasteFromClipboard.
  ///
  /// In en, this message translates to:
  /// **'Paste from Clipboard'**
  String get pasteFromClipboard;

  /// No description provided for @copyToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copy to Clipboard'**
  String get copyToClipboard;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @scanQrCode.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get scanQrCode;

  /// No description provided for @importFromFile.
  ///
  /// In en, this message translates to:
  /// **'Import from File'**
  String get importFromFile;

  /// No description provided for @exportToFile.
  ///
  /// In en, this message translates to:
  /// **'Export to File'**
  String get exportToFile;

  /// No description provided for @shareConfig.
  ///
  /// In en, this message translates to:
  /// **'Share Configuration'**
  String get shareConfig;

  /// No description provided for @duplicateConfig.
  ///
  /// In en, this message translates to:
  /// **'Duplicate Configuration'**
  String get duplicateConfig;

  /// No description provided for @renameConfig.
  ///
  /// In en, this message translates to:
  /// **'Rename Configuration'**
  String get renameConfig;

  /// No description provided for @testConnection.
  ///
  /// In en, this message translates to:
  /// **'Test Connection'**
  String get testConnection;

  /// No description provided for @connectionSpeed.
  ///
  /// In en, this message translates to:
  /// **'Connection Speed'**
  String get connectionSpeed;

  /// No description provided for @ping.
  ///
  /// In en, this message translates to:
  /// **'Ping'**
  String get ping;

  /// No description provided for @latency.
  ///
  /// In en, this message translates to:
  /// **'Latency'**
  String get latency;

  /// No description provided for @ms.
  ///
  /// In en, this message translates to:
  /// **'ms'**
  String get ms;

  /// No description provided for @kbps.
  ///
  /// In en, this message translates to:
  /// **'KB/s'**
  String get kbps;

  /// No description provided for @mbps.
  ///
  /// In en, this message translates to:
  /// **'MB/s'**
  String get mbps;

  /// No description provided for @gb.
  ///
  /// In en, this message translates to:
  /// **'GB'**
  String get gb;

  /// No description provided for @mb.
  ///
  /// In en, this message translates to:
  /// **'MB'**
  String get mb;

  /// No description provided for @kb.
  ///
  /// In en, this message translates to:
  /// **'KB'**
  String get kb;

  /// No description provided for @bytes.
  ///
  /// In en, this message translates to:
  /// **'Bytes'**
  String get bytes;

  /// No description provided for @perSecond.
  ///
  /// In en, this message translates to:
  /// **'/s'**
  String get perSecond;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get allTime;

  /// No description provided for @trafficUsage.
  ///
  /// In en, this message translates to:
  /// **'Traffic Usage'**
  String get trafficUsage;

  /// No description provided for @sessionDuration.
  ///
  /// In en, this message translates to:
  /// **'Session Duration'**
  String get sessionDuration;

  /// No description provided for @averageSpeed.
  ///
  /// In en, this message translates to:
  /// **'Average Speed'**
  String get averageSpeed;

  /// No description provided for @peakSpeed.
  ///
  /// In en, this message translates to:
  /// **'Peak Speed'**
  String get peakSpeed;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noData;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @duplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicate;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @test.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get test;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get deselectAll;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @sortByName.
  ///
  /// In en, this message translates to:
  /// **'Sort by Name'**
  String get sortByName;

  /// No description provided for @sortByDate.
  ///
  /// In en, this message translates to:
  /// **'Sort by Date'**
  String get sortByDate;

  /// No description provided for @sortByUsage.
  ///
  /// In en, this message translates to:
  /// **'Sort by Usage'**
  String get sortByUsage;

  /// No description provided for @ascending.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get ascending;

  /// No description provided for @descending.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get descending;

  /// No description provided for @coreManagement.
  ///
  /// In en, this message translates to:
  /// **'Core Management'**
  String get coreManagement;

  /// No description provided for @installedCores.
  ///
  /// In en, this message translates to:
  /// **'Installed Cores'**
  String get installedCores;

  /// No description provided for @availableCores.
  ///
  /// In en, this message translates to:
  /// **'Available Cores'**
  String get availableCores;

  /// No description provided for @coreVersion.
  ///
  /// In en, this message translates to:
  /// **'Core Version'**
  String get coreVersion;

  /// No description provided for @latestVersion.
  ///
  /// In en, this message translates to:
  /// **'Latest Version'**
  String get latestVersion;

  /// No description provided for @updateCore.
  ///
  /// In en, this message translates to:
  /// **'Update Core'**
  String get updateCore;

  /// No description provided for @installCore.
  ///
  /// In en, this message translates to:
  /// **'Install Core'**
  String get installCore;

  /// No description provided for @uninstallCore.
  ///
  /// In en, this message translates to:
  /// **'Uninstall Core'**
  String get uninstallCore;

  /// No description provided for @coreUpdated.
  ///
  /// In en, this message translates to:
  /// **'Core updated successfully'**
  String get coreUpdated;

  /// No description provided for @coreInstalled.
  ///
  /// In en, this message translates to:
  /// **'Core installed successfully'**
  String get coreInstalled;

  /// No description provided for @coreUninstalled.
  ///
  /// In en, this message translates to:
  /// **'Core uninstalled successfully'**
  String get coreUninstalled;

  /// No description provided for @downloadingCore.
  ///
  /// In en, this message translates to:
  /// **'Downloading core...'**
  String get downloadingCore;

  /// No description provided for @installingCore.
  ///
  /// In en, this message translates to:
  /// **'Installing core...'**
  String get installingCore;

  /// No description provided for @uninstallingCore.
  ///
  /// In en, this message translates to:
  /// **'Uninstalling core...'**
  String get uninstallingCore;

  /// No description provided for @coreUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Core update failed'**
  String get coreUpdateFailed;

  /// No description provided for @coreInstallFailed.
  ///
  /// In en, this message translates to:
  /// **'Core installation failed'**
  String get coreInstallFailed;

  /// No description provided for @coreUninstallFailed.
  ///
  /// In en, this message translates to:
  /// **'Core uninstallation failed'**
  String get coreUninstallFailed;

  /// No description provided for @confirmUninstall.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to uninstall this core?'**
  String get confirmUninstall;

  /// No description provided for @xray.
  ///
  /// In en, this message translates to:
  /// **'Xray'**
  String get xray;

  /// No description provided for @singbox.
  ///
  /// In en, this message translates to:
  /// **'sing-box'**
  String get singbox;

  /// No description provided for @hysteria2.
  ///
  /// In en, this message translates to:
  /// **'Hysteria2'**
  String get hysteria2;

  /// No description provided for @connectionLogs.
  ///
  /// In en, this message translates to:
  /// **'Connection Logs'**
  String get connectionLogs;

  /// No description provided for @viewLogs.
  ///
  /// In en, this message translates to:
  /// **'View Logs'**
  String get viewLogs;

  /// No description provided for @clearLogs.
  ///
  /// In en, this message translates to:
  /// **'Clear Logs'**
  String get clearLogs;

  /// No description provided for @exportLogs.
  ///
  /// In en, this message translates to:
  /// **'Export Logs'**
  String get exportLogs;

  /// No description provided for @logsCleared.
  ///
  /// In en, this message translates to:
  /// **'Logs cleared'**
  String get logsCleared;

  /// No description provided for @logsExported.
  ///
  /// In en, this message translates to:
  /// **'Logs exported'**
  String get logsExported;

  /// No description provided for @noLogs.
  ///
  /// In en, this message translates to:
  /// **'No logs available'**
  String get noLogs;

  /// No description provided for @copyLog.
  ///
  /// In en, this message translates to:
  /// **'Copy Log'**
  String get copyLog;

  /// No description provided for @logCopied.
  ///
  /// In en, this message translates to:
  /// **'Log copied to clipboard'**
  String get logCopied;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
