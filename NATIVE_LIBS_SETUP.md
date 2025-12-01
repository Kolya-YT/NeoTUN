# Настройка Native Libraries для Android

## Проблема
Android с SELinux не позволяет запускать произвольные исполняемые файлы из app директорий.

## Решение
Использовать native libraries (.so файлы) которые встраиваются в APK.

## Шаги

### 1. Получить libv2ray.so

**Вариант A: Из v2rayNG (рекомендуется)**
```bash
# Скачай последний APK
wget https://github.com/2dust/v2rayNG/releases/latest/download/v2rayNG_xxx_arm64-v8a.apk

# Распакуй (APK это ZIP)
unzip v2rayNG_xxx_arm64-v8a.apk -d v2rayNG

# Скопируй библиотеку
cp v2rayNG/lib/arm64-v8a/libv2ray.so android/app/src/main/jniLibs/arm64-v8a/
```

**Вариант B: Скомпилировать самостоятельно**
```bash
# Установи Go и gomobile
go install golang.org/x/mobile/cmd/gomobile@latest
gomobile init

# Клонируй Xray
git clone https://github.com/XTLS/Xray-core
cd Xray-core

# Собери для Android
gomobile bind -target=android/arm64 -o libxray.aar

# Извлеки .so из .aar
unzip libxray.aar
cp jni/arm64-v8a/libxray.so ../android/app/src/main/jniLibs/arm64-v8a/
```

### 2. Структура директорий

```
android/app/src/main/jniLibs/
├── arm64-v8a/          # Современные устройства (обязательно)
│   └── libv2ray.so
├── armeabi-v7a/        # Старые устройства (опционально)
│   └── libv2ray.so
└── x86_64/             # Эмуляторы (опционально)
    └── libv2ray.so
```

### 3. Обновить код

Код уже готов в:
- `android/app/src/main/kotlin/com/neotun/app/V2rayCore.kt` - JNI wrapper
- `VpnService.kt` и `TunVpnService.kt` - используют native library если доступна

### 4. Пересобрать APK

```bash
flutter build apk --release --split-per-abi
```

## Преимущества

✅ Нет проблем с SELinux  
✅ Нет Permission denied  
✅ Быстрее запускается  
✅ Меньше батареи  
✅ Работает на всех Android устройствах  

## Примечание

Если libv2ray.so не найдена, приложение автоматически вернется к запуску через процесс (текущий метод).
