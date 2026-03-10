# OpenClaw 配置文件说明

## 已确认的官方文件位置

根据 OpenClaw 官方文档，当前版本主要涉及以下文件：

- 主配置：`~/.openclaw/openclaw.json`
- 认证主存储：`~/.openclaw/agents/<agentId>/agent/auth-profiles.json`
- 认证运行时缓存：`~/.openclaw/agents/<agentId>/agent/auth.json`
- 旧版 OAuth 导入文件：`~/.openclaw/credentials/oauth.json`
- 自定义模型目录：`~/.openclaw/agents/<agentId>/agent/models.json`

以上路径也会受到 `OPENCLAW_STATE_DIR`、`OPENCLAW_AGENT_DIR`、`PI_CODING_AGENT_DIR` 等环境变量影响。

## 关键结论

### 1. `openclaw.json` 是主配置入口

OpenClaw 的主配置文件是：

```bash
~/.openclaw/openclaw.json
```

其中与模型切换最相关的字段是：

- `agents.defaults.model.primary`：当前默认模型，格式是 `provider/model`
- `agents.defaults.model.fallbacks`：回退模型列表
- `agents.defaults.models`：允许使用的模型目录 / 白名单
- `models.providers`：自定义 provider 定义

### 2. `models.providers.*.models` 是数组，不是对象

这正是本次脚本显示 `0`、`1` 的根因。

官方 schema 中，自定义 provider 大致长这样：

```json
{
  "models": {
    "mode": "merge",
    "providers": {
      "su8": {
        "baseUrl": "https://example.com/v1",
        "api": "openai-completions",
        "models": [
          {
            "id": "grok-4-fast-non-reasoning",
            "name": "Grok 4 Fast"
          },
          {
            "id": "grok-4-fast-reasoning",
            "name": "Grok 4 Fast Reasoning"
          }
        ]
      }
    }
  }
}
```

所以如果脚本对 `models` 做 `keys[]`，拿到的就会是数组下标 `0`、`1`，而不是模型 ID。

### 3. 当前默认模型不是 `activeVendor`，而是 `agents.defaults.model.primary`

在 OpenClaw 官方配置中，当前默认模型通常类似：

```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "su8/grok-4-fast-non-reasoning"
      }
    }
  }
}
```

因此在 `.models.providers` 结构下：

- 不能再仅依赖 `activeVendor`
- 应优先读取 `agents.defaults.model.primary`
- 并从 `provider/model` 中拆出当前 provider 和 model

### 4. `auth-profiles.json` 才是认证主存储

认证相关文件的职责如下：

- `auth-profiles.json`：OAuth / API Key 的正式存储位置
- `auth.json`：运行时缓存，通常不建议手工编辑
- `oauth.json`：旧版导入文件，仅首次迁移时使用

## 本次脚本修复内容

已修复 `openclaw-vendor-manager-universal.sh`：

- 正确读取 `.models.providers.*.models` 数组中的 `id`
- 正确显示当前主模型 `agents.defaults.model.primary`
- 在 `.models.providers` 结构下切换模型时，写入 `agents.defaults.model.primary`
- 在 `.models.providers` 结构下新增模型时，按官方数组 schema 写入
- 增强 `check-config.sh`，同时扫描：
  - `openclaw.json`
  - `auth-profiles.json`
  - `auth.json`
  - `models.json`
  - `oauth.json`

## 推荐检查命令

在安装了 OpenClaw 的机器上，建议依次执行：

```bash
./check-config.sh
```

如果系统安装了 `openclaw` CLI，也建议执行：

```bash
openclaw config file
openclaw models status --json
```

## 官方文档参考

- 配置文件位置：OpenClaw Configuration Guide
- 模型配置：Models CLI / Configuration Reference
- 认证文件：OAuth / Model Failover

主要参考页面：

- https://www.openclawdoc.com/en/docs/configuration/
- https://docs.openclaw.ai/concepts/models
- https://docs.openclaw.ai/gateway/configuration-reference
- https://docs.openclaw.ai/concepts/oauth
- https://docs.openclaw.ai/concepts/model-failover

---

更新时间：2026-03-10
状态：已按官方文档核对并修正
