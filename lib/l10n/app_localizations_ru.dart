// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'NeoTUN';

  @override
  String get home => 'Главная';

  @override
  String get cores => 'Ядра';

  @override
  String get settings => 'Настройки';

  @override
  String get statistics => 'Статистика';

  @override
  String get connected => 'Подключено';

  @override
  String get disconnected => 'Отключено';

  @override
  String get connect => 'Подключить';

  @override
  String get disconnect => 'Отключить';

  @override
  String get stop => 'Стоп';

  @override
  String get proxyMode => 'Режим прокси';

  @override
  String get tunMode => 'Режим TUN';

  @override
  String get noConfigurations => 'Нет конфигураций';

  @override
  String get tapToAddConfig => 'Нажмите + чтобы добавить конфигурацию';

  @override
  String get addConfig => 'Добавить конфигурацию';

  @override
  String get editConfig => 'Редактировать конфигурацию';

  @override
  String get deleteConfig => 'Удалить конфигурацию';

  @override
  String get deleteConfirmation =>
      'Вы уверены, что хотите удалить эту конфигурацию?';

  @override
  String get cancel => 'Отмена';

  @override
  String get delete => 'Удалить';

  @override
  String get save => 'Сохранить';

  @override
  String get configName => 'Имя конфигурации';

  @override
  String get coreType => 'Тип ядра';

  @override
  String get jsonConfig => 'JSON конфигурация';

  @override
  String get active => 'Активно';

  @override
  String get currentSession => 'Текущая сессия';

  @override
  String get totalStatistics => 'Общая статистика';

  @override
  String get upload => 'Отправлено';

  @override
  String get download => 'Получено';

  @override
  String get duration => 'Длительность';

  @override
  String get totalUpload => 'Всего отправлено';

  @override
  String get totalDownload => 'Всего получено';

  @override
  String get totalTraffic => 'Всего трафика';

  @override
  String get resetStatistics => 'Сбросить статистику';

  @override
  String get resetConfirmation =>
      'Вы уверены, что хотите сбросить всю статистику?';

  @override
  String get reset => 'Сбросить';

  @override
  String get statisticsReset => 'Статистика успешно сброшена';

  @override
  String get theme => 'Тема';

  @override
  String get language => 'Язык';

  @override
  String get darkTheme => 'Тёмная тема';

  @override
  String get lightTheme => 'Светлая тема';

  @override
  String get systemTheme => 'Системная тема';

  @override
  String get about => 'О программе';

  @override
  String get version => 'Версия';

  @override
  String get checkUpdates => 'Проверить обновления';

  @override
  String get importConfig => 'Импорт конфигурации';

  @override
  String get exportConfig => 'Экспорт конфигурации';

  @override
  String get qrScanner => 'QR сканер';

  @override
  String get subscription => 'Подписка';

  @override
  String get updateCores => 'Обновить ядра';

  @override
  String get error => 'Ошибка';

  @override
  String get success => 'Успешно';

  @override
  String get failedToStart => 'Не удалось запустить';

  @override
  String get coreNotInstalled => 'Ядро не установлено';

  @override
  String get general => 'Общие';

  @override
  String get network => 'Сеть';

  @override
  String get advanced => 'Расширенные';

  @override
  String get autoUpdate => 'Автообновление';

  @override
  String get autoUpdateDescription =>
      'Автоматически проверять обновления при запуске';

  @override
  String get clearCache => 'Очистить кэш';

  @override
  String get clearCacheDescription => 'Очистить кэш приложения';

  @override
  String get dataDirectory => 'Папка данных';

  @override
  String get openDataDirectory => 'Открыть папку данных';

  @override
  String get english => 'English';

  @override
  String get russian => 'Русский';

  @override
  String get systemDefault => 'Системная';

  @override
  String get light => 'Светлая';

  @override
  String get dark => 'Тёмная';

  @override
  String get system => 'Системная';

  @override
  String get appearance => 'Внешний вид';

  @override
  String get selectTheme => 'Выбрать тему';

  @override
  String get selectLanguage => 'Выбрать язык';

  @override
  String get appInfo => 'О приложении';

  @override
  String get checkingForUpdates => 'Проверка обновлений...';

  @override
  String get upToDate => 'У вас последняя версия!';

  @override
  String get updateAvailable => 'Доступно обновление';

  @override
  String get downloadUpdate => 'Скачать обновление';

  @override
  String get noUpdateAvailable => 'Нет доступных обновлений';

  @override
  String get enterConfigName => 'Введите имя конфигурации';

  @override
  String get enterJsonConfig => 'Введите JSON конфигурацию';

  @override
  String get invalidJson => 'Неверный формат JSON';

  @override
  String get configSaved => 'Конфигурация сохранена';

  @override
  String get configDeleted => 'Конфигурация удалена';

  @override
  String get pasteFromClipboard => 'Вставить из буфера';

  @override
  String get copyToClipboard => 'Копировать в буфер';

  @override
  String get copiedToClipboard => 'Скопировано в буфер обмена';

  @override
  String get scanQrCode => 'Сканировать QR-код';

  @override
  String get importFromFile => 'Импорт из файла';

  @override
  String get exportToFile => 'Экспорт в файл';

  @override
  String get shareConfig => 'Поделиться конфигурацией';

  @override
  String get duplicateConfig => 'Дублировать конфигурацию';

  @override
  String get renameConfig => 'Переименовать конфигурацию';

  @override
  String get testConnection => 'Тест соединения';

  @override
  String get connectionSpeed => 'Скорость соединения';

  @override
  String get ping => 'Пинг';

  @override
  String get latency => 'Задержка';

  @override
  String get ms => 'мс';

  @override
  String get kbps => 'КБ/с';

  @override
  String get mbps => 'МБ/с';

  @override
  String get gb => 'ГБ';

  @override
  String get mb => 'МБ';

  @override
  String get kb => 'КБ';

  @override
  String get bytes => 'Байт';

  @override
  String get perSecond => '/с';

  @override
  String get today => 'Сегодня';

  @override
  String get thisWeek => 'На этой неделе';

  @override
  String get thisMonth => 'В этом месяце';

  @override
  String get allTime => 'За всё время';

  @override
  String get trafficUsage => 'Использование трафика';

  @override
  String get sessionDuration => 'Длительность сессии';

  @override
  String get averageSpeed => 'Средняя скорость';

  @override
  String get peakSpeed => 'Пиковая скорость';

  @override
  String get noData => 'Нет данных';

  @override
  String get loading => 'Загрузка...';

  @override
  String get retry => 'Повторить';

  @override
  String get close => 'Закрыть';

  @override
  String get ok => 'ОК';

  @override
  String get yes => 'Да';

  @override
  String get no => 'Нет';

  @override
  String get apply => 'Применить';

  @override
  String get discard => 'Отменить';

  @override
  String get edit => 'Редактировать';

  @override
  String get duplicate => 'Дублировать';

  @override
  String get rename => 'Переименовать';

  @override
  String get share => 'Поделиться';

  @override
  String get test => 'Тест';

  @override
  String get refresh => 'Обновить';

  @override
  String get clear => 'Очистить';

  @override
  String get selectAll => 'Выбрать всё';

  @override
  String get deselectAll => 'Снять выделение';

  @override
  String get search => 'Поиск';

  @override
  String get filter => 'Фильтр';

  @override
  String get sort => 'Сортировка';

  @override
  String get sortByName => 'По имени';

  @override
  String get sortByDate => 'По дате';

  @override
  String get sortByUsage => 'По использованию';

  @override
  String get ascending => 'По возрастанию';

  @override
  String get descending => 'По убыванию';

  @override
  String get coreManagement => 'Управление ядрами';

  @override
  String get installedCores => 'Установленные ядра';

  @override
  String get availableCores => 'Доступные ядра';

  @override
  String get coreVersion => 'Версия ядра';

  @override
  String get latestVersion => 'Последняя версия';

  @override
  String get updateCore => 'Обновить ядро';

  @override
  String get installCore => 'Установить ядро';

  @override
  String get uninstallCore => 'Удалить ядро';

  @override
  String get coreUpdated => 'Ядро успешно обновлено';

  @override
  String get coreInstalled => 'Ядро успешно установлено';

  @override
  String get coreUninstalled => 'Ядро успешно удалено';

  @override
  String get downloadingCore => 'Загрузка ядра...';

  @override
  String get installingCore => 'Установка ядра...';

  @override
  String get uninstallingCore => 'Удаление ядра...';

  @override
  String get coreUpdateFailed => 'Не удалось обновить ядро';

  @override
  String get coreInstallFailed => 'Не удалось установить ядро';

  @override
  String get coreUninstallFailed => 'Не удалось удалить ядро';

  @override
  String get confirmUninstall => 'Вы уверены, что хотите удалить это ядро?';

  @override
  String get xray => 'Xray';

  @override
  String get connectionLogs => 'Логи подключения';

  @override
  String get viewLogs => 'Просмотр логов';

  @override
  String get clearLogs => 'Очистить логи';

  @override
  String get exportLogs => 'Экспортировать логи';

  @override
  String get logsCleared => 'Логи очищены';

  @override
  String get logsExported => 'Логи экспортированы';

  @override
  String get noLogs => 'Нет логов';

  @override
  String get copyLog => 'Копировать лог';

  @override
  String get logCopied => 'Лог скопирован в буфер обмена';

  @override
  String get autoReconnect => 'Автопереподключение';

  @override
  String get autoReconnectDescription =>
      'Автоматически переподключаться при потере соединения';

  @override
  String get pullToRefresh => 'Потяните для обновления';

  @override
  String get testing => 'Тестирование...';

  @override
  String get testFailed => 'Тест не пройден';

  @override
  String get testSuccessful => 'Тест успешен';

  @override
  String get timeout => 'Таймаут';

  @override
  String get unreachable => 'Недоступно';

  @override
  String get importFromClipboard => 'Импорт из буфера';

  @override
  String get clipboardEmpty => 'Буфер обмена пуст';

  @override
  String get invalidConfigFormat => 'Неверный формат конфигурации';

  @override
  String get configImported => 'Конфигурация импортирована';

  @override
  String get noValidConfigFound =>
      'В буфере обмена не найдено корректной конфигурации';

  @override
  String get testAllConfigs => 'Тест всех конфигураций';

  @override
  String get testingConfigs => 'Тестирование конфигураций...';

  @override
  String get speedTest => 'Тест скорости';

  @override
  String get downloadSpeed => 'Скорость загрузки';

  @override
  String get uploadSpeed => 'Скорость отдачи';

  @override
  String get jitter => 'Джиттер';

  @override
  String get packetLoss => 'Потеря пакетов';

  @override
  String get testInProgress => 'Идёт тестирование...';

  @override
  String get startTest => 'Начать тест';

  @override
  String get stopTest => 'Остановить тест';
}
