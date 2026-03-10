# OpenClaw Provider Manager - 快速开始

## 🚀 5 分钟快速上手

### 1. 一键部署

```bash
cd openclaw-provider-manage
./deploy.sh
```

一键部署脚本会自动完成所有安装步骤，无需手动 `npm install`。

或者手动安装：
```bash
npm install
```

### 2. 运行测试（可选）

```bash
npm test
```

### 3. 开始使用

#### 方式一：快速启动脚本（推荐）

```bash
./start.sh
```

会显示菜单：
```
1) 命令行交互模式
2) 列出所有供应商
3) 启动 Telegram Bot
4) 运行测试
5) 安装/更新依赖
0) 退出
```

#### 方式二：命令行直接使用

```bash
# 列出所有供应商
./openclaw-vendor-manager.sh --list

# 切换供应商
./openclaw-vendor-manager.sh --vendor anthropic

# 添加供应商
./openclaw-vendor-manager.sh --add-vendor
```

#### 方式三：Telegram Bot

```bash
# 1. 设置 Bot Token
export TELEGRAM_BOT_TOKEN="your_token_here"

# 2. 启动 Bot
npm run telegram

# 3. 在 Telegram 中发送 /openclaw
```

## 📱 Telegram Bot 使用演示

1. 向你的 Bot 发送 `/openclaw` 或 `/start`
2. 看到主卡片界面，显示当前活跃供应商
3. 点击按钮进行操作：
   - 📋 查看所有供应商
   - ➕ 添加供应商
   - 🔄 切换供应商
   - ⚙️ 管理模型
   - 🔃 重启 OpenClaw

## 🎯 常用操作示例

### 添加新供应商（命令行）

```bash
./openclaw-vendor-manager.sh --add-vendor
```

按提示输入：
- 供应商 ID: `deepseek`
- 供应商名称: `DeepSeek`
- API 端点: `https://api.deepseek.com`
- API Key 环境变量: `DEEPSEEK_API_KEY`
- 默认模型: `deepseek-chat`

### 切换供应商和模型

```bash
# 切换到 OpenAI 的 GPT-4
./openclaw-vendor-manager.sh --vendor openai --model gpt-4

# 只切换供应商（使用默认模型）
./openclaw-vendor-manager.sh --vendor anthropic
```

### 添加模型到现有供应商

```bash
./openclaw-vendor-manager.sh --add-model --vendor openai
```

## 🔧 配置 API Keys

```bash
# 复制环境变量示例文件
cp .env.example .env

# 编辑 .env 文件，填入你的 API Keys
nano .env

# 加载环境变量
source .env
```

## 📊 查看配置

```bash
# 列出所有供应商
./openclaw-vendor-manager.sh --list

# 或使用 Node.js API
node index.js list
```

## 🔄 重启 OpenClaw

配置修改后需要重启 OpenClaw：

```bash
# 方式一：通过 Telegram Bot
点击 "🔃 重启 OpenClaw" 按钮

# 方式二：手动重启
pkill -USR2 openclaw
```

## 💡 提示

- ✅ 所有配置修改都会自动备份
- ✅ 即使 OpenClaw 无法连接也能配置
- ✅ 支持自动检测 OpenClaw 安装目录
- ✅ Telegram Bot 提供可视化操作界面

## 🆘 遇到问题？

查看完整文档：`README.md`

或运行帮助命令：
```bash
./openclaw-vendor-manager.sh --help
```
