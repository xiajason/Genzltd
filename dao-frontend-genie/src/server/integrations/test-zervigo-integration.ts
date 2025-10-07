import { zervigoStatistics } from './zervigo-statistics';

// 测试Zervigo统计服务集成
export const testZervigoIntegration = async () => {
  console.log('🧪 开始测试Zervigo统计服务集成...');

  try {
    // 测试数据
    const testVoteResult = {
      proposalId: 'test_prop_001',
      title: '测试提案 - 集成功能验证',
      description: '这是一个用于测试Zervigo集成的测试提案',
      proposalType: 'GOVERNANCE',
      status: 'PASSED' as const,
      votesFor: 3,
      votesAgainst: 1,
      totalVotes: 4,
      passRate: 0.75,
      voterCount: 4,
      averageVotingPower: 6.5,
      startTime: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000), // 7天前
      endTime: new Date(), // 现在
      createdAt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000),
      updatedAt: new Date(),
    };

    const testVotingBehavior = {
      proposalId: 'test_prop_001',
      voterId: 'test_user_001',
      voteChoice: 'FOR' as const,
      votingPower: 8,
      voterReputation: 85,
      voterContribution: 65,
      voteTimestamp: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000), // 2天前
      timeToVote: 48, // 48小时
    };

    const testGovernanceStats = {
      totalProposals: 5,
      activeProposals: 2,
      passedProposals: 2,
      rejectedProposals: 1,
      totalVotes: 15,
      uniqueVoters: 5,
      averageParticipationRate: 0.8,
      topVotingMembers: [
        {
          userId: 'user_001',
          username: '张三',
          voteCount: 4,
          votingPower: 8,
        },
        {
          userId: 'user_002',
          username: '李四',
          voteCount: 3,
          votingPower: 7,
        },
      ],
    };

    // 测试推送提案结果
    console.log('📊 测试推送提案结果...');
    await zervigoStatistics.pushProposalResult(testVoteResult);
    console.log('✅ 提案结果推送测试成功');

    // 测试推送投票行为
    console.log('🗳️ 测试推送投票行为...');
    await zervigoStatistics.pushVotingBehavior(testVotingBehavior);
    console.log('✅ 投票行为推送测试成功');

    // 测试推送治理统计
    console.log('📈 测试推送治理统计...');
    await zervigoStatistics.pushGovernanceStatistics(testGovernanceStats);
    console.log('✅ 治理统计推送测试成功');

    console.log('🎉 所有Zervigo集成测试通过！');

  } catch (error) {
    console.error('❌ Zervigo集成测试失败:', error);
    throw error;
  }
};

// 如果直接运行此文件，执行测试
if (require.main === module) {
  testZervigoIntegration()
    .then(() => {
      console.log('✅ 测试完成');
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ 测试失败:', error);
      process.exit(1);
    });
}
