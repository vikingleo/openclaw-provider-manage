#!/bin/bash

# OpenClaw Provider Manager - 快速启动脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🚀 OpenClaw Provider Manager${NC}"
echo ""

# 显示菜单
show_menu() {
    echo "请选择操作模式："
    echo ""
    echo "  1) 命令行交互模式"
    echo "  2) 列出所有供应商"
    echo "  3) 启动 Telegram Bot"
    echo "  4) 运行测试"
    echo "  5) 安装/更新依赖"
    echo "  0) 退出"
    echo ""
}

# 主循环
while true; do
    show_menu
    read -p "请输入选项 [0-5]: " choice

    case $choice in
        1)
            echo ""
            echo -e "${GREEN}启动命令行交互模式...${NC}"
            echo ""
            "$SCRIPT_DIR/openclaw-vendor-manager.sh"
            ;;
        2)
            echo ""
            echo -e "${GREEN}列出所有供应商...${NC}"
            echo ""
            "$SCRIPT_DIR/openclaw-vendor-manager.sh" --list
            echo ""
            ;;
        3)
            echo ""
            if [ -z "$TELEGRAM_BOT_TOKEN" ]; then
                echo -e "${YELLOW}⚠️  未设置 TELEGRAM_BOT_TOKEN${NC}"
                echo ""
                read -p "请输入 Telegram Bot Token: " token
                export TELEGRAM_BOT_TOKEN="$token"
            fi
            echo -e "${GREEN}启动 Telegram Bot...${NC}"
            echo ""
            cd "$SCRIPT_DIR" && npm run telegram
            ;;
        4)
            echo ""
            echo -e "${GREEN}运行测试...${NC}"
            echo ""
            cd "$SCRIPT_DIR" && npm test
            echo ""
            ;;
        5)
            echo ""
            echo -e "${GREEN}安装/更新依赖...${NC}"
            echo ""
            cd "$SCRIPT_DIR" && npm install
            echo ""
            ;;
        0)
            echo ""
            echo -e "${GREEN}退出${NC}"
            exit 0
            ;;
        *)
            echo ""
            echo -e "${YELLOW}无效选项，请重新选择${NC}"
            echo ""
            ;;
    esac
done
