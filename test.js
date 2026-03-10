#!/usr/bin/env node

const assert = require('assert/strict');
const ProviderManager = require('./index.js');
const fs = require('fs');
const os = require('os');
const path = require('path');

let testDir = null;
let testConfigPath = null;

function createLegacyConfig() {
  return {
    ai: {
      activeVendor: 'anthropic',
      vendors: {
        anthropic: {
          name: 'Anthropic',
          enabled: true,
          apiEndpoint: 'https://api.anthropic.com',
          apiKeyEnv: 'ANTHROPIC_API_KEY',
          defaultModel: 'claude-3-5-sonnet-20241022',
          models: {
            'claude-3-5-sonnet-20241022': {
              name: 'Claude 3.5 Sonnet',
              contextWindow: 200000,
              maxOutputTokens: 8192
            }
          }
        }
      }
    }
  };
}

function createOfficialConfig() {
  return {
    agents: {
      defaults: {
        model: {
          primary: 'su8/grok-4-fast-non-reasoning'
        },
        models: {
          'su8/grok-4-fast-non-reasoning': { alias: 'grok-fast' }
        }
      }
    },
    models: {
      mode: 'merge',
      providers: {
        fox: {
          baseUrl: 'https://api.fox.example/v1',
          api: 'openai-completions',
          models: [
            {
              id: 'claude-3-7-sonnet',
              name: 'Claude 3.7 Sonnet',
              contextWindow: 200000,
              maxOutputTokens: 8192
            }
          ]
        },
        su8: {
          baseUrl: 'https://api.su8.example/v1',
          api: 'openai-completions',
          models: [
            {
              id: 'grok-4-fast-non-reasoning',
              name: 'Grok 4 Fast',
              contextWindow: 256000,
              maxOutputTokens: 8192
            },
            {
              id: 'grok-4-fast-reasoning',
              name: 'Grok 4 Fast Reasoning',
              contextWindow: 256000,
              maxOutputTokens: 8192
            }
          ]
        }
      }
    }
  };
}

function setupTestEnv(configFactory, label) {
  testDir = fs.mkdtempSync(path.join(os.tmpdir(), `openclaw-provider-manage-${label}-`));
  testConfigPath = path.join(testDir, 'openclaw.json');
  fs.writeFileSync(testConfigPath, JSON.stringify(configFactory(), null, 2));
  console.log('✅ 测试环境已创建:', testDir);
}

function cleanupTestEnv() {
  if (testDir && fs.existsSync(testDir)) {
    fs.rmSync(testDir, { recursive: true, force: true });
    console.log('✅ 测试环境已清理');
  }
  testDir = null;
  testConfigPath = null;
}

function createManager() {
  return new ProviderManager({
    openclawDir: testDir,
    configPath: testConfigPath
  });
}

function runLegacySuite() {
  console.log('📦 运行 legacy schema 测试');
  setupTestEnv(createLegacyConfig, 'legacy');

  const manager = createManager();

  console.log('📋 测试 1: 列出供应商');
  const providers = manager.listProviders();
  assert.equal(providers.length, 1, '应该有 1 个供应商');
  assert.equal(providers[0].id, 'anthropic', '供应商 ID 应该是 anthropic');
  assert.ok(providers[0].models.includes('claude-3-5-sonnet-20241022'), '应该列出 legacy 模型');
  console.log('  ✅ 通过\n');

  console.log('📋 测试 2: 获取供应商详情');
  const provider = manager.getProvider('anthropic');
  assert.equal(provider.name, 'Anthropic', '供应商名称应该是 Anthropic');
  assert.equal(provider.isActive, true, '供应商应该是活跃的');
  assert.ok(provider.models['claude-3-5-sonnet-20241022'] !== undefined, '应该包含模型详情');
  console.log('  ✅ 通过\n');

  console.log('➕ 测试 3: 添加新供应商');
  const newProvider = manager.addProvider({
    id: 'openai',
    name: 'OpenAI',
    apiEndpoint: 'https://api.openai.com/v1',
    apiKeyEnv: 'OPENAI_API_KEY',
    defaultModel: 'gpt-4'
  });
  assert.equal(newProvider.id, 'openai', '新供应商 ID 应该是 openai');
  console.log('  ✅ 通过\n');

  console.log('➕ 测试 4: 添加模型');
  const updatedProvider = manager.addModel('openai', {
    id: 'gpt-4-turbo',
    name: 'GPT-4 Turbo',
    contextWindow: 128000,
    maxOutputTokens: 4096
  });
  assert.ok(updatedProvider.models['gpt-4-turbo'] !== undefined, '应该包含新模型');
  console.log('  ✅ 通过\n');

  console.log('🔄 测试 5: 切换供应商');
  manager.switchProvider('openai', 'gpt-4-turbo');
  manager.loadConfig();
  assert.equal(manager.config.ai.activeVendor, 'openai', '活跃供应商应该是 openai');
  assert.equal(manager.config.ai.vendors.openai.defaultModel, 'gpt-4-turbo', '默认模型应该是 gpt-4-turbo');
  console.log('  ✅ 通过\n');

  console.log('🗑️ 测试 6: 删除模型');
  const afterDelete = manager.deleteModel('openai', 'gpt-4');
  assert.equal(afterDelete.models['gpt-4'], undefined, 'gpt-4 应该被删除');
  console.log('  ✅ 通过\n');

  console.log('🗑️ 测试 7: 删除供应商');
  manager.deleteProvider('openai');
  const remainingProviders = manager.listProviders();
  assert.equal(remainingProviders.length, 1, '应该只剩 1 个供应商');
  assert.equal(remainingProviders[0].id, 'anthropic', '剩余供应商应该是 anthropic');
  console.log('  ✅ 通过\n');

  console.log('💾 测试 8: 配置备份');
  const backupPath = manager.backupConfig();
  assert.ok(fs.existsSync(backupPath), '备份文件应该存在');
  console.log('  ✅ 通过\n');

  cleanupTestEnv();
}

function runOfficialSuite() {
  console.log('📦 运行 official schema 测试');
  setupTestEnv(createOfficialConfig, 'official');

  const manager = createManager();

  console.log('📋 测试 9: 列出官方供应商');
  const providers = manager.listProviders();
  assert.equal(providers.length, 2, '应该有 2 个供应商');
  assert.equal(providers.find(provider => provider.id === 'su8').isActive, true, 'su8 应该为活跃供应商');
  assert.ok(providers.find(provider => provider.id === 'su8').models.includes('grok-4-fast-non-reasoning'), '应列出官方模型 ID');
  console.log('  ✅ 通过\n');

  console.log('📋 测试 10: 获取官方供应商详情');
  const provider = manager.getProvider('su8');
  assert.equal(provider.defaultModel, 'grok-4-fast-non-reasoning', '默认模型应来自 active model');
  assert.ok(provider.models['grok-4-fast-reasoning'] !== undefined, '应包含数组模型详情');
  console.log('  ✅ 通过\n');

  console.log('🔄 测试 11: 切换官方供应商与模型');
  manager.switchProvider('fox', 'claude-3-7-sonnet');
  manager.loadConfig();
  assert.equal(manager.config.agents.defaults.model.primary, 'fox/claude-3-7-sonnet', '主模型应写入 agents.defaults.model.primary');
  console.log('  ✅ 通过\n');

  console.log('➕ 测试 12: 添加官方模型');
  const updatedProvider = manager.addModel('fox', {
    id: 'claude-4-opus',
    name: 'Claude 4 Opus',
    contextWindow: 300000,
    maxOutputTokens: 16384
  });
  assert.ok(updatedProvider.models['claude-4-opus'] !== undefined, '应包含新增官方模型');
  manager.loadConfig();
  assert.ok(Array.isArray(manager.config.models.providers.fox.models), '官方模型应保持数组结构');
  console.log('  ✅ 通过\n');

  console.log('🗑️ 测试 13: 删除官方模型');
  manager.deleteModel('fox', 'claude-3-7-sonnet');
  const foxProvider = manager.getProvider('fox');
  assert.equal(foxProvider.models['claude-3-7-sonnet'], undefined, '官方模型应已删除');
  console.log('  ✅ 通过\n');

  console.log('➕ 测试 14: 添加官方供应商');
  const newProvider = manager.addProvider({
    id: 'newp',
    apiEndpoint: 'https://api.newp.example/v1',
    apiKeyEnv: 'NEWP_API_KEY',
    defaultModel: 'my-model'
  });
  assert.equal(newProvider.id, 'newp', '应成功添加官方供应商');
  manager.loadConfig();
  assert.ok(Array.isArray(manager.config.models.providers.newp.models), '新增官方供应商模型应为数组');
  console.log('  ✅ 通过\n');

  cleanupTestEnv();
}

async function runTests() {
  console.log('🧪 开始测试 OpenClaw Provider Manager\n');

  try {
    runLegacySuite();
    runOfficialSuite();
    console.log('🎉 所有测试通过！\n');
  } catch (error) {
    console.error('❌ 测试失败:', error.message);
    console.error(error.stack);
    process.exit(1);
  } finally {
    cleanupTestEnv();
  }
}

if (require.main === module) {
  runTests().catch(error => {
    console.error('❌ 测试执行失败:', error);
    cleanupTestEnv();
    process.exit(1);
  });
}

module.exports = { runTests, setupTestEnv, cleanupTestEnv };
