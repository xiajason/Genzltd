import { z } from "zod";
import { createTRPCRouter, publicProcedure, protectedProcedure } from "@/server/api/trpc";
import { TRPCError } from "@trpc/server";
import jwt from "jsonwebtoken";
import { nanoid } from "nanoid";

// 输入验证schema
const createInvitationSchema = z.object({
  daoId: z.string().min(1, "DAO ID不能为空"),
  inviteeEmail: z.string().email("请输入有效的邮箱地址"),
  inviteeName: z.string().optional(),
  roleType: z.enum(["member", "moderator", "admin"]).default("member"),
  invitationType: z.enum(["direct", "referral", "public"]).default("direct"),
  expiresInDays: z.number().min(1).max(30).default(7)
});

const validateInvitationSchema = z.object({
  token: z.string().min(1, "Token不能为空")
});

const acceptInvitationSchema = z.object({
  token: z.string().min(1, "Token不能为空"),
  userData: z.object({
    name: z.string().optional(),
    avatar: z.string().optional()
  }).optional()
});

const getInvitationsSchema = z.object({
  daoId: z.string().min(1, "DAO ID不能为空"),
  status: z.enum(["pending", "accepted", "expired", "revoked"]).optional(),
  page: z.number().min(1).default(1),
  limit: z.number().min(1).max(100).default(20)
});

// 权限检查函数
async function canInviteMembers(userId: string, daoId: string) {
  // 检查用户是否为DAO成员且具有邀请权限
  // 这里简化处理，实际应该检查用户角色和权限
  return true; // 临时返回true，后续需要实现具体的权限检查逻辑
}

async function canManageInvitations(userId: string, daoId: string) {
  // 检查用户是否有管理邀请的权限
  return true; // 临时返回true，后续需要实现具体的权限检查逻辑
}

// JWT密钥（应该从环境变量获取）
const JWT_SECRET = process.env.JWT_SECRET || "your-secret-key";

export const invitationRouter = createTRPCRouter({
  // 创建邀请
  createInvitation: protectedProcedure
    .input(createInvitationSchema)
    .mutation(async ({ input, ctx }) => {
      const { user } = ctx;
      
      // 验证用户权限
      if (!await canInviteMembers(user.id, input.daoId)) {
        throw new TRPCError({
          code: "FORBIDDEN",
          message: "您没有邀请成员的权限"
        });
      }
      
      // 检查是否已经存在相同的邀请
      const existingInvitation = await ctx.db.daoInvitation.findFirst({
        where: {
          daoId: input.daoId,
          inviteeEmail: input.inviteeEmail,
          status: "pending"
        }
      });
      
      if (existingInvitation) {
        throw new TRPCError({
          code: "CONFLICT",
          message: "该邮箱已存在待处理的邀请"
        });
      }
      
      // 生成邀请ID和token
      const invitationId = `inv_${nanoid()}`;
      const token = jwt.sign(
        {
          invitationId,
          daoId: input.daoId,
          inviterId: user.id,
          inviteeEmail: input.inviteeEmail,
          roleType: input.roleType,
          expiresAt: new Date(Date.now() + input.expiresInDays * 24 * 60 * 60 * 1000)
        },
        JWT_SECRET,
        { expiresIn: `${input.expiresInDays}d` }
      );
      
      // 计算过期时间
      const expiresAt = new Date(Date.now() + input.expiresInDays * 24 * 60 * 60 * 1000);
      
      // 创建邀请记录
      const invitation = await ctx.db.daoInvitation.create({
        data: {
          invitationId,
          daoId: input.daoId,
          inviterId: user.id,
          inviteeEmail: input.inviteeEmail,
          inviteeName: input.inviteeName,
          roleType: input.roleType,
          invitationType: input.invitationType,
          token,
          expiresAt
        }
      });
      
      // 更新邀请统计
      await ctx.db.daoInvitationStats.upsert({
        where: { daoId: input.daoId },
        update: {
          totalInvitations: { increment: 1 },
          pendingInvitations: { increment: 1 }
        },
        create: {
          daoId: input.daoId,
          totalInvitations: 1,
          pendingInvitations: 1
        }
      });
      
      // 生成邀请链接
      const invitationUrl = `${process.env.NEXT_PUBLIC_BASE_URL || 'http://localhost:3000'}/dao/invite/${token}`;
      
      // TODO: 发送邮件通知
      // await emailService.sendInvitationEmail({
      //   invitation,
      //   invitationUrl,
      //   inviterName: user.firstName || user.username || 'Unknown',
      //   daoName: 'DAO Name' // 需要从DAO数据获取
      // });
      
      return {
        success: true,
        invitation: {
          id: invitation.id,
          invitationId: invitation.invitationId,
          daoId: invitation.daoId,
          inviteeEmail: invitation.inviteeEmail,
          inviteeName: invitation.inviteeName,
          roleType: invitation.roleType,
          invitationType: invitation.invitationType,
          status: invitation.status,
          expiresAt: invitation.expiresAt,
          createdAt: invitation.createdAt
        },
        invitationUrl,
        message: "邀请已创建，邮件发送功能待实现"
      };
    }),
  
  // 验证邀请链接
  validateInvitation: publicProcedure
    .input(validateInvitationSchema)
    .query(async ({ input, ctx }) => {
      try {
        // 解密token
        const payload = jwt.verify(input.token, JWT_SECRET) as any;
        
        // 检查邀请是否过期
        if (new Date() > new Date(payload.expiresAt)) {
          throw new TRPCError({
            code: "BAD_REQUEST",
            message: "邀请链接已过期"
          });
        }
        
        // 从数据库获取邀请信息
        const invitation = await ctx.db.daoInvitation.findUnique({
          where: { token: input.token },
          include: {
            inviter: {
              select: {
                firstName: true,
                lastName: true,
                username: true,
                avatarUrl: true
              }
            }
          }
        });
        
        if (!invitation || invitation.status !== "pending") {
          throw new TRPCError({
            code: "BAD_REQUEST",
            message: "邀请链接无效或已被处理"
          });
        }
        
        return {
          valid: true,
          invitation: {
            invitationId: invitation.invitationId,
            daoId: invitation.daoId,
            inviteeEmail: invitation.inviteeEmail,
            inviteeName: invitation.inviteeName,
            roleType: invitation.roleType,
            invitationType: invitation.invitationType,
            expiresAt: invitation.expiresAt,
            inviter: {
              name: invitation.inviter.firstName && invitation.inviter.lastName 
                ? `${invitation.inviter.firstName} ${invitation.inviter.lastName}`
                : invitation.inviter.username || 'Unknown',
              avatarUrl: invitation.inviter.avatarUrl
            }
          }
        };
      } catch (error) {
        if (error instanceof jwt.JsonWebTokenError) {
          throw new TRPCError({
            code: "BAD_REQUEST",
            message: "邀请链接格式错误"
          });
        }
        throw error;
      }
    }),
  
  // 接受邀请
  acceptInvitation: protectedProcedure
    .input(acceptInvitationSchema)
    .mutation(async ({ input, ctx }) => {
      const { user } = ctx;
      
      try {
        // 验证token
        const payload = jwt.verify(input.token, JWT_SECRET) as any;
        
        // 获取邀请记录
        const invitation = await ctx.db.daoInvitation.findUnique({
          where: { token: input.token }
        });
        
        if (!invitation || invitation.status !== "pending") {
          throw new TRPCError({
            code: "BAD_REQUEST",
            message: "邀请链接无效或已被处理"
          });
        }
        
        // 检查邀请是否过期
        if (new Date() > invitation.expiresAt) {
          // 更新邀请状态为过期
          await ctx.db.daoInvitation.update({
            where: { token: input.token },
            data: { status: "expired" }
          });
          
          throw new TRPCError({
            code: "BAD_REQUEST",
            message: "邀请链接已过期"
          });
        }
        
        // 检查用户是否已经是DAO成员
        const existingMember = await ctx.db.daoMember.findFirst({
          where: {
            userId: user.id,
            // 这里需要根据实际的DAO成员关系来检查
            // 暂时简化处理
          }
        });
        
        if (existingMember) {
          throw new TRPCError({
            code: "CONFLICT",
            message: "您已经是该DAO的成员"
          });
        }
        
        // 创建DAO成员记录
        const newMember = await ctx.db.daoMember.create({
          data: {
            userId: user.id,
            username: user.username || user.email?.split('@')[0],
            email: user.email,
            firstName: input.userData?.name?.split(' ')[0],
            lastName: input.userData?.name?.split(' ').slice(1).join(' '),
            avatarUrl: input.userData?.avatar,
            reputationScore: 80, // 默认声誉分数
            contributionPoints: 0,
            joinDate: new Date(),
            status: "ACTIVE"
          }
        });
        
        // 更新邀请状态
        await ctx.db.daoInvitation.update({
          where: { token: input.token },
          data: {
            status: "accepted",
            acceptedAt: new Date()
          }
        });
        
        // 更新邀请统计
        await ctx.db.daoInvitationStats.upsert({
          where: { daoId: invitation.daoId },
          update: {
            acceptedInvitations: { increment: 1 },
            pendingInvitations: { decrement: 1 }
          },
          create: {
            daoId: invitation.daoId,
            acceptedInvitations: 1,
            pendingInvitations: 0
          }
        });
        
        return {
          success: true,
          daoId: invitation.daoId,
          roleType: invitation.roleType,
          memberId: newMember.id,
          message: "成功加入DAO"
        };
      } catch (error) {
        if (error instanceof jwt.JsonWebTokenError) {
          throw new TRPCError({
            code: "BAD_REQUEST",
            message: "邀请链接格式错误"
          });
        }
        throw error;
      }
    }),
  
  // 获取邀请列表
  getInvitations: protectedProcedure
    .input(getInvitationsSchema)
    .query(async ({ input, ctx }) => {
      const { user } = ctx;
      
      // 验证权限
      if (!await canManageInvitations(user.id, input.daoId)) {
        throw new TRPCError({
          code: "FORBIDDEN",
          message: "您没有查看邀请列表的权限"
        });
      }
      
      // 构建查询条件
      const where: any = { daoId: input.daoId };
      if (input.status) {
        where.status = input.status;
      }
      
      // 获取邀请列表
      const [invitations, total] = await Promise.all([
        ctx.db.daoInvitation.findMany({
          where,
          include: {
            inviter: {
              select: {
                firstName: true,
                lastName: true,
                username: true,
                avatarUrl: true
              }
            }
          },
          orderBy: { createdAt: "desc" },
          skip: (input.page - 1) * input.limit,
          take: input.limit
        }),
        ctx.db.daoInvitation.count({ where })
      ]);
      
      // 格式化邀请数据
      const formattedInvitations = invitations.map(invitation => ({
        id: invitation.id,
        invitationId: invitation.invitationId,
        daoId: invitation.daoId,
        inviterId: invitation.inviterId,
        inviteeEmail: invitation.inviteeEmail,
        inviteeName: invitation.inviteeName,
        roleType: invitation.roleType,
        invitationType: invitation.invitationType,
        status: invitation.status,
        expiresAt: invitation.expiresAt,
        acceptedAt: invitation.acceptedAt,
        createdAt: invitation.createdAt,
        updatedAt: invitation.updatedAt,
        inviter: {
          name: invitation.inviter.firstName && invitation.inviter.lastName 
            ? `${invitation.inviter.firstName} ${invitation.inviter.lastName}`
            : invitation.inviter.username || 'Unknown',
          avatarUrl: invitation.inviter.avatarUrl
        }
      }));
      
      return {
        invitations: formattedInvitations,
        pagination: {
          page: input.page,
          limit: input.limit,
          total,
          totalPages: Math.ceil(total / input.limit)
        }
      };
    }),
  
  // 获取邀请统计
  getInvitationStats: protectedProcedure
    .input(z.object({ daoId: z.string() }))
    .query(async ({ input, ctx }) => {
      const { user } = ctx;
      
      // 验证权限
      if (!await canManageInvitations(user.id, input.daoId)) {
        throw new TRPCError({
          code: "FORBIDDEN",
          message: "您没有查看邀请统计的权限"
        });
      }
      
      const stats = await ctx.db.daoInvitationStats.findUnique({
        where: { daoId: input.daoId }
      });
      
      if (!stats) {
        return {
          totalInvitations: 0,
          acceptedInvitations: 0,
          pendingInvitations: 0,
          expiredInvitations: 0,
          acceptanceRate: 0
        };
      }
      
      const acceptanceRate = stats.totalInvitations > 0 
        ? (stats.acceptedInvitations / stats.totalInvitations) * 100 
        : 0;
      
      return {
        totalInvitations: stats.totalInvitations,
        acceptedInvitations: stats.acceptedInvitations,
        pendingInvitations: stats.pendingInvitations,
        expiredInvitations: stats.expiredInvitations,
        acceptanceRate: Math.round(acceptanceRate * 100) / 100,
        lastUpdated: stats.lastUpdated
      };
    }),
  
  // 撤销邀请
  revokeInvitation: protectedProcedure
    .input(z.object({ invitationId: z.string() }))
    .mutation(async ({ input, ctx }) => {
      const { user } = ctx;
      
      // 获取邀请记录
      const invitation = await ctx.db.daoInvitation.findUnique({
        where: { invitationId: input.invitationId }
      });
      
      if (!invitation) {
        throw new TRPCError({
          code: "NOT_FOUND",
          message: "邀请不存在"
        });
      }
      
      // 验证权限（只有邀请者或管理员可以撤销）
      if (invitation.inviterId !== user.id && !await canManageInvitations(user.id, invitation.daoId)) {
        throw new TRPCError({
          code: "FORBIDDEN",
          message: "您没有撤销此邀请的权限"
        });
      }
      
      // 检查邀请状态
      if (invitation.status !== "pending") {
        throw new TRPCError({
          code: "BAD_REQUEST",
          message: "只能撤销待处理的邀请"
        });
      }
      
      // 更新邀请状态
      await ctx.db.daoInvitation.update({
        where: { invitationId: input.invitationId },
        data: { status: "revoked" }
      });
      
      // 更新邀请统计
      await ctx.db.daoInvitationStats.upsert({
        where: { daoId: invitation.daoId },
        update: {
          pendingInvitations: { decrement: 1 }
        },
        create: {
          daoId: invitation.daoId,
          pendingInvitations: 0
        }
      });
      
      return {
        success: true,
        message: "邀请已撤销"
      };
    })
});
