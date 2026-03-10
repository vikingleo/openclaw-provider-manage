#!/bin/bash

# OpenClaw Provider Manager 安装脚本

set -e

echo "🚀 开始安装 OpenClaw Provider Manager"
echo ""

# 检查 Node.js
if ! command -v node &> /dev/null; then
    echo "❌ 未找到 Node.js，请先安装 Node.js (>= 14.0.0)"
    echo "   macOS: brew install node"
    echo "   Ubuntu: sudo apt-get install nodejs npm"
    exit 1
fi

NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 14 ]; then
    echo "❌ Node.js 版本过低 (当前: $(node -v))，需要 >= 14.0.0"
    exit 1
fi

echo "✅ Node.js 版本: $(node -v)"

# 检查 npm
if ! command -v npm &> /dev/null; then
    echo "❌ 未找到 npm"
    exit 1
fi

echo "✅ npm 版本: $(npm -v)"
echo ""

# 安装依赖
echo "📦 安装依赖..."
npm install

if [ $? -eq 0 ]; then
    echo "✅ 依赖安装成功"
else
    echo "❌ 依赖安装失败"
    exit 1
fi

echo ""

# 运行测试
echo "🧪 运行测试..."
npm test

if [ $? -eq 0 ]; then
    echo "✅ 测试通过"
else
    echo "❌ 测试失败"
    exit 1
fi

echo ""

# 设置可执行权限
chmod +x openclaw-vendor-manager.sh
echo "✅ 已设置脚本执行权限"

echo ""
echo "🎉 安装完成！"
echo ""
echo "使用方式："
echo ""
echo "1. 命令行脚本："
echo "   ./openclaw-vendor-manager.sh --list"
echo ""
echo "2. Node.js API："
echo "   node index.js list"
echo ""
echo "3. Telegram Bot (需要先设置 TELEGRAM_BOT_TOKEN)："
echo "   export TELEGRAM_BOT_TOKEN='your_token_here'"
echo "   npm run telegram"
echo ""
echo "详细文档请查看 README.md"
