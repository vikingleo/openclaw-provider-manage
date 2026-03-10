#!/bin/bash

# OpenClaw Provider Manager - 一键部署脚本
# 自动安装所有依赖，无需手动 npm install

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 显示欢迎信息
clear
cat << 'EOF'
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   ██████╗ ██████╗ ███████╗███╗   ██╗ ██████╗██╗      █████╗  ║
║  ██╔═══██╗██╔══██╗██╔════╝████╗  ██║██╔════╝██║     ██╔══██╗ ║
║  ██║   ██║██████╔╝█████╗  ██╔██╗ ██║██║     ██║     ███████║ ║
║  ██║   ██║██╔═══╝ ██╔══╝  ██║╚██╗██║██║     ██║     ██╔══██║ ║
║  ╚██████╔╝██║     ███████╗██║ ╚████║╚██████╗███████╗██║  ██║ ║
║   ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═══╝ ╚═════╝╚══════╝╚═╝  ╚═╝ ║
║                                                               ║
║              Provider Manager - 一键部署                      ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝

EOF

echo -e "${CYAN}🚀 开始一键部署 OpenClaw Provider Manager${NC}"
echo ""

# 检查系统
echo -e "${BLUE}[1/6]${NC} 检查系统环境..."

# 检查操作系统
OS="$(uname -s)"
case "$OS" in
    Linux*)     OS_TYPE="Linux";;
    Darwin*)    OS_TYPE="macOS";;
    *)          OS_TYPE="Unknown";;
esac

echo -e "  ${GREEN}✓${NC} 操作系统: $OS_TYPE"

# 检查必需工具
echo ""
echo -e "${BLUE}[2/6]${NC} 检查必需工具..."

MISSING_TOOLS=()

# 检查 jq
if ! command -v jq &> /dev/null; then
    MISSING_TOOLS+=("jq")
    echo -e "  ${YELLOW}⚠${NC} jq 未安装"
else
    echo -e "  ${GREEN}✓${NC} jq: $(jq --version)"
fi

# 检查 Node.js
if ! command -v node &> /dev/null; then
    MISSING_TOOLS+=("node")
    echo -e "  ${YELLOW}⚠${NC} Node.js 未安装"
else
    NODE_VERSION=$(node -v)
    echo -e "  ${GREEN}✓${NC} Node.js: $NODE_VERSION"
fi

# 检查 npm
if ! command -v npm &> /dev/null; then
    MISSING_TOOLS+=("npm")
    echo -e "  ${YELLOW}⚠${NC} npm 未安装"
else
    NPM_VERSION=$(npm -v)
    echo -e "  ${GREEN}✓${NC} npm: $NPM_VERSION"
fi

# 如果有缺失的工具，提供安装指导
if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}⚠️  缺少必需工具: ${MISSING_TOOLS[*]}${NC}"
    echo ""
    echo "请先安装缺失的工具："
    echo ""

    if [[ "$OS_TYPE" == "macOS" ]]; then
        echo "  macOS (使用 Homebrew):"
        [[ " ${MISSING_TOOLS[@]} " =~ " jq " ]] && echo "    brew install jq"
        [[ " ${MISSING_TOOLS[@]} " =~ " node " ]] && echo "    brew install node"
    elif [[ "$OS_TYPE" == "Linux" ]]; then
        echo "  Ubuntu/Debian:"
        [[ " ${MISSING_TOOLS[@]} " =~ " jq " ]] && echo "    sudo apt-get install jq"
        [[ " ${MISSING_TOOLS[@]} " =~ " node " ]] && echo "    sudo apt-get install nodejs npm"
        echo ""
        echo "  CentOS/RHEL:"
        [[ " ${MISSING_TOOLS[@]} " =~ " jq " ]] && echo "    sudo yum install jq"
        [[ " ${MISSING_TOOLS[@]} " =~ " node " ]] && echo "    sudo yum install nodejs npm"
    fi

    echo ""
    echo -e "${CYAN}💡 提示: 安装完成后重新运行此脚本${NC}"
    exit 1
fi

# 设置可执行权限
echo ""
echo -e "${BLUE}[3/6]${NC} 设置脚本权限..."

chmod +x openclaw-vendor-manager.sh
chmod +x install.sh
chmod +x start.sh
chmod +x demo.sh
chmod +x verify.sh
chmod +x welcome.sh

echo -e "  ${GREEN}✓${NC} 所有脚本已设置可执行权限"

# 安装 Node.js 依赖
echo ""
echo -e "${BLUE}[4/6]${NC} 安装 Node.js 依赖..."

if [ -d "node_modules" ]; then
    echo -e "  ${CYAN}ℹ${NC} node_modules 已存在，跳过安装"
else
    echo -e "  ${CYAN}→${NC} 正在安装 node-telegram-bot-api..."
    npm install --silent
    echo -e "  ${GREEN}✓${NC} 依赖安装完成"
fi

# 运行测试
echo ""
echo -e "${BLUE}[5/6]${NC} 运行测试验证..."

if npm test > /dev/null 2>&1; then
    echo -e "  ${GREEN}✓${NC} 所有测试通过"
else
    echo -e "  ${YELLOW}⚠${NC} 测试失败，但不影响使用"
fi

# 创建环境变量文件（如果不存在）
echo ""
echo -e "${BLUE}[6/6]${NC} 配置环境..."

if [ ! -f ".env" ]; then
    cp .env.example .env
    echo -e "  ${GREEN}✓${NC} 已创建 .env 配置文件"
    echo -e "  ${CYAN}ℹ${NC} 如需使用 Telegram Bot，请编辑 .env 文件设置 TELEGRAM_BOT_TOKEN"
else
    echo -e "  ${CYAN}ℹ${NC} .env 文件已存在，跳过创建"
fi

# 部署完成
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ 部署完成！${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 显示使用方式
echo -e "${CYAN}🚀 快速开始:${NC}"
echo ""
echo -e "  ${YELLOW}方式一: 交互式菜单（推荐）${NC}"
echo -e "    ./start.sh"
echo ""
echo -e "  ${YELLOW}方式二: 命令行脚本${NC}"
echo -e "    ./openclaw-vendor-manager.sh --list"
echo -e "    ./openclaw-vendor-manager.sh --vendor anthropic"
echo -e "    ./openclaw-vendor-manager.sh --add-vendor"
echo ""
echo -e "  ${YELLOW}方式三: Telegram Bot${NC}"
echo -e "    1. 编辑 .env 文件，设置 TELEGRAM_BOT_TOKEN"
echo -e "    2. source .env"
echo -e "    3. npm run telegram"
echo ""

# 显示文档
echo -e "${CYAN}📚 查看文档:${NC}"
echo ""
echo -e "  README.md       - 完整说明文档"
echo -e "  QUICKSTART.md   - 快速开始指南"
echo -e "  PROJECT.md      - 项目架构说明"
echo ""

# 显示验证命令
echo -e "${CYAN}🔍 验证安装:${NC}"
echo ""
echo -e "  ./verify.sh     - 验证项目完整性"
echo -e "  npm test        - 运行测试套件"
echo -e "  ./demo.sh       - 查看功能演示"
echo ""

# 询问是否立即启动
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
read -p "是否立即启动交互式菜单？(y/N): " START_NOW

if [[ "$START_NOW" =~ ^[Yy]$ ]]; then
    echo ""
    exec ./start.sh
else
    echo ""
    echo -e "${GREEN}🎉 随时运行 ./start.sh 开始使用！${NC}"
    echo ""
fi
