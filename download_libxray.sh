#!/bin/bash
# Bash скрипт для скачивания libxray.aar
# Основано на архитектуре v2rayNG

set -e

echo "=== NeoTUN - Download libxray.aar ==="
echo ""

# Параметры
GITHUB_REPO="2dust/AndroidLibXrayLite"
OUTPUT_DIR="android/app/libs"
OUTPUT_FILE="$OUTPUT_DIR/libxray.aar"

# Создаём директорию если не существует
if [ ! -d "$OUTPUT_DIR" ]; then
    echo "Creating directory: $OUTPUT_DIR"
    mkdir -p "$OUTPUT_DIR"
fi

# Проверяем существующий файл
if [ -f "$OUTPUT_FILE" ]; then
    echo "libxray.aar already exists at: $OUTPUT_FILE"
    read -p "Do you want to re-download? (y/N): " response
    if [ "$response" != "y" ] && [ "$response" != "Y" ]; then
        echo "Skipping download."
        exit 0
    fi
    rm -f "$OUTPUT_FILE"
fi

echo "Fetching latest release info from GitHub..."

# Получаем информацию о последнем релизе
RELEASE_URL="https://api.github.com/repos/$GITHUB_REPO/releases/latest"
RELEASE_JSON=$(curl -s -H "User-Agent: NeoTUN-Downloader" "$RELEASE_URL")

VERSION=$(echo "$RELEASE_JSON" | grep -o '"tag_name": *"[^"]*"' | sed 's/"tag_name": *"\(.*\)"/\1/')
echo "Latest version: $VERSION"

# Ищем libxray.aar в assets
DOWNLOAD_URL=$(echo "$RELEASE_JSON" | grep -o '"browser_download_url": *"[^"]*libxray.aar"' | sed 's/"browser_download_url": *"\(.*\)"/\1/')

if [ -z "$DOWNLOAD_URL" ]; then
    echo "ERROR: libxray.aar not found in release assets"
    echo "Available assets:"
    echo "$RELEASE_JSON" | grep -o '"name": *"[^"]*"' | sed 's/"name": *"\(.*\)"/  - \1/'
    exit 1
fi

echo ""
echo "Downloading libxray.aar..."
echo "  URL: $DOWNLOAD_URL"
echo "  Output: $OUTPUT_FILE"
echo ""

# Скачиваем файл
if command -v wget &> /dev/null; then
    wget -O "$OUTPUT_FILE" "$DOWNLOAD_URL"
elif command -v curl &> /dev/null; then
    curl -L -o "$OUTPUT_FILE" "$DOWNLOAD_URL"
else
    echo "ERROR: Neither wget nor curl is available"
    exit 1
fi

echo ""
echo "✓ Successfully downloaded libxray.aar"
echo "  Version: $VERSION"
echo "  Location: $OUTPUT_FILE"

# Проверяем размер файла
FILE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
echo "  Size: $FILE_SIZE"

echo ""
echo "You can now build the Android app:"
echo "  flutter build apk --release"
