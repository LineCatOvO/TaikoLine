#!/bin/bash
# TaikoLine Web Build Script
# 自动化Godot Web打包流程

set -e

# 配置
GODOT_PATH="$HOME/bin/Godot_v4.4-stable_linux.arm64"
PROJECT_PATH="$(dirname "$0")/.."
EXPORT_PRESET="Web"

echo "🎮 TaikoLine Web Build Script"
echo "=============================="

# 检查Godot是否存在
if [ ! -f "$GODOT_PATH" ]; then
    echo "❌ Error: Godot not found at $GODOT_PATH"
    exit 1
fi

# 切换到项目目录
cd "$PROJECT_PATH"
echo "📁 Project path: $(pwd)"

# 执行Web导出
echo "🔨 Building Web export..."
"$GODOT_PATH" --headless --export-release "$EXPORT_PRESET"

# 检查导出结果
if [ -f "web/index.html" ]; then
    echo "✅ Build successful!"
    echo "📦 Output: web/"
    ls -lh web/
else
    echo "❌ Build failed: index.html not found"
    exit 1
fi

echo ""
echo "🚀 Run 'npm start' to launch the web server"