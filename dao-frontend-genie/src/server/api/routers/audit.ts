import { z } from "zod";
import { createTRPCRouter, publicProcedure, protectedProcedure } from "@/server/api/trpc";
import { TRPCError } from "@trpc/server";
import { v4 as uuidv4 } from "uuid";

// 审计日志API - 基于Looma CRM审计系统设计经验

// 输入验证schema
const createAuditLogSchema = z.object({
  eventType: z.enum([
    "LOGIN", "LOGOUT", "DATA_ACCESS", "DATA_MODIFICATION", "DATA_DELETION",
    "PERMISSION_CHANGE", "ROLE_ASSIGNMENT", "SYSTEM_CONFIG", "SECURITY_VIOLATION",
    "API_ACCESS", "PROPOSAL_CREATE", "PROPOSAL_UPDATE", "VOTE_CAST", "MEMBER_INVITE", "CONFIG_CHANGE"
  ]),
  userId: z.string().min(1, "用户ID不能为空"),
  username: z.string().min(1, "用户名不能为空"),
  sessionId: z.string().optional(),
  ipAddress: z.string().optional(),
  userAgent: z.string().optional(),
  daoId: z.string().optional(),
  resourceType: z.string().optional(),
  resourceId: z.string().optional(),
  action: z.string().optional(),
  status: z.enum(["SUCCESS", "FAILURE", "WARNING", "SUSPICIOUS"]).default("SUCCESS"),
  level: z.enum(["LOW", "MEDIUM", "HIGH", "CRITICAL"]).default("LOW"),
  details: z.record(z.any()).optional(),
  durationMs: z.number().optional(),
  errorMessage: z.string().optional(),
});

const getAuditLogsSchema = z.object({
  userId: z.string().optional(),
  daoId: z.string().optional(),
  eventType: z.enum([
    "LOGIN", "LOGOUT", "DATA_ACCESS", "DATA_MODIFICATION", "DATA_DELETION",
    "PERMISSION_CHANGE", "ROLE_ASSIGNMENT", "SYSTEM_CONFIG", "SECURITY_VIOLATION",
    "API_ACCESS", "PROPOSAL_CREATE", "PROPOSAL_UPDATE", "VOTE_CAST", "MEMBER_INVITE", "CONFIG_CHANGE"
  ]).optional(),
  status: z.enum(["SUCCESS", "FAILURE", "WARNING", "SUSPICIOUS"]).optional(),
  level: z.enum(["LOW", "MEDIUM", "HIGH", "CRITICAL"]).optional(),
  startDate: z.date().optional(),
  endDate: z.date().optional(),
  page: z.number().min(1).default(1),
  limit: z.number().min(1).max(100).default(20),
});

const createAuditRuleSchema = z.object({
  ruleId: z.string().min(1, "规则ID不能为空"),
  name: z.string().min(1, "规则名称不能为空"),
  description: z.string().optional(),
  eventTypes: z.array(z.string()).min(1, "事件类型不能为空"),
  conditions: z.record(z.any()).optional(),
  actions: z.array(z.string()).min(1, "动作不能为空"),
});

export const auditRouter = createTRPCRouter({
  // 记录审计日志
  logEvent: protectedProcedure
    .input(createAuditLogSchema)
    .mutation(async ({ input, ctx }) => {
      try {
        const eventId = uuidv4();
        
        const auditLog = await ctx.db.dAOAuditLog.create({
          data: {
            eventId,
            eventType: input.eventType,
            userId: input.userId,
            username: input.username,
            sessionId: input.sessionId,
            ipAddress: input.ipAddress,
            userAgent: input.userAgent,
            daoId: input.daoId,
            resourceType: input.resourceType,
            resourceId: input.resourceId,
            action: input.action,
            status: input.status,
            level: input.level,
            details: input.details,
            durationMs: input.durationMs,
            errorMessage: input.errorMessage,
          },
        });

        // 触发审计规则评估
        await evaluateAuditRules(ctx.db, auditLog);

        return { success: true, data: auditLog, message: "审计日志记录成功" };
      } catch (error) {
        console.error("记录审计日志失败:", error);
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "记录审计日志失败",
        });
      }
    }),

  // 获取审计日志列表
  getAuditLogs: protectedProcedure
    .input(getAuditLogsSchema)
    .query(async ({ input, ctx }) => {
      try {
        // 检查用户是否有查看审计日志的权限
        const hasPermission = await checkUserPermission(
          ctx.db,
          ctx.session.user.id,
          "SYSTEM",
          "READ"
        );
        
        if (!hasPermission) {
          throw new TRPCError({
            code: "FORBIDDEN",
            message: "无权限查看审计日志",
          });
        }

        const where: any = {};
        
        if (input.userId) where.userId = input.userId;
        if (input.daoId) where.daoId = input.daoId;
        if (input.eventType) where.eventType = input.eventType;
        if (input.status) where.status = input.status;
        if (input.level) where.level = input.level;
        
        if (input.startDate || input.endDate) {
          where.timestamp = {};
          if (input.startDate) where.timestamp.gte = input.startDate;
          if (input.endDate) where.timestamp.lte = input.endDate;
        }

        const skip = (input.page - 1) * input.limit;
        
        const [auditLogs, total] = await Promise.all([
          ctx.db.dAOAuditLog.findMany({
            where,
            include: {
              user: {
                select: {
                  username: true,
                  email: true,
                },
              },
            },
            orderBy: { timestamp: "desc" },
            skip,
            take: input.limit,
          }),
          ctx.db.dAOAuditLog.count({ where }),
        ]);

        return {
          success: true,
          data: {
            auditLogs,
            pagination: {
              page: input.page,
              limit: input.limit,
              total,
              totalPages: Math.ceil(total / input.limit),
            },
          },
        };
      } catch (error) {
        console.error("获取审计日志失败:", error);
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "获取审计日志失败",
        });
      }
    }),

  // 获取审计日志详情
  getAuditLogDetail: protectedProcedure
    .input(z.object({ eventId: z.string().min(1, "事件ID不能为空") }))
    .query(async ({ input, ctx }) => {
      try {
        // 检查用户是否有查看审计日志的权限
        const hasPermission = await checkUserPermission(
          ctx.db,
          ctx.session.user.id,
          "SYSTEM",
          "READ"
        );
        
        if (!hasPermission) {
          throw new TRPCError({
            code: "FORBIDDEN",
            message: "无权限查看审计日志详情",
          });
        }

        const auditLog = await ctx.db.dAOAuditLog.findUnique({
          where: { eventId: input.eventId },
          include: {
            user: {
              select: {
                username: true,
                email: true,
                firstName: true,
                lastName: true,
              },
            },
          },
        });

        if (!auditLog) {
          throw new TRPCError({
            code: "NOT_FOUND",
            message: "审计日志未找到",
          });
        }

        return { success: true, data: auditLog };
      } catch (error) {
        console.error("获取审计日志详情失败:", error);
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "获取审计日志详情失败",
        });
      }
    }),

  // 创建审计规则
  createAuditRule: protectedProcedure
    .input(createAuditRuleSchema)
    .mutation(async ({ input, ctx }) => {
      try {
        // 检查用户是否有创建审计规则的权限
        const hasPermission = await checkUserPermission(
          ctx.db,
          ctx.session.user.id,
          "SYSTEM",
          "CREATE"
        );
        
        if (!hasPermission) {
          throw new TRPCError({
            code: "FORBIDDEN",
            message: "无权限创建审计规则",
          });
        }

        const auditRule = await ctx.db.dAOAuditRule.create({
          data: {
            ruleId: input.ruleId,
            name: input.name,
            description: input.description,
            eventTypes: input.eventTypes,
            conditions: input.conditions || {},
            actions: input.actions,
          },
        });

        return { success: true, data: auditRule, message: "审计规则创建成功" };
      } catch (error) {
        console.error("创建审计规则失败:", error);
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "创建审计规则失败",
        });
      }
    }),

  // 获取审计规则列表
  getAuditRules: protectedProcedure
    .query(async ({ ctx }) => {
      try {
        // 检查用户是否有查看审计规则的权限
        const hasPermission = await checkUserPermission(
          ctx.db,
          ctx.session.user.id,
          "SYSTEM",
          "READ"
        );
        
        if (!hasPermission) {
          throw new TRPCError({
            code: "FORBIDDEN",
            message: "无权限查看审计规则",
          });
        }

        const auditRules = await ctx.db.dAOAuditRule.findMany({
          where: { isActive: true },
          orderBy: { createdAt: "desc" },
        });

        return { success: true, data: auditRules };
      } catch (error) {
        console.error("获取审计规则失败:", error);
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "获取审计规则失败",
        });
      }
    }),

  // 获取审计告警列表
  getAuditAlerts: protectedProcedure
    .input(z.object({
      severity: z.enum(["LOW", "MEDIUM", "HIGH", "CRITICAL"]).optional(),
      isResolved: z.boolean().optional(),
      page: z.number().min(1).default(1),
      limit: z.number().min(1).max(100).default(20),
    }))
    .query(async ({ input, ctx }) => {
      try {
        // 检查用户是否有查看审计告警的权限
        const hasPermission = await checkUserPermission(
          ctx.db,
          ctx.session.user.id,
          "SYSTEM",
          "READ"
        );
        
        if (!hasPermission) {
          throw new TRPCError({
            code: "FORBIDDEN",
            message: "无权限查看审计告警",
          });
        }

        const where: any = {};
        
        if (input.severity) where.severity = input.severity;
        if (input.isResolved !== undefined) where.isResolved = input.isResolved;

        const skip = (input.page - 1) * input.limit;
        
        const [alerts, total] = await Promise.all([
          ctx.db.dAOAuditAlert.findMany({
            where,
            orderBy: { timestamp: "desc" },
            skip,
            take: input.limit,
          }),
          ctx.db.dAOAuditAlert.count({ where }),
        ]);

        return {
          success: true,
          data: {
            alerts,
            pagination: {
              page: input.page,
              limit: input.limit,
              total,
              totalPages: Math.ceil(total / input.limit),
            },
          },
        };
      } catch (error) {
        console.error("获取审计告警失败:", error);
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "获取审计告警失败",
        });
      }
    }),

  // 解决审计告警
  resolveAlert: protectedProcedure
    .input(z.object({ alertId: z.string().min(1, "告警ID不能为空") }))
    .mutation(async ({ input, ctx }) => {
      try {
        // 检查用户是否有解决审计告警的权限
        const hasPermission = await checkUserPermission(
          ctx.db,
          ctx.session.user.id,
          "SYSTEM",
          "UPDATE"
        );
        
        if (!hasPermission) {
          throw new TRPCError({
            code: "FORBIDDEN",
            message: "无权限解决审计告警",
          });
        }

        const alert = await ctx.db.dAOAuditAlert.update({
          where: { alertId: input.alertId },
          data: {
            isResolved: true,
            resolvedBy: ctx.session.user.id,
            resolvedAt: new Date(),
          },
        });

        return { success: true, data: alert, message: "审计告警已解决" };
      } catch (error) {
        console.error("解决审计告警失败:", error);
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "解决审计告警失败",
        });
      }
    }),

  // 获取审计统计
  getAuditStats: protectedProcedure
    .input(z.object({
      daoId: z.string().optional(),
      startDate: z.date().optional(),
      endDate: z.date().optional(),
    }))
    .query(async ({ input, ctx }) => {
      try {
        // 检查用户是否有查看审计统计的权限
        const hasPermission = await checkUserPermission(
          ctx.db,
          ctx.session.user.id,
          "SYSTEM",
          "READ"
        );
        
        if (!hasPermission) {
          throw new TRPCError({
            code: "FORBIDDEN",
            message: "无权限查看审计统计",
          });
        }

        const where: any = {};
        
        if (input.daoId) where.daoId = input.daoId;
        
        if (input.startDate || input.endDate) {
          where.timestamp = {};
          if (input.startDate) where.timestamp.gte = input.startDate;
          if (input.endDate) where.timestamp.lte = input.endDate;
        }

        const [
          totalEvents,
          successEvents,
          failureEvents,
          warningEvents,
          suspiciousEvents,
          criticalAlerts,
          unresolvedAlerts,
        ] = await Promise.all([
          ctx.db.dAOAuditLog.count({ where }),
          ctx.db.dAOAuditLog.count({ where: { ...where, status: "SUCCESS" } }),
          ctx.db.dAOAuditLog.count({ where: { ...where, status: "FAILURE" } }),
          ctx.db.dAOAuditLog.count({ where: { ...where, status: "WARNING" } }),
          ctx.db.dAOAuditLog.count({ where: { ...where, status: "SUSPICIOUS" } }),
          ctx.db.dAOAuditAlert.count({ where: { severity: "CRITICAL", isResolved: false } }),
          ctx.db.dAOAuditAlert.count({ where: { isResolved: false } }),
        ]);

        // 按事件类型统计
        const eventTypeStats = await ctx.db.dAOAuditLog.groupBy({
          by: ['eventType'],
          where,
          _count: {
            eventType: true,
          },
          orderBy: {
            _count: {
              eventType: 'desc',
            },
          },
        });

        // 按级别统计
        const levelStats = await ctx.db.dAOAuditLog.groupBy({
          by: ['level'],
          where,
          _count: {
            level: true,
          },
        });

        return {
          success: true,
          data: {
            overview: {
              totalEvents,
              successEvents,
              failureEvents,
              warningEvents,
              suspiciousEvents,
              criticalAlerts,
              unresolvedAlerts,
            },
            eventTypeStats,
            levelStats,
          },
        };
      } catch (error) {
        console.error("获取审计统计失败:", error);
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "获取审计统计失败",
        });
      }
    }),

  // 导出审计日志
  exportAuditLogs: protectedProcedure
    .input(getAuditLogsSchema)
    .mutation(async ({ input, ctx }) => {
      try {
        // 检查用户是否有导出审计日志的权限
        const hasPermission = await checkUserPermission(
          ctx.db,
          ctx.session.user.id,
          "SYSTEM",
          "EXPORT"
        );
        
        if (!hasPermission) {
          throw new TRPCError({
            code: "FORBIDDEN",
            message: "无权限导出审计日志",
          });
        }

        const where: any = {};
        
        if (input.userId) where.userId = input.userId;
        if (input.daoId) where.daoId = input.daoId;
        if (input.eventType) where.eventType = input.eventType;
        if (input.status) where.status = input.status;
        if (input.level) where.level = input.level;
        
        if (input.startDate || input.endDate) {
          where.timestamp = {};
          if (input.startDate) where.timestamp.gte = input.startDate;
          if (input.endDate) where.timestamp.lte = input.endDate;
        }

        const auditLogs = await ctx.db.dAOAuditLog.findMany({
          where,
          include: {
            user: {
              select: {
                username: true,
                email: true,
              },
            },
          },
          orderBy: { timestamp: "desc" },
        });

        // 转换为CSV格式
        const csvData = auditLogs.map(log => ({
          eventId: log.eventId,
          timestamp: log.timestamp.toISOString(),
          eventType: log.eventType,
          username: log.username,
          daoId: log.daoId,
          resourceType: log.resourceType,
          resourceId: log.resourceId,
          action: log.action,
          status: log.status,
          level: log.level,
          ipAddress: log.ipAddress,
          userAgent: log.userAgent,
          durationMs: log.durationMs,
          errorMessage: log.errorMessage,
        }));

        return {
          success: true,
          data: {
            csvData,
            totalRecords: csvData.length,
            exportTime: new Date().toISOString(),
          },
          message: "审计日志导出成功",
        };
      } catch (error) {
        console.error("导出审计日志失败:", error);
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "导出审计日志失败",
        });
      }
    }),
});

// 审计规则评估函数 - 基于Looma CRM审计规则引擎
async function evaluateAuditRules(db: any, auditLog: any) {
  try {
    const rules = await db.dAOAuditRule.findMany({
      where: { isActive: true },
    });

    for (const rule of rules) {
      if (rule.eventTypes.includes(auditLog.eventType)) {
        const shouldTrigger = evaluateRuleConditions(rule.conditions, auditLog);
        
        if (shouldTrigger) {
          await createAuditAlert(db, rule, auditLog);
        }
      }
    }
  } catch (error) {
    console.error("审计规则评估失败:", error);
  }
}

// 规则条件评估
function evaluateRuleConditions(conditions: any, auditLog: any): boolean {
  try {
    // 简单的条件评估逻辑
    if (conditions.level && auditLog.level === conditions.level) {
      return true;
    }
    
    if (conditions.status && auditLog.status === conditions.status) {
      return true;
    }
    
    if (conditions.userId && auditLog.userId === conditions.userId) {
      return true;
    }
    
    if (conditions.daoId && auditLog.daoId === conditions.daoId) {
      return true;
    }
    
    return false;
  } catch (error) {
    console.error("规则条件评估失败:", error);
    return false;
  }
}

// 创建审计告警
async function createAuditAlert(db: any, rule: any, auditLog: any) {
  try {
    const alertId = uuidv4();
    
    const alert = await db.dAOAuditAlert.create({
      data: {
        alertId,
        ruleId: rule.ruleId,
        eventId: auditLog.eventId,
        severity: auditLog.level,
        message: `审计规则触发: ${rule.name}`,
        details: {
          rule: rule.name,
          event: auditLog.eventType,
          user: auditLog.username,
          timestamp: auditLog.timestamp,
        },
      },
    });

    console.log(`审计告警已创建: ${alertId} - ${rule.name}`);
    return alert;
  } catch (error) {
    console.error("创建审计告警失败:", error);
  }
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
