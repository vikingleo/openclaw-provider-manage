# OpenClaw 配置结构说明

## ✅ 确认的配置结构

根据官方文档和实际测试，OpenClaw 使用以下配置结构：

```json
{
  "models": {
    "mode": "merge",
    "providers": {
      "anthropic": {
        "baseUrl": "https://api.anthropic.com",
        "apiKey": "sk-ant-xxx",
        "auth": "api-key"
      },
      "openai": {
        "baseUrl": "https://api.openai.com/v1",
        "apiKey": "sk-xxx",
        "auth": "api-key"
      }
    }
  }
}
```

## 📍 配置路径

**标准路径**: `.models.providers`

- `models.mode`: 配置模式（通常为 "merge"）
- `models.providers`: 供应商配置对象

## 🔧 供应商配置字段

每个供应商包含以下字段：

```json
{
  "供应商ID": {
    "baseUrl": "API 端点 URL",
    "apiKey": "API 密钥",
    "auth": "认证方式 (通常为 api-key)",
    "models": {
      "模型ID": {
        "name": "模型显示名称",
        "contextWindow": 200000,
        "maxOutputTokens": 8192
      }
    }
  }
}
```

## 🚀 使用方式

现在脚本会正确检测并使用 `.models.providers` 路径：

```bash
./openclaw-vendor-manager-universal.sh

# 输出:
[INFO] 检测配置文件结构...
[SUCCESS] 检测到配置路径: .models.providers
```

## 📝 配置示例

### 添加 Anthropic 供应商

```json
{
  "models": {
    "mode": "merge",
    "providers": {
      "anthropic": {
        "baseUrl": "https://api.anthropic.com",
        "apiKey": "sk-ant-xxx",
        "auth": "api-key",
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

## 🔗 参考资源

- [api-provider-setup skill](https://playbooks.com/skills/aaaaqwq/agi-super-skills/api-provider-setup)
- [OpenClaw配置千问Qwen教程](https://www.beizigen.com/post/openclaw-configuration-qwen/)
- [Model Providers Documentation](https://molty.finna.ai/docs/concepts/model-providers)

---

**更新日期**: 2026-03-10
**状态**: ✅ 已确认并修复
