#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');
const { promisify } = require('util');

const execAsync = promisify(exec);

class ProviderManager {
  constructor() {
    this.openclawDir = this.detectOpenClawDir();
    this.configPath = path.join(this.openclawDir, 'openclaw.json');
    this.config = null;
  }

  detectOpenClawDir() {
    const candidates = [
      path.join(process.env.HOME, '.openclaw'),
      '/srv/openclaw',
      '/opt/openclaw',
      path.join(process.env.HOME, 'openclaw')
    ];

    for (const dir of candidates) {
      const configFile = path.join(dir, 'openclaw.json');
      if (fs.existsSync(configFile)) {
        return dir;
      }
    }

    throw new Error('无法检测到 OpenClaw 目录，请手动配置');
  }

  loadConfig() {
    try {
      const data = fs.readFileSync(this.configPath, 'utf8');
      this.config = JSON.parse(data);
      return this.config;
    } catch (error) {
      throw new Error(`加载配置失败: ${error.message}`);
    }
  }

  saveConfig() {
    try {
      // 备份
      this.backupConfig();

      // 保存
      fs.writeFileSync(
        this.configPath,
        JSON.stringify(this.config, null, 2),
        'utf8'
      );
      return true;
    } catch (error) {
      throw new Error(`保存配置失败: ${error.message}`);
    }
  }

  backupConfig() {
    const backupDir = path.join(this.openclawDir, '.openclaw', 'backups', 'provider-manager');
    if (!fs.existsSync(backupDir)) {
      fs.mkdirSync(backupDir, { recursive: true });
    }

    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const backupPath = path.join(backupDir, `openclaw.json.${timestamp}`);
    fs.copyFileSync(this.configPath, backupPath);

    return backupPath;
  }

  listProviders() {
    this.loadConfig();
    const vendors = this.config.ai?.vendors || {};

    return Object.entries(vendors).map(([id, vendor]) => ({
      id,
      name: vendor.name || id,
      enabled: vendor.enabled || false,
      defaultModel: vendor.defaultModel || '',
      models: Object.keys(vendor.models || {}),
      apiEndpoint: vendor.apiEndpoint || '',
      isActive: this.config.ai?.activeVendor === id
    }));
  }

  getProvider(vendorId) {
    this.loadConfig();
    const vendor = this.config.ai?.vendors?.[vendorId];

    if (!vendor) {
      throw new Error(`供应商 '${vendorId}' 不存在`);
    }

    return {
      id: vendorId,
      name: vendor.name || vendorId,
      enabled: vendor.enabled || false,
      defaultModel: vendor.defaultModel || '',
      models: vendor.models || {},
      apiEndpoint: vendor.apiEndpoint || '',
      apiKeyEnv: vendor.apiKeyEnv || '',
      isActive: this.config.ai?.activeVendor === vendorId
    };
  }

  addProvider(vendorData) {
    this.loadConfig();

    if (!this.config.ai) {
      this.config.ai = { vendors: {} };
    }
    if (!this.config.ai.vendors) {
      this.config.ai.vendors = {};
    }

    const { id, name, apiEndpoint, apiKeyEnv, defaultModel } = vendorData;

    if (this.config.ai.vendors[id]) {
      throw new Error(`供应商 '${id}' 已存在`);
    }

    this.config.ai.vendors[id] = {
      name: name || id,
      enabled: true,
      apiEndpoint: apiEndpoint || '',
      apiKeyEnv: apiKeyEnv || '',
      defaultModel: defaultModel || '',
      models: defaultModel ? {
        [defaultModel]: {
          name: defaultModel,
          contextWindow: 200000,
          maxOutputTokens: 8192
        }
      } : {}
    };

    this.saveConfig();
    return this.getProvider(id);
  }

  updateProvider(vendorId, updates) {
    this.loadConfig();

    if (!this.config.ai?.vendors?.[vendorId]) {
      throw new Error(`供应商 '${vendorId}' 不存在`);
    }

    Object.assign(this.config.ai.vendors[vendorId], updates);
    this.saveConfig();

    return this.getProvider(vendorId);
  }

  deleteProvider(vendorId) {
    this.loadConfig();

    if (!this.config.ai?.vendors?.[vendorId]) {
      throw new Error(`供应商 '${vendorId}' 不存在`);
    }

    delete this.config.ai.vendors[vendorId];

    // 如果删除的是活跃供应商，清除活跃状态
    if (this.config.ai.activeVendor === vendorId) {
      delete this.config.ai.activeVendor;
    }

    this.saveConfig();
    return true;
  }

  switchProvider(vendorId, modelId = null) {
    this.loadConfig();

    if (!this.config.ai?.vendors?.[vendorId]) {
      throw new Error(`供应商 '${vendorId}' 不存在`);
    }

    this.config.ai.activeVendor = vendorId;
    this.config.ai.vendors[vendorId].enabled = true;

    if (modelId) {
      if (!this.config.ai.vendors[vendorId].models?.[modelId]) {
        throw new Error(`模型 '${modelId}' 在供应商 '${vendorId}' 中不存在`);
      }
      this.config.ai.vendors[vendorId].defaultModel = modelId;
    }

    this.saveConfig();
    return this.getProvider(vendorId);
  }

  addModel(vendorId, modelData) {
    this.loadConfig();

    if (!this.config.ai?.vendors?.[vendorId]) {
      throw new Error(`供应商 '${vendorId}' 不存在`);
    }

    const { id, name, contextWindow, maxOutputTokens } = modelData;

    if (!this.config.ai.vendors[vendorId].models) {
      this.config.ai.vendors[vendorId].models = {};
    }

    if (this.config.ai.vendors[vendorId].models[id]) {
      throw new Error(`模型 '${id}' 已存在于供应商 '${vendorId}'`);
    }

    this.config.ai.vendors[vendorId].models[id] = {
      name: name || id,
      contextWindow: contextWindow || 200000,
      maxOutputTokens: maxOutputTokens || 8192
    };

    this.saveConfig();
    return this.getProvider(vendorId);
  }

  deleteModel(vendorId, modelId) {
    this.loadConfig();

    if (!this.config.ai?.vendors?.[vendorId]) {
      throw new Error(`供应商 '${vendorId}' 不存在`);
    }

    if (!this.config.ai.vendors[vendorId].models?.[modelId]) {
      throw new Error(`模型 '${modelId}' 不存在于供应商 '${vendorId}'`);
    }

    delete this.config.ai.vendors[vendorId].models[modelId];

    // 如果删除的是默认模型，清除默认模型设置
    if (this.config.ai.vendors[vendorId].defaultModel === modelId) {
      const remainingModels = Object.keys(this.config.ai.vendors[vendorId].models || {});
      this.config.ai.vendors[vendorId].defaultModel = remainingModels[0] || '';
    }

    this.saveConfig();
    return this.getProvider(vendorId);
  }

  async restartOpenClaw() {
    try {
      // 尝试优雅重启
      await execAsync('pkill -USR2 openclaw || true');
      return { success: true, message: '已发送重启信号' };
    } catch (error) {
      return { success: false, message: `重启失败: ${error.message}` };
    }
  }
}

module.exports = ProviderManager;

// CLI 入口
if (require.main === module) {
  const manager = new ProviderManager();
  const command = process.argv[2];

  try {
    switch (command) {
      case 'list':
        console.log(JSON.stringify(manager.listProviders(), null, 2));
        break;

      case 'get':
        const vendorId = process.argv[3];
        console.log(JSON.stringify(manager.getProvider(vendorId), null, 2));
        break;

      case 'add':
        const vendorData = JSON.parse(process.argv[3]);
        console.log(JSON.stringify(manager.addProvider(vendorData), null, 2));
        break;

      case 'switch':
        const switchVendor = process.argv[3];
        const switchModel = process.argv[4];
        console.log(JSON.stringify(manager.switchProvider(switchVendor, switchModel), null, 2));
        break;

      default:
        console.error('未知命令:', command);
        process.exit(1);
    }
  } catch (error) {
    console.error('错误:', error.message);
    process.exit(1);
  }
}
