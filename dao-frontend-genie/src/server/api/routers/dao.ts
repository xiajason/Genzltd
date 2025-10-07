import { z } from "zod";
import { createTRPCRouter, procedure } from "@/server/api/trpc";
import { db } from "@/server/db";
import { zervigoStatistics } from "@/server/integrations/zervigo-statistics";
import { zervigoNotification } from "@/server/integrations/zervigo-notification";
import { zervigoBanner } from "@/server/integrations/zervigo-banner";

// 输入验证Schema
const createProposalSchema = z.object({
  title: z.string().min(1, "提案标题不能为空"),
  description: z.string().min(10, "提案描述至少10个字符"),
  proposalType: z.enum(["GOVERNANCE", "FUNDING", "TECHNICAL", "POLICY"]),
  proposerId: z.string(),
  startTime: z.string().optional(),
  endTime: z.string().optional(),
});

const voteSchema = z.object({
  proposalId: z.string(),
  voterId: z.string(),
  voteChoice: z.enum(["FOR", "AGAINST", "ABSTAIN"]),
});

const createDAOSchema = z.object({
  name: z.string().min(1, "DAO名称不能为空"),
  description: z.string().min(10, "DAO描述至少10个字符"),
  creatorId: z.string(),
});

export const daoRouter = createTRPCRouter({
  // 创建提案
  createProposal: procedure
    .input(createProposalSchema)
    .mutation(async ({ input }) => {
      try {
        // 生成唯一的提案ID
        const proposalId = `prop_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
        
        // 自动设置投票时间（默认7天）
        const now = new Date();
        const endTime = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000); // 7天后
        
        const proposal = await db.dAOProposal.create({
          data: {
            proposalId,
            title: input.title,
            description: input.description,
            proposerId: input.proposerId,
            proposalType: input.proposalType,
            status: "ACTIVE", // ✅ 自动激活
            startTime: now,   // ✅ 自动开始时间
            endTime: endTime, // ✅ 自动结束时间
          },
          include: {
            proposer: true,
          },
        });

        // 发送提案创建通知
        try {
          const proposer = await db.dAOMember.findUnique({
            where: { userId: input.proposerId }
          });

          const activeMembers = await db.dAOMember.findMany({
            where: { status: 'ACTIVE' },
            select: { id: true }
          });

          const targetUserIds = activeMembers.map(member => Number(member.id));

          if (proposer && targetUserIds.length > 0) {
            await zervigoNotification.sendProposalCreatedNotification({
              proposalId: proposal.proposalId,
              title: proposal.title,
              description: proposal.description,
              proposalType: proposal.proposalType,
              proposerId: proposal.proposerId,
              proposerName: proposer.username || proposer.firstName || '未知用户',
              status: proposal.status,
              startTime: proposal.startTime,
              endTime: proposal.endTime,
              votingDeadline: proposal.endTime,
            }, targetUserIds);

            console.log(`📢 提案创建通知已发送: ${proposal.proposalId}`);
          }

          // 创建提案Banner公告
          await zervigoBanner.createProposalBanner({
            proposalId: proposal.proposalId,
            title: proposal.title,
            description: proposal.description,
            proposalType: proposal.proposalType,
            proposerName: proposer.username || proposer.firstName || '未知用户',
            status: proposal.status,
            startTime: proposal.startTime,
            endTime: proposal.endTime,
            votesFor: 0,
            votesAgainst: 0,
            totalVotes: 0,
            passRate: 0,
            voterCount: 0,
          });

          // 创建提案详情Markdown内容
          await zervigoBanner.createProposalMarkdownContent({
            proposalId: proposal.proposalId,
            title: proposal.title,
            description: proposal.description,
            proposalType: proposal.proposalType,
            proposerName: proposer.username || proposer.firstName || '未知用户',
            status: proposal.status,
            startTime: proposal.startTime,
            endTime: proposal.endTime,
            votesFor: 0,
            votesAgainst: 0,
            totalVotes: 0,
            passRate: 0,
            voterCount: 0,
          });

          console.log(`📢 提案Banner公告和Markdown内容已创建: ${proposal.proposalId}`);
        } catch (error) {
          console.error(`❌ 发送提案创建通知或创建Banner失败:`, error);
          // 不抛出错误，避免影响提案创建流程
        }

        return {
          success: true,
          data: proposal,
          message: "提案创建成功并已自动激活，投票期7天",
        };
      } catch (error) {
        console.error("创建提案失败:", error);
        throw new Error("创建提案失败");
      }
    }),

  // 获取所有提案
  getProposals: procedure
    .input(z.object({
      page: z.number().default(1),
      limit: z.number().default(10),
      status: z.string().optional(),
      type: z.string().optional(),
    }))
    .query(async ({ input }) => {
      try {
        const { page, limit, status, type } = input;
        const skip = (page - 1) * limit;

        const where = {
          ...(status && { status: status as any }),
          ...(type && { proposalType: type as any }),
        };

        const [proposals, total] = await Promise.all([
          db.dAOProposal.findMany({
            where,
            skip,
            take: limit,
            include: {
              proposer: true,
            },
            orderBy: {
              createdAt: "desc",
            },
          }),
          db.dAOProposal.count({ where }),
        ]);

        return {
          success: true,
          data: proposals,
          pagination: {
            page,
            limit,
            total,
            totalPages: Math.ceil(total / limit),
          },
        };
      } catch (error) {
        console.error("获取提案失败:", error);
        throw new Error("获取提案失败");
      }
    }),

  // 获取提案详情
  getProposal: procedure
    .input(z.object({ id: z.string() }))
    .query(async ({ input }) => {
      try {
        const proposal = await db.dAOProposal.findUnique({
          where: { proposalId: input.id },
          include: {
            proposer: true,
            votes: {
              include: {
                voter: true,
              },
            },
          },
        });

        if (!proposal) {
          throw new Error("提案不存在");
        }

        return {
          success: true,
          data: proposal,
        };
      } catch (error) {
        console.error("获取提案详情失败:", error);
        throw new Error("获取提案详情失败");
      }
    }),

  // 激活提案
  activateProposal: procedure
    .input(z.object({ proposalId: z.string() }))
    .mutation(async ({ input }) => {
      try {
        const proposal = await db.dAOProposal.update({
          where: { proposalId: input.proposalId },
          data: {
            status: "ACTIVE",
            startTime: new Date(),
            endTime: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7天后结束
          },
        });

        return {
          success: true,
          data: proposal,
          message: "提案已激活",
        };
      } catch (error) {
        console.error("激活提案失败:", error);
        throw new Error("激活提案失败");
      }
    }),

  // 投票
  vote: procedure
    .input(voteSchema)
    .mutation(async ({ input }) => {
      try {
        // 检查提案是否存在且处于活跃状态
        const proposal = await db.dAOProposal.findUnique({
          where: { proposalId: input.proposalId },
        });

        if (!proposal) {
          throw new Error("提案不存在");
        }

        if (proposal.status !== "ACTIVE") {
          throw new Error("提案未激活或已结束");
        }

        // 检查是否已经投票
        const existingVote = await db.dAOVote.findFirst({
          where: {
            proposalId: input.proposalId,
            voterId: input.voterId,
          },
        });

        if (existingVote) {
          throw new Error("您已经投过票了");
        }

        // 获取投票者信息以计算投票权重
        const voter = await db.dAOMember.findUnique({
          where: { userId: input.voterId },
        });

        if (!voter) {
          throw new Error("投票者不存在");
        }

        // 计算投票权重（基于声誉积分和贡献积分）
        const votingPower = Math.floor((voter.reputationScore * 0.6 + voter.contributionPoints * 0.4) / 10);

        // 创建投票记录
        const vote = await db.dAOVote.create({
          data: {
            proposalId: input.proposalId,
            voterId: input.voterId,
            voteChoice: input.voteChoice,
            votingPower,
          },
        });

        // 更新提案投票统计
        const voteUpdates = {
          votesFor: input.voteChoice === "FOR" ? 1 : 0,
          votesAgainst: input.voteChoice === "AGAINST" ? 1 : 0,
          totalVotes: 1,
        };

        await db.dAOProposal.update({
          where: { proposalId: input.proposalId },
          data: {
            votesFor: { increment: voteUpdates.votesFor },
            votesAgainst: { increment: voteUpdates.votesAgainst },
            totalVotes: { increment: voteUpdates.totalVotes },
          },
        });

        // 推送投票行为到Zervigo统计服务
        try {
          const timeToVote = (new Date().getTime() - proposal.createdAt.getTime()) / (1000 * 60 * 60);
          
          await zervigoStatistics.pushVotingBehavior({
            proposalId: input.proposalId,
            voterId: input.voterId,
            voteChoice: input.voteChoice,
            votingPower,
            voterReputation: voter.reputationScore,
            voterContribution: voter.contributionPoints,
            voteTimestamp: new Date(),
            timeToVote,
          });
          
          console.log(`📊 投票行为已推送到Zervigo统计服务: ${input.proposalId} - ${input.voterId}`);
        } catch (error) {
          console.error(`❌ 推送投票行为到Zervigo失败:`, error);
          // 不抛出错误，避免影响投票流程
        }

        return {
          success: true,
          data: vote,
          message: "投票成功",
        };
      } catch (error) {
        console.error("投票失败:", error);
        throw new Error(error instanceof Error ? error.message : "投票失败");
      }
    }),

  // 获取用户投票记录
  getUserVote: procedure
    .input(z.object({ proposalId: z.string(), voterId: z.string() }))
    .query(async ({ input }) => {
      try {
        const vote = await db.dAOVote.findUnique({
          where: {
            unique_vote: {
              proposalId: input.proposalId,
              voterId: input.voterId,
            },
          },
        });

        return {
          success: true,
          data: vote,
        };
      } catch (error) {
        console.error("获取投票记录失败:", error);
        throw new Error("获取投票记录失败");
      }
    }),

  // 获取成员列表
  getMembers: procedure
    .input(z.object({
      page: z.number().default(1),
      limit: z.number().default(10),
      status: z.string().optional(),
    }))
    .query(async ({ input }) => {
      try {
        const { page, limit, status } = input;
        const skip = (page - 1) * limit;

        const where = {
          ...(status && { status: status as any }),
        };

        const [members, total] = await Promise.all([
          db.dAOMember.findMany({
            where,
            skip,
            take: limit,
            orderBy: {
              reputationScore: "desc",
            },
          }),
          db.dAOMember.count({ where }),
        ]);

        // 计算投票权重并格式化数据
        const membersWithVotingPower = members.map(member => ({
          ...member,
          votingPower: Math.floor((member.reputationScore * 0.6 + member.contributionPoints * 0.4) / 10),
          // 格式化JSON字段为数组
          skillsList: member.skills ? (typeof member.skills === 'string' ? JSON.parse(member.skills) : member.skills) : [],
          interestsList: member.interests ? (typeof member.interests === 'string' ? JSON.parse(member.interests) : member.interests) : [],
          languagesList: member.languages ? (typeof member.languages === 'string' ? JSON.parse(member.languages) : member.languages) : [],
        }));

        return {
          success: true,
          data: membersWithVotingPower,
          pagination: {
            page,
            limit,
            total,
            totalPages: Math.ceil(total / limit),
          },
        };
      } catch (error) {
        console.error("获取成员列表失败:", error);
        throw new Error("获取成员列表失败");
      }
    }),

  // 创建DAO
  createDAO: procedure
    .input(createDAOSchema)
    .mutation(async ({ input }) => {
      try {
        // 这里可以扩展为实际的DAO创建逻辑
        // 目前返回成功响应，实际实现需要根据具体需求
        return {
          success: true,
          data: {
            id: `dao_${Date.now()}`,
            name: input.name,
            description: input.description,
            creatorId: input.creatorId,
            createdAt: new Date(),
          },
          message: "DAO创建成功",
        };
      } catch (error) {
        console.error("创建DAO失败:", error);
        throw new Error("创建DAO失败");
      }
    }),

  // 获取统计信息
  getStats: procedure
    .query(async () => {
      try {
        const [totalMembers, activeProposals, totalProposals, avgReputation] = await Promise.all([
          db.dAOMember.count({ where: { status: "ACTIVE" } }),
          db.dAOProposal.count({ where: { status: "ACTIVE" } }),
          db.dAOProposal.count(),
          db.dAOMember.aggregate({
            _avg: {
              reputationScore: true,
            },
          }),
        ]);

        return {
          success: true,
          data: {
            totalMembers,
            activeProposals,
            totalProposals,
            avgReputation: Math.round(avgReputation._avg.reputationScore || 0),
            totalRewards: 0, // 可以后续实现
          },
        };
      } catch (error) {
        console.error("获取统计信息失败:", error);
        throw new Error("获取统计信息失败");
      }
    }),
});

