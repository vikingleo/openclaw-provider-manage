# OpenClaw Provider Manager - 项目总览

## 📦 项目信息

- **名称**: OpenClaw Provider Manager
- **版本**: 1.0.0
- **类型**: OpenClaw 扩展
- **功能**: 供应商模型一键配置管理，支持 Telegram 卡片式操作

## 🎯 核心功能

### 1. 供应商管理
- ✅ 添加新供应商
- ✅ 修改供应商配置
- ✅ 删除供应商
- ✅ 查询供应商详情
- ✅ 切换活跃供应商

### 2. 模型管理
- ✅ 为供应商添加模型
- ✅ 删除模型
- ✅ 设置默认模型
- ✅ 配置模型参数（上下文窗口、最大输出）

### 3. Telegram 卡片式管理
- ✅ 可视化卡片界面
- ✅ 交互式操作流程
- ✅ 实时状态展示
- ✅ 二次确认保护

### 4. 安全特性
- ✅ 自动配置备份
- ✅ 支持配置回滚
- ✅ 离线操作支持
- ✅ 错误处理和提示

## 📁 文件结构

```
openclaw-provider-manage/
├── 📄 核心文件
│   ├── extension.json              # 扩展配置
│   ├── package.json                # Node.js 依赖配置
│   ├── index.js                    # 核心管理模块 (ProviderManager)
│   └── telegram-card.js            # Telegram 卡片管理器
│
├── 🔧 脚本文件
│   ├── openclaw-vendor-manager.sh  # 原有命令行脚本（保留）
│   ├── install.sh                  # 安装脚本
│   ├── start.sh                    # 快速启动脚本
│   ├── demo.sh                     # 演示脚本
│   └── test.js                     # 测试脚本
│
├── 📚 文档文件
│   ├── README.md                   # 完整说明文档
│   ├── QUICKSTART.md               # 快速开始指南
│   ├── CHANGELOG.md                # 更新日志
│   └── PROJECT.md                  # 本文件
│
└── 📋 配置示例
    ├── .env.example                # 环境变量示例
    ├── openclaw.json.example       # OpenClaw 配置示例
    └── .gitignore                  # Git 忽略规则
```

## 🚀 使用方式

### 方式一：快速启动脚本（推荐新手）

```bash
./start.sh
```

提供交互式菜单，包含所有功能。

### 方式二：命令行脚本（原有功能）

```bash
# 列出供应商
./openclaw-vendor-manager.sh --list

# 切换供应商
./openclaw-vendor-manager.sh --vendor anthropic --model claude-3-5-sonnet-20241022

# 添加供应商
./openclaw-vendor-manager.sh --add-vendor

# 添加模型
./openclaw-vendor-manager.sh --add-model --vendor openai
```

### 方式三：Node.js API（开发者）

```javascript
const ProviderManager = require('./index.js');
const manager = new ProviderManager();

// 列出供应商
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
```

### 方式四：Telegram Bot（可视化管理）

```bash
# 设置 Token
export TELEGRAM_BOT_TOKEN="your_token"

# 启动 Bot
npm run telegram

# 在 Telegram 中发送 /openclaw
```

## 🔑 核心类和方法

### ProviderManager 类

```javascript
class ProviderManager {
  // 供应商操作
  listProviders()                    // 列出所有供应商
  getProvider(vendorId)              // 获取供应商详情
  addProvider(vendorData)            // 添加供应商
  updateProvider(vendorId, updates)  // 更新供应商
  deleteProvider(vendorId)           // 删除供应商
  switchProvider(vendorId, modelId)  // 切换供应商

  // 模型操作
  addModel(vendorId, modelData)      // 添加模型
  deleteModel(vendorId, modelId)     // 删除模型

  // 配置操作
  loadConfig()                       // 加载配置
  saveConfig()                       // 保存配置
  backupConfig()                     // 备份配置

  // 系统操作
  restartOpenClaw()                  // 重启 OpenClaw
}
```

### TelegramCardManager 类

```javascript
class TelegramCardManager {
  // 卡片展示
  showMainCard(msg)                  // 主卡片
  showProviderList(chatId)           // 供应商列表
  showProviderDetail(chatId, vendorId) // 供应商详情
  showSwitchMenu(chatId)             // 切换菜单

  // 操作流程
  startAddProvider(chatId)           // 添加供应商流程
  startAddModel(chatId, vendorId)    // 添加模型流程
  switchProvider(chatId, vendorId)   // 切换供应商

  // 删除操作
  confirmDeleteModel(...)            // 确认删除模型
  confirmDeleteProvider(...)         // 确认删除供应商
  deleteModel(...)                   // 执行删除模型
  deleteProvider(...)                // 执行删除供应商

  // 系统操作
  restartOpenClaw(chatId)            // 重启 OpenClaw
}
```

## 🔄 工作流程

### 添加供应商流程

```
用户触发 → 输入供应商信息 → 验证 → 保存配置 → 备份 → 完成
```

### 切换供应商流程

```
选择供应商 → 验证存在 → 更新配置 → 备份 → 提示重启
```

### Telegram 操作流程

```
发送命令 → 显示卡片 → 点击按钮 → 执行操作 → 更新卡片 → 显示结果
```

## 🛡️ 安全机制

1. **配置备份**: 每次修改前自动备份
2. **二次确认**: 删除操作需要确认
3. **错误处理**: 完善的错误捕获和提示
4. **离线支持**: 即使服务不可用也能配置

## 📊 配置文件格式

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
      }
    }
  }
}
```

## 🧪 测试

```bash
# 运行完整测试套件
npm test

# 或运行演示
./demo.sh
```

测试覆盖：
- ✅ 列出供应商
- ✅ 获取供应商详情
- ✅ 添加供应商
- ✅ 添加模型
- ✅ 切换供应商
- ✅ 删除模型
- ✅ 删除供应商
- ✅ 配置备份

## 📝 开发规范

### 代码风格
- 使用 ES6+ 语法
- 异步操作使用 async/await
- 错误处理使用 try-catch
- 函数命名使用驼峰命名法

### 提交规范
- feat: 新功能
- fix: 修复
- docs: 文档
- test: 测试
- refactor: 重构

## 🔮 未来计划

- [ ] Web UI 界面
- [ ] 批量导入/导出配置
- [ ] 供应商健康检查
- [ ] 使用统计和分析
- [ ] 多语言支持
- [ ] Docker 容器化

## 📞 支持

- 📖 查看文档: `README.md`
- 🚀 快速开始: `QUICKSTART.md`
- 🐛 报告问题: GitHub Issues
- 💬 讨论交流: GitHub Discussions

## 📄 许可证

MIT License - 自由使用和修改

---

**最后更新**: 2026-03-10
**版本**: 1.0.0
