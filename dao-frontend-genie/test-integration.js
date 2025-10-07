// 测试DAO与Zervigo集成功能
const { triggerGovernanceStatsSync } = require('./src/server/cron/governance-stats-sync.ts');

async function testIntegration() {
  console.log('🧪 开始测试DAO-Zervigo集成...');
  
  try {
    // 触发治理统计同步
    await triggerGovernanceStatsSync();
    console.log('✅ 治理统计同步测试完成');
    
    console.log('🎉 集成测试成功！');
  } catch (error) {
    console.error('❌ 集成测试失败:', error);
  }
}

testIntegration();
