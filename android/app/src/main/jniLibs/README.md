# Native Libraries для Android

Эта директория содержит скомпилированные ядра в формате .so для Android.

## Как получить libv2ray.so

1. Скачай последний APK v2rayNG: https://github.com/2dust/v2rayNG/releases
2. Переименуй .apk в .zip и распакуй
3. Найди `lib/arm64-v8a/libv2ray.so`
4. Скопируй в `android/app/src/main/jniLibs/arm64-v8a/libv2ray.so`

## Структура

```
jniLibs/
├── arm64-v8a/          # Для современных устройств (64-bit ARM)
│   └── libv2ray.so
├── armeabi-v7a/        # Для старых устройств (32-bit ARM)
│   └── libv2ray.so
└── x86_64/             # Для эмуляторов
    └── libv2ray.so
```

## Альтернатива

Можно скомпилировать самостоятельно:
```bash
git clone https://github.com/XTLS/Xray-core
cd Xray-core
go get golang.org/x/mobile/cmd/gomobile
gomobile bind -target=android -o libxray.aar
```

Но проще использовать готовые из v2rayNG.
