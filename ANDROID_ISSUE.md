# Android Permission Denied Issue

## Проблема

На Android приложение не может запустить исполняемые файлы ядер (xray, sing-box) из-за ограничений SELinux:
```
[STDERR] sh: /data/user/0/com.neotun.app/files/cores/xray: Permission denied
```

## Причина

Android с SELinux не позволяет запускать бинарные файлы из app-private директорий (`/data/data/`, `/data/user/0/`), даже с правами 777.

## Попытки решения

1. ✗ chmod 755/777 - не работает
2. ✗ Копирование в `/data/local/tmp` - не работает на всех устройствах
3. ✗ Запуск через `sh -c` - не работает
4. ✗ Использование `exec` - не работает
5. ✗ TUN режим через VpnService - та же проблема

## Рабочие решения

### 1. AndroidLibXrayLite (Рекомендуется)

Интегрировать https://github.com/2dust/AndroidLibXrayLite как native library:

**Преимущества:**
- ✅ Ядро компилируется как .so файл
- ✅ .so файлы могут выполняться в app context
- ✅ Нет проблем с SELinux
- ✅ Используется в v2rayNG и других приложениях

**Недостатки:**
- ⏱️ Требует времени на интеграцию
- 📦 Увеличивает размер APK
- 🔧 Только для Xray (для sing-box нужна другая библиотека)

**План интеграции:**
1. Скачать AAR из релизов AndroidLibXrayLite
2. Положить в `android/app/libs/`
3. Добавить в `build.gradle.kts`
4. Создать Kotlin wrapper (XrayHelper)
5. Интегрировать через MethodChannel

### 2. Root доступ

Запуск через `su -c` на устройствах с root:

**Преимущества:**
- ✅ Работает сразу
- ✅ Поддерживает все ядра

**Недостатки:**
- ❌ Требует root
- ❌ Большинство пользователей не имеют root

### 3. Только Windows версия

Временно поддерживать только Windows пока не исправим Android:

**Преимущества:**
- ✅ Windows версия работает отлично
- ✅ Нет проблем с правами

**Недостатки:**
- ❌ Нет мобильной версии

## Рекомендация

**Интегрировать AndroidLibXrayLite** - это единственное долгосрочное решение которое работает без root.

## Временное решение

Добавить в README предупреждение:
```
⚠️ Android версия в разработке. Используйте Windows версию.
```

## Статус

🟢 **РЕШЕНО** - Интегрирована AndroidLibXrayLite для Xray на Android
🟢 **Windows версия** - работает отлично

## Реализованное решение

Интегрирована нативная библиотека AndroidLibXrayLite:

1. ✅ Создан XrayHelper.kt wrapper для работы с libxray.so
2. ✅ Обновлен VpnService для использования нативной библиотеки
3. ✅ Обновлен TunVpnService для TUN режима
4. ✅ Windows продолжает использовать обычный xray.exe

### Как это работает

**Android (Xray):**
- Использует AndroidLibXrayLite (libxray.so)
- Нет проблем с SELinux
- Работает без root

**Android (sing-box, Hysteria2):**
- Пока используют Process (требуют root или TUN)
- Планируется интеграция нативных библиотек

**Windows (все ядра):**
- Используют обычные .exe файлы
- Работают через Process.start()

Подробности в [ANDROID_XRAY_SETUP.md](ANDROID_XRAY_SETUP.md)
