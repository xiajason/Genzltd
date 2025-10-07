import { startProposalChecker } from './cron/proposal-checker';
import { startGovernanceStatsSync } from './cron/governance-stats-sync';
import { startGovernanceNotification } from './cron/governance-notification';
import { initializePointsSystem } from './startup-points';

// 应用启动时初始化
export const initializeApp = async () => {
  console.log('🚀 初始化DAO Genie应用...');
  
  // 启动提案状态检查器
  startProposalChecker();
  
  // 启动治理统计同步器
  startGovernanceStatsSync();
  
  // 启动治理通知器
  startGovernanceNotification();
  
  // 初始化积分系统
  await initializePointsSystem();
  
  console.log('✅ DAO Genie应用初始化完成');
  console.log('📊 已启用Zervigo统计服务集成');
  console.log('📢 已启用Zervigo通知服务集成');
  console.log('🎯 已启用Zervigo Banner服务集成');
  console.log('🔄 已启用积分桥接系统');
};

// 在模块加载时自动初始化（仅在服务器端）
if (typeof window === 'undefined') {
  initializeApp();
}
