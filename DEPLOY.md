# 一键部署说明

## 🎯 设计目标

让用户无需手动运行 `npm install`，通过一键部署脚本自动完成所有安装配置。

## ✨ 功能特性

`deploy.sh` 脚本会自动完成：

1. ✅ **检查系统环境** - 检测操作系统类型
2. ✅ **检查必需工具** - 验证 jq, node, npm 是否安装
3. ✅ **提供安装指导** - 如果缺少工具，显示对应系统的安装命令
4. ✅ **设置脚本权限** - 自动 chmod +x 所有脚本
5. ✅ **安装 Node.js 依赖** - 自动运行 npm install
6. ✅ **运行测试验证** - 确保安装成功
7. ✅ **创建配置文件** - 自动创建 .env 文件
8. ✅ **显示使用指南** - 部署完成后显示快速开始指南
9. ✅ **交互式启动** - 询问是否立即启动

## 📝 使用方式

```bash
# 克隆仓库
git clone git@github.com:vikingleo/openclaw-provider-manage.git
cd openclaw-provider-manage

# 一键部署
./deploy.sh

# 按提示操作即可
```

## 🔧 技术实现

### 系统检测

```bash
# 检测操作系统
OS="$(uname -s)"
case "$OS" in
    Linux*)     OS_TYPE="Linux";;
    Darwin*)    OS_TYPE="macOS";;
    *)          OS_TYPE="Unknown";;
esac
```

### 工具检测

检测必需工具：
- `jq` - JSON 处理
- `node` - Node.js 运行时
- `npm` - 包管理器

如果缺少工具，根据操作系统提供安装命令：

**macOS (Homebrew):**
```bash
brew install jq
brew install node
```

**Ubuntu/Debian:**
```bash
sudo apt-get install jq
sudo apt-get install nodejs npm
```

**CentOS/RHEL:**
```bash
sudo yum install jq
sudo yum install nodejs npm
```

### 智能安装

```bash
# 检查 node_modules 是否已存在
if [ -d "node_modules" ]; then
    echo "node_modules 已存在，跳过安装"
else
    npm install --silent
fi
```

### 自动配置

```bash
# 创建 .env 文件（如果不存在）
if [ ! -f ".env" ]; then
    cp .env.example .env
    echo "已创建 .env 配置文件"
fi
```

## 🎨 用户体验

### 部署过程展示

```
╔═══════════════════════════════════════════════════════════════╗
║              Provider Manager - 一键部署                      ║
╚═══════════════════════════════════════════════════════════════╝

🚀 开始一键部署 OpenClaw Provider Manager

[1/6] 检查系统环境...
  ✓ 操作系统: macOS

[2/6] 检查必需工具...
  ✓ jq: jq-1.7.1
  ✓ Node.js: v22.18.0
  ✓ npm: 11.11.0

[3/6] 设置脚本权限...
  ✓ 所有脚本已设置可执行权限

[4/6] 安装 Node.js 依赖...
  → 正在安装 node-telegram-bot-api...
  ✓ 依赖安装完成

[5/6] 运行测试验证...
  ✓ 所有测试通过

[6/6] 配置环境...
  ✓ 已创建 .env 配置文件

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ 部署完成！
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🚀 快速开始:
  ./start.sh

是否立即启动交互式菜单？(y/N):
```

## 💡 优势

1. **零配置** - 用户无需了解 npm 命令
2. **智能检测** - 自动检测系统环境和缺失工具
3. **友好提示** - 提供详细的安装指导
4. **容错处理** - 优雅处理各种异常情况
5. **交互体验** - 部署完成后可立即启动使用

## 🔄 与其他脚本的关系

```
deploy.sh (一键部署)
  ├── 检查环境
  ├── 安装依赖
  ├── 运行测试
  └── 启动 start.sh (可选)
      ├── 命令行模式 → openclaw-vendor-manager.sh
      ├── Telegram Bot → npm run telegram
      └── 测试验证 → npm test
```

## 📊 部署流程图

```
用户克隆仓库
    ↓
运行 ./deploy.sh
    ↓
检查系统环境 ──→ 缺少工具 ──→ 显示安装指导 ──→ 退出
    ↓ 环境完整
设置脚本权限
    ↓
安装 npm 依赖
    ↓
运行测试验证
    ↓
创建配置文件
    ↓
显示使用指南
    ↓
询问是否启动 ──→ 是 ──→ 启动 start.sh
    ↓ 否
部署完成
```

## 🎯 适用场景

- ✅ 首次安装
- ✅ 环境迁移
- ✅ 依赖更新
- ✅ 快速演示
- ✅ CI/CD 集成

## 🔧 自定义

可以通过修改 `deploy.sh` 添加自定义步骤：

```bash
# 在部署完成后添加自定义操作
echo ""
echo "执行自定义配置..."
# 你的自定义代码
```

## 📝 注意事项

1. 首次运行需要网络连接（下载 npm 包）
2. 需要有执行权限（`chmod +x deploy.sh`）
3. 如果系统缺少必需工具，会提示安装命令
4. 部署过程中会自动创建 `.env` 文件

## 🎉 总结

一键部署脚本大大简化了安装流程，让用户可以：
- 无需了解 npm 命令
- 无需手动安装依赖
- 无需配置环境变量
- 一条命令完成所有设置

真正实现"开箱即用"的体验！
