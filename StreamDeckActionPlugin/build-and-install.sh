#!/bin/bash

################################################
## Package.swift で設定している name と一致させること
##  ~example~
##  products: [
##      .executable(name: "action-plugin", ...
##  ],
################################################
PLUGIN_NAME="action-plugin"

# === パス ===
BINARY_PATH=".build/release/$PLUGIN_NAME"
PLUGIN_ROOT_DIR="$HOME/Library/Application Support/com.elgato.StreamDeck/Plugins"
PLUGIN_NAME="com.elgato.$PLUGIN_NAME.sdPlugin"
PLUGIN_DIR="$PLUGIN_ROOT_DIR/$PLUGIN_NAME"

# === ビルド ===
echo "🔨 Building release binary..."
swift build -c release || { echo "❌ Build failed"; exit 1; }

# === 配置先の削除と再生成 ===
echo "🧹 Removing existing plugin directory (if exists)..."
rm -rf "$PLUGIN_DIR"
mkdir -p "$PLUGIN_DIR"

# === バイナリと定義ファイルをコピー ===
echo "📦 Copying binary..."
cp "$BINARY_PATH" "$PLUGIN_DIR/"

# === manifest の生成とプラグイン書き出し ===
echo "📄 Generating manifest and exporting plugin..."
"$BINARY_PATH" export "./$PLUGIN_NAME" \
  --output "$PLUGIN_ROOT_DIR" \
  --generate-manifest \
  --copy-executable

# === Images（任意） ===
if [ -d "Images" ]; then
  echo "🖼️ Copying Images/ directory..."
  cp -R Images "$PLUGIN_DIR/"
fi

echo "✅ Plugin installed"

# === Stream Deck を終了（起動している場合のみ） ===
if pgrep -x "Stream Deck" >/dev/null; then
  echo "🛑 Killing Stream Deck..."
  killall "Stream Deck"
else
  echo "✅ Stream Deck is not running."
fi

## === 再起動 ===
#open -a "Elgato Stream Deck"
