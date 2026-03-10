#!/bin/bash

# OpenClaw 供应商模型一键维护脚本 - 通用版本
# 支持多种配置结构，自动检测并适配
#
# 使用方式:
#   ./openclaw-vendor-manager-universal.sh
#   ./openclaw-vendor-manager-universal.sh --vendor anthropic --model claude-3-5-sonnet-20241022
#   ./openclaw-vendor-manager-universal.sh --add-vendor
#   ./openclaw-vendor-manager-universal.sh --add-model --vendor openai
#   ./openclaw-vendor-manager-universal.sh --openclaw-dir /srv/openclaw
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
CONFIG_PATH=""  # 实际的配置路径（如 .ai.vendors 或 .providers）
CONFIG_PATH_ARRAY="[]"

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

set_config_path_metadata() {
    CONFIG_PATH_ARRAY=$(jq -Rn --arg p "$CONFIG_PATH" '$p | ltrimstr(".") | split(".")')
}

# 显示帮助
show_help() {
    cat <<EOF
OpenClaw 供应商模型一键维护脚本 (通用版本)

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

    log_error "无法自动检测 OpenClaw 目录"
    log_info "请使用 --openclaw-dir 参数手动指定"
    log_info "常见位置: ~/.openclaw, /srv/openclaw, /opt/openclaw"
    exit 1
}

# 检测配置结构
detect_config_structure() {
    local config_file="$OPENCLAW_DIR/openclaw.json"

    log_info "检测配置文件结构..."

    # 尝试多种可能的路径
    local paths=(
        ".models.providers"
        ".ai.vendors"
        ".providers"
        ".vendors"
        ".llm.providers"
    )

    for path in "${paths[@]}"; do
        if jq -e "$path" "$config_file" >/dev/null 2>&1; then
            CONFIG_PATH="$path"
            set_config_path_metadata
            log_success "检测到配置路径: $CONFIG_PATH"
            return 0
        fi
    done

    # 如果都不存在，询问用户要使用哪个路径
    log_warn "未检测到标准的供应商配置路径"
    echo ""
    echo "请选择要使用的配置路径:"
    echo "  1) .models.providers (OpenClaw 标准)"
    echo "  2) .ai.vendors"
    echo "  3) .providers"
    echo "  4) .vendors"
    echo "  5) 自定义路径"
    echo ""
    read -p "请选择 [1-5]: " choice

    case $choice in
        1)
            CONFIG_PATH=".models.providers"
            ;;
        2)
            CONFIG_PATH=".ai.vendors"
            ;;
        3)
            CONFIG_PATH=".providers"
            ;;
        4)
            CONFIG_PATH=".vendors"
            ;;
        5)
            read -p "请输入自定义路径 (如 .llm.providers): " custom_path
            CONFIG_PATH="$custom_path"
            ;;
        *)
            log_error "无效选择"
            exit 1
            ;;
    esac

    # 初始化配置路径
    init_config_path
    set_config_path_metadata
}

# 初始化配置路径
init_config_path() {
    local config_file="$OPENCLAW_DIR/openclaw.json"

    log_info "初始化配置路径: $CONFIG_PATH"

    # 备份
    local backup_file="${config_file}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$config_file" "$backup_file"
    log_info "已备份配置到: $backup_file"

    # 根据路径创建结构
    local tmp_file=$(mktemp)

    if [[ "$CONFIG_PATH" == ".models.providers" ]]; then
        jq '.models.mode = (.models.mode // "merge") | .models.providers = (.models.providers // {})' "$config_file" > "$tmp_file"
    elif [[ "$CONFIG_PATH" == ".ai.vendors" ]]; then
        jq '.ai.vendors = (.ai.vendors // {})' "$config_file" > "$tmp_file"
    elif [[ "$CONFIG_PATH" == ".providers" ]]; then
        jq '.providers = (.providers // {})' "$config_file" > "$tmp_file"
    elif [[ "$CONFIG_PATH" == ".vendors" ]]; then
        jq '.vendors = (.vendors // {})' "$config_file" > "$tmp_file"
    else
        # 自定义路径，使用 setpath
        local path_array=$(echo "$CONFIG_PATH" | sed 's/^\.//; s/\./","/g' | sed 's/^/["/; s/$/"]/')
        jq "setpath($path_array; getpath($path_array) // {})" "$config_file" > "$tmp_file"
    fi

    mv "$tmp_file" "$config_file"
    log_success "配置路径已初始化"
}

list_vendor_models() {
    local config_file="$1"
    local vendor="$2"

    jq -r \
        --argjson path "$CONFIG_PATH_ARRAY" \
        --arg vendor "$vendor" '
        (getpath($path + [$vendor, "models"]) // {}) as $models |
        if ($models | type) == "array" then
            $models[]? | (.id // .name // empty)
        elif ($models | type) == "object" then
            $models | keys[]
        else
            empty
        end
    ' "$config_file" 2>/dev/null || true
}

provider_has_model() {
    local config_file="$1"
    local vendor="$2"
    local model="$3"

    jq -e \
        --argjson path "$CONFIG_PATH_ARRAY" \
        --arg vendor "$vendor" \
        --arg model "$model" '
        (getpath($path + [$vendor, "models"]) // {}) as $models |
        if ($models | type) == "array" then
            any($models[]?; (.id // .name // empty) == $model)
        elif ($models | type) == "object" then
            $models | has($model)
        else
            false
        end
    ' "$config_file" >/dev/null 2>&1
}

get_primary_model_ref() {
    local config_file="$1"

    jq -r '
        if (.agents.defaults.model | type) == "object" then
            .agents.defaults.model.primary // ""
        elif (.agents.defaults.model | type) == "string" then
            .agents.defaults.model
        else
            ""
        end
    ' "$config_file" 2>/dev/null || echo ""
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

# 备份配置文件
backup_config() {
    local config_file="$OPENCLAW_DIR/openclaw.json"
    local backup_dir="$OPENCLAW_DIR/.openclaw/backups/vendor-manager"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$backup_dir/openclaw.json.$timestamp"

    mkdir -p "$backup_dir"
    cp "$config_file" "$backup_file"

    log_success "配置已备份到: $backup_file" >&2
    echo "$backup_file"
}

# 列出当前配置
list_current_config() {
    local config_file="$OPENCLAW_DIR/openclaw.json"
    local primary_model_ref=""
    local active_vendor=""
    local active_model=""

    log_info "当前 OpenClaw 配置:"
    echo ""
    log_info "配置路径: $CONFIG_PATH"
    echo ""

    if [[ "$CONFIG_PATH" == ".models.providers" ]]; then
        primary_model_ref=$(get_primary_model_ref "$config_file")
        if [[ "$primary_model_ref" == */* ]]; then
            active_vendor="${primary_model_ref%%/*}"
            active_model="${primary_model_ref#*/}"
        fi
    fi

    # 读取供应商配置
    local vendors=$(jq -r "$CONFIG_PATH // {} | keys[]" "$config_file" 2>/dev/null || echo "")

    if [[ -z "$vendors" ]]; then
        log_warn "未找到任何供应商配置"
        echo ""
        log_info "提示: 选择选项 3 添加新供应商"
        return
    fi

    echo -e "${BLUE}已配置的供应商:${NC}"
    for vendor in $vendors; do
        local models
        models=$(list_vendor_models "$config_file" "$vendor")

        if [[ "$CONFIG_PATH" == ".models.providers" ]]; then
            if [[ "$vendor" == "$active_vendor" && -n "$active_model" ]]; then
                echo -e "  ${GREEN}✓${NC} $vendor (当前默认供应商)"
                echo -e "    当前主模型: ${BLUE}$active_model${NC}"
            else
                echo -e "  ${YELLOW}○${NC} $vendor"
            fi

            local base_url=$(jq -r --arg vendor "$vendor" --argjson path "$CONFIG_PATH_ARRAY" 'getpath($path + [$vendor, "baseUrl"]) // ""' "$config_file" 2>/dev/null || echo "")
            local api_mode=$(jq -r --arg vendor "$vendor" --argjson path "$CONFIG_PATH_ARRAY" 'getpath($path + [$vendor, "api"]) // ""' "$config_file" 2>/dev/null || echo "")

            if [[ -n "$base_url" && "$base_url" != "null" ]]; then
                echo "    Base URL: $base_url"
            fi
            if [[ -n "$api_mode" && "$api_mode" != "null" ]]; then
                echo "    API 协议: $api_mode"
            fi
        else
            local enabled=$(jq -r "$CONFIG_PATH.\"$vendor\".enabled // false" "$config_file")
            local default_model=$(jq -r "$CONFIG_PATH.\"$vendor\".defaultModel // \"\"" "$config_file")

            if [[ "$enabled" == "true" ]]; then
                echo -e "  ${GREEN}✓${NC} $vendor (已启用)"
            else
                echo -e "  ${YELLOW}○${NC} $vendor (已禁用)"
            fi

            if [[ -n "$default_model" ]]; then
                echo -e "    默认模型: ${BLUE}$default_model${NC}"
            fi
        fi

        if [[ -n "$models" ]]; then
            echo "    可用模型:"
            for model in $models; do
                echo "      - $model"
            done
        fi
        echo ""
    done

    # 显示当前活跃供应商（如果有）
    if [[ "$CONFIG_PATH" == ".models.providers" ]]; then
        if [[ -n "$primary_model_ref" ]]; then
            echo -e "${GREEN}当前主模型:${NC} $primary_model_ref"
        fi
    else
        local active_path="${CONFIG_PATH%.*}.activeVendor"
        local active_vendor=$(jq -r "$active_path // \"\"" "$config_file" 2>/dev/null || echo "")
        if [[ -n "$active_vendor" && "$active_vendor" != "null" ]]; then
            echo -e "${GREEN}当前活跃供应商:${NC} $active_vendor"
        fi
    fi
}

# 切换供应商
switch_vendor() {
    local vendor="$1"
    local model="${2:-}"
    local config_file="$OPENCLAW_DIR/openclaw.json"

    # 检查供应商是否存在
    local vendor_exists=$(jq -r "$CONFIG_PATH.\"$vendor\" // null" "$config_file")
    if [[ "$vendor_exists" == "null" ]]; then
        log_error "供应商 '$vendor' 不存在"
        log_info "可用的供应商:"
        jq -r "$CONFIG_PATH // {} | keys[]" "$config_file" | sed 's/^/  - /'
        exit 1
    fi

    # 备份配置
    local backup_file=$(backup_config)

    # 更新配置
    local tmp_file=$(mktemp)
    local active_path="${CONFIG_PATH%.*}.activeVendor"

    if [[ "$CONFIG_PATH" == ".models.providers" ]]; then
        local target_model="$model"

        if [[ -n "$target_model" ]]; then
            if ! provider_has_model "$config_file" "$vendor" "$target_model"; then
                log_error "模型 '$target_model' 在供应商 '$vendor' 中不存在"
                log_info "可用的模型:"
                list_vendor_models "$config_file" "$vendor" | sed 's/^/  - /'
                exit 1
            fi
        else
            target_model=$(list_vendor_models "$config_file" "$vendor" | head -n 1)
            if [[ -z "$target_model" ]]; then
                log_error "供应商 '$vendor' 没有可用模型，无法切换"
                exit 1
            fi
        fi

        local model_ref="$vendor/$target_model"
        jq \
            --arg model_ref "$model_ref" '
            .agents = (.agents // {}) |
            .agents.defaults = (.agents.defaults // {}) |
            .agents.defaults.model = (
                if (.agents.defaults.model | type) == "object" then
                    (.agents.defaults.model + {primary: $model_ref})
                else
                    {primary: $model_ref}
                end
            ) |
            if (.agents.defaults.models | type) == "object" then
                .agents.defaults.models[$model_ref] = (.agents.defaults.models[$model_ref] // {})
            else
                .
            end
        ' "$config_file" > "$tmp_file"

        mv "$tmp_file" "$config_file"
        log_success "已切换到主模型 '$model_ref'"
    else
        if [[ -n "$model" ]]; then
            # 检查模型是否存在
            if ! provider_has_model "$config_file" "$vendor" "$model"; then
                log_error "模型 '$model' 在供应商 '$vendor' 中不存在"
                log_info "可用的模型:"
                list_vendor_models "$config_file" "$vendor" | sed 's/^/  - /'
                exit 1
            fi

            # 切换到指定供应商和模型
            jq "$active_path = \"$vendor\" | $CONFIG_PATH.\"$vendor\".defaultModel = \"$model\" | $CONFIG_PATH.\"$vendor\".enabled = true" "$config_file" > "$tmp_file"
            mv "$tmp_file" "$config_file"
            log_success "已切换到供应商 '$vendor' 的模型 '$model'"
        else
            # 只切换供应商，使用其默认模型
            jq "$active_path = \"$vendor\" | $CONFIG_PATH.\"$vendor\".enabled = true" "$config_file" > "$tmp_file"
            mv "$tmp_file" "$config_file"
            local default_model=$(jq -r "$CONFIG_PATH.\"$vendor\".defaultModel // \"\"" "$config_file")
            log_success "已切换到供应商 '$vendor'"
            if [[ -n "$default_model" && "$default_model" != "null" ]]; then
                log_info "使用默认模型: $default_model"
            fi
        fi
    fi

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
    local vendor_exists=$(jq -r "$CONFIG_PATH.\"$vendor_id\" // null" "$config_file")
    if [[ "$vendor_exists" != "null" ]]; then
        log_error "供应商 '$vendor_id' 已存在"
        exit 1
    fi

    if [[ "$CONFIG_PATH" == ".models.providers" ]]; then
        read -p "Base URL (例如: https://api.anthropic.com): " api_endpoint
        read -p "API 协议 (默认: openai-completions): " api_mode
        api_mode="${api_mode:-openai-completions}"
        read -p "API Key 环境变量名 (例如: ANTHROPIC_API_KEY): " api_key_env
        read -p "默认模型 ID (例如: claude-sonnet-4-5): " default_model
        read -p "模型显示名称 (默认: $default_model): " model_name
        model_name="${model_name:-$default_model}"
        read -p "上下文窗口大小 (默认: 200000): " context_window
        context_window="${context_window:-200000}"
        read -p "最大输出 tokens (默认: 8192): " max_output
        max_output="${max_output:-8192}"
    else
        read -p "供应商名称 (例如: Anthropic, OpenAI): " vendor_name
        read -p "API 端点 (例如: https://api.anthropic.com): " api_endpoint
        read -p "API Key 环境变量名 (例如: ANTHROPIC_API_KEY): " api_key_env
        read -p "默认模型 ID (例如: claude-3-5-sonnet-20241022): " default_model
    fi

    # 备份配置
    local backup_file=$(backup_config)

    # 添加供应商
    local tmp_file=$(mktemp)
    if [[ "$CONFIG_PATH" == ".models.providers" ]]; then
        local model_ref="$vendor_id/$default_model"
        jq \
            --arg vendor_id "$vendor_id" \
            --arg api_endpoint "$api_endpoint" \
            --arg api_key_env "$api_key_env" \
            --arg api_mode "$api_mode" \
            --arg default_model "$default_model" \
            --arg model_name "$model_name" \
            --argjson context_window "$context_window" \
            --argjson max_output "$max_output" \
            --arg model_ref "$model_ref" '
            .models = (.models // {}) |
            .models.mode = (.models.mode // "merge") |
            .models.providers = (.models.providers // {}) |
            .models.providers[$vendor_id] = {
                baseUrl: $api_endpoint,
                apiKey: (if ($api_key_env | length) > 0 then "${" + $api_key_env + "}" else "" end),
                api: $api_mode,
                models: [
                    {
                        id: $default_model,
                        name: $model_name,
                        contextWindow: $context_window,
                        maxOutputTokens: $max_output
                    }
                ]
            } |
            if (.agents.defaults.models | type) == "object" then
                .agents.defaults.models[$model_ref] = (.agents.defaults.models[$model_ref] // {alias: $model_name})
            else
                .
            end
        ' "$config_file" > "$tmp_file"
    else
        jq "$CONFIG_PATH.\"$vendor_id\" = {
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
    fi

    mv "$tmp_file" "$config_file"

    log_success "已添加供应商 '$vendor_id'"
    if [[ -n "$api_key_env" ]]; then
        log_warn "请确保设置环境变量: $api_key_env"
    fi

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
    local vendor_exists=$(jq -r "$CONFIG_PATH.\"$vendor\" // null" "$config_file")
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
    if provider_has_model "$config_file" "$vendor" "$model_id"; then
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
    if [[ "$CONFIG_PATH" == ".models.providers" ]]; then
        local model_ref="$vendor/$model_id"
        jq \
            --argjson path "$CONFIG_PATH_ARRAY" \
            --arg vendor "$vendor" \
            --arg model_id "$model_id" \
            --arg model_name "$model_name" \
            --argjson context_window "$context_window" \
            --argjson max_output "$max_output" \
            --arg model_ref "$model_ref" '
            setpath(
                $path + [$vendor, "models"];
                ((getpath($path + [$vendor, "models"]) // []) + [
                    {
                        id: $model_id,
                        name: $model_name,
                        contextWindow: $context_window,
                        maxOutputTokens: $max_output
                    }
                ])
            ) |
            if (.agents.defaults.models | type) == "object" then
                .agents.defaults.models[$model_ref] = (.agents.defaults.models[$model_ref] // {alias: $model_name})
            else
                .
            end
        ' "$config_file" > "$tmp_file"
    else
        jq "$CONFIG_PATH.\"$vendor\".models.\"$model_id\" = {
            \"name\": \"$model_name\",
            \"contextWindow\": $context_window,
            \"maxOutputTokens\": $max_output
        }" "$config_file" > "$tmp_file"
    fi

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

    log_info "OpenClaw 供应商模型维护脚本 (通用版本)"
    echo ""

    check_dependencies
    detect_openclaw_dir
    check_openclaw_dir
    detect_config_structure

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
