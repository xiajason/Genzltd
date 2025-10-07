/**
 * 统一积分API路由
 * 提供积分管理、奖励、历史查询等功能
 * 
 * @author DAO Genie Team
 * @version 1.0
 * @created 2025-10-01
 */

import { z } from "zod";
import { createTRPCRouter, publicProcedure } from "@/server/api/trpc";
import { db } from "@/server/db";
import { pointsBridgeService } from "@/server/services/points-bridge-service";

// 积分奖励输入验证
const awardPointsSchema = z.object({
  userId: z.string().min(1, "用户ID不能为空"),
  pointsChange: z.number().int("积分变动必须是整数"),
  changeType: z.enum(['earn', 'spend', 'transfer', 'adjust']),
  reason: z.string().min(1, "积分变动原因不能为空"),
  sourceSystem: z.enum(['zervigo', 'dao', 'system']),
  referenceType: z.string().optional(),
  referenceId: z.string().optional(),
  description: z.string().optional()
});

// 积分查询输入验证
const getPointsSchema = z.object({
  userId: z.string().min(1, "用户ID不能为空")
});

// 积分历史查询输入验证
const getPointsHistorySchema = z.object({
  userId: z.string().min(1, "用户ID不能为空"),
  page: z.number().int().min(1).default(1),
  limit: z.number().int().min(1).max(100).default(20),
  sourceSystem: z.enum(['zervigo', 'dao', 'system']).optional(),
  changeType: z.enum(['earn', 'spend', 'transfer', 'adjust']).optional()
});

// 积分统计查询输入验证
const getPointsStatsSchema = z.object({
  userId: z.string().min(1, "用户ID不能为空"),
  period: z.enum(['day', 'week', 'month', 'year']).default('month')
});

export const pointsRouter = createTRPCRouter({
  /**
   * 获取用户积分
   */
  getUserPoints: publicProcedure
    .input(getPointsSchema)
    .query(async ({ input }) => {
      try {
        const points = await db.unifiedPoints.findUnique({
          where: { user_id: input.userId }
        });

        if (!points) {
          // 如果用户积分不存在，创建默认积分
          const defaultPoints = await db.unifiedPoints.create({
            data: {
              user_id: input.userId,
              total_points: 100,
              available_points: 100,
              reputation_points: 80,
              contribution_points: 20,
              activity_points: 0,
              voting_power: 8,
              governance_level: 1
            }
          });
          return defaultPoints;
        }

        return points;
      } catch (error) {
        console.error('获取用户积分失败:', error);
        throw new Error('获取用户积分失败');
      }
    }),

  /**
   * 奖励积分
   */
  awardPoints: publicProcedure
    .input(awardPointsSchema)
    .mutation(async ({ input }) => {
      try {
        // 1. 获取当前积分
        const currentPoints = await db.unifiedPoints.findUnique({
          where: { user_id: input.userId }
        });

        if (!currentPoints) {
          throw new Error('用户积分不存在');
        }

        // 2. 计算新积分
        const newTotalPoints = Math.max(0, currentPoints.total_points + input.pointsChange);
        const newAvailablePoints = Math.max(0, currentPoints.available_points + input.pointsChange);

        // 3. 根据积分类型更新对应字段
        let updateData: any = {
          total_points: newTotalPoints,
          available_points: newAvailablePoints,
          updated_at: new Date()
        };

        // 根据积分类型更新具体字段
        switch (input.sourceSystem) {
          case 'zervigo':
            if (input.pointsChange > 0) {
              updateData.contribution_points = Math.max(0, currentPoints.contribution_points + input.pointsChange);
            }
            break;
          case 'dao':
            if (input.pointsChange > 0) {
              updateData.reputation_points = Math.max(0, currentPoints.reputation_points + input.pointsChange);
            }
            break;
          case 'system':
            if (input.pointsChange > 0) {
              updateData.activity_points = Math.max(0, currentPoints.activity_points + input.pointsChange);
            }
            break;
        }

        // 4. 更新积分
        const updatedPoints = await db.unifiedPoints.update({
          where: { user_id: input.userId },
          data: updateData
        });

        // 5. 记录积分历史
        await db.pointsHistory.create({
          data: {
            user_id: input.userId,
            points_change: input.pointsChange,
            change_type: input.changeType,
            reason: input.reason,
            description: input.description,
            source_system: input.sourceSystem,
            reference_type: input.referenceType,
            reference_id: input.referenceId ? parseInt(input.referenceId) : null,
            balance_before: currentPoints.total_points,
            balance_after: newTotalPoints,
            voting_power_before: currentPoints.voting_power,
            voting_power_after: updatedPoints.voting_power
          }
        });

        // 6. 触发积分同步
        try {
          await pointsBridgeService.bidirectionalSync(input.userId);
        } catch (syncError) {
          console.error('积分同步失败:', syncError);
          // 同步失败不影响积分奖励结果
        }

        return {
          success: true,
          data: updatedPoints,
          message: '积分奖励成功'
        };

      } catch (error) {
        console.error('积分奖励失败:', error);
        throw new Error(error instanceof Error ? error.message : '积分奖励失败');
      }
    }),

  /**
   * 获取积分历史
   */
  getPointsHistory: publicProcedure
    .input(getPointsHistorySchema)
    .query(async ({ input }) => {
      try {
        const offset = (input.page - 1) * input.limit;

        const whereClause: any = {
          user_id: input.userId
        };

        if (input.sourceSystem) {
          whereClause.source_system = input.sourceSystem;
        }

        if (input.changeType) {
          whereClause.change_type = input.changeType;
        }

        const [history, total] = await Promise.all([
          db.pointsHistory.findMany({
            where: whereClause,
            orderBy: { created_at: 'desc' },
            skip: offset,
            take: input.limit
          }),
          db.pointsHistory.count({
            where: whereClause
          })
        ]);

        return {
          data: history,
          total,
          page: input.page,
          limit: input.limit,
          totalPages: Math.ceil(total / input.limit)
        };

      } catch (error) {
        console.error('获取积分历史失败:', error);
        throw new Error('获取积分历史失败');
      }
    }),

  /**
   * 获取积分统计
   */
  getPointsStats: publicProcedure
    .input(getPointsStatsSchema)
    .query(async ({ input }) => {
      try {
        // 计算时间范围
        const now = new Date();
        let startDate: Date;

        switch (input.period) {
          case 'day':
            startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate());
            break;
          case 'week':
            startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
            break;
          case 'month':
            startDate = new Date(now.getFullYear(), now.getMonth(), 1);
            break;
          case 'year':
            startDate = new Date(now.getFullYear(), 0, 1);
            break;
          default:
            startDate = new Date(now.getFullYear(), now.getMonth(), 1);
        }

        const [totalEarned, totalSpent, monthlyStats, sourceStats, recentActivity] = await Promise.all([
          // 总获得积分
          db.pointsHistory.aggregate({
            where: {
              user_id: input.userId,
              change_type: 'earn',
              created_at: { gte: startDate }
            },
            _sum: { points_change: true }
          }),

          // 总消费积分
          db.pointsHistory.aggregate({
            where: {
              user_id: input.userId,
              change_type: 'spend',
              created_at: { gte: startDate }
            },
            _sum: { points_change: true }
          }),

          // 月度统计
          db.pointsHistory.groupBy({
            by: ['change_type'],
            where: {
              user_id: input.userId,
              created_at: { gte: startDate }
            },
            _sum: { points_change: true },
            _count: { id: true }
          }),

          // 来源统计
          db.pointsHistory.groupBy({
            by: ['source_system'],
            where: {
              user_id: input.userId,
              created_at: { gte: startDate }
            },
            _sum: { points_change: true },
            _count: { id: true }
          }),

          // 最近活动
          db.pointsHistory.findMany({
            where: {
              user_id: input.userId,
              created_at: { gte: startDate }
            },
            orderBy: { created_at: 'desc' },
            take: 10
          })
        ]);

        return {
          totalEarned: totalEarned._sum.points_change || 0,
          totalSpent: totalSpent._sum.points_change || 0,
          monthlyStats,
          sourceStats,
          recentActivity,
          period: input.period
        };

      } catch (error) {
        console.error('获取积分统计失败:', error);
        throw new Error('获取积分统计失败');
      }
    }),

  /**
   * 获取积分排行榜
   */
  getPointsLeaderboard: publicProcedure
    .input(z.object({
      type: z.enum(['total', 'reputation', 'contribution', 'activity', 'voting_power']).default('total'),
      limit: z.number().int().min(1).max(100).default(10)
    }))
    .query(async ({ input }) => {
      try {
        const orderByField = `${input.type}_points` as keyof typeof db.unifiedPoints.fields;
        
        const leaderboard = await db.unifiedPoints.findMany({
          orderBy: { [orderByField]: 'desc' },
          take: input.limit,
          include: {
            // 这里需要根据实际的关联关系调整
            // member: {
            //   select: {
            //     username: true,
            //     avatar_url: true
            //   }
            // }
          }
        });

        return leaderboard;

      } catch (error) {
        console.error('获取积分排行榜失败:', error);
        throw new Error('获取积分排行榜失败');
      }
    }),

  /**
   * 手动触发积分同步
   */
  triggerSync: publicProcedure
    .input(z.object({
      userId: z.string().optional(),
      syncType: z.enum(['zervigo_to_dao', 'dao_to_zervigo', 'bidirectional']).default('bidirectional')
    }))
    .mutation(async ({ input }) => {
      try {
        if (input.userId) {
          // 同步特定用户
          if (input.syncType === 'zervigo_to_dao') {
            await pointsBridgeService.syncZervigoToDAO(input.userId);
          } else if (input.syncType === 'dao_to_zervigo') {
            await pointsBridgeService.syncDAOToZervigo(input.userId);
          } else {
            await pointsBridgeService.bidirectionalSync(input.userId);
          }
        } else {
          // 全量同步
          await pointsBridgeService.performFullSync();
        }

        return {
          success: true,
          message: '积分同步成功'
        };

      } catch (error) {
        console.error('积分同步失败:', error);
        throw new Error(error instanceof Error ? error.message : '积分同步失败');
      }
    }),

  /**
   * 获取同步状态
   */
  getSyncStatus: publicProcedure
    .query(async () => {
      try {
        const status = await pointsBridgeService.getSyncStatus();
        return status;

      } catch (error) {
        console.error('获取同步状态失败:', error);
        throw new Error('获取同步状态失败');
      }
    }),

  /**
   * 获取积分奖励规则
   */
  getRewardRules: publicProcedure
    .input(z.object({
      sourceSystem: z.enum(['zervigo', 'dao', 'system']).optional(),
      isActive: z.boolean().optional()
    }))
    .query(async ({ input }) => {
      try {
        const whereClause: any = {};

        if (input.sourceSystem) {
          whereClause.source_system = input.sourceSystem;
        }

        if (input.isActive !== undefined) {
          whereClause.is_active = input.isActive;
        }

        const rules = await db.pointsRewardRules.findMany({
          where: whereClause,
          orderBy: { created_at: 'desc' }
        });

        return rules;

      } catch (error) {
        console.error('获取积分奖励规则失败:', error);
        throw new Error('获取积分奖励规则失败');
      }
    }),

  /**
   * 更新积分奖励规则
   */
  updateRewardRule: publicProcedure
    .input(z.object({
      ruleId: z.string(),
      isActive: z.boolean()
    }))
    .mutation(async ({ input }) => {
      try {
        const updatedRule = await db.pointsRewardRules.update({
          where: { rule_id: input.ruleId },
          data: { is_active: input.isActive }
        });

        return {
          success: true,
          data: updatedRule,
          message: '积分奖励规则更新成功'
        };

      } catch (error) {
        console.error('更新积分奖励规则失败:', error);
        throw new Error('更新积分奖励规则失败');
      }
    })
});
