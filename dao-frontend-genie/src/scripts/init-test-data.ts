// 初始化测试数据的脚本
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function initTestData() {
  try {
    console.log('开始初始化测试数据...');

    // 创建测试成员
    const members = [
      {
        userId: 'user_001',
        walletAddress: '0x1234567890123456789012345678901234567890',
        reputationScore: 100,
        contributionPoints: 50,
        status: 'ACTIVE' as const,
      },
      {
        userId: 'user_002',
        walletAddress: '0x2345678901234567890123456789012345678901',
        reputationScore: 85,
        contributionPoints: 35,
        status: 'ACTIVE' as const,
      },
      {
        userId: 'user_003',
        walletAddress: '0x3456789012345678901234567890123456789012',
        reputationScore: 70,
        contributionPoints: 25,
        status: 'ACTIVE' as const,
      },
    ];

    console.log('创建测试成员...');
    for (const memberData of members) {
      await prisma.dAOMember.upsert({
        where: { userId: memberData.userId },
        update: memberData,
        create: memberData,
      });
    }

    // 创建测试提案
    const proposals = [
      {
        proposalId: 'prop_001',
        title: 'DAO治理机制优化提案',
        description: '建议优化DAO治理机制，提高决策效率。具体包括：1. 调整投票权重计算方式；2. 缩短提案审核周期；3. 增加提案执行透明度。',
        proposerId: 'user_001',
        proposalType: 'GOVERNANCE' as const,
        status: 'ACTIVE' as const,
        startTime: new Date(),
        endTime: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7天后
        votesFor: 25,
        votesAgainst: 8,
        totalVotes: 33,
      },
      {
        proposalId: 'prop_002',
        title: '技术架构升级提案',
        description: '建议升级系统技术架构，提高性能和安全性。包括：1. 升级数据库版本；2. 优化API响应速度；3. 增强安全防护措施。',
        proposerId: 'user_002',
        proposalType: 'TECHNICAL' as const,
        status: 'DRAFT' as const,
        votesFor: 0,
        votesAgainst: 0,
        totalVotes: 0,
      },
      {
        proposalId: 'prop_003',
        title: '社区基金分配提案',
        description: '建议将社区基金按以下比例分配：开发团队40%，社区奖励30%，运营费用20%，储备资金10%。',
        proposerId: 'user_003',
        proposalType: 'FUNDING' as const,
        status: 'PASSED' as const,
        startTime: new Date(Date.now() - 14 * 24 * 60 * 60 * 1000), // 14天前
        endTime: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000), // 7天前
        votesFor: 45,
        votesAgainst: 12,
        totalVotes: 57,
      },
    ];

    console.log('创建测试提案...');
    for (const proposalData of proposals) {
      await prisma.dAOProposal.upsert({
        where: { proposalId: proposalData.proposalId },
        update: proposalData,
        create: proposalData,
      });
    }

    // 创建测试投票记录
    const votes = [
      {
        proposalId: 'prop_001',
        voterId: 'user_001',
        voteChoice: 'FOR' as const,
        votingPower: 85,
      },
      {
        proposalId: 'prop_001',
        voterId: 'user_002',
        voteChoice: 'AGAINST' as const,
        votingPower: 72,
      },
      {
        proposalId: 'prop_003',
        voterId: 'user_001',
        voteChoice: 'FOR' as const,
        votingPower: 85,
      },
      {
        proposalId: 'prop_003',
        voterId: 'user_002',
        voteChoice: 'FOR' as const,
        votingPower: 72,
      },
      {
        proposalId: 'prop_003',
        voterId: 'user_003',
        voteChoice: 'AGAINST' as const,
        votingPower: 58,
      },
    ];

    console.log('创建测试投票记录...');
    for (const voteData of votes) {
      await prisma.dAOVote.upsert({
        where: {
          unique_vote: {
            proposalId: voteData.proposalId,
            voterId: voteData.voterId,
          },
        },
        update: voteData,
        create: voteData,
      });
    }

    // 创建测试活动记录
    const activities = [
      {
        userId: 'user_001',
        activityType: 'PROPOSAL_CREATED',
        activityDescription: '创建了提案: DAO治理机制优化提案',
        metadata: { proposalId: 'prop_001' },
      },
      {
        userId: 'user_002',
        activityType: 'VOTE_CAST',
        activityDescription: '对提案进行了投票: 技术架构升级提案',
        metadata: { proposalId: 'prop_001', voteChoice: 'AGAINST' },
      },
      {
        userId: 'user_003',
        activityType: 'REPUTATION_EARNED',
        activityDescription: '因参与治理获得了声誉积分',
        metadata: { points: 10, reason: 'active_participation' },
      },
    ];

    console.log('创建测试活动记录...');
    for (const activityData of activities) {
      await prisma.dAOActivity.create({
        data: activityData,
      });
    }

    console.log('测试数据初始化完成！');
    console.log('创建的数据:');
    console.log(`- 成员: ${members.length} 个`);
    console.log(`- 提案: ${proposals.length} 个`);
    console.log(`- 投票: ${votes.length} 条`);
    console.log(`- 活动: ${activities.length} 条`);

  } catch (error) {
    console.error('初始化测试数据失败:', error);
    throw error;
  } finally {
    await prisma.$disconnect();
  }
}

// 如果直接运行此脚本
if (require.main === module) {
  initTestData()
    .then(() => {
      console.log('脚本执行完成');
      process.exit(0);
    })
    .catch((error) => {
      console.error('脚本执行失败:', error);
      process.exit(1);
    });
}

export default initTestData;

