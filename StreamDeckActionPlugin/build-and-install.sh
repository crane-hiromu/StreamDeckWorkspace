#!/bin/bash

# === 設定 ===
PLUGIN_NAME="StreamDeckActionPlugin"
BINARY_PATH=".build/release/$PLUGIN_NAME"
PLUGIN_DIR="$HOME/Library/Application Support/com.elgato.StreamDeck/Plugins/com.hiromu.sample.sdPlugin"

# === ビルド ===
echo "🔨 Building release binary..."
swift build -c release || { echo "❌ Build failed"; exit 1; }

# === 配置先のクリア＆作成 ===
echo "🧹 Removing existing plugin directory (if exists)..."
rm -rf "$PLUGIN_DIR"
mkdir -p "$PLUGIN_DIR"

# === バイナリと定義ファイルをコピー ===
echo "📦 Copying binary..."
cp "$BINARY_PATH" "$PLUGIN_DIR/"

# === Images（任意） ===
if [ -d "Images" ]; then
  echo "🖼️ Copying Images/ directory..."
  cp -R Images "$PLUGIN_DIR/"
fi

echo "✅ Plugin installed"

## === 再起動 ===
#killall "Stream Deck"
#open -a "Elgato Stream Deck"
