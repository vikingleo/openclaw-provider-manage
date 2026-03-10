#!/usr/bin/env bash
#
# OpenClaw 供应商模型一键维护脚本
# 用于在 OpenClaw 无法使用时快速切换供应商和模型
#
# 使用方式:
#   ./openclaw-vendor-manager.sh
#   ./openclaw-vendor-manager.sh --vendor anthropic --model claude-3-5-sonnet-20241022
#   ./openclaw-vendor-manager.sh --add-vendor
#   ./openclaw-vendor-manager.sh --add-model --vendor openai
#   ./openclaw-vendor-manager.sh --openclaw-dir /srv/openclaw
#

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 默认值
OPENCLAW_DIR=""
VENDOR=""
MODEL=""
ADD_VENDOR=false
ADD_MODEL=false
LIST_ONLY=false

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

# 显示帮助
show_help() {
    cat <<EOF
OpenClaw 供应商模型一键维护脚本

用法:
    $0 [选项]

可选参数:
    --openclaw-dir <目录>       OpenClaw 安装目录 (默认: ~/.openclaw 或自动检测)

操作选项:
    --list                      仅列出当前配置的供应商和模型
    --vendor <供应商>           切换到指定供应商
    --model <模型>              切换到指定模型（需配合 --vendor）
    --add-vendor                添加新供应商
    --add-model                 向指定供应商添加新模型（需配合 --vendor）

示例:
    # 自动检测 OpenClaw 目录并列出配置
    $0 --list

    # 自动检测并切换到指定供应商
    $0 --vendor anthropic

    # 指定目录并切换到指定供应商的指定模型
    $0 --openclaw-dir /srv/openclaw --vendor openai --model gpt-4

    # 添加新供应商
    $0 --add-vendor

    # 向指定供应商添加新模型
    $0 --add-model --vendor openai

EOF
}

# 解析参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --openclaw-dir)
                OPENCLAW_DIR="$2"
                shift 2
                ;;
            --vendor)
                VENDOR="$2"
                shift 2
                ;;
            --model)
                MODEL="$2"
                shift 2
                ;;
            --add-vendor)
                ADD_VENDOR=true
                shift
                ;;
            --add-model)
                ADD_MODEL=true
                shift
                ;;
            --list)
                LIST_ONLY=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# 自动检测 OpenClaw 目录
detect_openclaw_dir() {
    if [[ -n "$OPENCLAW_DIR" ]]; then
        return
    fi

    local candidates=(
        "$HOME/.openclaw"
        "/srv/openclaw"
        "/opt/openclaw"
        "$HOME/openclaw"
    )

    log_info "自动检测 OpenClaw 目录..."

    for dir in "${candidates[@]}"; do
        if [[ -f "$dir/openclaw.json" ]]; then
            OPENCLAW_DIR="$dir"
            log_success "检测到 OpenClaw 目录: $OPENCLAW_DIR"
            return
        fi
    done

    # 尝试通过进程查找
    local pid_dir=$(ps aux | grep -i openclaw | grep -v grep | awk '{for(i=1;i<=NF;i++) if($i ~ /openclaw/) print $i}' | head -1 | xargs dirname 2>/dev/null || echo "")
    if [[ -n "$pid_dir" && -f "$pid_dir/openclaw.json" ]]; then
        OPENCLAW_DIR="$pid_dir"
        log_success "通过进程检测到 OpenClaw 目录: $OPENCLAW_DIR"
        return
    fi

    log_error "无法自动检测 OpenClaw 目录"
    log_info "请使用 --openclaw-dir 参数手动指定"
    log_info "常见位置: ~/.openclaw, /srv/openclaw, /opt/openclaw"
    exit 1
}

# 检查依赖
check_dependencies() {
    local missing_deps=()

    for cmd in jq node; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "缺少必需的依赖: ${missing_deps[*]}"
        log_info "请安装: brew install jq node (macOS) 或 apt-get install jq nodejs (Linux)"
        exit 1
    fi
}

# 检查 OpenClaw 目录
check_openclaw_dir() {
    if [[ ! -d "$OPENCLAW_DIR" ]]; then
        log_error "OpenClaw 目录不存在: $OPENCLAW_DIR"
        exit 1
    fi

    local config_file="$OPENCLAW_DIR/openclaw.json"
    if [[ ! -f "$config_file" ]]; then
        log_error "找不到配置文件: $config_file"
        exit 1
    fi

    log_success "找到 OpenClaw 配置: $config_file"
}

# 初始化配置文件
init_config() {
    local config_file="$OPENCLAW_DIR/openclaw.json"

    log_info "初始化 OpenClaw 配置文件..."

    # 备份现有配置（如果存在）
    if [[ -f "$config_file" ]]; then
        local backup_file="${config_file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$config_file" "$backup_file"
        log_info "已备份现有配置到: $backup_file"
    fi

    # 检查是否已有 ai 结构
    local has_ai=$(jq -e '.ai' "$config_file" 2>/dev/null)
    if [[ $? -eq 0 ]]; then
        # 只添加 vendors 结构
        local tmp_file=$(mktemp)
        jq '.ai.vendors = {}' "$config_file" > "$tmp_file"
        mv "$tmp_file" "$config_file"
    else
        # 创建完整的 ai 结构
        local tmp_file=$(mktemp)
        if [[ -f "$config_file" ]]; then
            jq '. + {"ai": {"vendors": {}}}' "$config_file" > "$tmp_file"
        else
            echo '{"ai": {"vendors": {}}}' > "$tmp_file"
        fi
        mv "$tmp_file" "$config_file"
    fi

    log_success "配置文件已初始化"
}

# 备份配置文件
backup_config() {
    local config_file="$OPENCLAW_DIR/openclaw.json"
    local backup_dir="$OPENCLAW_DIR/.openclaw/backups/vendor-manager"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$backup_dir/openclaw.json.$timestamp"

    mkdir -p "$backup_dir"
    cp "$config_file" "$backup_file"

    log_success "配置已备份到: $backup_file"
    echo "$backup_file"
}

# 列出当前配置
list_current_config() {
    local config_file="$OPENCLAW_DIR/openclaw.json"

    log_info "当前 OpenClaw 配置:"
    echo ""

    # 检查配置文件是否有 ai.vendors 结构
    local has_vendors=$(jq -e '.ai.vendors' "$config_file" 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        log_warn "配置文件缺少 ai.vendors 结构"
        echo ""
        read -p "是否初始化配置文件？(y/N): " init_now
        if [[ "$init_now" =~ ^[Yy]$ ]]; then
            init_config
            echo ""
            log_info "配置已初始化，现在可以添加供应商了"
        fi
        return
    fi

    # 读取 AI 供应商配置
    local vendors=$(jq -r '.ai.vendors // {} | keys[]' "$config_file" 2>/dev/null || echo "")

    if [[ -z "$vendors" ]]; then
        log_warn "未找到任何供应商配置"
        echo ""
        log_info "提示: 选择选项 3 添加新供应商"
        return
    fi

    echo -e "${BLUE}已配置的供应商:${NC}"
    for vendor in $vendors; do
        local enabled=$(jq -r ".ai.vendors.\"$vendor\".enabled // false" "$config_file")
        local models=$(jq -r ".ai.vendors.\"$vendor\".models // {} | keys[]" "$config_file" 2>/dev/null || echo "")
        local default_model=$(jq -r ".ai.vendors.\"$vendor\".defaultModel // \"\"" "$config_file")

        if [[ "$enabled" == "true" ]]; then
            echo -e "  ${GREEN}✓${NC} $vendor (已启用)"
        else
            echo -e "  ${YELLOW}○${NC} $vendor (已禁用)"
        fi

        if [[ -n "$default_model" ]]; then
            echo -e "    默认模型: ${BLUE}$default_model${NC}"
        fi

        if [[ -n "$models" ]]; then
            echo "    可用模型:"
            for model in $models; do
                echo "      - $model"
            done
        fi
        echo ""
    done

    # 显示当前活跃供应商
    local active_vendor=$(jq -r '.ai.activeVendor // ""' "$config_file")
    if [[ -n "$active_vendor" ]]; then
        echo -e "${GREEN}当前活跃供应商:${NC} $active_vendor"
    fi
}

# 切换供应商
switch_vendor() {
    local vendor="$1"
    local model="${2:-}"
    local config_file="$OPENCLAW_DIR/openclaw.json"

    # 检查供应商是否存在
    local vendor_exists=$(jq -r ".ai.vendors.\"$vendor\" // null" "$config_file")
    if [[ "$vendor_exists" == "null" ]]; then
        log_error "供应商 '$vendor' 不存在"
        log_info "可用的供应商:"
        jq -r '.ai.vendors // {} | keys[]' "$config_file" | sed 's/^/  - /'
        exit 1
    fi

    # 备份配置
    local backup_file=$(backup_config)

    # 更新配置
    local tmp_file=$(mktemp)

    if [[ -n "$model" ]]; then
        # 检查模型是否存在
        local model_exists=$(jq -r ".ai.vendors.\"$vendor\".models.\"$model\" // null" "$config_file")
        if [[ "$model_exists" == "null" ]]; then
            log_error "模型 '$model' 在供应商 '$vendor' 中不存在"
            log_info "可用的模型:"
            jq -r ".ai.vendors.\"$vendor\".models // {} | keys[]" "$config_file" | sed 's/^/  - /'
            exit 1
        fi

        # 切换到指定供应商和模型
        jq ".ai.activeVendor = \"$vendor\" | .ai.vendors.\"$vendor\".defaultModel = \"$model\" | .ai.vendors.\"$vendor\".enabled = true" "$config_file" > "$tmp_file"
        log_success "已切换到供应商 '$vendor' 的模型 '$model'"
    else
        # 只切换供应商，使用其默认模型
        jq ".ai.activeVendor = \"$vendor\" | .ai.vendors.\"$vendor\".enabled = true" "$config_file" > "$tmp_file"
        local default_model=$(jq -r ".ai.vendors.\"$vendor\".defaultModel // \"\"" "$config_file")
        log_success "已切换到供应商 '$vendor'"
        if [[ -n "$default_model" ]]; then
            log_info "使用默认模型: $default_model"
        fi
    fi

    mv "$tmp_file" "$config_file"

    log_info "如需回滚，请执行:"
    echo "  cp $backup_file $config_file"
}

# 添加新供应商
add_vendor() {
    local config_file="$OPENCLAW_DIR/openclaw.json"

    echo ""
    log_info "添加新供应商"
    echo ""

    # 输入供应商信息
    read -p "供应商 ID (例如: anthropic, openai, deepseek): " vendor_id
    if [[ -z "$vendor_id" ]]; then
        log_error "供应商 ID 不能为空"
        exit 1
    fi

    # 检查是否已存在
    local vendor_exists=$(jq -r ".ai.vendors.\"$vendor_id\" // null" "$config_file")
    if [[ "$vendor_exists" != "null" ]]; then
        log_error "供应商 '$vendor_id' 已存在"
        exit 1
    fi

    read -p "供应商名称 (例如: Anthropic, OpenAI): " vendor_name
    read -p "API 端点 (例如: https://api.anthropic.com): " api_endpoint
    read -p "API Key 环境变量名 (例如: ANTHROPIC_API_KEY): " api_key_env
    read -p "默认模型 ID (例如: claude-3-5-sonnet-20241022): " default_model

    # 备份配置
    local backup_file=$(backup_config)

    # 添加供应商
    local tmp_file=$(mktemp)
    jq ".ai.vendors.\"$vendor_id\" = {
        \"name\": \"$vendor_name\",
        \"enabled\": true,
        \"apiEndpoint\": \"$api_endpoint\",
        \"apiKeyEnv\": \"$api_key_env\",
        \"defaultModel\": \"$default_model\",
        \"models\": {
            \"$default_model\": {
                \"name\": \"$default_model\",
                \"contextWindow\": 200000,
                \"maxOutputTokens\": 8192
            }
        }
    }" "$config_file" > "$tmp_file"

    mv "$tmp_file" "$config_file"

    log_success "已添加供应商 '$vendor_id'"
    log_warn "请确保设置环境变量: $api_key_env"

    # 询问是否立即切换
    read -p "是否立即切换到此供应商? (y/N): " switch_now
    if [[ "$switch_now" =~ ^[Yy]$ ]]; then
        switch_vendor "$vendor_id"
    fi
}

# 向供应商添加新模型
add_model() {
    local vendor="$1"
    local config_file="$OPENCLAW_DIR/openclaw.json"

    # 检查供应商是否存在
    local vendor_exists=$(jq -r ".ai.vendors.\"$vendor\" // null" "$config_file")
    if [[ "$vendor_exists" == "null" ]]; then
        log_error "供应商 '$vendor' 不存在"
        exit 1
    fi

    echo ""
    log_info "向供应商 '$vendor' 添加新模型"
    echo ""

    read -p "模型 ID (例如: gpt-4, claude-3-opus-20240229): " model_id
    if [[ -z "$model_id" ]]; then
        log_error "模型 ID 不能为空"
        exit 1
    fi

    # 检查模型是否已存在
    local model_exists=$(jq -r ".ai.vendors.\"$vendor\".models.\"$model_id\" // null" "$config_file")
    if [[ "$model_exists" != "null" ]]; then
        log_error "模型 '$model_id' 已存在于供应商 '$vendor'"
        exit 1
    fi

    read -p "模型显示名称 (默认: $model_id): " model_name
    model_name="${model_name:-$model_id}"

    read -p "上下文窗口大小 (默认: 200000): " context_window
    context_window="${context_window:-200000}"

    read -p "最大输出 tokens (默认: 8192): " max_output
    max_output="${max_output:-8192}"

    # 备份配置
    local backup_file=$(backup_config)

    # 添加模型
    local tmp_file=$(mktemp)
    jq ".ai.vendors.\"$vendor\".models.\"$model_id\" = {
        \"name\": \"$model_name\",
        \"contextWindow\": $context_window,
        \"maxOutputTokens\": $max_output
    }" "$config_file" > "$tmp_file"

    mv "$tmp_file" "$config_file"

    log_success "已向供应商 '$vendor' 添加模型 '$model_id'"

    # 询问是否设为默认并切换
    read -p "是否设为默认模型并立即切换? (y/N): " switch_now
    if [[ "$switch_now" =~ ^[Yy]$ ]]; then
        switch_vendor "$vendor" "$model_id"
    fi
}

# 主函数
main() {
    parse_args "$@"

    log_info "OpenClaw 供应商模型维护脚本"
    echo ""

    check_dependencies
    detect_openclaw_dir
    check_openclaw_dir

    echo ""

    if [[ "$LIST_ONLY" == true ]]; then
        list_current_config
        exit 0
    fi

    if [[ "$ADD_VENDOR" == true ]]; then
        add_vendor
        exit 0
    fi

    if [[ "$ADD_MODEL" == true ]]; then
        if [[ -z "$VENDOR" ]]; then
            log_error "--add-model 需要配合 --vendor 使用"
            exit 1
        fi
        add_model "$VENDOR"
        exit 0
    fi

    if [[ -n "$VENDOR" ]]; then
        switch_vendor "$VENDOR" "$MODEL"
        exit 0
    fi

    # 默认显示交互式菜单
    while true; do
        echo ""
        echo "请选择操作:"
        echo "  1) 列出当前配置"
        echo "  2) 切换供应商"
        echo "  3) 添加新供应商"
        echo "  4) 向供应商添加新模型"
        echo "  0) 退出"
        echo ""
        read -p "请输入选项 [0-4]: " choice

        case $choice in
            1)
                list_current_config
                ;;
            2)
                list_current_config
                echo ""
                read -p "请输入供应商 ID: " vendor_input
                if [[ -n "$vendor_input" ]]; then
                    read -p "请输入模型 ID (留空使用默认): " model_input
                    switch_vendor "$vendor_input" "$model_input"
                fi
                ;;
            3)
                add_vendor
                ;;
            4)
                list_current_config
                echo ""
                read -p "请输入供应商 ID: " vendor_input
                if [[ -n "$vendor_input" ]]; then
                    add_model "$vendor_input"
                fi
                ;;
            0)
                log_info "退出"
                exit 0
                ;;
            *)
                log_error "无效选项"
                ;;
        esac
    done
}

main "$@"
