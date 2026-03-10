# OpenClaw 配置文件结构适配说明

## 问题

用户反馈：
1. OpenClaw 已经在运行，有自己的配置文件
2. "列出当前配置"依然提示"未找到任何供应商配置"
3. 不能覆盖 openclaw.json，只能添加供应商和模型配置

## 需要确认的信息

为了正确适配脚本，需要了解实际的配置文件结构。

### 请运行检查脚本

```bash
./check-config.sh
```

或者手动提供以下信息：

### 1. 配置文件位置

```bash
# 查找配置文件
find ~ -name "openclaw.json" 2>/dev/null
find /srv -name "openclaw.json" 2>/dev/null
find /opt -name "openclaw.json" 2>/dev/null
```

### 2. 配置文件结构

```bash
# 查看配置文件结构
cat /path/to/openclaw.json | jq 'keys'

# 或者查看完整内容（隐藏敏感信息）
cat /path/to/openclaw.json | jq '.'
```

## 可能的配置结构

OpenClaw 可能使用以下几种配置结构：

### 结构 1: ai.vendors (我们当前假设的)

```json
{
  "ai": {
    "activeVendor": "anthropic",
    "vendors": {
      "anthropic": {
        "name": "Anthropic",
        "models": {...}
      }
    }
  }
}
```

### 结构 2: 顶层 vendors

```json
{
  "vendors": {
    "anthropic": {...}
  }
}
```

### 结构 3: providers

```json
{
  "providers": {
    "anthropic": {...}
  }
}
```

### 结构 4: models 直接配置

```json
{
  "models": {
    "claude-3-5-sonnet": {...}
  }
}
```

### 结构 5: 其他自定义结构

```json
{
  "llm": {
    "providers": {...}
  }
}
```

## 适配方案

一旦确认了实际的配置结构，我们将：

1. **修改脚本以支持实际的配置路径**
   - 更新 jq 查询路径
   - 适配读取和写入逻辑

2. **确保不覆盖现有配置**
   - 只添加/修改供应商配置
   - 保留其他所有配置项

3. **支持多种配置结构**
   - 自动检测配置结构
   - 适配不同的路径

## 临时解决方案

在确认配置结构之前，可以手动添加供应商：

```bash
# 备份配置
cp /path/to/openclaw.json /path/to/openclaw.json.backup

# 手动编辑配置
nano /path/to/openclaw.json

# 添加供应商配置（根据实际结构调整）
```

## 下一步

请提供：
1. 配置文件的实际路径
2. 配置文件的结构（可以隐藏敏感信息如 API keys）
3. OpenClaw 的版本信息（如果有）

我们将立即适配脚本以支持实际的配置结构。
