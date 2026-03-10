#!/bin/bash

# OpenClaw Provider Manager - 项目验证脚本

echo "🔍 OpenClaw Provider Manager - 项目验证"
echo "========================================"
echo ""

# 颜色
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓${NC} $1"
        return 0
    else
        echo -e "${RED}✗${NC} $1 (缺失)"
        return 1
    fi
}

check_executable() {
    if [ -x "$1" ]; then
        echo -e "${GREEN}✓${NC} $1 (可执行)"
        return 0
    else
        echo -e "${RED}✗${NC} $1 (不可执行)"
        return 1
    fi
}

echo -e "${BLUE}1. 检查核心文件${NC}"
check_file "extension.json"
check_file "package.json"
check_file "index.js"
check_file "telegram-card.js"
check_file "test.js"
echo ""

echo -e "${BLUE}2. 检查脚本文件${NC}"
check_executable "openclaw-vendor-manager.sh"
check_executable "install.sh"
check_executable "start.sh"
check_executable "demo.sh"
echo ""

echo -e "${BLUE}3. 检查文档文件${NC}"
check_file "README.md"
check_file "QUICKSTART.md"
check_file "CHANGELOG.md"
check_file "PROJECT.md"
echo ""

echo -e "${BLUE}4. 检查配置文件${NC}"
check_file ".env.example"
check_file "openclaw.json.example"
check_file ".gitignore"
echo ""

echo -e "${BLUE}5. 检查 Node.js 环境${NC}"
if command -v node &> /dev/null; then
    echo -e "${GREEN}✓${NC} Node.js: $(node -v)"
else
    echo -e "${RED}✗${NC} Node.js 未安装"
fi

if command -v npm &> /dev/null; then
    echo -e "${GREEN}✓${NC} npm: $(npm -v)"
else
    echo -e "${RED}✗${NC} npm 未安装"
fi
echo ""

echo -e "${BLUE}6. 检查依赖${NC}"
if [ -d "node_modules" ]; then
    echo -e "${GREEN}✓${NC} node_modules 已安装"
else
    echo -e "${RED}✗${NC} node_modules 未安装 (运行 npm install)"
fi
echo ""

echo "========================================"
echo -e "${GREEN}✅ 项目验证完成${NC}"
echo ""
echo "下一步："
echo "  1. 安装依赖: npm install"
echo "  2. 运行测试: npm test"
echo "  3. 开始使用: ./start.sh"
