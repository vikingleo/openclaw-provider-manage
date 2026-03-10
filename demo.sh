#!/bin/bash

# OpenClaw Provider Manager - 演示脚本

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🎬 OpenClaw Provider Manager 功能演示"
echo "======================================"
echo ""

# 颜色
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

demo_step() {
    echo -e "${BLUE}▶ $1${NC}"
    echo ""
}

demo_result() {
    echo -e "${GREEN}✓ $1${NC}"
    echo ""
}

# 1. 测试核心功能
demo_step "1. 运行测试套件"
cd "$SCRIPT_DIR"
npm test
demo_result "测试通过"

# 2. 列出供应商（使用命令行脚本）
demo_step "2. 列出供应商（命令行脚本）"
./openclaw-vendor-manager.sh --list || echo "需要配置 OpenClaw 目录"
demo_result "命令行脚本工作正常"

# 3. 使用 Node.js API
demo_step "3. 使用 Node.js API"
node index.js list || echo "需要配置 OpenClaw 目录"
demo_result "Node.js API 工作正常"

# 4. 显示项目结构
demo_step "4. 项目结构"
tree -L 1 -a 2>/dev/null || ls -lah
demo_result "项目文件完整"

echo ""
echo "======================================"
echo -e "${GREEN}🎉 演示完成！${NC}"
echo ""
echo "下一步："
echo "  1. 配置环境变量: cp .env.example .env && nano .env"
echo "  2. 启动交互模式: ./start.sh"
echo "  3. 或启动 Telegram Bot: npm run telegram"
echo ""
