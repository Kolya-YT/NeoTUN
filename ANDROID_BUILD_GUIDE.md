# 📱 Руководство по сборке Android APK

## Проблема
Android SDK не установлен на вашей системе. Для сборки APK нужен Android SDK.

---

## ✅ Решение 1: Установка Android Studio (Рекомендуется)

### Шаг 1: Скачайте Android Studio
https://developer.android.com/studio

### Шаг 2: Установите Android Studio
1. Запустите установщик
2. Выберите "Standard" установку
3. Дождитесь загрузки SDK компонентов

### Шаг 3: Настройте Flutter
```powershell
flutter doctor --android-licenses
# Примите все лицензии (нажимайте 'y')
```

### Шаг 4: Соберите APK
```powershell
flutter build apk --debug
# Или для release (требуется keystore):
flutter build apk --release
```

**Результат:** `build/app/outputs/flutter-apk/app-debug.apk`

---

## ✅ Решение 2: Установка только Android SDK (Без Android Studio)

### Шаг 1: Скачайте Command Line Tools
https://developer.android.com/studio#command-tools

### Шаг 2: Распакуйте в папку
```
C:\Users\YourName\AppData\Local\Android\Sdk\cmdline-tools\latest\
```

### Шаг 3: Установите необходимые компоненты
```powershell
cd C:\Users\YourName\AppData\Local\Android\Sdk\cmdline-tools\latest\bin

# Установите platform-tools
.\sdkmanager.bat "platform-tools"

# Установите build-tools
.\sdkmanager.bat "build-tools;34.0.0"

# Установите platforms
.\sdkmanager.bat "platforms;android-34"

# Примите лицензии
.\sdkmanager.bat --licenses
```

### Шаг 4: Настройте переменные окружения
```powershell
# Добавьте в PATH:
$env:ANDROID_HOME = "C:\Users\YourName\AppData\Local\Android\Sdk"
$env:PATH += ";$env:ANDROID_HOME\platform-tools"
$env:PATH += ";$env:ANDROID_HOME\cmdline-tools\latest\bin"
```

### Шаг 5: Соберите APK
```powershell
flutter build apk --debug
```

---

## ✅ Решение 3: Использование GitHub Actions (Автоматическая сборка)

### Преимущества
- ✅ Не требует локальной установки Android SDK
- ✅ Автоматическая сборка при push
- ✅ Публикация в GitHub Releases

### Шаг 1: Настройте GitHub репозиторий
```bash
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/yourusername/neotun.git
git push -u origin main
```

### Шаг 2: Создайте тег для релиза
```bash
git tag v1.0.0
git push origin v1.0.0
```

### Шаг 3: GitHub Actions автоматически соберет APK
Workflow уже настроен в `.github/workflows/release.yml`

### Шаг 4: Скачайте APK из Releases
https://github.com/yourusername/neotun/releases

---

## ✅ Решение 4: Быстрая установка через Chocolatey (Windows)

### Шаг 1: Установите Chocolatey (если нет)
```powershell
# Запустите PowerShell от имени администратора
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

### Шаг 2: Установите Android SDK
```powershell
choco install android-sdk -y
```

### Шаг 3: Настройте Flutter
```powershell
flutter config --android-sdk "C:\Android\android-sdk"
flutter doctor --android-licenses
```

### Шаг 4: Соберите APK
```powershell
flutter build apk --debug
```

---

## 🔧 Текущий статус вашей системы

```
✅ Flutter: Установлен (3.38.3)
✅ Windows SDK: Установлен
✅ Visual Studio: Установлен
❌ Android SDK: НЕ установлен
```

---

## 📦 Что нужно для сборки APK

### Минимальные требования:
1. **Android SDK** (любым из способов выше)
2. **Java JDK** (обычно идет с Android Studio)
3. **Flutter** (уже установлен ✅)

### Для Release APK дополнительно:
4. **Keystore** для подписи APK
5. **key.properties** файл с настройками

---

## 🚀 Быстрый старт (Рекомендуемый путь)

### Вариант A: Если нужен APK прямо сейчас
**Используйте GitHub Actions** (Решение 3)
- Не требует установки SDK
- Автоматическая сборка
- Готовый APK через 10-15 минут

### Вариант B: Если планируете разработку
**Установите Android Studio** (Решение 1)
- Полный набор инструментов
- Удобная IDE
- Эмулятор Android

### Вариант C: Минимальная установка
**Command Line Tools** (Решение 2)
- Только необходимое
- Меньше места на диске
- Быстрая установка

---

## 📝 Создание Keystore для Release APK

### Шаг 1: Создайте keystore
```powershell
keytool -genkey -v -keystore android/app/neotun.jks `
  -keyalg RSA -keysize 2048 -validity 10000 `
  -alias neotun
```

### Шаг 2: Создайте key.properties
```properties
# android/key.properties
storePassword=your_password
keyPassword=your_password
keyAlias=neotun
storeFile=neotun.jks
```

### Шаг 3: Соберите Release APK
```powershell
flutter build apk --release --split-per-abi
```

**Результат:**
- `app-armeabi-v7a-release.apk` (32-bit ARM)
- `app-arm64-v8a-release.apk` (64-bit ARM) ← Рекомендуется
- `app-x86_64-release.apk` (x86 64-bit)

---

## 🐛 Решение проблем

### Проблема: "Android SDK not found"
```powershell
# Проверьте путь к SDK
flutter config --android-sdk "C:\Users\YourName\AppData\Local\Android\Sdk"

# Проверьте статус
flutter doctor -v
```

### Проблема: "License not accepted"
```powershell
flutter doctor --android-licenses
# Нажимайте 'y' для всех лицензий
```

### Проблема: "Gradle build failed"
```powershell
# Очистите кэш
cd android
.\gradlew clean

# Попробуйте снова
cd ..
flutter build apk --debug
```

### Проблема: "Java not found"
```powershell
# Установите Java JDK
choco install openjdk11 -y

# Или скачайте с
# https://adoptium.net/
```

---

## 📊 Сравнение методов установки

| Метод | Время | Размер | Сложность | Рекомендация |
|-------|-------|--------|-----------|--------------|
| Android Studio | 30-60 мин | ~3 GB | Легко | ⭐⭐⭐⭐⭐ |
| Command Line Tools | 10-20 мин | ~500 MB | Средне | ⭐⭐⭐⭐ |
| GitHub Actions | 0 мин | 0 MB | Легко | ⭐⭐⭐⭐⭐ |
| Chocolatey | 15-30 мин | ~1 GB | Легко | ⭐⭐⭐ |

---

## 🎯 Следующие шаги

### После установки SDK:

1. **Проверьте установку**
   ```powershell
   flutter doctor -v
   ```

2. **Соберите debug APK**
   ```powershell
   flutter build apk --debug
   ```

3. **Установите на устройство**
   ```powershell
   # Подключите Android устройство через USB
   flutter install
   
   # Или скопируйте APK вручную
   # build/app/outputs/flutter-apk/app-debug.apk
   ```

4. **Тестируйте приложение**
   - Установите APK на Android устройство
   - Проверьте все функции
   - Проверьте TUN режим

---

## 💡 Полезные команды

```powershell
# Проверка устройств
flutter devices

# Запуск на устройстве
flutter run -d <device-id>

# Сборка разных вариантов
flutter build apk --debug          # Debug APK
flutter build apk --profile        # Profile APK
flutter build apk --release        # Release APK
flutter build apk --split-per-abi  # Отдельные APK для архитектур

# Информация о сборке
flutter build apk --release --verbose

# Очистка
flutter clean
```

---

## 📞 Нужна помощь?

### Документация
- Flutter: https://docs.flutter.dev/deployment/android
- Android: https://developer.android.com/studio/build

### Поддержка
- GitHub Issues: https://github.com/yourusername/neotun/issues
- Flutter Discord: https://discord.gg/flutter

---

## ✅ Чеклист перед сборкой

- [ ] Flutter установлен и обновлен
- [ ] Android SDK установлен
- [ ] Java JDK установлен
- [ ] Лицензии приняты (`flutter doctor --android-licenses`)
- [ ] `flutter doctor` показывает ✓ для Android
- [ ] (Опционально) Keystore создан для release
- [ ] (Опционально) key.properties настроен

---

**Рекомендация:** Используйте **GitHub Actions** для автоматической сборки или установите **Android Studio** для полноценной разработки.

Удачи! 🚀
