#!/bin/bash

# 检查 OpenClaw 配置文件结构

echo "🔍 检查 OpenClaw 配置文件结构"
echo ""

# 可能的配置文件位置
LOCATIONS=(
    "$HOME/.openclaw/openclaw.json"
    "/root/.openclaw/openclaw.json"
    "/srv/openclaw/openclaw.json"
    "/opt/openclaw/openclaw.json"
)

for loc in "${LOCATIONS[@]}"; do
    if [[ -f "$loc" ]]; then
        echo "✓ 找到配置文件: $loc"
        echo ""
        echo "文件大小: $(du -h "$loc" | cut -f1)"
        echo ""
        echo "配置结构:"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        # 显示顶层键
        echo "顶层键:"
        jq 'keys' "$loc" 2>/dev/null || echo "无法解析 JSON"
        echo ""

        # 检查可能的 AI 配置路径
        echo "检查可能的 AI 配置路径:"

        # 路径 1: .ai.vendors
        if jq -e '.ai.vendors' "$loc" >/dev/null 2>&1; then
            echo "  ✓ .ai.vendors 存在"
            jq '.ai.vendors | keys' "$loc" 2>/dev/null
        else
            echo "  ✗ .ai.vendors 不存在"
        fi

        # 路径 2: .vendors
        if jq -e '.vendors' "$loc" >/dev/null 2>&1; then
            echo "  ✓ .vendors 存在"
            jq '.vendors | keys' "$loc" 2>/dev/null
        else
            echo "  ✗ .vendors 不存在"
        fi

        # 路径 3: .providers
        if jq -e '.providers' "$loc" >/dev/null 2>&1; then
            echo "  ✓ .providers 存在"
            jq '.providers | keys' "$loc" 2>/dev/null
        else
            echo "  ✗ .providers 不存在"
        fi

        # 路径 4: .models
        if jq -e '.models' "$loc" >/dev/null 2>&1; then
            echo "  ✓ .models 存在"
            jq '.models | keys' "$loc" 2>/dev/null
        else
            echo "  ✗ .models 不存在"
        fi

        echo ""
        echo "完整配置预览 (前 30 行):"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        jq '.' "$loc" 2>/dev/null | head -30
        echo ""

        break
    fi
done

if [[ ! -f "$loc" ]]; then
    echo "✗ 未找到任何配置文件"
    echo ""
    echo "请提供配置文件路径或内容，以便我们适配脚本"
fi
