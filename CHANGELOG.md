# Changelog

## [1.0.0] - 2026-03-10

### 新增功能

- ✅ 核心供应商管理功能
  - 添加、修改、删除、查询供应商
  - 供应商配置包含 API 端点、密钥环境变量等
  - 自动检测 OpenClaw 安装目录

- ✅ 模型管理功能
  - 为供应商添加/删除模型
  - 配置模型参数（上下文窗口、最大输出 tokens）
  - 设置默认模型

- ✅ 一键切换功能
  - 快速切换活跃供应商
  - 切换到指定供应商的指定模型
  - 自动启用目标供应商

- ✅ Telegram 卡片式管理
  - 可视化卡片界面
  - 供应商列表展示（状态、模型数量）
  - 供应商详情查看
  - 交互式添加供应商流程
  - 交互式添加模型流程
  - 删除操作带二次确认
  - 一键重启 OpenClaw

- ✅ 配置安全
  - 自动备份配置文件
  - 备份文件带时间戳
  - 支持配置回滚

- ✅ 离线操作支持
  - 即使 OpenClaw 无法连接也能配置
  - 配置修改后重启生效

- ✅ 多种使用方式
  - 命令行脚本（原有功能保留）
  - Node.js API
  - Telegram Bot

### 技术特性

- Node.js >= 14.0.0
- 自动依赖管理
- 完整的测试套件
- 详细的文档和示例

### 文件结构

```
openclaw-provider-manage/
├── extension.json              # 扩展配置
├── package.json                # Node.js 配置
├── index.js                    # 核心管理模块
├── telegram-card.js            # Telegram 卡片管理器
├── openclaw-vendor-manager.sh  # 命令行脚本（保留）
├── test.js                     # 测试脚本
├── install.sh                  # 安装脚本
├── start.sh                    # 快速启动脚本
├── README.md                   # 说明文档
├── CHANGELOG.md                # 更新日志
├── .env.example                # 环境变量示例
└── openclaw.json.example       # 配置文件示例
```
