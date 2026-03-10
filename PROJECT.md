# OpenClaw Provider Manager 项目说明

## 项目定位

本项目用于管理 OpenClaw 的 provider 与 model 配置，支持：

- 命令行维护 provider / model
- Telegram 卡片式管理
- 自动备份配置
- 同时兼容旧版 `ai.vendors` 与官方 `models.providers` schema

## 核心能力

### 1. 供应商管理
- ✅ 添加新供应商
- ✅ 修改供应商配置
- ✅ 删除供应商
- ✅ 查询供应商详情
- ✅ 切换当前供应商

### 2. 模型管理
- ✅ 为供应商添加模型
- ✅ 删除模型
- ✅ 设置当前主模型
- ✅ 配置模型参数（上下文窗口、最大输出）

### 3. 交互方式
- ✅ Shell 脚本
- ✅ Node.js API
- ✅ Telegram 卡片

## 当前推荐配置结构

OpenClaw 官方主配置文件：`~/.openclaw/openclaw.json`

关键字段：

- `models.providers`：provider 定义
- `models.providers.<provider>.models[]`：模型数组
- `agents.defaults.model.primary`：当前主模型，格式 `provider/model`
- `agents.defaults.models`：可选模型注册表

示例：

```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "anthropic/claude-sonnet-4-5"
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
          }
        ]
      }
    }
  }
}
```

## 核心类

### `ProviderManager`

```javascript
class ProviderManager {
  listProviders()
  getProvider(vendorId)
  addProvider(vendorData)
  updateProvider(vendorId, updates)
  deleteProvider(vendorId)
  switchProvider(vendorId, modelId)
  addModel(vendorId, modelData)
  deleteModel(vendorId, modelId)
  loadConfig()
  saveConfig()
  backupConfig()
  restartOpenClaw()
}
```

### `TelegramCardManager`

```javascript
class TelegramCardManager {
  showMainCard(msg)
  showProviderList(chatId)
  showProviderDetail(chatId, vendorId)
  showSwitchMenu(chatId)
  startAddProvider(chatId)
  startAddModel(chatId, vendorId)
  switchProvider(chatId, vendorId)
  confirmDeleteModel(...)
  confirmDeleteProvider(...)
  deleteModel(...)
  deleteProvider(...)
  restartOpenClaw(chatId)
}
```

## 运行方式

### 命令行

```bash
./openclaw-vendor-manager-universal.sh --list
./openclaw-vendor-manager-universal.sh --vendor anthropic --model claude-sonnet-4-5
./openclaw-vendor-manager-universal.sh --add-vendor
./openclaw-vendor-manager-universal.sh --add-model --vendor openai
```

### Node API

```javascript
const ProviderManager = require('./index.js');
const manager = new ProviderManager();

manager.addProvider({
  id: 'anthropic',
  apiEndpoint: 'https://api.anthropic.com',
  apiKeyEnv: 'ANTHROPIC_API_KEY',
  defaultModel: 'claude-sonnet-4-5'
});

manager.switchProvider('anthropic', 'claude-sonnet-4-5');
```

### Telegram

```bash
export TELEGRAM_BOT_TOKEN="your_token"
npm run telegram
```

## 测试

```bash
npm test
```

当前测试覆盖：
- ✅ legacy schema (`ai.vendors`)
- ✅ official schema (`models.providers`)
- ✅ 列出供应商
- ✅ 获取供应商详情
- ✅ 添加供应商
- ✅ 添加模型
- ✅ 切换供应商 / 模型
- ✅ 删除模型
- ✅ 删除供应商
- ✅ 配置备份

## 说明

- 对官方 schema，当前主模型由 `agents.defaults.model.primary` 决定
- 对旧版 schema，仍兼容 `ai.activeVendor` / `defaultModel`
- 本项目不会主动覆盖整份配置，只会定点修改 provider / model 相关字段
