#!/bin/bash

# Скрипт для компиляции ядер в .so библиотеки для Android

set -e

echo "🔨 Building native libraries for Android..."

# Проверка зависимостей
if ! command -v go &> /dev/null; then
    echo "❌ Go не установлен. Установите: https://go.dev/dl/"
    exit 1
fi

if ! command -v gomobile &> /dev/null; then
    echo "📦 Устанавливаем gomobile..."
    go install golang.org/x/mobile/cmd/gomobile@latest
    gomobile init
fi

# Создаем директории
mkdir -p android/app/src/main/jniLibs/arm64-v8a
mkdir -p android/app/src/main/jniLibs/armeabi-v7a
mkdir -p android/app/src/main/jniLibs/x86_64
mkdir -p temp_build

cd temp_build

# Компилируем Xray-core
echo "📥 Клонируем Xray-core..."
if [ ! -d "Xray-core" ]; then
    git clone --depth 1 https://github.com/XTLS/Xray-core.git
fi

cd Xray-core

echo "🔨 Компилируем Xray для Android..."

# Компиляция для arm64-v8a
echo "  → arm64-v8a..."
CGO_ENABLED=1 GOOS=android GOARCH=arm64 \
    go build -buildmode=c-shared \
    -ldflags="-s -w" \
    -o ../../android/app/src/main/jniLibs/arm64-v8a/libxray.so \
    ./main

# Компиляция для armeabi-v7a
echo "  → armeabi-v7a..."
CGO_ENABLED=1 GOOS=android GOARCH=arm \
    GOARM=7 \
    go build -buildmode=c-shared \
    -ldflags="-s -w" \
    -o ../../android/app/src/main/jniLibs/armeabi-v7a/libxray.so \
    ./main

# Компиляция для x86_64
echo "  → x86_64..."
CGO_ENABLED=1 GOOS=android GOARCH=amd64 \
    go build -buildmode=c-shared \
    -ldflags="-s -w" \
    -o ../../android/app/src/main/jniLibs/x86_64/libxray.so \
    ./main

cd ../..

echo "✅ Готово! Библиотеки созданы:"
ls -lh android/app/src/main/jniLibs/*/libxray.so

echo ""
echo "📝 Следующие шаги:"
echo "1. Обнови V2rayCore.kt чтобы загружать 'xray' вместо 'v2ray'"
echo "2. Запусти: flutter build apk --release --split-per-abi"
