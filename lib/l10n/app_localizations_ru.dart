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
}
