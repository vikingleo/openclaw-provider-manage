#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');
const { promisify } = require('util');

const execAsync = promisify(exec);

class ProviderManager {
  constructor(options = {}) {
    this.openclawDir = options.openclawDir || this.detectOpenClawDir();
    this.configPath = options.configPath || path.join(this.openclawDir, 'openclaw.json');
    this.config = null;
  }

  detectOpenClawDir() {
    const candidates = [
      path.join(process.env.HOME || '', '.openclaw'),
      '/srv/openclaw',
      '/opt/openclaw',
      path.join(process.env.HOME || '', 'openclaw')
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
      this.backupConfig();
      fs.writeFileSync(this.configPath, JSON.stringify(this.config, null, 2), 'utf8');
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

  getSchema() {
    if (this.config?.models?.providers && typeof this.config.models.providers === 'object') {
      return 'official';
    }
    return 'legacy';
  }

  ensureLegacyConfig() {
    if (!this.config.ai) {
      this.config.ai = {};
    }
    if (!this.config.ai.vendors) {
      this.config.ai.vendors = {};
    }
    return this.config.ai.vendors;
  }

  ensureOfficialConfig() {
    if (!this.config.models) {
      this.config.models = {};
    }
    if (!this.config.models.mode) {
      this.config.models.mode = 'merge';
    }
    if (!this.config.models.providers) {
      this.config.models.providers = {};
    }
    return this.config.models.providers;
  }

  ensureOfficialModelRegistry() {
    if (!this.config.agents) {
      this.config.agents = {};
    }
    if (!this.config.agents.defaults) {
      this.config.agents.defaults = {};
    }
    if (!this.config.agents.defaults.models || typeof this.config.agents.defaults.models !== 'object' || Array.isArray(this.config.agents.defaults.models)) {
      this.config.agents.defaults.models = {};
    }
    return this.config.agents.defaults.models;
  }

  getVendors() {
    return this.getSchema() === 'official'
      ? (this.config.models?.providers || {})
      : (this.config.ai?.vendors || {});
  }

  getRawProvider(vendorId) {
    return this.getVendors()[vendorId] || null;
  }

  getActiveModelRef() {
    const model = this.config?.agents?.defaults?.model;
    if (typeof model === 'string') {
      return model;
    }
    if (model && typeof model === 'object') {
      return model.primary || '';
    }
    return '';
  }

  setActiveModelRef(modelRef) {
    if (!this.config.agents) {
      this.config.agents = {};
    }
    if (!this.config.agents.defaults) {
      this.config.agents.defaults = {};
    }

    const currentModel = this.config.agents.defaults.model;
    if (currentModel && typeof currentModel === 'object' && !Array.isArray(currentModel)) {
      this.config.agents.defaults.model = { ...currentModel, primary: modelRef };
    } else {
      this.config.agents.defaults.model = { primary: modelRef };
    }
  }

  clearActiveModelRef() {
    if (!this.config?.agents?.defaults) {
      return;
    }

    const currentModel = this.config.agents.defaults.model;
    if (currentModel && typeof currentModel === 'object' && !Array.isArray(currentModel)) {
      delete currentModel.primary;
      if (Object.keys(currentModel).length === 0) {
        delete this.config.agents.defaults.model;
      }
      return;
    }

    delete this.config.agents.defaults.model;
  }

  parseModelRef(modelRef) {
    if (!modelRef || typeof modelRef !== 'string') {
      return { vendorId: '', modelId: '' };
    }

    const parts = modelRef.split('/');
    if (parts.length < 2) {
      return { vendorId: '', modelId: modelRef };
    }

    return {
      vendorId: parts[0],
      modelId: parts.slice(1).join('/')
    };
  }

  extractApiKeyEnv(apiKeyValue) {
    if (typeof apiKeyValue !== 'string') {
      return '';
    }

    const match = apiKeyValue.match(/^\$\{([^}]+)\}$/);
    return match ? match[1] : '';
  }

  normalizeModels(models) {
    if (Array.isArray(models)) {
      return models
        .filter(model => model && typeof model === 'object')
        .map(model => {
          const modelId = model.id || model.name;
          return modelId ? {
            id: modelId,
            name: model.name || modelId,
            contextWindow: model.contextWindow,
            maxOutputTokens: model.maxOutputTokens,
            raw: { ...model }
          } : null;
        })
        .filter(Boolean);
    }

    if (models && typeof models === 'object') {
      return Object.entries(models).map(([id, model]) => ({
        id,
        name: model?.name || id,
        contextWindow: model?.contextWindow,
        maxOutputTokens: model?.maxOutputTokens,
        raw: { ...(model || {}) }
      }));
    }

    return [];
  }

  serializeModels(models) {
    if (this.getSchema() === 'official') {
      return models.map(model => ({
        ...model.raw,
        id: model.id,
        name: model.name || model.id,
        ...(model.contextWindow !== undefined ? { contextWindow: model.contextWindow } : {}),
        ...(model.maxOutputTokens !== undefined ? { maxOutputTokens: model.maxOutputTokens } : {})
      }));
    }

    return models.reduce((result, model) => {
      result[model.id] = {
        ...model.raw,
        name: model.name || model.id,
        ...(model.contextWindow !== undefined ? { contextWindow: model.contextWindow } : {}),
        ...(model.maxOutputTokens !== undefined ? { maxOutputTokens: model.maxOutputTokens } : {})
      };
      return result;
    }, {});
  }

  getModelsMap(models) {
    return models.reduce((result, model) => {
      result[model.id] = {
        name: model.name || model.id,
        ...(model.contextWindow !== undefined ? { contextWindow: model.contextWindow } : {}),
        ...(model.maxOutputTokens !== undefined ? { maxOutputTokens: model.maxOutputTokens } : {})
      };
      return result;
    }, {});
  }

  getUnifiedProvider(vendorId, provider) {
    const schema = this.getSchema();
    const normalizedModels = this.normalizeModels(provider.models);
    const activeInfo = this.parseModelRef(this.getActiveModelRef());
    const isActive = schema === 'official'
      ? activeInfo.vendorId === vendorId
      : this.config.ai?.activeVendor === vendorId;
    const activeModel = isActive && schema === 'official' ? activeInfo.modelId : '';
    const defaultModel = activeModel || provider.defaultModel || normalizedModels[0]?.id || '';

    return {
      id: vendorId,
      name: provider.name || provider.label || vendorId,
      enabled: provider.enabled ?? (schema === 'official'),
      defaultModel,
      activeModel,
      models: this.getModelsMap(normalizedModels),
      modelIds: normalizedModels.map(model => model.id),
      apiEndpoint: provider.apiEndpoint || provider.baseUrl || '',
      apiKeyEnv: provider.apiKeyEnv || this.extractApiKeyEnv(provider.apiKey),
      isActive,
      schema
    };
  }

  ensureProviderExists(vendorId) {
    const provider = this.getRawProvider(vendorId);
    if (!provider) {
      throw new Error(`供应商 '${vendorId}' 不存在`);
    }
    return provider;
  }

  getNormalizedProviderModels(vendorId) {
    const provider = this.ensureProviderExists(vendorId);
    return this.normalizeModels(provider.models);
  }

  upsertOfficialModelRegistry(modelRef, alias) {
    const registry = this.ensureOfficialModelRegistry();
    if (!registry[modelRef]) {
      registry[modelRef] = alias ? { alias } : {};
    }
  }

  removeOfficialModelRegistry(modelRef) {
    if (this.config?.agents?.defaults?.models && typeof this.config.agents.defaults.models === 'object') {
      delete this.config.agents.defaults.models[modelRef];
    }
  }

  listProviders() {
    this.loadConfig();
    const vendors = this.getVendors();

    return Object.entries(vendors).map(([id, provider]) => {
      const unified = this.getUnifiedProvider(id, provider);
      return {
        id: unified.id,
        name: unified.name,
        enabled: unified.enabled,
        defaultModel: unified.defaultModel,
        activeModel: unified.activeModel,
        models: unified.modelIds,
        apiEndpoint: unified.apiEndpoint,
        apiKeyEnv: unified.apiKeyEnv,
        isActive: unified.isActive,
        schema: unified.schema
      };
    });
  }

  getProvider(vendorId) {
    this.loadConfig();
    const provider = this.ensureProviderExists(vendorId);
    return this.getUnifiedProvider(vendorId, provider);
  }

  addProvider(vendorData) {
    this.loadConfig();

    const { id, name, apiEndpoint, apiKeyEnv, defaultModel, api } = vendorData;
    if (!id) {
      throw new Error('供应商 ID 不能为空');
    }

    if (this.getRawProvider(id)) {
      throw new Error(`供应商 '${id}' 已存在`);
    }

    if (this.getSchema() === 'official') {
      const providers = this.ensureOfficialConfig();
      providers[id] = {
        ...(name ? { name } : {}),
        baseUrl: apiEndpoint || '',
        ...(apiKeyEnv ? { apiKey: `\${${apiKeyEnv}}` } : {}),
        api: api || 'openai-completions',
        models: defaultModel ? [{
          id: defaultModel,
          name: defaultModel,
          contextWindow: 200000,
          maxOutputTokens: 8192
        }] : []
      };

      if (defaultModel) {
        this.upsertOfficialModelRegistry(`${id}/${defaultModel}`, defaultModel);
      }
    } else {
      const vendors = this.ensureLegacyConfig();
      vendors[id] = {
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
    }

    this.saveConfig();
    return this.getProvider(id);
  }

  updateProvider(vendorId, updates) {
    this.loadConfig();
    const provider = this.ensureProviderExists(vendorId);

    if (this.getSchema() === 'official') {
      if (updates.name !== undefined) {
        provider.name = updates.name;
      }
      if (updates.apiEndpoint !== undefined) {
        provider.baseUrl = updates.apiEndpoint;
      }
      if (updates.apiKeyEnv !== undefined) {
        provider.apiKey = updates.apiKeyEnv ? `\${${updates.apiKeyEnv}}` : '';
      }
      if (updates.api !== undefined) {
        provider.api = updates.api;
      }
      if (updates.enabled !== undefined) {
        provider.enabled = updates.enabled;
      }
      if (updates.defaultModel !== undefined && updates.defaultModel) {
        const models = this.getNormalizedProviderModels(vendorId);
        const exists = models.some(model => model.id === updates.defaultModel);
        if (!exists) {
          throw new Error(`模型 '${updates.defaultModel}' 在供应商 '${vendorId}' 中不存在`);
        }
        this.setActiveModelRef(`${vendorId}/${updates.defaultModel}`);
        this.upsertOfficialModelRegistry(`${vendorId}/${updates.defaultModel}`, updates.defaultModel);
      }
    } else {
      Object.assign(provider, updates);
    }

    this.saveConfig();
    return this.getProvider(vendorId);
  }

  deleteProvider(vendorId) {
    this.loadConfig();
    this.ensureProviderExists(vendorId);

    if (this.getSchema() === 'official') {
      delete this.config.models.providers[vendorId];

      const activeModelRef = this.getActiveModelRef();
      const activeInfo = this.parseModelRef(activeModelRef);
      if (activeInfo.vendorId === vendorId) {
        this.clearActiveModelRef();
      }

      if (this.config?.agents?.defaults?.models && typeof this.config.agents.defaults.models === 'object') {
        Object.keys(this.config.agents.defaults.models)
          .filter(modelRef => modelRef.startsWith(`${vendorId}/`))
          .forEach(modelRef => delete this.config.agents.defaults.models[modelRef]);
      }
    } else {
      delete this.config.ai.vendors[vendorId];
      if (this.config.ai.activeVendor === vendorId) {
        delete this.config.ai.activeVendor;
      }
    }

    this.saveConfig();
    return true;
  }

  switchProvider(vendorId, modelId = null) {
    this.loadConfig();
    this.ensureProviderExists(vendorId);

    if (this.getSchema() === 'official') {
      const models = this.getNormalizedProviderModels(vendorId);
      const targetModel = modelId || models[0]?.id || '';

      if (!targetModel) {
        throw new Error(`供应商 '${vendorId}' 没有可用模型`);
      }

      const exists = models.some(model => model.id === targetModel);
      if (!exists) {
        throw new Error(`模型 '${targetModel}' 在供应商 '${vendorId}' 中不存在`);
      }

      this.setActiveModelRef(`${vendorId}/${targetModel}`);
      this.upsertOfficialModelRegistry(`${vendorId}/${targetModel}`, targetModel);
    } else {
      this.config.ai.activeVendor = vendorId;
      this.config.ai.vendors[vendorId].enabled = true;

      if (modelId) {
        if (!this.config.ai.vendors[vendorId].models?.[modelId]) {
          throw new Error(`模型 '${modelId}' 在供应商 '${vendorId}' 中不存在`);
        }
        this.config.ai.vendors[vendorId].defaultModel = modelId;
      }
    }

    this.saveConfig();
    return this.getProvider(vendorId);
  }

  addModel(vendorId, modelData) {
    this.loadConfig();
    const provider = this.ensureProviderExists(vendorId);
    const { id, name, contextWindow, maxOutputTokens } = modelData;

    if (!id) {
      throw new Error('模型 ID 不能为空');
    }

    const models = this.getNormalizedProviderModels(vendorId);
    if (models.some(model => model.id === id)) {
      throw new Error(`模型 '${id}' 已存在于供应商 '${vendorId}'`);
    }

    models.push({
      id,
      name: name || id,
      contextWindow: contextWindow || 200000,
      maxOutputTokens: maxOutputTokens || 8192,
      raw: {}
    });

    provider.models = this.serializeModels(models);

    if (this.getSchema() === 'official') {
      this.upsertOfficialModelRegistry(`${vendorId}/${id}`, name || id);
    }

    this.saveConfig();
    return this.getProvider(vendorId);
  }

  deleteModel(vendorId, modelId) {
    this.loadConfig();
    const provider = this.ensureProviderExists(vendorId);
    const models = this.getNormalizedProviderModels(vendorId);

    if (!models.some(model => model.id === modelId)) {
      throw new Error(`模型 '${modelId}' 不存在于供应商 '${vendorId}'`);
    }

    const remainingModels = models.filter(model => model.id !== modelId);
    provider.models = this.serializeModels(remainingModels);

    if (this.getSchema() === 'official') {
      const activeModelRef = this.getActiveModelRef();
      const activeInfo = this.parseModelRef(activeModelRef);
      if (activeInfo.vendorId === vendorId && activeInfo.modelId === modelId) {
        if (remainingModels[0]) {
          this.setActiveModelRef(`${vendorId}/${remainingModels[0].id}`);
        } else {
          this.clearActiveModelRef();
        }
      }
      this.removeOfficialModelRegistry(`${vendorId}/${modelId}`);
    } else if (this.config.ai.vendors[vendorId].defaultModel === modelId) {
      this.config.ai.vendors[vendorId].defaultModel = remainingModels[0]?.id || '';
    }

    this.saveConfig();
    return this.getProvider(vendorId);
  }

  async restartOpenClaw() {
    try {
      await execAsync('pkill -USR2 openclaw || true');
      return { success: true, message: '已发送重启信号' };
    } catch (error) {
      return { success: false, message: `重启失败: ${error.message}` };
    }
  }
}

module.exports = ProviderManager;

if (require.main === module) {
  const manager = new ProviderManager();
  const command = process.argv[2];

  try {
    switch (command) {
      case 'list':
        console.log(JSON.stringify(manager.listProviders(), null, 2));
        break;

      case 'get': {
        const vendorId = process.argv[3];
        console.log(JSON.stringify(manager.getProvider(vendorId), null, 2));
        break;
      }

      case 'add': {
        const vendorData = JSON.parse(process.argv[3]);
        console.log(JSON.stringify(manager.addProvider(vendorData), null, 2));
        break;
      }

      case 'switch': {
        const switchVendor = process.argv[3];
        const switchModel = process.argv[4];
        console.log(JSON.stringify(manager.switchProvider(switchVendor, switchModel), null, 2));
        break;
      }

      default:
        console.error('未知命令:', command);
        process.exit(1);
    }
  } catch (error) {
    console.error('错误:', error.message);
    process.exit(1);
  }
}
