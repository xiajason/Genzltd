import { z } from "zod";
import { createTRPCRouter, publicProcedure, protectedProcedure } from "@/server/api/trpc";
import { TRPCError } from "@trpc/server";

// 多语言支持API - 国际化系统

// 输入验证schema
const createLanguageSchema = z.object({
  code: z.string().min(2).max(5, "语言代码长度应为2-5个字符"),
  name: z.string().min(1, "语言名称不能为空"),
  nativeName: z.string().min(1, "本地名称不能为空"),
  isDefault: z.boolean().default(false),
});

const createTranslationSchema = z.object({
  languageId: z.string().min(1, "语言ID不能为空"),
  key: z.string().min(1, "翻译键不能为空"),
  value: z.string().min(1, "翻译值不能为空"),
  category: z.string().optional(),
  context: z.string().optional(),
});

const updateTranslationSchema = createTranslationSchema.partial().extend({
  id: z.string().min(1, "翻译ID不能为空"),
});

const getTranslationsSchema = z.object({
  languageId: z.string().optional(),
  category: z.string().optional(),
  context: z.string().optional(),
  search: z.string().optional(),
  page: z.number().min(1).default(1),
  limit: z.number().min(1).max(100).default(20),
});

const bulkImportTranslationsSchema = z.object({
  languageId: z.string().min(1, "语言ID不能为空"),
  translations: z.array(z.object({
    key: z.string(),
    value: z.string(),
    category: z.string().optional(),
    context: z.string().optional(),
  })).min(1, "翻译数据不能为空"),
});

export const i18nRouter = createTRPCRouter({
  // 创建语言
  createLanguage: protectedProcedure
    .input(createLanguageSchema)
    .mutation(async ({ input, ctx }) => {
      try {
        // 检查用户是否有创建语言的权限
        const hasPermission = await checkUserPermission(
          ctx.db,
          ctx.session.user.id,
          "SYSTEM",
          "CREATE"
        );
        
        if (!hasPermission) {
          throw new TRPCError({
            code: "FORBIDDEN",
            message: "无权限创建语言",
          });
        }

        // 如果设置为默认语言，先取消其他语言的默认状态
        if (input.isDefault) {
          await ctx.db.dAOLanguage.updateMany({
            where: { isDefault: true },
            data: { isDefault: false },
          });
        }

        const language = await ctx.db.dAOLanguage.create({
          data: {
            code: input.code.toLowerCase(),
            name: input.name,
            nativeName: input.nativeName,
            isDefault: input.isDefault,
          },
        });

        return { success: true, data: language, message: "语言创建成功" };
      } catch (error) {
        console.error("创建语言失败:", error);
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "创建语言失败",
        });
      }
    }),

  // 获取语言列表
  getLanguages: publicProcedure
    .query(async ({ ctx }) => {
      try {
        const languages = await ctx.db.dAOLanguage.findMany({
          where: { isActive: true },
          orderBy: [
            { isDefault: "desc" },
            { name: "asc" },
          ],
        });

        return { success: true, data: languages };
      } catch (error) {
        console.error("获取语言列表失败:", error);
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "获取语言列表失败",
        });
      }
    }),

  // 获取默认语言
  getDefaultLanguage: publicProcedure
    .query(async ({ ctx }) => {
      try {
        const defaultLanguage = await ctx.db.dAOLanguage.findFirst({
          where: { 
            isActive: true,
            isDefault: true,
          },
        });

        // 如果没有默认语言，返回第一个语言
        if (!defaultLanguage) {
          const firstLanguage = await ctx.db.dAOLanguage.findFirst({
            where: { isActive: true },
            orderBy: { name: "asc" },
          });
          return { success: true, data: firstLanguage };
        }

        return { success: true, data: defaultLanguage };
      } catch (error) {
        console.error("获取默认语言失败:", error);
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "获取默认语言失败",
        });
      }
    }),

  // 创建翻译
  createTranslation: protectedProcedure
    .input(createTranslationSchema)
    .mutation(async ({ input, ctx }) => {
      try {
        // 检查用户是否有创建翻译的权限
        const hasPermission = await checkUserPermission(
          ctx.db,
          ctx.session.user.id,
          "SYSTEM",
          "CREATE"
        );
        
        if (!hasPermission) {
          throw new TRPCError({
            code: "FORBIDDEN",
            message: "无权限创建翻译",
          });
        }

        const translation = await ctx.db.dAOTranslation.create({
          data: {
            languageId: BigInt(input.languageId),
            key: input.key,
            value: input.value,
            category: input.category,
            context: input.context,
          },
        });

        return { success: true, data: translation, message: "翻译创建成功" };
      } catch (error) {
        console.error("创建翻译失败:", error);
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "创建翻译失败",
        });
      }
    }),

  // 获取翻译列表
  getTranslations: publicProcedure
    .input(getTranslationsSchema)
    .query(async ({ input, ctx }) => {
      try {
        const where: any = {};
        
        if (input.languageId) {
          where.languageId = BigInt(input.languageId);
        }
        if (input.category) {
          where.category = input.category;
        }
        if (input.context) {
          where.context = input.context;
        }
        if (input.search) {
          where.OR = [
            { key: { contains: input.search } },
            { value: { contains: input.search } },
          ];
        }

        const skip = (input.page - 1) * input.limit;
        
        const [translations, total] = await Promise.all([
          ctx.db.dAOTranslation.findMany({
            where: { ...where, isActive: true },
            include: {
              language: true,
            },
            orderBy: { createdAt: "desc" },
            skip,
            take: input.limit,
          }),
          ctx.db.dAOTranslation.count({ where: { ...where, isActive: true } }),
        ]);

        return {
          success: true,
          data: {
            translations,
            pagination: {
              page: input.page,
              limit: input.limit,
              total,
              totalPages: Math.ceil(total / input.limit),
            },
          },
        };
      } catch (error) {
        console.error("获取翻译列表失败:", error);
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "获取翻译列表失败",
        });
      }
    }),

  // 更新翻译
  updateTranslation: protectedProcedure
    .input(updateTranslationSchema)
    .mutation(async ({ input, ctx }) => {
      try {
        // 检查用户是否有更新翻译的权限
        const hasPermission = await checkUserPermission(
          ctx.db,
          ctx.session.user.id,
          "SYSTEM",
          "UPDATE"
        );
        
        if (!hasPermission) {
          throw new TRPCError({
            code: "FORBIDDEN",
            message: "无权限更新翻译",
          });
        }

        const updateData: any = {};
        if (input.languageId) updateData.languageId = BigInt(input.languageId);
        if (input.key) updateData.key = input.key;
        if (input.value) updateData.value = input.value;
        if (input.category !== undefined) updateData.category = input.category;
        if (input.context !== undefined) updateData.context = input.context;

        const translation = await ctx.db.dAOTranslation.update({
          where: { id: BigInt(input.id) },
          data: updateData,
        });

        return { success: true, data: translation, message: "翻译更新成功" };
      } catch (error) {
        console.error("更新翻译失败:", error);
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "更新翻译失败",
        });
      }
    }),

  // 删除翻译
  deleteTranslation: protectedProcedure
    .input(z.object({ id: z.string().min(1, "翻译ID不能为空") }))
    .mutation(async ({ input, ctx }) => {
      try {
        // 检查用户是否有删除翻译的权限
        const hasPermission = await checkUserPermission(
          ctx.db,
          ctx.session.user.id,
          "SYSTEM",
          "DELETE"
        );
        
        if (!hasPermission) {
          throw new TRPCError({
            code: "FORBIDDEN",
            message: "无权限删除翻译",
          });
        }

        await ctx.db.dAOTranslation.update({
          where: { id: BigInt(input.id) },
          data: { isActive: false },
        });

        return { success: true, message: "翻译删除成功" };
      } catch (error) {
        console.error("删除翻译失败:", error);
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "删除翻译失败",
        });
      }
    }),

  // 批量导入翻译
  bulkImportTranslations: protectedProcedure
    .input(bulkImportTranslationsSchema)
    .mutation(async ({ input, ctx }) => {
      try {
        // 检查用户是否有导入翻译的权限
        const hasPermission = await checkUserPermission(
          ctx.db,
          ctx.session.user.id,
          "SYSTEM",
          "IMPORT"
        );
        
        if (!hasPermission) {
          throw new TRPCError({
            code: "FORBIDDEN",
            message: "无权限导入翻译",
          });
        }

        const results = [];
        let successCount = 0;
        let errorCount = 0;

        for (const translation of input.translations) {
          try {
            const result = await ctx.db.dAOTranslation.upsert({
              where: {
                unique_language_key: {
                  languageId: BigInt(input.languageId),
                  key: translation.key,
                },
              },
              update: {
                value: translation.value,
                category: translation.category,
                context: translation.context,
              },
              create: {
                languageId: BigInt(input.languageId),
                key: translation.key,
                value: translation.value,
                category: translation.category,
                context: translation.context,
              },
            });
            
            results.push({ success: true, data: result });
            successCount++;
          } catch (error) {
            results.push({ 
              success: false, 
              error: error instanceof Error ? error.message : "未知错误",
              key: translation.key 
            });
            errorCount++;
          }
        }

        return {
          success: true,
          data: {
            results,
            summary: {
              total: input.translations.length,
              success: successCount,
              error: errorCount,
            },
          },
          message: `批量导入完成: 成功 ${successCount} 条，失败 ${errorCount} 条`,
        };
      } catch (error) {
        console.error("批量导入翻译失败:", error);
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "批量导入翻译失败",
        });
      }
    }),

  // 获取翻译键列表
  getTranslationKeys: publicProcedure
    .input(z.object({
      languageId: z.string().optional(),
      category: z.string().optional(),
    }))
    .query(async ({ input, ctx }) => {
      try {
        const where: any = { isActive: true };
        
        if (input.languageId) {
          where.languageId = BigInt(input.languageId);
        }
        if (input.category) {
          where.category = input.category;
        }

        const translations = await ctx.db.dAOTranslation.findMany({
          where,
          select: {
            key: true,
            category: true,
            context: true,
          },
          distinct: ['key'],
          orderBy: { key: "asc" },
        });

        return { success: true, data: translations };
      } catch (error) {
        console.error("获取翻译键列表失败:", error);
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "获取翻译键列表失败",
        });
      }
    }),

  // 获取翻译分类列表
  getTranslationCategories: publicProcedure
    .query(async ({ ctx }) => {
      try {
        const categories = await ctx.db.dAOTranslation.findMany({
          where: { 
            isActive: true,
            category: { not: null },
          },
          select: {
            category: true,
          },
          distinct: ['category'],
          orderBy: { category: "asc" },
        });

        return { 
          success: true, 
          data: categories.map(item => item.category).filter(Boolean) 
        };
      } catch (error) {
        console.error("获取翻译分类列表失败:", error);
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "获取翻译分类列表失败",
        });
      }
    }),

  // 获取语言翻译统计
  getLanguageStats: publicProcedure
    .input(z.object({
      languageId: z.string().optional(),
    }))
    .query(async ({ input, ctx }) => {
      try {
        const where: any = { isActive: true };
        
        if (input.languageId) {
          where.languageId = BigInt(input.languageId);
        }

        const [
          totalTranslations,
          categoryStats,
          recentTranslations,
        ] = await Promise.all([
          ctx.db.dAOTranslation.count({ where }),
          ctx.db.dAOTranslation.groupBy({
            by: ['category'],
            where,
            _count: {
              category: true,
            },
            orderBy: {
              _count: {
                category: 'desc',
              },
            },
          }),
          ctx.db.dAOTranslation.count({
            where: {
              ...where,
              createdAt: {
                gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000), // 最近30天
              },
            },
          }),
        ]);

        return {
          success: true,
          data: {
            totalTranslations,
            categoryStats,
            recentTranslations,
          },
        };
      } catch (error) {
        console.error("获取语言统计失败:", error);
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "获取语言统计失败",
        });
      }
    }),

  // 获取翻译文本 (用于前端显示)
  getTranslationText: publicProcedure
    .input(z.object({
      languageCode: z.string().min(2, "语言代码不能为空"),
      key: z.string().min(1, "翻译键不能为空"),
    }))
    .query(async ({ input, ctx }) => {
      try {
        // 先查找指定语言的翻译
        let translation = await ctx.db.dAOTranslation.findFirst({
          where: {
            key: input.key,
            isActive: true,
            language: {
              code: input.languageCode.toLowerCase(),
              isActive: true,
            },
          },
          include: {
            language: true,
          },
        });

        // 如果没有找到，查找默认语言的翻译
        if (!translation) {
          translation = await ctx.db.dAOTranslation.findFirst({
            where: {
              key: input.key,
              isActive: true,
              language: {
                isDefault: true,
                isActive: true,
              },
            },
            include: {
              language: true,
            },
          });
        }

        // 如果还是没有找到，返回键名本身
        const value = translation ? translation.value : input.key;

        return { 
          success: true, 
          data: { 
            key: input.key,
            value,
            language: translation?.language?.code || input.languageCode,
          } 
        };
      } catch (error) {
        console.error("获取翻译文本失败:", error);
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "获取翻译文本失败",
        });
      }
    }),

  // 批量获取翻译文本 (用于前端批量加载)
  getBatchTranslationTexts: publicProcedure
    .input(z.object({
      languageCode: z.string().min(2, "语言代码不能为空"),
      keys: z.array(z.string()).min(1, "翻译键列表不能为空"),
    }))
    .query(async ({ input, ctx }) => {
      try {
        // 获取指定语言的翻译
        const translations = await ctx.db.dAOTranslation.findMany({
          where: {
            key: { in: input.keys },
            isActive: true,
            language: {
              code: input.languageCode.toLowerCase(),
              isActive: true,
            },
          },
          include: {
            language: true,
          },
        });

        // 获取默认语言的翻译（用于补充缺失的翻译）
        const defaultTranslations = await ctx.db.dAOTranslation.findMany({
          where: {
            key: { in: input.keys },
            isActive: true,
            language: {
              isDefault: true,
              isActive: true,
            },
          },
          include: {
            language: true,
          },
        });

        // 合并结果
        const translationMap = new Map();
        
        // 先添加指定语言的翻译
        translations.forEach(t => {
          translationMap.set(t.key, {
            key: t.key,
            value: t.value,
            language: t.language.code,
          });
        });

        // 再添加默认语言的翻译（如果指定语言没有）
        defaultTranslations.forEach(t => {
          if (!translationMap.has(t.key)) {
            translationMap.set(t.key, {
              key: t.key,
              value: t.value,
              language: t.language.code,
            });
          }
        });

        // 为缺失的键添加默认值
        const result = input.keys.map(key => {
          if (translationMap.has(key)) {
            return translationMap.get(key);
          }
          return {
            key,
            value: key, // 如果没有翻译，返回键名本身
            language: input.languageCode,
          };
        });

        return { success: true, data: result };
      } catch (error) {
        console.error("批量获取翻译文本失败:", error);
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "批量获取翻译文本失败",
        });
      }
    }),

  // 获取支持的默认语言列表
  getSupportedLanguages: publicProcedure
    .query(async () => {
      const supportedLanguages = [
        { code: "zh", name: "中文", nativeName: "中文", isDefault: true },
        { code: "en", name: "English", nativeName: "English", isDefault: false },
        { code: "ja", name: "日本語", nativeName: "日本語", isDefault: false },
        { code: "ko", name: "한국어", nativeName: "한국어", isDefault: false },
        { code: "es", name: "Español", nativeName: "Español", isDefault: false },
        { code: "fr", name: "Français", nativeName: "Français", isDefault: false },
        { code: "de", name: "Deutsch", nativeName: "Deutsch", isDefault: false },
        { code: "ru", name: "Русский", nativeName: "Русский", isDefault: false },
        { code: "pt", name: "Português", nativeName: "Português", isDefault: false },
        { code: "it", name: "Italiano", nativeName: "Italiano", isDefault: false },
      ];

      return { success: true, data: supportedLanguages };
    }),

  // 获取默认翻译模板
  getDefaultTranslationTemplate: publicProcedure
    .input(z.object({
      languageCode: z.string().min(2, "语言代码不能为空"),
    }))
    .query(async ({ input }) => {
      const defaultTranslations = {
        // 通用
        common: {
          save: "保存",
          cancel: "取消",
          delete: "删除",
          edit: "编辑",
          create: "创建",
          update: "更新",
          search: "搜索",
          filter: "筛选",
          export: "导出",
          import: "导入",
          loading: "加载中...",
          success: "成功",
          error: "错误",
          warning: "警告",
          confirm: "确认",
          yes: "是",
          no: "否",
        },
        
        // 导航
        navigation: {
          home: "首页",
          proposals: "提案",
          votes: "投票",
          members: "成员",
          analytics: "分析",
          settings: "设置",
          profile: "个人资料",
          logout: "退出登录",
        },
        
        // DAO相关
        dao: {
          title: "DAO治理系统",
          description: "基于积分的去中心化自治组织治理平台",
          createProposal: "创建提案",
          voteOnProposal: "投票",
          memberList: "成员列表",
          governanceStats: "治理统计",
          treasuryManagement: "国库管理",
        },
        
        // 权限相关
        permission: {
          accessDenied: "访问被拒绝",
          insufficientPermissions: "权限不足",
          roleRequired: "需要角色",
          adminOnly: "仅管理员",
        },
        
        // 审计相关
        audit: {
          auditLog: "审计日志",
          securityEvents: "安全事件",
          systemActivity: "系统活动",
          complianceReport: "合规报告",
        },
      };

      // 根据语言代码返回相应的翻译
      // 这里简化处理，实际应该根据语言代码返回对应的翻译
      return { 
        success: true, 
        data: {
          languageCode: input.languageCode,
          translations: defaultTranslations,
        } 
      };
    }),
});

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
