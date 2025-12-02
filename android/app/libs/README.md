# Android Libraries

## libxray.aar

Эта директория должна содержать `libxray.aar` из AndroidLibXrayLite.

### Установка

#### Вариант 1: Скачать готовый AAR

1. Перейдите на https://github.com/2dust/AndroidLibXrayLite/releases
2. Скачайте последний `libxray.aar`
3. Поместите файл в эту директорию: `android/app/libs/libxray.aar`

#### Вариант 2: Собрать самостоятельно

```bash
git clone https://github.com/2dust/AndroidLibXrayLite.git
cd AndroidLibXrayLite
./gradlew assembleRelease
cp library/build/outputs/aar/library-release.aar ../NeoTUN/android/app/libs/libxray.aar
```

### Проверка

После установки структура должна быть:

```
android/app/libs/
├── README.md
└── libxray.aar
```

### Версия

Рекомендуемая версия: **1.8.24** или новее

### Документация

- AndroidLibXrayLite: https://github.com/2dust/AndroidLibXrayLite
- v2rayNG (использует эту библиотеку): https://github.com/2dust/v2rayNG
