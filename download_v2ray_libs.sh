#!/bin/bash

# Скрипт для скачивания готовых libv2ray.so из v2rayNG

set -e

echo "📥 Скачиваем готовые библиотеки из v2rayNG..."

# Создаем директории
mkdir -p android/app/src/main/jniLibs/arm64-v8a
mkdir -p android/app/src/main/jniLibs/armeabi-v7a
mkdir -p android/app/src/main/jniLibs/x86_64
mkdir -p temp_download

cd temp_download

# Получаем последний релиз v2rayNG
echo "🔍 Получаем информацию о последнем релизе..."
RELEASE_INFO=$(curl -s https://api.github.com/repos/2dust/v2rayNG/releases/latest)
VERSION=$(echo "$RELEASE_INFO" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')

echo "📦 Найдена версия: $VERSION"

# Функция для скачивания и извлечения
download_arch() {
    local arch=$1
    local pattern=$2
    
    echo "📥 Скачиваем $arch..."
    
    # Находим URL для APK
    local url=$(echo "$RELEASE_INFO" | grep "browser_download_url.*$pattern.*\.apk" | head -1 | cut -d '"' -f 4)
    
    if [ -z "$url" ]; then
        echo "  ⚠️  APK для $arch не найден"
        return
    fi
    
    local apk_file="${arch}.apk"
    echo "  → Скачиваем..."
    curl -L -o "$apk_file" "$url"
    
    # Распаковываем APK
    echo "  → Распаковываем..."
    unzip -q "$apk_file" -d "$arch"
    
    # Копируем libv2ray.so
    local so_file="$arch/lib/$arch/libv2ray.so"
    if [ -f "$so_file" ]; then
        cp "$so_file" "../android/app/src/main/jniLibs/$arch/libv2ray.so"
        echo "  ✅ libv2ray.so скопирован"
    else
        echo "  ⚠️  libv2ray.so не найден в APK"
    fi
    
    # Удаляем временные файлы
    rm -f "$apk_file"
    rm -rf "$arch"
}

# Скачиваем для всех архитектур
download_arch "arm64-v8a" "arm64-v8a"
download_arch "armeabi-v7a" "armeabi-v7a"
download_arch "x86_64" "x86_64"

cd ..

echo ""
echo "✅ Готово! Проверяем файлы:"
ls -lh android/app/src/main/jniLibs/*/libv2ray.so 2>/dev/null || echo "  ⚠️  Файлы не найдены"

echo ""
echo "📝 Следующие шаги:"
echo "1. Запусти: flutter build apk --release --split-per-abi"
echo "2. Установи новый APK на устройство"
echo "3. Проблема Permission denied должна исчезнуть!"
