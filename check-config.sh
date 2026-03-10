#!/bin/bash

set -euo pipefail

# 检查 OpenClaw 配置文件结构

echo "🔍 检查 OpenClaw 配置文件结构"
echo ""

ROOTS=(
    "$HOME/.openclaw"
    "/root/.openclaw"
    "/srv/openclaw"
    "/opt/openclaw"
)

print_json_preview() {
    local file="$1"
    echo "--- $file ---"
    if jq '.' "$file" >/dev/null 2>&1; then
        jq '.' "$file" | head -40
    else
        sed -n '1,40p' "$file"
    fi
    echo ""
}

found_any=false

for root in "${ROOTS[@]}"; do
    [[ -d "$root" ]] || continue

    found_any=true
    echo "✓ 找到 OpenClaw 目录: $root"
    echo ""

    if [[ -f "$root/openclaw.json" ]]; then
        echo "配置文件: $root/openclaw.json"
        echo "文件大小: $(du -h "$root/openclaw.json" | cut -f1)"
        echo ""
        echo "顶层键:"
        jq 'keys' "$root/openclaw.json" 2>/dev/null || echo "无法解析 JSON"
        echo ""

        echo "供应商相关路径:"
        for path in '.models.providers' '.ai.vendors' '.vendors' '.providers' '.llm.providers'; do
            if jq -e "$path" "$root/openclaw.json" >/dev/null 2>&1; then
                echo "  ✓ $path 存在"
                jq -r "$path | keys[]" "$root/openclaw.json" 2>/dev/null | sed 's/^/    - /' || true
            else
                echo "  ✗ $path 不存在"
            fi
        done
        echo ""

        echo "默认模型相关路径:"
        if jq -e '.agents.defaults.model' "$root/openclaw.json" >/dev/null 2>&1; then
            echo "  ✓ .agents.defaults.model 存在"
            jq '.agents.defaults.model' "$root/openclaw.json" 2>/dev/null
        else
            echo "  ✗ .agents.defaults.model 不存在"
        fi
        if jq -e '.agents.defaults.models' "$root/openclaw.json" >/dev/null 2>&1; then
            echo "  ✓ .agents.defaults.models 存在"
            jq '.agents.defaults.models | keys' "$root/openclaw.json" 2>/dev/null
        else
            echo "  ✗ .agents.defaults.models 不存在"
        fi
        echo ""

        echo "完整配置预览 (前 40 行):"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        jq '.' "$root/openclaw.json" 2>/dev/null | head -40
        echo ""
    else
        echo "✗ 未找到 $root/openclaw.json"
        echo ""
    fi

    echo "认证与模型文件:"
    files=$(find "$root" -maxdepth 5 \( -name 'auth-profiles.json' -o -name 'auth.json' -o -name 'models.json' -o -name 'oauth.json' \) | sort || true)
    if [[ -z "$files" ]]; then
        echo "  ✗ 未找到 auth-profiles.json / auth.json / models.json / oauth.json"
    else
        while IFS= read -r file; do
            [[ -n "$file" ]] || continue
            echo "  ✓ $file"
        done <<< "$files"
    fi
    echo ""

    if [[ -n "${files:-}" ]]; then
        echo "文件预览:"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        while IFS= read -r file; do
            [[ -n "$file" ]] || continue
            print_json_preview "$file"
        done <<< "$files"
    fi

    echo "=============================================================="
    echo ""
done

if [[ "$found_any" == false ]]; then
    echo "✗ 未找到任何 OpenClaw 目录"
    echo ""
    echo "请检查以下常见路径:"
    printf '  - %s\n' "${ROOTS[@]}"
fi
