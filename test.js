#!/usr/bin/env node

/**
 * OpenClaw Provider Manager - 测试脚本
 */

const ProviderManager = require('./index.js');
const fs = require('fs');
const path = require('path');

// 创建测试配置目录
const testDir = path.join(__dirname, '.test-openclaw');
const testConfigPath = path.join(testDir, 'openclaw.json');

// 初始化测试环境
function setupTestEnv() {
  if (!fs.existsSync(testDir)) {
    fs.mkdirSync(testDir, { recursive: true });
  }

  // 创建测试配置文件
  const testConfig = {
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

  fs.writeFileSync(testConfigPath, JSON.stringify(testConfig, null, 2));
  console.log('✅ 测试环境已创建:', testDir);
}

// 清理测试环境
function cleanupTestEnv() {
  if (fs.existsSync(testDir)) {
    fs.rmSync(testDir, { recursive: true, force: true });
    console.log('✅ 测试环境已清理');
  }
}

// 测试用例
async function runTests() {
  console.log('🧪 开始测试 OpenClaw Provider Manager\n');

  try {
    setupTestEnv();

    // 创建管理器实例（使用测试目录）
    const manager = new ProviderManager();
    manager.openclawDir = testDir;
    manager.configPath = testConfigPath;

    // 测试 1: 列出供应商
    console.log('📋 测试 1: 列出供应商');
    const providers = manager.listProviders();
    console.log('  结果:', JSON.stringify(providers, null, 2));
    console.assert(providers.length === 1, '应该有 1 个供应商');
    console.assert(providers[0].id === 'anthropic', '供应商 ID 应该是 anthropic');
    console.log('  ✅ 通过\n');

    // 测试 2: 获取供应商详情
    console.log('📋 测试 2: 获取供应商详情');
    const provider = manager.getProvider('anthropic');
    console.log('  结果:', JSON.stringify(provider, null, 2));
    console.assert(provider.name === 'Anthropic', '供应商名称应该是 Anthropic');
    console.assert(provider.isActive === true, '供应商应该是活跃的');
    console.log('  ✅ 通过\n');

    // 测试 3: 添加新供应商
    console.log('➕ 测试 3: 添加新供应商');
    const newProvider = manager.addProvider({
      id: 'openai',
      name: 'OpenAI',
      apiEndpoint: 'https://api.openai.com/v1',
      apiKeyEnv: 'OPENAI_API_KEY',
      defaultModel: 'gpt-4'
    });
    console.log('  结果:', JSON.stringify(newProvider, null, 2));
    console.assert(newProvider.id === 'openai', '新供应商 ID 应该是 openai');
    console.log('  ✅ 通过\n');

    // 测试 4: 添加模型
    console.log('➕ 测试 4: 添加模型');
    const updatedProvider = manager.addModel('openai', {
      id: 'gpt-4-turbo',
      name: 'GPT-4 Turbo',
      contextWindow: 128000,
      maxOutputTokens: 4096
    });
    console.log('  结果:', JSON.stringify(updatedProvider.models, null, 2));
    console.assert(updatedProvider.models['gpt-4-turbo'] !== undefined, '应该包含新模型');
    console.log('  ✅ 通过\n');

    // 测试 5: 切换供应商
    console.log('🔄 测试 5: 切换供应商');
    const switched = manager.switchProvider('openai', 'gpt-4-turbo');
    console.log('  结果:', JSON.stringify(switched, null, 2));
    manager.loadConfig();
    console.assert(manager.config.ai.activeVendor === 'openai', '活跃供应商应该是 openai');
    console.assert(manager.config.ai.vendors.openai.defaultModel === 'gpt-4-turbo', '默认模型应该是 gpt-4-turbo');
    console.log('  ✅ 通过\n');

    // 测试 6: 删除模型
    console.log('🗑️ 测试 6: 删除模型');
    manager.deleteModel('openai', 'gpt-4');
    const afterDelete = manager.getProvider('openai');
    console.log('  结果:', JSON.stringify(afterDelete.models, null, 2));
    console.assert(afterDelete.models['gpt-4'] === undefined, 'gpt-4 应该被删除');
    console.log('  ✅ 通过\n');

    // 测试 7: 删除供应商
    console.log('🗑️ 测试 7: 删除供应商');
    manager.deleteProvider('openai');
    const remainingProviders = manager.listProviders();
    console.log('  结果:', JSON.stringify(remainingProviders, null, 2));
    console.assert(remainingProviders.length === 1, '应该只剩 1 个供应商');
    console.assert(remainingProviders[0].id === 'anthropic', '剩余供应商应该是 anthropic');
    console.log('  ✅ 通过\n');

    // 测试 8: 配置备份
    console.log('💾 测试 8: 配置备份');
    const backupPath = manager.backupConfig();
    console.log('  备份路径:', backupPath);
    console.assert(fs.existsSync(backupPath), '备份文件应该存在');
    console.log('  ✅ 通过\n');

    console.log('🎉 所有测试通过！\n');

  } catch (error) {
    console.error('❌ 测试失败:', error.message);
    console.error(error.stack);
    process.exit(1);
  } finally {
    cleanupTestEnv();
  }
}

// 运行测试
if (require.main === module) {
  runTests().catch(error => {
    console.error('❌ 测试执行失败:', error);
    cleanupTestEnv();
    process.exit(1);
  });
}

module.exports = { runTests, setupTestEnv, cleanupTestEnv };
