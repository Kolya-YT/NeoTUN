# 🚀 Собрать APK ПРЯМО СЕЙЧАС

## Проблема
У вас нет Android SDK, но нужен APK файл.

## ✅ 3 Быстрых решения

---

## Решение 1: Автоматическая установка SDK (5 минут)

### Запустите скрипт установки:

```powershell
# Откройте PowerShell от имени администратора
# Перейдите в папку проекта
cd C:\Users\KolyaYT\Desktop\V2RAYX

# Запустите скрипт
.\install_android_sdk.ps1
```

**Что делает скрипт:**
1. ✅ Скачивает Android Command Line Tools
2. ✅ Устанавливает SDK компоненты
3. ✅ Настраивает переменные окружения
4. ✅ Принимает лицензии
5. ✅ Настраивает Flutter

**После установки:**
```powershell
flutter build apk --debug
```

**Результат:** `build/app/outputs/flutter-apk/app-debug.apk`

---

## Решение 2: GitHub Actions (0 минут локальной работы)

### Шаг 1: Создайте GitHub репозиторий

```bash
# Инициализируйте git (если еще не сделано)
git init
git add .
git commit -m "NeoTUN v1.0 - Initial release"

# Создайте репозиторий на GitHub.com
# Затем:
git remote add origin https://github.com/ВАШ_USERNAME/neotun.git
git branch -M main
git push -u origin main
```

### Шаг 2: Создайте тег для релиза

```bash
git tag v1.0.0
git push origin v1.0.0
```

### Шаг 3: Дождитесь сборки

1. Откройте https://github.com/ВАШ_USERNAME/neotun/actions
2. Дождитесь завершения workflow (10-15 минут)
3. Перейдите в Releases
4. Скачайте APK файл

**Преимущества:**
- ✅ Не требует локальной установки SDK
- ✅ Автоматическая сборка
- ✅ Подписанный APK (если настроить secrets)
- ✅ Публикация в Releases

---

## Решение 3: Использовать готовый APK (Временное решение)

Пока SDK устанавливается, можно использовать debug APK без подписи.

### Создайте минимальный APK вручную:

```powershell
# Создайте базовую структуру
mkdir build\app\outputs\flutter-apk -Force

# Скопируйте манифест
Copy-Item android\app\src\main\AndroidManifest.xml build\app\outputs\flutter-apk\
```

**Примечание:** Этот метод не создаст рабочий APK, нужен полноценный SDK.

---

## 🎯 РЕКОМЕНДАЦИЯ: Используйте Решение 1

### Почему?
- ⚡ Быстро (5-10 минут)
- 🔧 Автоматизировано
- ✅ Полноценный SDK для будущей разработки
- 📱 Сразу можно собрать APK

### Как запустить:

1. **Откройте PowerShell от имени администратора**
   - Нажмите Win + X
   - Выберите "Windows PowerShell (Администратор)"

2. **Перейдите в папку проекта**
   ```powershell
   cd C:\Users\KolyaYT\Desktop\V2RAYX
   ```

3. **Разрешите выполнение скриптов**
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

4. **Запустите установку**
   ```powershell
   .\install_android_sdk.ps1
   ```

5. **Дождитесь завершения** (5-10 минут)

6. **Соберите APK**
   ```powershell
   flutter build apk --debug
   ```

7. **Найдите APK**
   ```
   build\app\outputs\flutter-apk\app-debug.apk
   ```

---

## 📱 Установка APK на Android

### Метод 1: USB кабель
```powershell
# Подключите Android устройство
# Включите "Отладка по USB" в настройках разработчика

# Установите APK
flutter install

# Или через adb
adb install build\app\outputs\flutter-apk\app-debug.apk
```

### Метод 2: Файловый менеджер
1. Скопируйте APK на устройство
2. Откройте файловый менеджер
3. Нажмите на APK файл
4. Разрешите установку из неизвестных источников
5. Установите

### Метод 3: Google Drive / Telegram
1. Загрузите APK в облако
2. Скачайте на Android устройство
3. Установите

---

## ⏱️ Сравнение времени

| Метод | Время установки SDK | Время сборки APK | Общее время |
|-------|---------------------|------------------|-------------|
| Скрипт | 5-10 мин | 2-3 мин | **7-13 мин** |
| GitHub Actions | 0 мин | 10-15 мин | **10-15 мин** |
| Android Studio | 30-60 мин | 2-3 мин | **32-63 мин** |

---

## 🐛 Если что-то пошло не так

### Ошибка: "Execution Policy"
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
.\install_android_sdk.ps1
```

### Ошибка: "Access Denied"
- Запустите PowerShell от имени администратора

### Ошибка: "Network Error"
- Проверьте интернет соединение
- Попробуйте позже
- Используйте VPN если GitHub заблокирован

### Ошибка: "Flutter not found"
```powershell
# Проверьте установку Flutter
flutter --version

# Если не найден, добавьте в PATH
$env:Path += ";C:\src\flutter\bin"
```

---

## 📊 Что будет установлено

### Android SDK компоненты:
- ✅ Command Line Tools (latest)
- ✅ Platform Tools (adb, fastboot)
- ✅ Build Tools 34.0.0
- ✅ Android Platform 34 (Android 14)

### Размер:
- Command Line Tools: ~150 MB
- Platform Tools: ~50 MB
- Build Tools: ~80 MB
- Platform: ~70 MB
- **Общий размер: ~350 MB**

### Время загрузки:
- Быстрый интернет (100 Mbps): ~3 минуты
- Средний интернет (10 Mbps): ~5 минут
- Медленный интернет (1 Mbps): ~30 минут

---

## ✅ После успешной сборки

### Проверьте APK:
```powershell
# Размер файла
Get-Item build\app\outputs\flutter-apk\app-debug.apk | Select-Object Name, Length

# Информация о APK
flutter build apk --debug --verbose
```

### Тестирование:
1. Установите на Android устройство
2. Откройте приложение
3. Скачайте ядро (XRay/sing-box)
4. Добавьте конфигурацию
5. Подключитесь
6. Проверьте работу

---

## 🎉 Готово!

После выполнения любого из решений у вас будет:
- ✅ Рабочий APK файл
- ✅ Возможность устанавливать на Android
- ✅ Полноценное приложение NeoTUN

**Выберите решение и начните прямо сейчас!** 🚀

---

## 💡 Совет

Если нужен APK **прямо сейчас** и нет времени ждать:
1. Используйте **GitHub Actions** (Решение 2)
2. Пока собирается, установите SDK локально (Решение 1)
3. В будущем сможете собирать локально

**Удачи!** 🎯
