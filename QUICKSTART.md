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

#### 方式一：启动入口脚本（推荐）

```bash
./start.sh
```

会显示菜单：

```text
1) 命令行交互模式
2) 列出所有供应商
3) 启动 Telegram Bot
4) 运行测试
5) 安装/更新依赖
0) 退出
```

#### 方式二：交互式命令行

直接运行通用脚本，不带参数时会进入交互式菜单：

```bash
./openclaw-vendor-manager-universal.sh
```

交互式菜单如下：

```text
请选择操作:
  1) 列出当前配置
  2) 切换供应商
  3) 添加新供应商
  4) 向供应商添加新模型
  0) 退出
```

适合场景：
- 第一次使用，不熟悉参数
- 在服务器上临时维护 provider / model
- 想按提示一步步录入配置

#### 方式三：命令行直接使用

```bash
# 列出所有供应商
./openclaw-vendor-manager-universal.sh --list

# 切换供应商
./openclaw-vendor-manager-universal.sh --vendor anthropic

# 切换到指定供应商的指定模型
./openclaw-vendor-manager-universal.sh --vendor openai --model gpt-4.1

# 添加供应商
./openclaw-vendor-manager-universal.sh --add-vendor

# 添加模型
./openclaw-vendor-manager-universal.sh --add-model --vendor openai
```

#### 方式四：Telegram Bot

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

### 交互式维护 provider

```bash
./openclaw-vendor-manager-universal.sh
```

然后按菜单：
- 输入 `1` 查看当前 provider / model
- 输入 `2` 切换当前 provider / model
- 输入 `3` 添加新 provider
- 输入 `4` 给已有 provider 增加模型

### 添加新供应商（命令行）

```bash
./openclaw-vendor-manager-universal.sh --add-vendor
```

### 切换供应商和模型

```bash
# 切换到 OpenAI 的 GPT-4.1
./openclaw-vendor-manager-universal.sh --vendor openai --model gpt-4.1

# 只切换供应商（使用默认/首个模型）
./openclaw-vendor-manager-universal.sh --vendor anthropic
```

### 添加模型到现有供应商

```bash
./openclaw-vendor-manager-universal.sh --add-model --vendor openai
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
./openclaw-vendor-manager-universal.sh --list

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
- ✅ 默认推荐使用 `openclaw-vendor-manager-universal.sh`

## 🆘 遇到问题？

查看完整文档：`README.md`

或运行帮助命令：

```bash
./openclaw-vendor-manager-universal.sh --help
```
