#!/bin/bash
# Скрипт для загрузки libxray.aar для Android
# Основано на AndroidLibXrayLite от 2dust

set -e

LIBS_DIR="android/app/libs"
AAR_FILE="$LIBS_DIR/libxray.aar"

echo "=== Загрузка libxray.aar ==="

# Создаём директорию если её нет
mkdir -p "$LIBS_DIR"

# Проверяем существующий файл
if [ -f "$AAR_FILE" ]; then
    echo "✓ libxray.aar уже существует"
    size=$(du -h "$AAR_FILE" | cut -f1)
    echo "  Размер: $size"
    
    read -p "Перезагрузить? (y/N): " response
    if [ "$response" != "y" ] && [ "$response" != "Y" ]; then
        echo "Пропускаем загрузку"
        exit 0
    fi
fi

echo "Получение информации о последнем релизе..."

# Получаем информацию о последнем релизе
RELEASE_URL="https://api.github.com/repos/2dust/AndroidLibXrayLite/releases/latest"
RELEASE_JSON=$(curl -s -H "User-Agent: NeoTUN-Downloader" "$RELEASE_URL")

VERSION=$(echo "$RELEASE_JSON" | grep -o '"tag_name": *"[^"]*"' | cut -d'"' -f4)
echo "✓ Последняя версия: $VERSION"

# Извлекаем URL для libv2ray.aar (AndroidLibXrayLite использует это имя)
DOWNLOAD_URL=$(echo "$RELEASE_JSON" | grep -o '"browser_download_url": *"[^"]*libv2ray.aar"' | cut -d'"' -f4)

if [ -z "$DOWNLOAD_URL" ]; then
    echo "✗ libv2ray.aar не найден в релизе"
    echo "Доступные файлы:"
    echo "$RELEASE_JSON" | grep -o '"name": *"[^"]*"' | cut -d'"' -f4
    exit 1
fi

echo "Загрузка libxray.aar..."
echo "URL: $DOWNLOAD_URL"

# Загружаем файл
TEMP_FILE="$AAR_FILE.tmp"
curl -L -H "User-Agent: NeoTUN-Downloader" -o "$TEMP_FILE" "$DOWNLOAD_URL" --progress-bar

# Проверяем что файл загружен
if [ ! -f "$TEMP_FILE" ]; then
    echo "✗ Файл не был загружен"
    exit 1
fi

# Переименовываем временный файл
mv -f "$TEMP_FILE" "$AAR_FILE"

size=$(du -h "$AAR_FILE" | cut -f1)
echo "✓ libxray.aar загружен успешно ($size)"
echo "✓ Версия: $VERSION"
echo "✓ Путь: $AAR_FILE"

echo ""
echo "=== Готово ==="
echo "Теперь можно собрать Android приложение с поддержкой VPN"
