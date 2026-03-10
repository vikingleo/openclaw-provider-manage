# OpenClaw 通用版本脚本说明

## 🎯 问题解决

### 原问题
- 原脚本假设配置路径为 `.ai.vendors`
- 实际 OpenClaw 可能使用不同的配置结构
- 用户报告"未找到任何供应商配置"

### 解决方案
创建了 **通用版本脚本** (`openclaw-vendor-manager-universal.sh`)，支持：
- ✅ 自动检测配置结构
- ✅ 支持多种配置路径
- ✅ 不覆盖现有配置
- ✅ 只添加/修改供应商配置

## 📋 支持的配置结构

脚本会自动检测以下配置路径：

1. **`.ai.vendors`** - AI 供应商配置（推荐）
2. **`.providers`** - 顶层供应商配置
3. **`.vendors`** - 顶层供应商配置（简化版）
4. **`.llm.providers`** - LLM 供应商配置
5. **`.models`** - 模型配置
6. **自定义路径** - 用户指定的任意路径

## 🚀 使用方式

### 自动检测模式（推荐）

```bash
# 运行脚本，自动检测配置结构
./openclaw-vendor-manager-universal.sh

# 脚本会：
# 1. 检测 OpenClaw 目录
# 2. 检测配置文件结构
# 3. 自动适配配置路径
# 4. 显示交互式菜单
```

### 命令行模式

```bash
# 列出供应商（自动检测配置路径）
./openclaw-vendor-manager-universal.sh --list

# 添加供应商
./openclaw-vendor-manager-universal.sh --add-vendor

# 切换供应商
./openclaw-vendor-manager-universal.sh --vendor anthropic

# 添加模型
./openclaw-vendor-manager-universal.sh --add-model --vendor openai
```

## 🔍 配置检测流程

```
启动脚本
    ↓
检测 OpenClaw 目录
    ↓
读取 openclaw.json
    ↓
尝试检测配置路径:
  - .ai.vendors
  - .providers
  - .vendors
  - .llm.providers
  - .models
    ↓
找到配置路径 ──→ 使用该路径
    ↓ 未找到
询问用户选择路径
    ↓
初始化配置路径
    ↓
开始操作
```

## 📝 配置路径选择

如果脚本无法自动检测配置路径，会提示：

```
[WARN] 未检测到标准的供应商配置路径

请选择要使用的配置路径:
  1) .ai.vendors (推荐)
  2) .providers
  3) .vendors
  4) 自定义路径

请选择 [1-4]:
```

### 推荐选择

- **新安装**: 选择 1 (`.ai.vendors`)
- **已有配置**: 根据现有结构选择
- **不确定**: 运行 `./check-config.sh` 查看实际结构

## 🛡️ 安全特性

### 1. 不覆盖现有配置

脚本只添加/修改供应商配置，保留其他所有配置项：

```bash
# 原配置
{
  "server": {"port": 8080},
  "telegram": {"token": "xxx"}
}

# 添加供应商后
{
  "server": {"port": 8080},
  "telegram": {"token": "xxx"},
  "ai": {
    "vendors": {
      "anthropic": {...}
    }
  }
}
```

### 2. 自动备份

每次修改前自动备份：

```
[SUCCESS] 配置已备份到: /root/.openclaw/.openclaw/backups/vendor-manager/openclaw.json.20260310_143025
```

### 3. 回滚支持

修改后显示回滚命令：

```
如需回滚，请执行:
  cp /path/to/backup /path/to/openclaw.json
```

## 🔄 与原脚本的区别

| 特性 | 原脚本 | 通用版本 |
|------|--------|----------|
| 配置路径 | 固定 `.ai.vendors` | 自动检测多种路径 |
| 路径选择 | 不支持 | 支持用户选择 |
| 配置初始化 | 覆盖整个文件 | 只添加缺失的路径 |
| 现有配置 | 可能覆盖 | 完全保留 |
| 错误提示 | 简单 | 详细引导 |

## 📊 使用示例

### 示例 1: 首次使用

```bash
$ ./openclaw-vendor-manager-universal.sh

[INFO] OpenClaw 供应商模型维护脚本 (通用版本)

[INFO] 自动检测 OpenClaw 目录...
[SUCCESS] 检测到 OpenClaw 目录: /root/.openclaw
[SUCCESS] 找到 OpenClaw 配置: /root/.openclaw/openclaw.json

[INFO] 检测配置文件结构...
[WARN] 未检测到标准的供应商配置路径

请选择要使用的配置路径:
  1) .ai.vendors (推荐)
  2) .providers
  3) .vendors
  4) 自定义路径

请选择 [1-4]: 1

[INFO] 初始化配置路径: .ai.vendors
[INFO] 已备份配置到: /root/.openclaw/openclaw.json.backup.20260310_143025
[SUCCESS] 配置路径已初始化

请选择操作:
  1) 列出当前配置
  2) 切换供应商
  3) 添加新供应商
  4) 向供应商添加新模型
  0) 退出

请输入选项 [0-4]:
```

### 示例 2: 已有配置

```bash
$ ./openclaw-vendor-manager-universal.sh --list

[INFO] OpenClaw 供应商模型维护脚本 (通用版本)

[INFO] 自动检测 OpenClaw 目录...
[SUCCESS] 检测到 OpenClaw 目录: /root/.openclaw
[SUCCESS] 找到 OpenClaw 配置: /root/.openclaw/openclaw.json

[INFO] 检测配置文件结构...
[SUCCESS] 检测到配置路径: .providers

[INFO] 当前 OpenClaw 配置:

[INFO] 配置路径: .providers

已配置的供应商:
  ✓ anthropic (已启用)
    默认模型: claude-3-5-sonnet-20241022
    可用模型:
      - claude-3-5-sonnet-20241022
      - claude-3-opus-20240229

  ○ openai (已禁用)
    默认模型: gpt-4
    可用模型:
      - gpt-4
      - gpt-4-turbo

当前活跃供应商: anthropic
```

## 🔧 技术实现

### 动态路径检测

```bash
# 尝试多种可能的路径
local paths=(
    ".ai.vendors"
    ".providers"
    ".vendors"
    ".llm.providers"
    ".models"
)

for path in "${paths[@]}"; do
    if jq -e "$path" "$config_file" >/dev/null 2>&1; then
        CONFIG_PATH="$path"
        return 0
    fi
done
```

### 动态路径操作

```bash
# 读取供应商列表
jq -r "$CONFIG_PATH // {} | keys[]" "$config_file"

# 添加供应商
jq "$CONFIG_PATH.\"$vendor_id\" = {...}" "$config_file"

# 切换供应商
local active_path="${CONFIG_PATH%.*}.activeVendor"
jq "$active_path = \"$vendor\"" "$config_file"
```

## 📚 相关文档

- [配置结构检查工具](./CONFIG_STRUCTURE.md)
- [配置初始化说明](./CONFIG_INIT.md)
- [完整使用文档](./README.md)

## 🎉 总结

通用版本脚本解决了配置结构不统一的问题：

- ✅ 自动检测配置路径
- ✅ 支持多种配置结构
- ✅ 不覆盖现有配置
- ✅ 完全向后兼容
- ✅ 友好的用户体验

现在无论 OpenClaw 使用什么配置结构，脚本都能正常工作！

---

**Sources:**
- [Full guide to OpenClaw CLI and config file reference](https://lumadock.com/tutorials/openclaw-cli-config-reference)
- [OpenClaw Configuration](https://openclaw-openclaw.mintlify.app/configuration)
- [OpenClaw LLM Setup Guide](https://blog.laozhang.ai/en/posts/openclaw-llm-setup)
- [Every Setting Explained — EZClaws](https://www.ezclaws.com/posts/openclaw-configuration-deep-dive)
