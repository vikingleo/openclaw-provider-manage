# OpenClaw Provider Manager

OpenClaw 供应商模型一键配置管理扩展，支持命令行和 Telegram 卡片式操作。

## 功能特性

- ✅ 供应商管理：增加、修改、删除、查询
- ✅ 模型管理：为供应商添加/删除模型
- ✅ 一键切换：快速切换供应商和模型
- ✅ Telegram 卡片：通过 Telegram Bot 进行可视化管理
- ✅ 配置备份：自动备份配置文件
- ✅ 离线操作：即使 OpenClaw 无法连接也能配置
- ✅ 自动检测：自动检测 OpenClaw 安装目录

## 安装

```bash
cd openclaw-provider-manage
npm install
```

## 使用方式

### 1. 命令行脚本（原有功能保留）

```bash
# 列出所有供应商
./openclaw-vendor-manager.sh --list

# 切换供应商
./openclaw-vendor-manager.sh --vendor anthropic

# 切换到指定供应商的指定模型
./openclaw-vendor-manager.sh --vendor openai --model gpt-4

# 添加新供应商
./openclaw-vendor-manager.sh --add-vendor

# 向供应商添加模型
./openclaw-vendor-manager.sh --add-model --vendor openai

# 指定 OpenClaw 目录
./openclaw-vendor-manager.sh --openclaw-dir /srv/openclaw --list
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
  defaultModel: 'claude-3-5-sonnet-20241022'
});

// 切换供应商
manager.switchProvider('anthropic', 'claude-3-5-sonnet-20241022');

// 添加模型
manager.addModel('anthropic', {
  id: 'claude-3-opus-20240229',
  name: 'Claude 3 Opus',
  contextWindow: 200000,
  maxOutputTokens: 4096
});

// 删除模型
manager.deleteModel('anthropic', 'claude-3-opus-20240229');

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

#### Telegram 卡片功能

- **供应商列表**：查看所有已配置的供应商，显示状态和模型数量
- **供应商详情**：查看供应商的完整信息，包括所有模型
- **快速切换**：一键切换到任意供应商
- **添加供应商**：通过对话式流程添加新供应商
- **添加模型**：为现有供应商添加新模型
- **删除操作**：删除供应商或模型（带确认）
- **重启服务**：配置修改后一键重启 OpenClaw

## 目录结构

```
openclaw-provider-manage/
├── extension.json              # 扩展配置文件
├── package.json                # Node.js 依赖配置
├── index.js                    # 核心管理模块
├── telegram-card.js            # Telegram 卡片管理器
├── openclaw-vendor-manager.sh  # 原有命令行脚本（保留）
└── README.md                   # 说明文档
```

## 配置文件格式

OpenClaw 配置文件 (`openclaw.json`) 示例：

```json
{
  "ai": {
    "activeVendor": "anthropic",
    "vendors": {
      "anthropic": {
        "name": "Anthropic",
        "enabled": true,
        "apiEndpoint": "https://api.anthropic.com",
        "apiKeyEnv": "ANTHROPIC_API_KEY",
        "defaultModel": "claude-3-5-sonnet-20241022",
        "models": {
          "claude-3-5-sonnet-20241022": {
            "name": "Claude 3.5 Sonnet",
            "contextWindow": 200000,
            "maxOutputTokens": 8192
          }
        }
      },
      "openai": {
        "name": "OpenAI",
        "enabled": false,
        "apiEndpoint": "https://api.openai.com/v1",
        "apiKeyEnv": "OPENAI_API_KEY",
        "defaultModel": "gpt-4",
        "models": {
          "gpt-4": {
            "name": "GPT-4",
            "contextWindow": 128000,
            "maxOutputTokens": 4096
          }
        }
      }
    }
  }
}
```

## 配置备份

所有配置修改都会自动备份到：

```
~/.openclaw/.openclaw/backups/provider-manager/
```

备份文件命名格式：`openclaw.json.YYYY-MM-DDTHH-MM-SS`

## 环境变量

- `TELEGRAM_BOT_TOKEN` - Telegram Bot Token（使用 Telegram 功能时必需）
- 各供应商的 API Key 环境变量（如 `ANTHROPIC_API_KEY`、`OPENAI_API_KEY`）

## 注意事项

1. **离线操作**：本扩展可以在 OpenClaw 无法连接时使用，修改配置后重启即可
2. **配置备份**：每次修改都会自动备份，可以随时回滚
3. **模型切换**：本扩展只负责供应商管理，不做模型切换（使用 `/models` 命令）
4. **重启建议**：修改配置后建议重启 OpenClaw 使配置生效

## 常见问题

### 无法检测到 OpenClaw 目录

使用 `--openclaw-dir` 参数手动指定：

```bash
./openclaw-vendor-manager.sh --openclaw-dir /path/to/openclaw --list
```

### Telegram Bot 无响应

1. 检查 `TELEGRAM_BOT_TOKEN` 是否正确设置
2. 确保网络可以访问 Telegram API
3. 查看控制台错误日志

### 配置修改后不生效

尝试重启 OpenClaw：

```bash
# 通过 Telegram 卡片
点击 "🔃 重启 OpenClaw" 按钮

# 或手动重启
pkill -USR2 openclaw
```

## 开发

### 测试

```bash
# 测试核心功能
node index.js list

# 测试添加供应商
node index.js add '{"id":"test","name":"Test","apiEndpoint":"https://api.test.com","apiKeyEnv":"TEST_API_KEY","defaultModel":"test-model"}'

# 测试切换
node index.js switch test test-model
```

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！
