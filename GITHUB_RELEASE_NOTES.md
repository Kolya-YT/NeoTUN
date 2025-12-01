# NeoTUN v1.1.4 - AndroidLibXrayLite Integration

## 🎉 Главное изменение

**Xray теперь работает на Android без root!**

Интегрирована нативная библиотека AndroidLibXrayLite - та же, что используется в популярном v2rayNG.

## ✨ Что нового

### Android
- ✅ **Нативная поддержка Xray** через AndroidLibXrayLite (libxray.so)
- ✅ **Работает без root** - решена проблема SELinux permissions
- ✅ **Стабильная работа** на всех Android устройствах
- ✅ **Proxy и TUN режимы** полностью поддерживаются

### Windows
- ✅ **Без изменений** - продолжает использовать xray.exe
- ✅ **Полная совместимость** с предыдущими версиями

### Документация
- 📚 Добавлено 8 новых документов с подробными инструкциями
- 📝 Обновлен README с архитектурой проекта
- 🔧 Добавлены скрипты для автоматизации сборки

## 📦 Файлы для скачивания

### Android APK
- **app-arm64-v8a-release.apk** (~20 MB) - для современных устройств (рекомендуется)
- **app-armeabi-v7a-release.apk** (~18 MB) - для старых устройств
- **app-x86_64-release.apk** (~22 MB) - для эмуляторов

### Windows
- **NeoTUN-Windows-x64.zip** (~60 MB) - portable версия

## 🚀 Установка

### Android
1. Скачайте APK для вашей архитектуры
2. Разрешите установку из неизвестных источников
3. Установите APK
4. Готово! Xray работает без root

### Windows
1. Скачайте ZIP архив
2. Распакуйте в любую папку
3. Запустите neotun.exe
4. Готово!

## 🔧 Технические детали

### Архитектура Android - Xray
```
Flutter → MethodChannel → VpnService → XrayHelper → libxray.so
```

### Поддерживаемые ядра

| Ядро | Android | Windows |
|------|---------|---------|
| Xray | ✅ Native (libxray.so) | ✅ xray.exe |
| sing-box | ⚠️ Process (TUN/root) | ✅ sing-box.exe |
| Hysteria2 | ⚠️ Process (TUN/root) | ✅ hysteria2.exe |

## 📋 Требования

### Android
- Android 5.0+ (API 21+)
- ~20 MB свободного места
- Без root!

### Windows
- Windows 10/11
- ~60 MB свободного места
- Права администратора для системного прокси

## 🐛 Известные проблемы

- sing-box и Hysteria2 на Android требуют TUN режим или root (планируется интеграция нативных библиотек)
- Некоторые антивирусы могут блокировать ядра (добавьте в исключения)

## 📚 Документация

Полная документация доступна в репозитории:
- [README.md](README.md) - обзор проекта
- [ANDROID_XRAY_SETUP.md](ANDROID_XRAY_SETUP.md) - настройка Android
- [BUILD_INSTRUCTIONS.md](BUILD_INSTRUCTIONS.md) - инструкции по сборке
- [WHATS_NEW.md](WHATS_NEW.md) - подробное описание изменений

## 🙏 Благодарности

- [2dust](https://github.com/2dust) - за AndroidLibXrayLite
- [v2rayNG](https://github.com/2dust/v2rayNG) - за пример интеграции
- [Xray-core](https://github.com/XTLS/Xray-core) - за отличное ядро
- Всем контрибьюторам и пользователям!

## 📞 Поддержка

Нашли баг? Есть предложение?
- [Создайте issue](https://github.com/Kolya-YT/NeoTUN/issues)
- Проверьте [документацию](README.md)
- Приложите логи при сообщении о проблемах

---

**Полный changelog:** [CHANGELOG.md](CHANGELOG.md)

**Сделано с ❤️ для свободного интернета**

⭐ Поставьте звезду, если проект вам понравился!
