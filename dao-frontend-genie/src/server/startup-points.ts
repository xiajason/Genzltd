/**
 * 积分系统启动脚本
 * 初始化积分桥接服务和相关功能
 * 
 * @author DAO Genie Team
 * @version 1.0
 * @created 2025-10-01
 */

import { pointsBridgeService } from '@/server/services/points-bridge-service';

/**
 * 初始化积分系统
 */
export async function initializePointsSystem(): Promise<void> {
  try {
    console.log('🚀 初始化积分系统...');

    // 启动积分桥接服务
    await pointsBridgeService.start();
    
    console.log('✅ 积分系统初始化完成');
    console.log('📊 积分桥接服务已启动');
    console.log('🔄 自动同步已启用');

  } catch (error) {
    console.error('❌ 积分系统初始化失败:', error);
    throw error;
  }
}

/**
 * 停止积分系统
 */
export async function stopPointsSystem(): Promise<void> {
  try {
    console.log('🛑 停止积分系统...');

    // 停止积分桥接服务
    await pointsBridgeService.stop();
    
    console.log('✅ 积分系统已停止');

  } catch (error) {
    console.error('❌ 积分系统停止失败:', error);
    throw error;
  }
}

/**
 * 获取积分系统状态
 */
export async function getPointsSystemStatus(): Promise<any> {
  try {
    const status = await pointsBridgeService.getSyncStatus();
    return {
      status: 'running',
      details: status,
      timestamp: new Date().toISOString()
    };
  } catch (error) {
    return {
      status: 'error',
      error: error instanceof Error ? error.message : 'Unknown error',
      timestamp: new Date().toISOString()
    };
  }
}
