import cron from 'node-cron';
import { db } from '@/server/db';
import { zervigoStatistics } from '@/server/integrations/zervigo-statistics';

// 启动治理统计同步器
export const startGovernanceStatsSync = () => {
  console.log('📊 启动治理统计同步器...');
  
  // 每小时同步一次治理统计数据
  cron.schedule('0 * * * *', async () => {
    try {
      await syncGovernanceStatistics();
    } catch (error) {
      console.error('治理统计同步失败:', error);
    }
  });

  console.log('✅ 治理统计同步器已启动，每小时同步一次');
};

// 同步治理统计数据
const syncGovernanceStatistics = async () => {
  try {
    console.log('🔄 开始同步治理统计数据...');

    // 获取提案统计
    const proposalStats = await db.dAOProposal.groupBy({
      by: ['status'],
      _count: {
        proposalId: true
      }
    });

    const stats = proposalStats.reduce((acc, stat) => {
      acc[stat.status] = stat._count.proposalId;
      return acc;
    }, {} as Record<string, number>);

    // 获取投票统计
    const voteStats = await db.dAOVote.findMany({
      include: { voter: true }
    });

    // 获取成员统计
    const memberStats = await db.dAOMember.findMany({
      where: { status: 'ACTIVE' }
    });

    // 计算参与度数据
    const totalProposals = Object.values(stats).reduce((sum, count) => sum + count, 0);
    const activeProposals = stats.ACTIVE || 0;
    const passedProposals = stats.PASSED || 0;
    const rejectedProposals = stats.REJECTED || 0;
    const totalVotes = voteStats.length;
    const uniqueVoters = new Set(voteStats.map(vote => vote.voterId)).size;
    const averageParticipationRate = memberStats.length > 0 ? uniqueVoters / memberStats.length : 0;

    // 获取活跃投票者
    const voterCounts = voteStats.reduce((acc, vote) => {
      acc[vote.voterId] = (acc[vote.voterId] || 0) + 1;
      return acc;
    }, {} as Record<string, number>);

    const topVotingMembers = Object.entries(voterCounts)
      .sort(([, a], [, b]) => b - a)
      .slice(0, 5)
      .map(([userId, voteCount]) => {
        const voter = voteStats.find(v => v.voterId === userId)?.voter;
        return {
          userId,
          username: voter?.username || 'Unknown',
          voteCount,
          votingPower: voter ? Math.floor((voter.reputationScore * 0.6 + voter.contributionPoints * 0.4) / 10) : 0,
        };
      });

    // 构建治理参与度数据
    const participationData = {
      totalProposals,
      activeProposals,
      passedProposals,
      rejectedProposals,
      totalVotes,
      uniqueVoters,
      averageParticipationRate,
      topVotingMembers,
    };

    // 推送到Zervigo统计服务
    await zervigoStatistics.pushGovernanceStatistics(participationData);

    console.log(`✅ 治理统计数据同步完成:`, {
      totalProposals,
      activeProposals,
      passedProposals,
      rejectedProposals,
      totalVotes,
      uniqueVoters,
      averageParticipationRate: (averageParticipationRate * 100).toFixed(1) + '%',
    });

  } catch (error) {
    console.error('❌ 同步治理统计数据失败:', error);
  }
};

// 手动触发同步（用于测试）
export const triggerGovernanceStatsSync = async () => {
  await syncGovernanceStatistics();
};
