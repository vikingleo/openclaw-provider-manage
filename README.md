# OpenClaw Provider Manager

OpenClaw 供应商模型一键配置管理扩展，支持命令行和 Telegram 卡片式操作。

**🚀 一键部署，无需手动 `npm install`！**

## 功能特性

- ✅ 供应商管理：增加、修改、删除、查询
- ✅ 模型管理：为供应商添加/删除模型
- ✅ 一键切换：快速切换供应商和模型
- ✅ Telegram 卡片：通过 Telegram Bot 进行可视化管理
- ✅ 配置备份：自动备份配置文件
- ✅ 离线操作：即使 OpenClaw 无法连接也能配置
- ✅ 自动检测：自动检测 OpenClaw 安装目录
- ✅ 双 schema 兼容：同时支持旧版 `ai.vendors` 与官方 `models.providers`

## 安装

### 方式一：一键部署（推荐）

```bash
cd openclaw-provider-manage
./deploy.sh
```

一键部署脚本会自动：
- ✅ 检查系统环境
- ✅ 安装所有依赖
- ✅ 设置脚本权限
- ✅ 运行测试验证
- ✅ 创建配置文件

### 方式二：手动安装

```bash
cd openclaw-provider-manage
npm install
```

## 使用方式

### 1. 命令行脚本

推荐使用通用脚本：

```bash
# 进入交互式菜单
./openclaw-vendor-manager-universal.sh

# 列出所有供应商
./openclaw-vendor-manager-universal.sh --list

# 切换到指定供应商
./openclaw-vendor-manager-universal.sh --vendor anthropic

# 切换到指定供应商的指定模型
./openclaw-vendor-manager-universal.sh --vendor openai --model gpt-4.1

# 添加新供应商
./openclaw-vendor-manager-universal.sh --add-vendor

# 向供应商添加模型
./openclaw-vendor-manager-universal.sh --add-model --vendor openai

# 指定 OpenClaw 目录
./openclaw-vendor-manager-universal.sh --openclaw-dir /srv/openclaw --list
```

不带参数运行时会进入交互式菜单：

```text
请选择操作:
  1) 列出当前配置
  2) 切换供应商
  3) 添加新供应商
  4) 向供应商添加新模型
  0) 退出
```

### 2. Node.js API

```javascript
const ProviderManager = require('./index.js');

const manager = new ProviderManager();

// 列出所有供应商
const providers = manager.listProviders();

// 添加供应商
manager.addProvider({
  id: 'anthropic',
  name: 'Anthropic',
  apiEndpoint: 'https://api.anthropic.com',
  apiKeyEnv: 'ANTHROPIC_API_KEY',
  defaultModel: 'claude-sonnet-4-5'
});

// 切换供应商 / 模型
manager.switchProvider('anthropic', 'claude-sonnet-4-5');

// 添加模型
manager.addModel('anthropic', {
  id: 'claude-opus-4-1',
  name: 'Claude Opus 4.1',
  contextWindow: 200000,
  maxOutputTokens: 8192
});

// 删除模型
manager.deleteModel('anthropic', 'claude-opus-4-1');

// 删除供应商
manager.deleteProvider('anthropic');
```

### 3. Telegram 卡片管理

#### 配置 Telegram Bot

1. 在 Telegram 中找到 [@BotFather](https://t.me/botfather)
2. 发送 `/newbot` 创建新 Bot
3. 获取 Bot Token
4. 设置环境变量：

```bash
export TELEGRAM_BOT_TOKEN="your_bot_token_here"
```

#### 启动 Telegram Bot

```bash
npm run telegram
```

#### 使用 Telegram 命令

在 Telegram 中向你的 Bot 发送：

- `/openclaw` 或 `/start` - 打开主管理卡片
- 通过卡片按钮进行操作：
  - 📋 查看所有供应商
  - ➕ 添加供应商
  - 🔄 切换供应商
  - ⚙️ 管理模型
  - 🔃 重启 OpenClaw

## 配置文件格式

OpenClaw 官方主配置文件通常位于 `~/.openclaw/openclaw.json`。

当前官方 schema 的关键字段：

- `models.providers`：自定义 provider 定义
- `agents.defaults.model.primary`：当前主模型，格式为 `provider/model`
- `agents.defaults.models`：可选的模型注册表 / alias 映射

示例：

```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "anthropic/claude-sonnet-4-5"
      },
      "models": {
        "anthropic/claude-sonnet-4-5": {
          "alias": "claude-sonnet"
        }
      }
    }
  },
  "models": {
    "mode": "merge",
    "providers": {
      "anthropic": {
        "baseUrl": "https://api.anthropic.com",
        "apiKey": "${ANTHROPIC_API_KEY}",
        "api": "openai-completions",
        "models": [
          {
            "id": "claude-sonnet-4-5",
            "name": "Claude Sonnet 4.5",
            "contextWindow": 200000,
            "maxOutputTokens": 8192
          },
          {
            "id": "claude-opus-4-1",
            "name": "Claude Opus 4.1",
            "contextWindow": 200000,
            "maxOutputTokens": 8192
          }
        ]
      },
      "openai": {
        "baseUrl": "https://api.openai.com/v1",
        "apiKey": "${OPENAI_API_KEY}",
        "api": "openai-completions",
        "models": [
          {
            "id": "gpt-4.1",
            "name": "GPT-4.1",
            "contextWindow": 128000,
            "maxOutputTokens": 16384
          }
        ]
      }
    }
  }
}
```

## 配置备份

所有配置修改都会自动备份到：

```bash
<OpenClaw目录>/.openclaw/backups/provider-manager/
```

## 环境变量

- `TELEGRAM_BOT_TOKEN` - Telegram Bot Token（使用 Telegram 功能时必需）
- 各供应商的 API Key 环境变量（如 `ANTHROPIC_API_KEY`、`OPENAI_API_KEY`）

## 注意事项

1. **离线操作**：本扩展可以在 OpenClaw 无法连接时使用，修改配置后重启即可
2. **配置备份**：每次修改都会自动备份，可以随时回滚
3. **模型切换**：在官方 schema 下，脚本会维护 `agents.defaults.model.primary`
4. **重启建议**：修改配置后建议重启 OpenClaw 使配置生效

## 常见问题

### 无法检测到 OpenClaw 目录

使用 `--openclaw-dir` 参数手动指定：

```bash
./openclaw-vendor-manager-universal.sh --openclaw-dir /path/to/openclaw --list
```

### 如何检查真实配置文件

```bash
./check-config.sh
```

这个脚本会同时检查：
- `openclaw.json`
- `auth-profiles.json`
- `auth.json`
- `models.json`
- `oauth.json`

### 配置修改后不生效

尝试重启 OpenClaw：

```bash
pkill -USR2 openclaw
```

## 测试

```bash
npm test
```

测试会覆盖：
- 旧版 `ai.vendors` schema
- 官方 `models.providers` schema
- 列出 / 切换 / 添加模型 / 删除模型 / 删除供应商 / 配置备份
