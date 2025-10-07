/**
 * 积分桥接服务
 * 实现Zervigo与DAO积分的双向同步机制
 * 
 * @author DAO Genie Team
 * @version 1.0
 * @created 2025-10-01
 */

import { db } from '@/server/db';
import axios from 'axios';

// 积分桥接服务配置
interface PointsBridgeConfig {
  zervigoApiUrl: string;
  zervigoApiToken: string;
  daoApiUrl: string;
  daoApiToken: string;
  syncInterval: number; // 同步间隔（毫秒）
  maxRetries: number; // 最大重试次数
}

// 积分数据接口
interface UnifiedPoints {
  id: number;
  userId: string;
  totalPoints: number;
  availablePoints: number;
  reputationPoints: number;
  contributionPoints: number;
  activityPoints: number;
  votingPower: number;
  governanceLevel: number;
  createdAt: Date;
  updatedAt: Date;
}

// Zervigo积分数据接口
interface ZervigoPoints {
  userId: string;
  balance: number;
  totalEarned: number;
  totalSpent: number;
  points: Array<{
    id: number;
    points: number;
    type: string;
    description: string;
    createdAt: string;
  }>;
}

// DAO积分数据接口
interface DAOPoints {
  userId: string;
  reputationScore: number;
  contributionPoints: number;
  votingPower: number;
}

// 同步日志接口
interface SyncLog {
  id: number;
  userId: string;
  syncType: 'zervigo_to_dao' | 'dao_to_zervigo' | 'bidirectional';
  syncStatus: 'pending' | 'success' | 'failed' | 'partial';
  syncData: any;
  errorMessage?: string;
  retryCount: number;
  createdAt: Date;
  completedAt?: Date;
}

export class PointsBridgeService {
  private config: PointsBridgeConfig;
  private isRunning: boolean = false;
  private syncTimer?: NodeJS.Timeout;

  constructor(config: PointsBridgeConfig) {
    this.config = config;
  }

  /**
   * 启动积分桥接服务
   */
  async start(): Promise<void> {
    if (this.isRunning) {
      console.log('积分桥接服务已在运行中');
      return;
    }

    console.log('启动积分桥接服务...');
    this.isRunning = true;

    // 立即执行一次全量同步
    await this.performFullSync();

    // 设置定时同步
    this.syncTimer = setInterval(async () => {
      try {
        await this.performIncrementalSync();
      } catch (error) {
        console.error('定时同步失败:', error);
      }
    }, this.config.syncInterval);

    console.log('积分桥接服务启动成功');
  }

  /**
   * 停止积分桥接服务
   */
  async stop(): Promise<void> {
    if (!this.isRunning) {
      console.log('积分桥接服务未在运行');
      return;
    }

    console.log('停止积分桥接服务...');
    this.isRunning = false;

    if (this.syncTimer) {
      clearInterval(this.syncTimer);
      this.syncTimer = undefined;
    }

    console.log('积分桥接服务已停止');
  }

  /**
   * 执行全量同步
   */
  async performFullSync(): Promise<void> {
    console.log('开始执行全量同步...');

    try {
      // 获取所有活跃用户
      const activeUsers = await this.getActiveUsers();
      console.log(`找到 ${activeUsers.length} 个活跃用户`);

      // 并发同步所有用户
      const syncPromises = activeUsers.map(userId => 
        this.bidirectionalSync(userId).catch(error => {
          console.error(`用户 ${userId} 同步失败:`, error);
          return { userId, error: error.message };
        })
      );

      const results = await Promise.allSettled(syncPromises);
      
      const successCount = results.filter(r => r.status === 'fulfilled').length;
      const failureCount = results.filter(r => r.status === 'rejected').length;

      console.log(`全量同步完成: 成功 ${successCount}, 失败 ${failureCount}`);

    } catch (error) {
      console.error('全量同步失败:', error);
      throw error;
    }
  }

  /**
   * 执行增量同步
   */
  async performIncrementalSync(): Promise<void> {
    console.log('开始执行增量同步...');

    try {
      // 获取最近更新的用户
      const recentlyUpdatedUsers = await this.getRecentlyUpdatedUsers();
      console.log(`找到 ${recentlyUpdatedUsers.length} 个最近更新的用户`);

      // 同步最近更新的用户
      for (const userId of recentlyUpdatedUsers) {
        try {
          await this.bidirectionalSync(userId);
        } catch (error) {
          console.error(`用户 ${userId} 增量同步失败:`, error);
        }
      }

      console.log('增量同步完成');

    } catch (error) {
      console.error('增量同步失败:', error);
    }
  }

  /**
   * Zervigo积分同步到DAO
   */
  async syncZervigoToDAO(userId: string): Promise<void> {
    try {
      console.log(`开始同步Zervigo积分到DAO: ${userId}`);

      // 1. 获取Zervigo用户积分
      const zervigoPoints = await this.getZervigoUserPoints(userId);
      
      // 2. 计算DAO积分权重
      const daoWeight = this.calculateDAOPointsWeight(zervigoPoints);
      
      // 3. 更新DAO成员积分
      await this.updateDAOMemberPoints(userId, daoWeight);
      
      // 4. 记录同步日志
      await this.logSyncOperation(userId, 'zervigo_to_dao', daoWeight, 'success');

      console.log(`Zervigo积分同步到DAO成功: ${userId}`);

    } catch (error) {
      console.error(`同步Zervigo到DAO失败: ${error.message}`);
      await this.logSyncOperation(userId, 'zervigo_to_dao', null, 'failed', error.message);
      throw error;
    }
  }

  /**
   * DAO积分同步到Zervigo
   */
  async syncDAOToZervigo(userId: string): Promise<void> {
    try {
      console.log(`开始同步DAO积分到Zervigo: ${userId}`);

      // 1. 获取DAO成员积分
      const daoPoints = await this.getDAOMemberPoints(userId);
      
      // 2. 转换为Zervigo积分
      const zervigoPoints = this.convertToZervigoPoints(daoPoints);
      
      // 3. 更新Zervigo用户积分
      await this.updateZervigoUserPoints(userId, zervigoPoints);
      
      // 4. 记录同步日志
      await this.logSyncOperation(userId, 'dao_to_zervigo', zervigoPoints, 'success');

      console.log(`DAO积分同步到Zervigo成功: ${userId}`);

    } catch (error) {
      console.error(`同步DAO到Zervigo失败: ${error.message}`);
      await this.logSyncOperation(userId, 'dao_to_zervigo', null, 'failed', error.message);
      throw error;
    }
  }

  /**
   * 双向同步
   */
  async bidirectionalSync(userId: string): Promise<void> {
    try {
      console.log(`开始双向同步: ${userId}`);

      await Promise.all([
        this.syncZervigoToDAO(userId),
        this.syncDAOToZervigo(userId)
      ]);

      await this.logSyncOperation(userId, 'bidirectional', null, 'success');

      console.log(`双向同步成功: ${userId}`);

    } catch (error) {
      console.error(`双向同步失败: ${error.message}`);
      await this.logSyncOperation(userId, 'bidirectional', null, 'failed', error.message);
      throw error;
    }
  }

  /**
   * 获取Zervigo用户积分
   */
  private async getZervigoUserPoints(userId: string): Promise<ZervigoPoints> {
    try {
      const response = await axios.get(`${this.config.zervigoApiUrl}/api/v1/points/user/${userId}/balance`, {
        headers: {
          'Authorization': `Bearer ${this.config.zervigoApiToken}`,
          'Content-Type': 'application/json'
        },
        timeout: 10000
      });

      if (response.data.success) {
        return response.data.data;
      } else {
        throw new Error(`获取Zervigo积分失败: ${response.data.message}`);
      }

    } catch (error) {
      if (axios.isAxiosError(error)) {
        if (error.response?.status === 404) {
          // 用户不存在，返回默认积分
          return {
            userId,
            balance: 100,
            totalEarned: 100,
            totalSpent: 0,
            points: []
          };
        }
        throw new Error(`Zervigo API调用失败: ${error.message}`);
      }
      throw error;
    }
  }

  /**
   * 获取DAO成员积分
   */
  private async getDAOMemberPoints(userId: string): Promise<DAOPoints> {
    const member = await db.dAOMember.findUnique({
      where: { user_id: userId },
      select: {
        reputation_score: true,
        contribution_points: true,
        voting_power: true
      }
    });

    if (!member) {
      throw new Error(`DAO成员不存在: ${userId}`);
    }

    return {
      userId,
      reputationScore: member.reputation_score,
      contributionPoints: member.contribution_points,
      votingPower: member.voting_power
    };
  }

  /**
   * 计算DAO积分权重
   */
  private calculateDAOPointsWeight(zervigoPoints: ZervigoPoints): Partial<UnifiedPoints> {
    // 基于Zervigo积分计算DAO权重
    const totalPoints = zervigoPoints.balance;
    
    // 积分分配策略
    const reputationPoints = Math.min(Math.floor(totalPoints * 0.3), 200); // 最多200分声誉
    const contributionPoints = Math.min(Math.floor(totalPoints * 0.7), 500); // 最多500分贡献
    const activityPoints = Math.min(Math.floor(totalPoints * 0.1), 100); // 最多100分活动

    // 计算投票权重
    const votingPower = Math.floor(
      (reputationPoints * 0.3 + contributionPoints * 0.5 + activityPoints * 0.2) / 10
    );

    return {
      totalPoints,
      availablePoints: totalPoints,
      reputationPoints,
      contributionPoints,
      activityPoints,
      votingPower: Math.max(votingPower, 1), // 最少1分投票权重
      governanceLevel: Math.min(Math.floor(totalPoints / 100), 10) // 最多10级治理等级
    };
  }

  /**
   * 转换为Zervigo积分
   */
  private convertToZervigoPoints(daoPoints: DAOPoints): { points: number; type: string } {
    // 基于DAO积分计算Zervigo积分
    const totalDAOValue = daoPoints.reputationScore + daoPoints.contributionPoints;
    const zervigoPoints = Math.floor(totalDAOValue * 1.5); // DAO积分价值更高

    return {
      points: zervigoPoints,
      type: 'dao_governance'
    };
  }

  /**
   * 更新DAO成员积分
   */
  private async updateDAOMemberPoints(userId: string, daoWeight: Partial<UnifiedPoints>): Promise<void> {
    // 更新统一积分表
    await db.unifiedPoints.upsert({
      where: { user_id: userId },
      update: {
        ...daoWeight,
        updated_at: new Date()
      },
      create: {
        user_id: userId,
        ...daoWeight
      }
    });

    // 更新DAO成员表
    await db.dAOMember.update({
      where: { user_id: userId },
      data: {
        reputation_score: daoWeight.reputationPoints || 0,
        contribution_points: daoWeight.contributionPoints || 0,
        voting_power: daoWeight.votingPower || 1
      }
    });
  }

  /**
   * 更新Zervigo用户积分
   */
  private async updateZervigoUserPoints(userId: string, zervigoPoints: { points: number; type: string }): Promise<void> {
    try {
      await axios.post(`${this.config.zervigoApiUrl}/api/v1/points/award`, {
        user_id: userId,
        points: zervigoPoints.points,
        type: zervigoPoints.type,
        description: `DAO治理积分转换: ${zervigoPoints.points}积分`
      }, {
        headers: {
          'Authorization': `Bearer ${this.config.zervigoApiToken}`,
          'Content-Type': 'application/json'
        },
        timeout: 10000
      });

    } catch (error) {
      if (axios.isAxiosError(error)) {
        throw new Error(`Zervigo积分更新失败: ${error.response?.data?.message || error.message}`);
      }
      throw error;
    }
  }

  /**
   * 记录同步操作日志
   */
  private async logSyncOperation(
    userId: string, 
    syncType: 'zervigo_to_dao' | 'dao_to_zervigo' | 'bidirectional',
    syncData: any,
    status: 'success' | 'failed',
    errorMessage?: string
  ): Promise<void> {
    await db.pointsSyncLogs.create({
      data: {
        user_id: userId,
        sync_type: syncType,
        sync_status: status,
        sync_data: syncData,
        error_message: errorMessage,
        completed_at: status === 'success' ? new Date() : null
      }
    });
  }

  /**
   * 获取活跃用户列表
   */
  private async getActiveUsers(): Promise<string[]> {
    const members = await db.dAOMember.findMany({
      where: { status: 'ACTIVE' },
      select: { user_id: true }
    });

    return members.map(member => member.user_id);
  }

  /**
   * 获取最近更新的用户
   */
  private async getRecentlyUpdatedUsers(): Promise<string[]> {
    // 获取最近1小时更新的用户
    const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);

    const members = await db.dAOMember.findMany({
      where: {
        status: 'ACTIVE',
        updated_at: {
          gte: oneHourAgo
        }
      },
      select: { user_id: true }
    });

    return members.map(member => member.user_id);
  }

  /**
   * 获取同步状态
   */
  async getSyncStatus(): Promise<{
    isRunning: boolean;
    lastSyncTime?: Date;
    totalUsers: number;
    syncStats: {
      success: number;
      failed: number;
      pending: number;
    };
  }> {
    const [totalUsers, lastSyncLog] = await Promise.all([
      db.dAOMember.count({ where: { status: 'ACTIVE' } }),
      db.pointsSyncLogs.findFirst({
        orderBy: { created_at: 'desc' }
      })
    ]);

    const syncStats = await db.pointsSyncLogs.groupBy({
      by: ['sync_status'],
      _count: { id: true }
    });

    const stats = {
      success: 0,
      failed: 0,
      pending: 0
    };

    syncStats.forEach(stat => {
      if (stat.sync_status === 'success') stats.success = stat._count.id;
      else if (stat.sync_status === 'failed') stats.failed = stat._count.id;
      else if (stat.sync_status === 'pending') stats.pending = stat._count.id;
    });

    return {
      isRunning: this.isRunning,
      lastSyncTime: lastSyncLog?.completed_at,
      totalUsers,
      syncStats: stats
    };
  }
}

// 默认配置
const defaultConfig: PointsBridgeConfig = {
  zervigoApiUrl: process.env.ZERVIGO_API_URL || 'http://localhost:7536',
  zervigoApiToken: process.env.ZERVIGO_API_TOKEN || 'zervigo_token_2024',
  daoApiUrl: process.env.DAO_API_URL || 'http://localhost:3000',
  daoApiToken: process.env.DAO_API_TOKEN || 'dao_token_2024',
  syncInterval: 5 * 60 * 1000, // 5分钟
  maxRetries: 3
};

// 创建全局实例
export const pointsBridgeService = new PointsBridgeService(defaultConfig);
