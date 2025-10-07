import { z } from "zod";
import { createTRPCRouter, publicProcedure, protectedProcedure } from "@/server/api/trpc";
import { TRPCError } from "@trpc/server";

// 权限管理API - 基于Zervigo权限设计经验

// 输入验证schema
const createPermissionSchema = z.object({
  permissionKey: z.string().min(1, "权限标识不能为空"),
  name: z.string().min(1, "权限名称不能为空"),
  description: z.string().optional(),
  resourceType: z.enum(["USER", "PROPOSAL", "VOTE", "MEMBER", "CONFIG", "TREASURY", "ANALYTICS", "SYSTEM"]),
  action: z.enum(["CREATE", "READ", "UPDATE", "DELETE", "LIST", "EXPORT", "IMPORT", "EXECUTE", "MANAGE"]),
  scope: z.enum(["OWN", "ORGANIZATION", "TENANT", "GLOBAL"]).default("OWN"),
  conditions: z.record(z.any()).optional(),
});

const createRoleSchema = z.object({
  roleKey: z.string().min(1, "角色标识不能为空"),
  name: z.string().min(1, "角色名称不能为空"),
  description: z.string().optional(),
  level: z.number().min(1).max(6).default(1),
  inheritsFrom: z.string().optional(),
});

const assignRoleSchema = z.object({
  userId: z.string().min(1, "用户ID不能为空"),
  roleId: z.string().min(1, "角色ID不能为空"),
  daoId: z.string().min(1, "DAO ID不能为空"),
  expiresAt: z.date().optional(),
});

const checkPermissionSchema = z.object({
  userId: z.string().min(1, "用户ID不能为空"),
  daoId: z.string().min(1, "DAO ID不能为空"),
  resourceType: z.enum(["USER", "PROPOSAL", "VOTE", "MEMBER", "CONFIG", "TREASURY", "ANALYTICS", "SYSTEM"]),
  action: z.enum(["CREATE", "READ", "UPDATE", "DELETE", "LIST", "EXPORT", "IMPORT", "EXECUTE", "MANAGE"]),
  resourceId: z.string().optional(),
});

export const permissionRouter = createTRPCRouter({
  // 创建权限
  createPermission: protectedProcedure
    .input(createPermissionSchema)
    .mutation(async ({ input, ctx }) => {
      try {
        // 检查用户是否有创建权限的权限
        const hasPermission = await checkUserPermission(
          ctx.db,
          ctx.session.user.id,
          "SYSTEM",
          "CREATE"
        );
        
        if (!hasPermission) {
          throw new TRPCError({
            code: "FORBIDDEN",
            message: "无权限创建权限",
          });
        }

        const permission = await ctx.db.dAOPermission.create({
          data: {
            permissionKey: input.permissionKey,
            name: input.name,
            description: input.description,
            resourceType: input.resourceType,
            action: input.action,
            scope: input.scope,
            conditions: input.conditions,
          },
        });

        return { success: true, data: permission, message: "权限创建成功" };
      } catch (error) {
        console.error("创建权限失败:", error);
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "创建权限失败",
        });
      }
    }),

  // 获取权限列表
  getPermissions: publicProcedure
    .query(async ({ ctx }) => {
      try {
        const permissions = await ctx.db.dAOPermission.findMany({
          where: { isActive: true },
          orderBy: { createdAt: "desc" },
        });

        return { success: true, data: permissions };
      } catch (error) {
        console.error("获取权限列表失败:", error);
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "获取权限列表失败",
        });
      }
    }),

  // 创建角色
  createRole: protectedProcedure
    .input(createRoleSchema)
    .mutation(async ({ input, ctx }) => {
      try {
        // 检查用户是否有创建角色的权限
        const hasPermission = await checkUserPermission(
          ctx.db,
          ctx.session.user.id,
          "SYSTEM",
          "CREATE"
        );
        
        if (!hasPermission) {
          throw new TRPCError({
            code: "FORBIDDEN",
            message: "无权限创建角色",
          });
        }

        const role = await ctx.db.dAORole.create({
          data: {
            roleKey: input.roleKey,
            name: input.name,
            description: input.description,
            level: input.level,
            inheritsFrom: input.inheritsFrom,
          },
        });

        return { success: true, data: role, message: "角色创建成功" };
      } catch (error) {
        console.error("创建角色失败:", error);
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "创建角色失败",
        });
      }
    }),

  // 获取角色列表
  getRoles: publicProcedure
    .query(async ({ ctx }) => {
      try {
        const roles = await ctx.db.dAORole.findMany({
          where: { isActive: true },
          include: {
            rolePermissions: {
              include: {
                permission: true,
              },
            },
          },
          orderBy: { level: "asc" },
        });

        return { success: true, data: roles };
      } catch (error) {
        console.error("获取角色列表失败:", error);
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "获取角色列表失败",
        });
      }
    }),

  // 为角色分配权限
  assignPermissionToRole: protectedProcedure
    .input(z.object({
      roleId: z.string().min(1, "角色ID不能为空"),
      permissionId: z.string().min(1, "权限ID不能为空"),
    }))
    .mutation(async ({ input, ctx }) => {
      try {
        // 检查用户是否有分配权限的权限
        const hasPermission = await checkUserPermission(
          ctx.db,
          ctx.session.user.id,
          "SYSTEM",
          "MANAGE"
        );
        
        if (!hasPermission) {
          throw new TRPCError({
            code: "FORBIDDEN",
            message: "无权限分配权限",
          });
        }

        const rolePermission = await ctx.db.dAORolePermission.create({
          data: {
            roleId: BigInt(input.roleId),
            permissionId: BigInt(input.permissionId),
          },
        });

        return { success: true, data: rolePermission, message: "权限分配成功" };
      } catch (error) {
        console.error("分配权限失败:", error);
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "分配权限失败",
        });
      }
    }),

  // 为用户分配角色
  assignRoleToUser: protectedProcedure
    .input(assignRoleSchema)
    .mutation(async ({ input, ctx }) => {
      try {
        // 检查用户是否有分配角色的权限
        const hasPermission = await checkUserPermission(
          ctx.db,
          ctx.session.user.id,
          "MEMBER",
          "MANAGE"
        );
        
        if (!hasPermission) {
          throw new TRPCError({
            code: "FORBIDDEN",
            message: "无权限分配角色",
          });
        }

        const userRole = await ctx.db.dAOUserRole.create({
          data: {
            userId: input.userId,
            roleId: BigInt(input.roleId),
            daoId: input.daoId,
            assignedBy: ctx.session.user.id,
            expiresAt: input.expiresAt,
          },
        });

        return { success: true, data: userRole, message: "角色分配成功" };
      } catch (error) {
        console.error("分配角色失败:", error);
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "分配角色失败",
        });
      }
    }),

  // 检查用户权限
  checkPermission: publicProcedure
    .input(checkPermissionSchema)
    .query(async ({ input, ctx }) => {
      try {
        const hasPermission = await checkUserPermission(
          ctx.db,
          input.userId,
          input.resourceType,
          input.action,
          input.daoId,
          input.resourceId
        );

        return { success: true, data: { hasPermission } };
      } catch (error) {
        console.error("检查权限失败:", error);
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "检查权限失败",
        });
      }
    }),

  // 获取用户角色
  getUserRoles: publicProcedure
    .input(z.object({
      userId: z.string().min(1, "用户ID不能为空"),
      daoId: z.string().optional(),
    }))
    .query(async ({ input, ctx }) => {
      try {
        const userRoles = await ctx.db.dAOUserRole.findMany({
          where: {
            userId: input.userId,
            ...(input.daoId && { daoId: input.daoId }),
            isActive: true,
          },
          include: {
            role: {
              include: {
                rolePermissions: {
                  include: {
                    permission: true,
                  },
                },
              },
            },
          },
        });

        return { success: true, data: userRoles };
      } catch (error) {
        console.error("获取用户角色失败:", error);
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "获取用户角色失败",
        });
      }
    }),

  // 获取用户权限
  getUserPermissions: publicProcedure
    .input(z.object({
      userId: z.string().min(1, "用户ID不能为空"),
      daoId: z.string().optional(),
    }))
    .query(async ({ input, ctx }) => {
      try {
        const userRoles = await ctx.db.dAOUserRole.findMany({
          where: {
            userId: input.userId,
            ...(input.daoId && { daoId: input.daoId }),
            isActive: true,
          },
          include: {
            role: {
              include: {
                rolePermissions: {
                  include: {
                    permission: true,
                  },
                },
              },
            },
          },
        });

        // 提取所有权限
        const permissions = new Set();
        userRoles.forEach(userRole => {
          userRole.role.rolePermissions.forEach(rolePermission => {
            permissions.add(rolePermission.permission);
          });
        });

        return { success: true, data: Array.from(permissions) };
      } catch (error) {
        console.error("获取用户权限失败:", error);
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "获取用户权限失败",
        });
      }
    }),

  // 撤销用户角色
  revokeUserRole: protectedProcedure
    .input(z.object({
      userId: z.string().min(1, "用户ID不能为空"),
      roleId: z.string().min(1, "角色ID不能为空"),
      daoId: z.string().min(1, "DAO ID不能为空"),
    }))
    .mutation(async ({ input, ctx }) => {
      try {
        // 检查用户是否有撤销角色的权限
        const hasPermission = await checkUserPermission(
          ctx.db,
          ctx.session.user.id,
          "MEMBER",
          "MANAGE"
        );
        
        if (!hasPermission) {
          throw new TRPCError({
            code: "FORBIDDEN",
            message: "无权限撤销角色",
          });
        }

        await ctx.db.dAOUserRole.updateMany({
          where: {
            userId: input.userId,
            roleId: BigInt(input.roleId),
            daoId: input.daoId,
          },
          data: {
            isActive: false,
          },
        });

        return { success: true, message: "角色撤销成功" };
      } catch (error) {
        console.error("撤销角色失败:", error);
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "撤销角色失败",
        });
      }
    }),

  // 获取默认角色列表
  getDefaultRoles: publicProcedure
    .query(async () => {
      const defaultRoles = [
        {
          roleKey: "guest",
          name: "访客",
          description: "访客用户，只能查看公开内容",
          level: 1,
        },
        {
          roleKey: "member",
          name: "成员",
          description: "普通成员，可以参与投票",
          level: 2,
        },
        {
          roleKey: "moderator",
          name: "版主",
          description: "版主，可以管理内容和成员",
          level: 3,
        },
        {
          roleKey: "admin",
          name: "管理员",
          description: "管理员，可以管理DAO配置",
          level: 4,
        },
        {
          roleKey: "super_admin",
          name: "超级管理员",
          description: "超级管理员，拥有所有权限",
          level: 5,
        },
      ];

      return { success: true, data: defaultRoles };
    }),

  // 获取默认权限列表
  getDefaultPermissions: publicProcedure
    .query(async () => {
      const defaultPermissions = [
        // 用户权限
        { permissionKey: "user:read", name: "查看用户", resourceType: "USER", action: "READ", scope: "OWN" },
        { permissionKey: "user:update", name: "更新用户", resourceType: "USER", action: "UPDATE", scope: "OWN" },
        
        // 提案权限
        { permissionKey: "proposal:create", name: "创建提案", resourceType: "PROPOSAL", action: "CREATE", scope: "ORGANIZATION" },
        { permissionKey: "proposal:read", name: "查看提案", resourceType: "PROPOSAL", action: "READ", scope: "ORGANIZATION" },
        { permissionKey: "proposal:update", name: "更新提案", resourceType: "PROPOSAL", action: "UPDATE", scope: "ORGANIZATION" },
        { permissionKey: "proposal:delete", name: "删除提案", resourceType: "PROPOSAL", action: "DELETE", scope: "ORGANIZATION" },
        
        // 投票权限
        { permissionKey: "vote:create", name: "投票", resourceType: "VOTE", action: "CREATE", scope: "ORGANIZATION" },
        { permissionKey: "vote:read", name: "查看投票", resourceType: "VOTE", action: "READ", scope: "ORGANIZATION" },
        
        // 成员权限
        { permissionKey: "member:read", name: "查看成员", resourceType: "MEMBER", action: "READ", scope: "ORGANIZATION" },
        { permissionKey: "member:manage", name: "管理成员", resourceType: "MEMBER", action: "MANAGE", scope: "ORGANIZATION" },
        
        // 配置权限
        { permissionKey: "config:read", name: "查看配置", resourceType: "CONFIG", action: "READ", scope: "ORGANIZATION" },
        { permissionKey: "config:update", name: "更新配置", resourceType: "CONFIG", action: "UPDATE", scope: "ORGANIZATION" },
        
        // 系统权限
        { permissionKey: "system:manage", name: "系统管理", resourceType: "SYSTEM", action: "MANAGE", scope: "GLOBAL" },
      ];

      return { success: true, data: defaultPermissions };
    }),
});

// 权限检查辅助函数 - 基于Zervigo权限引擎设计
async function checkUserPermission(
  db: any,
  userId: string,
  resourceType: string,
  action: string,
  daoId?: string,
  resourceId?: string
): Promise<boolean> {
  try {
    // 1. 获取用户角色
    const userRoles = await db.dAOUserRole.findMany({
      where: {
        userId,
        ...(daoId && { daoId }),
        isActive: true,
      },
      include: {
        role: {
          include: {
            rolePermissions: {
              include: {
                permission: true,
              },
            },
          },
        },
      },
    });

    // 2. 检查是否有超级管理员角色
    const hasSuperAdmin = userRoles.some((userRole: any) => 
      userRole.role.level >= 5 || userRole.role.roleKey === "super_admin"
    );
    
    if (hasSuperAdmin) {
      return true;
    }

    // 3. 检查具体权限
    for (const userRole of userRoles) {
      for (const rolePermission of userRole.role.rolePermissions) {
        const permission = rolePermission.permission;
        
        if (permission.resourceType === resourceType && 
            permission.action === action &&
            permission.isActive) {
          
          // 检查权限范围
          if (await checkPermissionScope(permission.scope, userId, resourceId, daoId)) {
            return true;
          }
        }
      }
    }

    return false;
  } catch (error) {
    console.error("权限检查失败:", error);
    return false;
  }
}

// 权限范围检查
async function checkPermissionScope(
  scope: string,
  userId: string,
  resourceId?: string,
  daoId?: string
): Promise<boolean> {
  switch (scope) {
    case "OWN":
      // 只能访问自己的资源
      return resourceId === userId;
    case "ORGANIZATION":
      // 可以访问组织内的资源
      return !!daoId;
    case "TENANT":
      // 可以访问租户内的资源
      return true;
    case "GLOBAL":
      // 可以访问所有资源
      return true;
    default:
      return false;
  }
}
