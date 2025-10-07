import { z } from "zod";
import { createTRPCRouter, protectedProcedure, publicProcedure } from "@/server/api/trpc";
import { TRPCError } from "@trpc/server";

// 智能治理API - 实现DAO社区决策机制的智能化

// 决策执行类型
const DecisionExecutionType = {
  FUNDING: "funding",           // 资金分配
  CONFIG_CHANGE: "config_change", // 配置变更
  MEMBER_MANAGEMENT: "member_management", // 成员管理
  SYSTEM_UPGRADE: "system_upgrade", // 系统升级
  POLICY_CHANGE: "policy_change", // 政策变更
} as const;

// 决策执行状态
const DecisionExecutionStatus = {
  PENDING: "pending",           // 等待执行
  EXECUTING: "executing",       // 执行中
  COMPLETED: "completed",       // 已完成
  FAILED: "failed",            // 执行失败
  CANCELLED: "cancelled",      // 已取消
} as const;

// 输入验证Schema
const createDecisionRuleSchema = z.object({
  ruleName: z.string().min(1, "规则名称不能为空"),
  description: z.string().optional(),
  triggerConditions: z.object({
    proposalType: z.enum(["GOVERNANCE", "FUNDING", "TECHNICAL", "POLICY"]),
    minVoteThreshold: z.number().min(0).max(100).default(50),
    minParticipationRate: z.number().min(0).max(100).default(30),
    requiredRoles: z.array(z.string()).optional(),
  }),
  executionActions: z.array(z.object({
    actionType: z.enum(["FUNDING", "CONFIG_CHANGE", "MEMBER_MANAGEMENT", "SYSTEM_UPGRADE", "POLICY_CHANGE"]),
    actionConfig: z.record(z.any()),
    executionDelay: z.number().min(0).default(0), // 延迟执行时间(小时)
  })),
  isActive: z.boolean().default(true),
});

const executeDecisionSchema = z.object({
  proposalId: z.string().min(1, "提案ID不能为空"),
  executionType: z.enum(["AUTO", "MANUAL", "SCHEDULED"]),
  scheduledTime: z.date().optional(),
});

export const smartGovernanceRouter = createTRPCRouter({
  // 创建智能决策规则
  createDecisionRule: protectedProcedure
    .input(createDecisionRuleSchema)
    .mutation(async ({ input, ctx }) => {
      try {
        // 检查用户是否有创建决策规则的权限
        const hasPermission = await checkUserPermission(
          ctx.db,
          ctx.session.user.id,
          "SYSTEM",
          "CREATE"
        );
        
        if (!hasPermission) {
          throw new TRPCError({
            code: "FORBIDDEN",
            message: "无权限创建决策规则",
          });
        }

        const decisionRule = await ctx.db.dAODecisionRule.create({
          data: {
            ruleName: input.ruleName,
            description: input.description,
            triggerConditions: input.triggerConditions,
            executionActions: input.executionActions,
            isActive: input.isActive,
            createdBy: ctx.session.user.id,
          },
        });

        // 记录审计日志
        await ctx.db.dAOAuditLog.create({
          data: {
            eventId: `audit_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
            eventType: "SYSTEM_CONFIG",
            userId: ctx.session.user.id,
            username: ctx.session.user.name || "系统用户",
            resourceType: "DECISION_RULE",
            resourceId: decisionRule.id.toString(),
            action: "CREATE",
            details: {
              ruleName: input.ruleName,
              triggerConditions: input.triggerConditions,
              executionActions: input.executionActions,
            },
          },
        });

        return { success: true, data: decisionRule, message: "智能决策规则创建成功" };
      } catch (error) {
        console.error("创建决策规则失败:", error);
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "创建决策规则失败",
        });
      }
    }),

  // 获取智能决策规则列表
  getDecisionRules: protectedProcedure
    .query(async ({ ctx }) => {
      try {
        const rules = await ctx.db.dAODecisionRule.findMany({
          where: { isActive: true },
          orderBy: { createdAt: "desc" },
        });

        return { success: true, data: rules };
      } catch (error) {
        console.error("获取决策规则失败:", error);
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "获取决策规则失败",
        });
      }
    }),

  // 执行智能决策
  executeDecision: protectedProcedure
    .input(executeDecisionSchema)
    .mutation(async ({ input, ctx }) => {
      try {
        // 获取提案信息
        const proposal = await ctx.db.dAOProposal.findUnique({
          where: { proposalId: input.proposalId },
          include: {
            votes: true,
            proposer: true,
          },
        });

        if (!proposal) {
          throw new TRPCError({
            code: "NOT_FOUND",
            message: "提案未找到",
          });
        }

        // 检查提案状态
        if (proposal.status !== "PASSED") {
          throw new TRPCError({
            code: "BAD_REQUEST",
            message: "提案未通过，无法执行",
          });
        }

        // 获取相关的决策规则
        const applicableRules = await ctx.db.dAODecisionRule.findMany({
          where: {
            isActive: true,
            triggerConditions: {
              path: ["proposalType"],
              equals: proposal.proposalType,
            },
          },
        });

        if (applicableRules.length === 0) {
          throw new TRPCError({
            code: "NOT_FOUND",
            message: "未找到适用的决策规则",
          });
        }

        // 创建决策执行记录
        const decisionExecution = await ctx.db.dAODecisionExecution.create({
          data: {
            proposalId: proposal.proposalId,
            executionType: input.executionType,
            status: "PENDING",
            scheduledTime: input.scheduledTime,
            executionRules: applicableRules.map(rule => ({
              ruleId: rule.id,
              ruleName: rule.ruleName,
              executionActions: rule.executionActions,
            })),
            createdBy: ctx.session.user.id,
          },
        });

        // 根据执行类型处理
        if (input.executionType === "AUTO") {
          // 自动执行
          await executeDecisionActions(decisionExecution, proposal);
        } else if (input.executionType === "SCHEDULED" && input.scheduledTime) {
          // 定时执行
          await scheduleDecisionExecution(decisionExecution, input.scheduledTime);
        }

        return { 
          success: true, 
          data: decisionExecution, 
          message: "智能决策执行已启动" 
        };
      } catch (error) {
        console.error("执行智能决策失败:", error);
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "执行智能决策失败",
        });
      }
    }),

  // 获取决策执行状态
  getDecisionExecutionStatus: protectedProcedure
    .input(z.object({ proposalId: z.string() }))
    .query(async ({ input, ctx }) => {
      try {
        const execution = await ctx.db.dAODecisionExecution.findFirst({
          where: { proposalId: input.proposalId },
          include: {
            executionLogs: true,
          },
          orderBy: { createdAt: "desc" },
        });

        return { success: true, data: execution };
      } catch (error) {
        console.error("获取决策执行状态失败:", error);
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "获取决策执行状态失败",
        });
      }
    }),

  // 获取智能决策统计
  getSmartGovernanceStats: protectedProcedure
    .input(z.object({
      startDate: z.date().optional(),
      endDate: z.date().optional(),
    }))
    .query(async ({ input, ctx }) => {
      try {
        const where: any = {};
        
        if (input.startDate || input.endDate) {
          where.createdAt = {};
          if (input.startDate) where.createdAt.gte = input.startDate;
          if (input.endDate) where.createdAt.lte = input.endDate;
        }

        const [
          totalExecutions,
          completedExecutions,
          failedExecutions,
          pendingExecutions,
          executionTypes,
        ] = await Promise.all([
          ctx.db.dAODecisionExecution.count({ where }),
          ctx.db.dAODecisionExecution.count({ where: { ...where, status: "COMPLETED" } }),
          ctx.db.dAODecisionExecution.count({ where: { ...where, status: "FAILED" } }),
          ctx.db.dAODecisionExecution.count({ where: { ...where, status: "PENDING" } }),
          ctx.db.dAODecisionExecution.groupBy({
            by: ['executionType'],
            where,
            _count: { executionType: true },
          }),
        ]);

        return {
          success: true,
          data: {
            overview: {
              totalExecutions,
              completedExecutions,
              failedExecutions,
              pendingExecutions,
              successRate: totalExecutions > 0 ? (completedExecutions / totalExecutions * 100).toFixed(2) : 0,
            },
            executionTypes,
          },
        };
      } catch (error) {
        console.error("获取智能治理统计失败:", error);
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "获取智能治理统计失败",
        });
      }
    }),

  // 取消决策执行
  cancelDecisionExecution: protectedProcedure
    .input(z.object({ executionId: z.string() }))
    .mutation(async ({ input, ctx }) => {
      try {
        const execution = await ctx.db.dAODecisionExecution.update({
          where: { id: BigInt(input.executionId) },
          data: { 
            status: "CANCELLED",
            cancelledBy: ctx.session.user.id,
            cancelledAt: new Date(),
          },
        });

        // 记录审计日志
        await ctx.db.dAOAuditLog.create({
          data: {
            eventId: `audit_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
            eventType: "SYSTEM_CONFIG",
            userId: ctx.session.user.id,
            username: ctx.session.user.name || "系统用户",
            resourceType: "DECISION_EXECUTION",
            resourceId: input.executionId,
            action: "CANCEL",
            details: { executionId: input.executionId },
          },
        });

        return { success: true, data: execution, message: "决策执行已取消" };
      } catch (error) {
        console.error("取消决策执行失败:", error);
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "取消决策执行失败",
        });
      }
    }),
});

// 智能决策执行引擎
async function executeDecisionActions(execution: any, proposal: any) {
  try {
    // 更新执行状态为执行中
    await execution.db.dAODecisionExecution.update({
      where: { id: execution.id },
      data: { 
        status: "EXECUTING",
        startedAt: new Date(),
      },
    });

    // 记录执行开始日志
    await execution.db.dAODecisionExecutionLog.create({
      data: {
        executionId: execution.id,
        logLevel: "INFO",
        message: "开始执行智能决策",
        details: { proposalId: proposal.proposalId },
      },
    });

    // 执行每个规则的动作
    for (const rule of execution.executionRules) {
      for (const action of rule.executionActions) {
        await executeAction(action, proposal, execution);
      }
    }

    // 更新执行状态为完成
    await execution.db.dAODecisionExecution.update({
      where: { id: execution.id },
      data: { 
        status: "COMPLETED",
        completedAt: new Date(),
      },
    });

    // 记录执行完成日志
    await execution.db.dAODecisionExecutionLog.create({
      data: {
        executionId: execution.id,
        logLevel: "INFO",
        message: "智能决策执行完成",
        details: { proposalId: proposal.proposalId },
      },
    });

  } catch (error) {
    // 更新执行状态为失败
    await execution.db.dAODecisionExecution.update({
      where: { id: execution.id },
      data: { 
        status: "FAILED",
        errorMessage: error instanceof Error ? error.message : "未知错误",
        failedAt: new Date(),
      },
    });

    // 记录执行失败日志
    await execution.db.dAODecisionExecutionLog.create({
      data: {
        executionId: execution.id,
        logLevel: "ERROR",
        message: "智能决策执行失败",
        details: { 
          error: error instanceof Error ? error.message : "未知错误",
          proposalId: proposal.proposalId,
        },
      },
    });
  }
}

// 执行具体动作
async function executeAction(action: any, proposal: any, execution: any) {
  try {
    switch (action.actionType) {
      case "FUNDING":
        await executeFundingAction(action, proposal, execution);
        break;
      case "CONFIG_CHANGE":
        await executeConfigChangeAction(action, proposal, execution);
        break;
      case "MEMBER_MANAGEMENT":
        await executeMemberManagementAction(action, proposal, execution);
        break;
      case "SYSTEM_UPGRADE":
        await executeSystemUpgradeAction(action, proposal, execution);
        break;
      case "POLICY_CHANGE":
        await executePolicyChangeAction(action, proposal, execution);
        break;
      default:
        throw new Error(`未知的动作类型: ${action.actionType}`);
    }
  } catch (error) {
    console.error(`执行动作失败: ${action.actionType}`, error);
    throw error;
  }
}

// 资金分配动作
async function executeFundingAction(action: any, proposal: any, execution: any) {
  // 实现资金分配逻辑
  const { recipient, amount, currency } = action.actionConfig;
  
  // 记录执行日志
  await execution.db.dAODecisionExecutionLog.create({
    data: {
      executionId: execution.id,
      logLevel: "INFO",
      message: "执行资金分配",
      details: { recipient, amount, currency },
    },
  });

  // TODO: 实现实际的资金分配逻辑
  console.log(`💰 执行资金分配: ${amount} ${currency} 给 ${recipient}`);
}

// 配置变更动作
async function executeConfigChangeAction(action: any, proposal: any, execution: any) {
  // 实现配置变更逻辑
  const { configKey, configValue } = action.actionConfig;
  
  // 记录执行日志
  await execution.db.dAODecisionExecutionLog.create({
    data: {
      executionId: execution.id,
      logLevel: "INFO",
      message: "执行配置变更",
      details: { configKey, configValue },
    },
  });

  // TODO: 实现实际的配置变更逻辑
  console.log(`⚙️ 执行配置变更: ${configKey} = ${configValue}`);
}

// 成员管理动作
async function executeMemberManagementAction(action: any, proposal: any, execution: any) {
  // 实现成员管理逻辑
  const { actionType, memberId, roleId } = action.actionConfig;
  
  // 记录执行日志
  await execution.db.dAODecisionExecutionLog.create({
    data: {
      executionId: execution.id,
      logLevel: "INFO",
      message: "执行成员管理",
      details: { actionType, memberId, roleId },
    },
  });

  // TODO: 实现实际的成员管理逻辑
  console.log(`👥 执行成员管理: ${actionType} 成员 ${memberId}`);
}

// 系统升级动作
async function executeSystemUpgradeAction(action: any, proposal: any, execution: any) {
  // 实现系统升级逻辑
  const { upgradeType, version } = action.actionConfig;
  
  // 记录执行日志
  await execution.db.dAODecisionExecutionLog.create({
    data: {
      executionId: execution.id,
      logLevel: "INFO",
      message: "执行系统升级",
      details: { upgradeType, version },
    },
  });

  // TODO: 实现实际的系统升级逻辑
  console.log(`🚀 执行系统升级: ${upgradeType} 版本 ${version}`);
}

// 政策变更动作
async function executePolicyChangeAction(action: any, proposal: any, execution: any) {
  // 实现政策变更逻辑
  const { policyType, policyContent } = action.actionConfig;
  
  // 记录执行日志
  await execution.db.dAODecisionExecutionLog.create({
    data: {
      executionId: execution.id,
      logLevel: "INFO",
      message: "执行政策变更",
      details: { policyType, policyContent },
    },
  });

  // TODO: 实现实际的政策变更逻辑
  console.log(`📋 执行政策变更: ${policyType}`);
}

// 定时执行决策
async function scheduleDecisionExecution(execution: any, scheduledTime: Date) {
  // 实现定时执行逻辑
  console.log(`⏰ 决策执行已安排在: ${scheduledTime}`);
  // TODO: 实现定时任务调度
}

// 权限检查辅助函数
async function checkUserPermission(
  db: any,
  userId: string,
  resourceType: string,
  action: string
): Promise<boolean> {
  try {
    // 简化版本，实际应该使用完整的权限检查逻辑
    const userRoles = await db.dAOUserRole.findMany({
      where: {
        userId,
        isActive: true,
      },
      include: {
        role: true,
      },
    });

    // 检查是否有高级角色
    const hasHighRole = userRoles.some((userRole: any) => 
      userRole.role.level >= 4 || userRole.role.roleKey === "admin" || userRole.role.roleKey === "super_admin"
    );
    
    return hasHighRole;
  } catch (error) {
    console.error("权限检查失败:", error);
    return false;
  }
}
