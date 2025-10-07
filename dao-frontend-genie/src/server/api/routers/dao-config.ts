import { z } from "zod";
import { createTRPCRouter, publicProcedure, protectedProcedure } from "@/server/api/trpc";
import { TRPCError } from "@trpc/server";

// 输入验证schema
const createDAOConfigSchema = z.object({
  daoId: z.string().min(1, "DAO ID不能为空"),
  daoName: z.string().min(1, "DAO名称不能为空"),
  daoDescription: z.string().optional(),
  daoLogo: z.string().optional(),
  daoType: z.enum(["COMMUNITY", "CORPORATE", "INVESTMENT", "GOVERNANCE", "SOCIAL", "DEFI", "NFT", "GAMING", "EDUCATION", "RESEARCH"]).default("COMMUNITY"),
  
  // 治理参数配置
  votingThreshold: z.number().min(0).max(100).default(50.0),
  proposalThreshold: z.number().min(0).default(1000),
  votingPeriod: z.number().min(1).max(30).default(7),
  executionDelay: z.number().min(0).max(7).default(1),
  minProposalAmount: z.number().min(0).optional(),
  
  // 成员管理配置
  maxMembers: z.number().min(1).optional(),
  allowMemberInvite: z.boolean().default(true),
  requireApproval: z.boolean().default(false),
  autoApproveThreshold: z.number().min(0).optional(),
  
  // 权限配置
  allowProposalCreation: z.boolean().default(true),
  allowVoting: z.boolean().default(true),
  allowTreasuryAccess: z.boolean().default(false),
  
  // 通知配置
  enableNotifications: z.boolean().default(true),
  notificationChannels: z.record(z.any()).optional(),
  
  // 高级配置
  governanceToken: z.string().optional(),
  contractAddress: z.string().optional(),
  totalSupply: z.bigint().optional(),
  circulatingSupply: z.bigint().optional(),
});

const updateDAOConfigSchema = createDAOConfigSchema.partial().extend({
  id: z.string().min(1, "配置ID不能为空"),
});

const getDAOConfigSchema = z.object({
  daoId: z.string().min(1, "DAO ID不能为空"),
});

const createDAOSettingSchema = z.object({
  daoId: z.string().min(1, "DAO ID不能为空"),
  settingKey: z.string().min(1, "设置键不能为空"),
  settingValue: z.string().min(1, "设置值不能为空"),
  settingType: z.enum(["STRING", "NUMBER", "BOOLEAN", "JSON", "ARRAY"]).default("STRING"),
  description: z.string().optional(),
  isPublic: z.boolean().default(false),
});

const updateDAOSettingSchema = createDAOSettingSchema.partial().extend({
  id: z.string().min(1, "设置ID不能为空"),
});

const getDAOSettingsSchema = z.object({
  daoId: z.string().min(1, "DAO ID不能为空"),
  isPublic: z.boolean().optional(),
});

export const daoConfigRouter = createTRPCRouter({
  // 创建DAO配置
  createConfig: protectedProcedure
    .input(createDAOConfigSchema)
    .mutation(async ({ input, ctx }) => {
      try {
        // 检查用户权限
        const user = await ctx.db.dAOMember.findUnique({
          where: { userId: ctx.session.user.id },
        });

        if (!user) {
          throw new TRPCError({
            code: "UNAUTHORIZED",
            message: "用户未找到",
          });
        }

        // 检查是否已存在配置
        const existingConfig = await ctx.db.dAOConfig.findUnique({
          where: { daoId: input.daoId },
        });

        if (existingConfig) {
          throw new TRPCError({
            code: "CONFLICT",
            message: "DAO配置已存在",
          });
        }

        // 创建DAO配置
        const config = await ctx.db.dAOConfig.create({
          data: {
            daoId: input.daoId,
            daoName: input.daoName,
            daoDescription: input.daoDescription,
            daoLogo: input.daoLogo,
            daoType: input.daoType,
            votingThreshold: input.votingThreshold,
            proposalThreshold: input.proposalThreshold,
            votingPeriod: input.votingPeriod,
            executionDelay: input.executionDelay,
            minProposalAmount: input.minProposalAmount,
            maxMembers: input.maxMembers,
            allowMemberInvite: input.allowMemberInvite,
            requireApproval: input.requireApproval,
            autoApproveThreshold: input.autoApproveThreshold,
            allowProposalCreation: input.allowProposalCreation,
            allowVoting: input.allowVoting,
            allowTreasuryAccess: input.allowTreasuryAccess,
            enableNotifications: input.enableNotifications,
            notificationChannels: input.notificationChannels,
            governanceToken: input.governanceToken,
            contractAddress: input.contractAddress,
            totalSupply: input.totalSupply,
            circulatingSupply: input.circulatingSupply,
            createdBy: ctx.session.user.id,
          },
          include: {
            createdByUser: true,
            settings: true,
          },
        });

        return { success: true, data: config, message: "DAO配置创建成功" };
      } catch (error) {
        console.error("创建DAO配置失败:", error);
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "创建DAO配置失败",
        });
      }
    }),

  // 获取DAO配置
  getConfig: publicProcedure
    .input(getDAOConfigSchema)
    .query(async ({ input, ctx }) => {
      try {
        const config = await ctx.db.dAOConfig.findUnique({
          where: { daoId: input.daoId },
          include: {
            createdByUser: true,
            settings: true,
          },
        });

        if (!config) {
          throw new TRPCError({
            code: "NOT_FOUND",
            message: "DAO配置未找到",
          });
        }

        return { success: true, data: config };
      } catch (error) {
        console.error("获取DAO配置失败:", error);
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "获取DAO配置失败",
        });
      }
    }),

  // 更新DAO配置
  updateConfig: protectedProcedure
    .input(updateDAOConfigSchema)
    .mutation(async ({ input, ctx }) => {
      try {
        // 检查用户权限
        const config = await ctx.db.dAOConfig.findUnique({
          where: { daoId: input.daoId },
        });

        if (!config) {
          throw new TRPCError({
            code: "NOT_FOUND",
            message: "DAO配置未找到",
          });
        }

        // 检查是否为创建者或管理员
        if (config.createdBy !== ctx.session.user.id) {
          // 这里可以添加更复杂的权限检查逻辑
          throw new TRPCError({
            code: "FORBIDDEN",
            message: "无权限修改此DAO配置",
          });
        }

        // 更新配置
        const updatedConfig = await ctx.db.dAOConfig.update({
          where: { daoId: input.daoId },
          data: {
            daoName: input.daoName,
            daoDescription: input.daoDescription,
            daoLogo: input.daoLogo,
            daoType: input.daoType,
            votingThreshold: input.votingThreshold,
            proposalThreshold: input.proposalThreshold,
            votingPeriod: input.votingPeriod,
            executionDelay: input.executionDelay,
            minProposalAmount: input.minProposalAmount,
            maxMembers: input.maxMembers,
            allowMemberInvite: input.allowMemberInvite,
            requireApproval: input.requireApproval,
            autoApproveThreshold: input.autoApproveThreshold,
            allowProposalCreation: input.allowProposalCreation,
            allowVoting: input.allowVoting,
            allowTreasuryAccess: input.allowTreasuryAccess,
            enableNotifications: input.enableNotifications,
            notificationChannels: input.notificationChannels,
            governanceToken: input.governanceToken,
            contractAddress: input.contractAddress,
            totalSupply: input.totalSupply,
            circulatingSupply: input.circulatingSupply,
          },
          include: {
            createdByUser: true,
            settings: true,
          },
        });

        return { success: true, data: updatedConfig, message: "DAO配置更新成功" };
      } catch (error) {
        console.error("更新DAO配置失败:", error);
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "更新DAO配置失败",
        });
      }
    }),

  // 删除DAO配置
  deleteConfig: protectedProcedure
    .input(z.object({ daoId: z.string().min(1, "DAO ID不能为空") }))
    .mutation(async ({ input, ctx }) => {
      try {
        // 检查用户权限
        const config = await ctx.db.dAOConfig.findUnique({
          where: { daoId: input.daoId },
        });

        if (!config) {
          throw new TRPCError({
            code: "NOT_FOUND",
            message: "DAO配置未找到",
          });
        }

        // 检查是否为创建者
        if (config.createdBy !== ctx.session.user.id) {
          throw new TRPCError({
            code: "FORBIDDEN",
            message: "无权限删除此DAO配置",
          });
        }

        // 删除配置和相关设置
        await ctx.db.dAOConfig.delete({
          where: { daoId: input.daoId },
        });

        return { success: true, message: "DAO配置删除成功" };
      } catch (error) {
        console.error("删除DAO配置失败:", error);
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "删除DAO配置失败",
        });
      }
    }),

  // 创建DAO设置
  createSetting: protectedProcedure
    .input(createDAOSettingSchema)
    .mutation(async ({ input, ctx }) => {
      try {
        // 检查DAO配置是否存在
        const config = await ctx.db.dAOConfig.findUnique({
          where: { daoId: input.daoId },
        });

        if (!config) {
          throw new TRPCError({
            code: "NOT_FOUND",
            message: "DAO配置未找到",
          });
        }

        // 检查用户权限
        if (config.createdBy !== ctx.session.user.id) {
          throw new TRPCError({
            code: "FORBIDDEN",
            message: "无权限为此DAO创建设置",
          });
        }

        // 创建设置
        const setting = await ctx.db.dAOSetting.create({
          data: {
            daoId: input.daoId,
            settingKey: input.settingKey,
            settingValue: input.settingValue,
            settingType: input.settingType,
            description: input.description,
            isPublic: input.isPublic,
          },
        });

        return { success: true, data: setting, message: "DAO设置创建成功" };
      } catch (error) {
        console.error("创建DAO设置失败:", error);
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "创建DAO设置失败",
        });
      }
    }),

  // 获取DAO设置列表
  getSettings: publicProcedure
    .input(getDAOSettingsSchema)
    .query(async ({ input, ctx }) => {
      try {
        const settings = await ctx.db.dAOSetting.findMany({
          where: {
            daoId: input.daoId,
            ...(input.isPublic !== undefined && { isPublic: input.isPublic }),
          },
          orderBy: { createdAt: "desc" },
        });

        return { success: true, data: settings };
      } catch (error) {
        console.error("获取DAO设置失败:", error);
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "获取DAO设置失败",
        });
      }
    }),

  // 更新DAO设置
  updateSetting: protectedProcedure
    .input(updateDAOSettingSchema)
    .mutation(async ({ input, ctx }) => {
      try {
        // 检查设置是否存在
        const setting = await ctx.db.dAOSetting.findUnique({
          where: { id: BigInt(input.id) },
          include: { dao: true },
        });

        if (!setting) {
          throw new TRPCError({
            code: "NOT_FOUND",
            message: "DAO设置未找到",
          });
        }

        // 检查用户权限
        if (setting.dao.createdBy !== ctx.session.user.id) {
          throw new TRPCError({
            code: "FORBIDDEN",
            message: "无权限修改此DAO设置",
          });
        }

        // 更新设置
        const updatedSetting = await ctx.db.dAOSetting.update({
          where: { id: BigInt(input.id) },
          data: {
            settingKey: input.settingKey,
            settingValue: input.settingValue,
            settingType: input.settingType,
            description: input.description,
            isPublic: input.isPublic,
          },
        });

        return { success: true, data: updatedSetting, message: "DAO设置更新成功" };
      } catch (error) {
        console.error("更新DAO设置失败:", error);
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "更新DAO设置失败",
        });
      }
    }),

  // 删除DAO设置
  deleteSetting: protectedProcedure
    .input(z.object({ id: z.string().min(1, "设置ID不能为空") }))
    .mutation(async ({ input, ctx }) => {
      try {
        // 检查设置是否存在
        const setting = await ctx.db.dAOSetting.findUnique({
          where: { id: BigInt(input.id) },
          include: { dao: true },
        });

        if (!setting) {
          throw new TRPCError({
            code: "NOT_FOUND",
            message: "DAO设置未找到",
          });
        }

        // 检查用户权限
        if (setting.dao.createdBy !== ctx.session.user.id) {
          throw new TRPCError({
            code: "FORBIDDEN",
            message: "无权限删除此DAO设置",
          });
        }

        // 删除设置
        await ctx.db.dAOSetting.delete({
          where: { id: BigInt(input.id) },
        });

        return { success: true, message: "DAO设置删除成功" };
      } catch (error) {
        console.error("删除DAO设置失败:", error);
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "删除DAO设置失败",
        });
      }
    }),

  // 获取DAO类型列表
  getDAOTypes: publicProcedure
    .query(async () => {
      const daoTypes = [
        { value: "COMMUNITY", label: "社区DAO", description: "基于社区的治理组织" },
        { value: "CORPORATE", label: "企业DAO", description: "企业级治理组织" },
        { value: "INVESTMENT", label: "投资DAO", description: "专注于投资的DAO" },
        { value: "GOVERNANCE", label: "治理DAO", description: "专注于治理的DAO" },
        { value: "SOCIAL", label: "社交DAO", description: "社交网络治理组织" },
        { value: "DEFI", label: "DeFi DAO", description: "去中心化金融治理" },
        { value: "NFT", label: "NFT DAO", description: "NFT项目治理" },
        { value: "GAMING", label: "游戏DAO", description: "游戏项目治理" },
        { value: "EDUCATION", label: "教育DAO", description: "教育项目治理" },
        { value: "RESEARCH", label: "研究DAO", description: "研究项目治理" },
      ];

      return { success: true, data: daoTypes };
    }),

  // 获取DAO配置统计
  getConfigStats: protectedProcedure
    .input(z.object({ daoId: z.string().min(1, "DAO ID不能为空") }))
    .query(async ({ input, ctx }) => {
      try {
        const config = await ctx.db.dAOConfig.findUnique({
          where: { daoId: input.daoId },
          include: {
            settings: true,
          },
        });

        if (!config) {
          throw new TRPCError({
            code: "NOT_FOUND",
            message: "DAO配置未找到",
          });
        }

        const stats = {
          totalSettings: config.settings.length,
          publicSettings: config.settings.filter(s => s.isPublic).length,
          privateSettings: config.settings.filter(s => !s.isPublic).length,
          configAge: Math.floor((Date.now() - config.createdAt.getTime()) / (1000 * 60 * 60 * 24)), // 天数
          lastUpdated: config.updatedAt,
        };

        return { success: true, data: stats };
      } catch (error) {
        console.error("获取DAO配置统计失败:", error);
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "获取DAO配置统计失败",
        });
      }
    }),
});
