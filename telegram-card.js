#!/usr/bin/env node

const TelegramBot = require('node-telegram-bot-api');
const ProviderManager = require('./index.js');

class TelegramCardManager {
  constructor(token) {
    this.bot = new TelegramBot(token, { polling: true });
    this.manager = new ProviderManager();
    this.userStates = new Map(); // 存储用户操作状态

    this.setupHandlers();
  }

  setupHandlers() {
    // 命令处理
    this.bot.onText(/\/openclaw/, (msg) => this.showMainCard(msg));
    this.bot.onText(/\/start/, (msg) => this.showMainCard(msg));

    // 回调查询处理
    this.bot.on('callback_query', (query) => this.handleCallback(query));
  }

  // 显示主卡片
  async showMainCard(msg) {
    const chatId = msg.chat.id;

    try {
      const providers = this.manager.listProviders();
      const activeProvider = providers.find(p => p.isActive);

      let text = '🔧 *OpenClaw 供应商管理*\n\n';

      if (activeProvider) {
        text += `✅ 当前活跃: *${activeProvider.name}*\n`;
        text += `📦 当前模型: \`${activeProvider.defaultModel}\`\n\n`;
      } else {
        text += '⚠️ 未设置活跃供应商\n\n';
      }

      text += `📊 已配置供应商: ${providers.length} 个\n`;
      text += `🟢 已启用: ${providers.filter(p => p.enabled).length} 个`;

      const keyboard = {
        inline_keyboard: [
          [
            { text: '📋 查看所有供应商', callback_data: 'list_providers' },
            { text: '➕ 添加供应商', callback_data: 'add_provider' }
          ],
          [
            { text: '🔄 切换供应商', callback_data: 'switch_provider' },
            { text: '⚙️ 管理模型', callback_data: 'manage_models' }
          ],
          [
            { text: '🔃 重启 OpenClaw', callback_data: 'restart_openclaw' }
          ]
        ]
      };

      await this.bot.sendMessage(chatId, text, {
        parse_mode: 'Markdown',
        reply_markup: keyboard
      });
    } catch (error) {
      await this.bot.sendMessage(chatId, `❌ 错误: ${error.message}`);
    }
  }

  // 列出所有供应商
  async showProviderList(chatId) {
    try {
      const providers = this.manager.listProviders();

      if (providers.length === 0) {
        await this.bot.sendMessage(chatId, '📭 暂无配置的供应商');
        return;
      }

      let text = '📋 *供应商列表*\n\n';

      const buttons = [];

      providers.forEach((provider, index) => {
        const status = provider.isActive ? '✅' : (provider.enabled ? '🟢' : '⚪');
        text += `${status} *${provider.name}* (\`${provider.id}\`)\n`;
        text += `   └ 模型: ${provider.models.length} 个`;
        if (provider.defaultModel) {
          text += ` | 默认: \`${provider.defaultModel}\``;
        }
        text += '\n\n';

        buttons.push([
          { text: `${status} ${provider.name}`, callback_data: `view_provider:${provider.id}` }
        ]);
      });

      buttons.push([{ text: '🔙 返回主菜单', callback_data: 'main_menu' }]);

      await this.bot.sendMessage(chatId, text, {
        parse_mode: 'Markdown',
        reply_markup: { inline_keyboard: buttons }
      });
    } catch (error) {
      await this.bot.sendMessage(chatId, `❌ 错误: ${error.message}`);
    }
  }

  // 查看供应商详情
  async showProviderDetail(chatId, vendorId) {
    try {
      const provider = this.manager.getProvider(vendorId);

      let text = `🔍 *供应商详情*\n\n`;
      text += `📛 名称: *${provider.name}*\n`;
      text += `🆔 ID: \`${provider.id}\`\n`;
      text += `🌐 端点: \`${provider.apiEndpoint || '未设置'}\`\n`;
      text += `🔑 API Key: \`${provider.apiKeyEnv || '未设置'}\`\n`;
      text += `📦 当前模型: \`${provider.defaultModel || '未设置'}\`\n`;
      text += `🔘 状态: ${provider.isActive ? '✅ 活跃' : (provider.enabled ? '🟢 已启用' : '⚪ 已禁用')}\n`;
      text += `🧩 Schema: \`${provider.schema}\`\n\n`;

      text += `*可用模型 (${Object.keys(provider.models).length})*:\n`;
      Object.entries(provider.models).forEach(([id, model]) => {
        const isDefault = id === provider.defaultModel ? '⭐' : '  ';
        text += `${isDefault} \`${id}\`\n`;
        text += `   └ 上下文: ${model.contextWindow} | 输出: ${model.maxOutputTokens}\n`;
      });

      const keyboard = {
        inline_keyboard: [
          [
            { text: '🔄 切换到此供应商', callback_data: `switch_to:${vendorId}` },
            { text: '✏️ 编辑', callback_data: `edit_provider:${vendorId}` }
          ],
          [
            { text: '➕ 添加模型', callback_data: `add_model:${vendorId}` },
            { text: '🗑️ 删除模型', callback_data: `delete_model_menu:${vendorId}` }
          ],
          [
            { text: '🗑️ 删除供应商', callback_data: `delete_provider:${vendorId}` },
            { text: '🔙 返回列表', callback_data: 'list_providers' }
          ]
        ]
      };

      await this.bot.sendMessage(chatId, text, {
        parse_mode: 'Markdown',
        reply_markup: keyboard
      });
    } catch (error) {
      await this.bot.sendMessage(chatId, `❌ 错误: ${error.message}`);
    }
  }

  // 切换供应商菜单
  async showSwitchMenu(chatId) {
    try {
      const providers = this.manager.listProviders();

      if (providers.length === 0) {
        await this.bot.sendMessage(chatId, '📭 暂无可切换的供应商');
        return;
      }

      let text = '🔄 *选择要切换的供应商*\n\n';
      const buttons = [];

      providers.forEach(provider => {
        const status = provider.isActive ? '✅' : '🔘';
        buttons.push([
          { text: `${status} ${provider.name}`, callback_data: `switch_to:${provider.id}` }
        ]);
      });

      buttons.push([{ text: '🔙 返回主菜单', callback_data: 'main_menu' }]);

      await this.bot.sendMessage(chatId, text, {
        parse_mode: 'Markdown',
        reply_markup: { inline_keyboard: buttons }
      });
    } catch (error) {
      await this.bot.sendMessage(chatId, `❌ 错误: ${error.message}`);
    }
  }

  // 切换供应商
  async switchProvider(chatId, vendorId) {
    try {
      const provider = this.manager.switchProvider(vendorId);

      await this.bot.sendMessage(chatId,
        `✅ 已切换到供应商: *${provider.name}*\n` +
        `📦 当前模型: \`${provider.defaultModel}\`\n\n` +
        `💡 提示: 可能需要重启 OpenClaw 使配置生效`,
        { parse_mode: 'Markdown' }
      );

      // 显示重启选项
      const keyboard = {
        inline_keyboard: [
          [
            { text: '🔃 立即重启 OpenClaw', callback_data: 'restart_openclaw' },
            { text: '🔙 返回主菜单', callback_data: 'main_menu' }
          ]
        ]
      };

      await this.bot.sendMessage(chatId, '是否需要重启？', {
        reply_markup: keyboard
      });
    } catch (error) {
      await this.bot.sendMessage(chatId, `❌ 切换失败: ${error.message}`);
    }
  }

  // 添加供应商流程
  async startAddProvider(chatId) {
    this.userStates.set(chatId, { action: 'add_provider', step: 'id' });

    await this.bot.sendMessage(chatId,
      '➕ *添加新供应商*\n\n' +
      '请输入供应商 ID (例如: anthropic, openai, deepseek)\n\n' +
      '发送 /cancel 取消操作',
      { parse_mode: 'Markdown' }
    );
  }

  // 添加模型流程
  async startAddModel(chatId, vendorId) {
    this.userStates.set(chatId, {
      action: 'add_model',
      step: 'id',
      vendorId: vendorId
    });

    await this.bot.sendMessage(chatId,
      `➕ *向供应商添加模型*\n\n` +
      `请输入模型 ID (例如: gpt-4, claude-3-opus-20240229)\n\n` +
      `发送 /cancel 取消操作`,
      { parse_mode: 'Markdown' }
    );
  }

  // 删除模型菜单
  async showDeleteModelMenu(chatId, vendorId) {
    try {
      const provider = this.manager.getProvider(vendorId);
      const models = Object.keys(provider.models);

      if (models.length === 0) {
        await this.bot.sendMessage(chatId, '📭 该供应商暂无模型');
        return;
      }

      let text = `🗑️ *删除模型*\n\n选择要删除的模型:\n`;
      const buttons = [];

      models.forEach(modelId => {
        const isDefault = modelId === provider.defaultModel ? '⭐' : '';
        buttons.push([
          { text: `${isDefault} ${modelId}`, callback_data: `confirm_delete_model:${vendorId}:${modelId}` }
        ]);
      });

      buttons.push([{ text: '🔙 返回', callback_data: `view_provider:${vendorId}` }]);

      await this.bot.sendMessage(chatId, text, {
        parse_mode: 'Markdown',
        reply_markup: { inline_keyboard: buttons }
      });
    } catch (error) {
      await this.bot.sendMessage(chatId, `❌ 错误: ${error.message}`);
    }
  }

  // 删除模型确认
  async confirmDeleteModel(chatId, vendorId, modelId) {
    const keyboard = {
      inline_keyboard: [
        [
          { text: '✅ 确认删除', callback_data: `do_delete_model:${vendorId}:${modelId}` },
          { text: '❌ 取消', callback_data: `view_provider:${vendorId}` }
        ]
      ]
    };

    await this.bot.sendMessage(chatId,
      `⚠️ *确认删除模型*\n\n` +
      `供应商: \`${vendorId}\`\n` +
      `模型: \`${modelId}\`\n\n` +
      `此操作不可恢复，确定要删除吗？`,
      { parse_mode: 'Markdown', reply_markup: keyboard }
    );
  }

  // 执行删除模型
  async deleteModel(chatId, vendorId, modelId) {
    try {
      this.manager.deleteModel(vendorId, modelId);
      await this.bot.sendMessage(chatId, `✅ 已删除模型: \`${modelId}\``, { parse_mode: 'Markdown' });
      await this.showProviderDetail(chatId, vendorId);
    } catch (error) {
      await this.bot.sendMessage(chatId, `❌ 删除失败: ${error.message}`);
    }
  }

  // 删除供应商确认
  async confirmDeleteProvider(chatId, vendorId) {
    const keyboard = {
      inline_keyboard: [
        [
          { text: '✅ 确认删除', callback_data: `do_delete_provider:${vendorId}` },
          { text: '❌ 取消', callback_data: `view_provider:${vendorId}` }
        ]
      ]
    };

    await this.bot.sendMessage(chatId,
      `⚠️ *确认删除供应商*\n\n` +
      `供应商: \`${vendorId}\`\n\n` +
      `此操作将删除该供应商及其所有模型配置，不可恢复！\n` +
      `确定要删除吗？`,
      { parse_mode: 'Markdown', reply_markup: keyboard }
    );
  }

  // 执行删除供应商
  async deleteProvider(chatId, vendorId) {
    try {
      this.manager.deleteProvider(vendorId);
      await this.bot.sendMessage(chatId, `✅ 已删除供应商: \`${vendorId}\``, { parse_mode: 'Markdown' });
      await this.showProviderList(chatId);
    } catch (error) {
      await this.bot.sendMessage(chatId, `❌ 删除失败: ${error.message}`);
    }
  }

  // 重启 OpenClaw
  async restartOpenClaw(chatId) {
    await this.bot.sendMessage(chatId, '🔃 正在重启 OpenClaw...');

    try {
      const result = await this.manager.restartOpenClaw();
      if (result.success) {
        await this.bot.sendMessage(chatId, `✅ ${result.message}`);
      } else {
        await this.bot.sendMessage(chatId, `⚠️ ${result.message}`);
      }
    } catch (error) {
      await this.bot.sendMessage(chatId, `❌ 重启失败: ${error.message}`);
    }
  }

  // 处理回调查询
  async handleCallback(query) {
    const chatId = query.message.chat.id;
    const data = query.data;

    await this.bot.answerCallbackQuery(query.id);

    try {
      if (data === 'main_menu') {
        await this.showMainCard(query.message);
      } else if (data === 'list_providers') {
        await this.showProviderList(chatId);
      } else if (data === 'add_provider') {
        await this.startAddProvider(chatId);
      } else if (data === 'switch_provider') {
        await this.showSwitchMenu(chatId);
      } else if (data === 'restart_openclaw') {
        await this.restartOpenClaw(chatId);
      } else if (data.startsWith('view_provider:')) {
        const vendorId = data.split(':')[1];
        await this.showProviderDetail(chatId, vendorId);
      } else if (data.startsWith('switch_to:')) {
        const vendorId = data.split(':')[1];
        await this.switchProvider(chatId, vendorId);
      } else if (data.startsWith('add_model:')) {
        const vendorId = data.split(':')[1];
        await this.startAddModel(chatId, vendorId);
      } else if (data.startsWith('delete_model_menu:')) {
        const vendorId = data.split(':')[1];
        await this.showDeleteModelMenu(chatId, vendorId);
      } else if (data.startsWith('confirm_delete_model:')) {
        const [, vendorId, modelId] = data.split(':');
        await this.confirmDeleteModel(chatId, vendorId, modelId);
      } else if (data.startsWith('do_delete_model:')) {
        const [, vendorId, modelId] = data.split(':');
        await this.deleteModel(chatId, vendorId, modelId);
      } else if (data.startsWith('delete_provider:')) {
        const vendorId = data.split(':')[1];
        await this.confirmDeleteProvider(chatId, vendorId);
      } else if (data.startsWith('do_delete_provider:')) {
        const vendorId = data.split(':')[1];
        await this.deleteProvider(chatId, vendorId);
      }
    } catch (error) {
      await this.bot.sendMessage(chatId, `❌ 操作失败: ${error.message}`);
    }
  }

  start() {
    console.log('🤖 Telegram 卡片管理器已启动');
  }
}

// 启动
if (require.main === module) {
  const token = process.env.TELEGRAM_BOT_TOKEN;

  if (!token) {
    console.error('❌ 请设置环境变量 TELEGRAM_BOT_TOKEN');
    process.exit(1);
  }

  const cardManager = new TelegramCardManager(token);
  cardManager.start();
}

module.exports = TelegramCardManager;
