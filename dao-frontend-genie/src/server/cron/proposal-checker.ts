import cron from 'node-cron';
import { db } from '@/server/db';
import { zervigoStatistics } from '@/server/integrations/zervigo-statistics';
import { zervigoNotification } from '@/server/integrations/zervigo-notification';
import { zervigoBanner } from '@/server/integrations/zervigo-banner';

// 启动提案检查器
export const startProposalChecker = () => {
  console.log('🔄 启动提案状态检查器...');
  
  // 每分钟检查一次活跃提案
  cron.schedule('* * * * *', async () => {
    try {
      await checkAndUpdateProposalStatus();
    } catch (error) {
      console.error('提案状态检查失败:', error);
    }
  });

  console.log('✅ 提案状态检查器已启动，每分钟检查一次');
};

// 检查并更新提案状态
const checkAndUpdateProposalStatus = async () => {
  const now = new Date();
  
  // 查找所有活跃的提案
  const activeProposals = await db.dAOProposal.findMany({
    where: { 
      status: "ACTIVE" 
    },
    include: { 
      votes: true 
    }
  });

  console.log(`🔍 检查 ${activeProposals.length} 个活跃提案`);

  for (const proposal of activeProposals) {
    // 检查是否超过投票截止时间
    if (proposal.endTime && now > proposal.endTime) {
      await processExpiredProposal(proposal);
    } else {
      // 检查是否需要发送投票提醒
      await checkAndSendVotingReminder(proposal);
    }
  }
};

// 处理过期的提案
const processExpiredProposal = async (proposal: any) => {
  console.log(`⏰ 处理过期提案: ${proposal.proposalId}`);
  
  const totalVotes = proposal.votesFor + proposal.votesAgainst;
  const passThreshold = 0.5; // 50%通过率
  
  let newStatus: string;
  let message: string;
  
  if (totalVotes === 0) {
    newStatus = "REJECTED";
    message = "无人投票，提案被拒绝";
  } else {
    const passRate = proposal.votesFor / totalVotes;
    if (passRate >= passThreshold) {
      newStatus = "PASSED";
      message = `提案通过 (${(passRate * 100).toFixed(1)}%支持率)`;
    } else {
      newStatus = "REJECTED";
      message = `提案被拒绝 (${(passRate * 100).toFixed(1)}%支持率)`;
    }
  }
  
  // 更新提案状态
  await db.dAOProposal.update({
    where: { proposalId: proposal.proposalId },
    data: { 
      status: newStatus,
      updatedAt: new Date()
    }
  });
  
  console.log(`✅ 提案 ${proposal.proposalId} 状态更新为: ${newStatus} - ${message}`);
  
  // 推送投票结果到Zervigo统计服务
  await pushVoteResultToZervigo(proposal, newStatus, message);
  
  // 发送提案结果通知
  await sendProposalResultNotification(proposal, newStatus, message);
  
  // 创建提案结果Banner公告
  await createProposalResultBanner(proposal, newStatus, message);
};

// 推送投票结果到Zervigo统计服务
const pushVoteResultToZervigo = async (proposal: any, newStatus: string, message: string) => {
  try {
    // 获取投票详情
    const votes = await db.dAOVote.findMany({
      where: { proposalId: proposal.proposalId },
      include: { voter: true }
    });

    // 计算统计数据
    const totalVotes = proposal.votesFor + proposal.votesAgainst;
    const passRate = totalVotes > 0 ? proposal.votesFor / totalVotes : 0;
    const voterCount = votes.length;
    const averageVotingPower = voterCount > 0 ? votes.reduce((sum, vote) => sum + vote.votingPower, 0) / voterCount : 0;

    // 构建投票结果数据
    const voteResult = {
      proposalId: proposal.proposalId,
      title: proposal.title,
      description: proposal.description,
      proposalType: proposal.proposalType,
      status: newStatus as 'PASSED' | 'REJECTED' | 'ACTIVE',
      votesFor: proposal.votesFor,
      votesAgainst: proposal.votesAgainst,
      totalVotes: proposal.totalVotes,
      passRate,
      voterCount,
      averageVotingPower,
      startTime: proposal.startTime,
      endTime: proposal.endTime,
      createdAt: proposal.createdAt,
      updatedAt: new Date(),
    };

    // 推送到Zervigo统计服务
    await zervigoStatistics.pushProposalResult(voteResult);

    // 推送投票行为分析
    for (const vote of votes) {
      const timeToVote = vote.voteTimestamp ? 
        (vote.voteTimestamp.getTime() - proposal.createdAt.getTime()) / (1000 * 60 * 60) : 0;
      
      await zervigoStatistics.pushVotingBehavior({
        proposalId: proposal.proposalId,
        voterId: vote.voterId,
        voteChoice: vote.voteChoice,
        votingPower: vote.votingPower,
        voterReputation: vote.voter?.reputationScore || 0,
        voterContribution: vote.voter?.contributionPoints || 0,
        voteTimestamp: vote.voteTimestamp,
        timeToVote,
      });
    }

    console.log(`📊 投票结果已推送到Zervigo统计服务: ${proposal.proposalId}`);
  } catch (error) {
    console.error(`❌ 推送投票结果到Zervigo失败:`, error);
    // 不抛出错误，避免影响提案处理流程
  }
};

// 检查并发送投票提醒
const checkAndSendVotingReminder = async (proposal: any) => {
  try {
    if (!proposal.endTime) return;

    const now = new Date();
    const remainingHours = Math.ceil((proposal.endTime.getTime() - now.getTime()) / (1000 * 60 * 60));

    // 在投票结束前24小时和48小时发送提醒
    if (remainingHours === 24 || remainingHours === 48) {
      const votes = await db.dAOVote.findMany({
        where: { proposalId: proposal.proposalId }
      });

      const activeMembers = await db.dAOMember.findMany({
        where: { status: 'ACTIVE' }
      });

      const voterCount = votes.length;
      const totalMembers = activeMembers.length;
      const participationRate = totalMembers > 0 ? voterCount / totalMembers : 0;

      const targetUserIds = activeMembers.map(member => Number(member.id));

      await zervigoNotification.sendVotingReminderNotification({
        proposalId: proposal.proposalId,
        title: proposal.title,
        remainingHours,
        totalVotes: proposal.totalVotes,
        voterCount,
        participationRate,
      }, targetUserIds);

      console.log(`⏰ 投票提醒已发送: ${proposal.proposalId} (剩余${remainingHours}小时)`);
    }
  } catch (error) {
    console.error(`❌ 发送投票提醒失败:`, error);
  }
};

// 发送提案结果通知
const sendProposalResultNotification = async (proposal: any, newStatus: string, message: string) => {
  try {
    const votes = await db.dAOVote.findMany({
      where: { proposalId: proposal.proposalId }
    });

    const activeMembers = await db.dAOMember.findMany({
      where: { status: 'ACTIVE' }
    });

    const totalVotes = proposal.votesFor + proposal.votesAgainst;
    const passRate = totalVotes > 0 ? proposal.votesFor / totalVotes : 0;

    const targetUserIds = activeMembers.map(member => Number(member.id));

    await zervigoNotification.sendProposalResultNotification({
      proposalId: proposal.proposalId,
      title: proposal.title,
      status: newStatus as 'PASSED' | 'REJECTED',
      votesFor: proposal.votesFor,
      votesAgainst: proposal.votesAgainst,
      totalVotes: proposal.totalVotes,
      passRate,
      voterCount: votes.length,
      message,
    }, targetUserIds);

    console.log(`📊 提案结果通知已发送: ${proposal.proposalId} - ${newStatus}`);
  } catch (error) {
    console.error(`❌ 发送提案结果通知失败:`, error);
  }
};

// 创建提案结果Banner公告
const createProposalResultBanner = async (proposal: any, newStatus: string, message: string) => {
  try {
    const votes = await db.dAOVote.findMany({
      where: { proposalId: proposal.proposalId }
    });

    const totalVotes = proposal.votesFor + proposal.votesAgainst;
    const passRate = totalVotes > 0 ? proposal.votesFor / totalVotes : 0;

    await zervigoBanner.createProposalResultBanner({
      proposalId: proposal.proposalId,
      title: proposal.title,
      description: proposal.description,
      proposalType: proposal.proposalType,
      proposerName: '系统',
      status: newStatus as 'PASSED' | 'REJECTED',
      startTime: proposal.startTime,
      endTime: proposal.endTime,
      votesFor: proposal.votesFor,
      votesAgainst: proposal.votesAgainst,
      totalVotes: proposal.totalVotes,
      passRate,
      voterCount: votes.length,
      message,
    });

    console.log(`📢 提案结果Banner公告已创建: ${proposal.proposalId} - ${newStatus}`);
  } catch (error) {
    console.error(`❌ 创建提案结果Banner公告失败:`, error);
  }
};

// 获取提案统计信息
export const getProposalStats = async () => {
  const stats = await db.dAOProposal.groupBy({
    by: ['status'],
    _count: {
      proposalId: true
    }
  });
  
  return stats.reduce((acc, stat) => {
    acc[stat.status] = stat._count.proposalId;
    return acc;
  }, {} as Record<string, number>);
};
