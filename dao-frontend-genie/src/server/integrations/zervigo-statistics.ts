import axios from 'axios';

// Zervigo统计服务配置
const ZERVIGO_STATISTICS_URL = process.env.ZERVIGO_STATISTICS_URL || 'http://localhost:7536';
const ZERVIGO_API_TOKEN = process.env.ZERVIGO_API_TOKEN || 'dao-integration-token';

// 投票结果数据结构
interface DAOVoteResult {
  proposalId: string;
  title: string;
  description: string;
  proposalType: string;
  status: 'PASSED' | 'REJECTED' | 'ACTIVE';
  votesFor: number;
  votesAgainst: number;
  totalVotes: number;
  passRate: number;
  voterCount: number;
  averageVotingPower: number;
  startTime: Date;
  endTime: Date;
  createdAt: Date;
  updatedAt: Date;
}

// 治理参与度数据
interface GovernanceParticipationData {
  totalProposals: number;
  activeProposals: number;
  passedProposals: number;
  rejectedProposals: number;
  totalVotes: number;
  uniqueVoters: number;
  averageParticipationRate: number;
  topVotingMembers: Array<{
    userId: string;
    username: string;
    voteCount: number;
    votingPower: number;
  }>;
}

// 投票行为分析数据
interface VotingBehaviorAnalysis {
  proposalId: string;
  voterId: string;
  voteChoice: 'FOR' | 'AGAINST' | 'ABSTAIN';
  votingPower: number;
  voterReputation: number;
  voterContribution: number;
  voteTimestamp: Date;
  timeToVote: number; // 从提案创建到投票的时间（小时）
}

/**
 * 推送DAO投票结果到Zervigo统计服务
 */
export class ZervigoStatisticsIntegration {
  private apiClient = axios.create({
    baseURL: ZERVIGO_STATISTICS_URL,
    headers: {
      'Authorization': `Bearer ${ZERVIGO_API_TOKEN}`,
      'Content-Type': 'application/json',
    },
    timeout: 10000,
  });

  /**
   * 推送提案投票结果
   */
  async pushProposalResult(voteResult: DAOVoteResult): Promise<void> {
    try {
      console.log(`📊 推送提案结果到Zervigo统计服务: ${voteResult.proposalId}`);

      // 推送实时分析数据
      await this.pushRealTimeAnalytics(voteResult);

      // 推送历史分析数据
      await this.pushHistoricalAnalysis(voteResult);

      // 推送治理参与度数据
      await this.pushGovernanceParticipation(voteResult);

      console.log(`✅ 提案结果推送成功: ${voteResult.proposalId}`);
    } catch (error) {
      console.error(`❌ 推送提案结果失败: ${voteResult.proposalId}`, error);
      // 不抛出错误，避免影响DAO系统正常运行
    }
  }

  /**
   * 推送实时分析数据
   */
  private async pushRealTimeAnalytics(voteResult: DAOVoteResult): Promise<void> {
    const analyticsData = [
      {
        metric_type: 'dao_governance',
        metric_name: 'proposal_result',
        metric_value: voteResult.status === 'PASSED' ? 1 : 0,
        dimensions: {
          proposal_id: voteResult.proposalId,
          proposal_type: voteResult.proposalType,
          status: voteResult.status,
          pass_rate: voteResult.passRate,
          voter_count: voteResult.voterCount,
        },
      },
      {
        metric_type: 'dao_governance',
        metric_name: 'voting_participation',
        metric_value: voteResult.voterCount,
        dimensions: {
          proposal_id: voteResult.proposalId,
          total_votes: voteResult.totalVotes,
          participation_rate: voteResult.voterCount / 5, // 假设5个成员
        },
      },
      {
        metric_type: 'dao_governance',
        metric_name: 'voting_consensus',
        metric_value: voteResult.passRate,
        dimensions: {
          proposal_id: voteResult.proposalId,
          votes_for: voteResult.votesFor,
          votes_against: voteResult.votesAgainst,
          consensus_level: voteResult.passRate > 0.8 ? 'high' : voteResult.passRate > 0.5 ? 'medium' : 'low',
        },
      },
    ];

    for (const data of analyticsData) {
      await this.apiClient.post('/api/v1/statistics/enhanced/realtime/record', data);
    }
  }

  /**
   * 推送历史分析数据
   */
  private async pushHistoricalAnalysis(voteResult: DAOVoteResult): Promise<void> {
    const analysisData = {
      analysis_type: 'governance_trend',
      entity_type: 'proposal',
      entity_id: 0, // DAO提案没有传统ID
      analysis_period: 'custom',
      start_date: voteResult.startTime.toISOString(),
      end_date: voteResult.endTime.toISOString(),
      analysis_result: {
        proposal_id: voteResult.proposalId,
        title: voteResult.title,
        type: voteResult.proposalType,
        outcome: voteResult.status,
        participation_metrics: {
          total_votes: voteResult.totalVotes,
          voter_count: voteResult.voterCount,
          participation_rate: voteResult.voterCount / 5,
          average_voting_power: voteResult.averageVotingPower,
        },
        consensus_metrics: {
          pass_rate: voteResult.passRate,
          votes_for: voteResult.votesFor,
          votes_against: voteResult.votesAgainst,
          consensus_level: voteResult.passRate > 0.8 ? 'high' : voteResult.passRate > 0.5 ? 'medium' : 'low',
        },
        temporal_metrics: {
          voting_duration_hours: (voteResult.endTime.getTime() - voteResult.startTime.getTime()) / (1000 * 60 * 60),
          creation_to_result_hours: (voteResult.endTime.getTime() - voteResult.createdAt.getTime()) / (1000 * 60 * 60),
        },
      },
      insights: this.generateInsights(voteResult),
      confidence: 0.85, // 基于数据完整性的置信度
    };

    await this.apiClient.post('/api/v1/statistics/enhanced/historical/analyze', analysisData);
  }

  /**
   * 推送治理参与度数据
   */
  private async pushGovernanceParticipation(voteResult: DAOVoteResult): Promise<void> {
    // 这里需要从数据库获取更多统计数据
    const participationData = {
      metric_type: 'dao_governance',
      metric_name: 'governance_health',
      metric_value: this.calculateGovernanceHealth(voteResult),
      dimensions: {
        proposal_count: 1,
        participation_rate: voteResult.voterCount / 5,
        consensus_rate: voteResult.passRate,
        voting_activity: voteResult.totalVotes,
        governance_effectiveness: voteResult.status === 'PASSED' ? 1 : 0,
      },
    };

    await this.apiClient.post('/api/v1/statistics/enhanced/realtime/record', participationData);
  }

  /**
   * 推送投票行为分析
   */
  async pushVotingBehavior(votingBehavior: VotingBehaviorAnalysis): Promise<void> {
    try {
      const behaviorData = {
        metric_type: 'dao_governance',
        metric_name: 'voting_behavior',
        metric_value: votingBehavior.votingPower,
        dimensions: {
          proposal_id: votingBehavior.proposalId,
          voter_id: votingBehavior.voterId,
          vote_choice: votingBehavior.voteChoice,
          voter_reputation: votingBehavior.voterReputation,
          voter_contribution: votingBehavior.voterContribution,
          time_to_vote_hours: votingBehavior.timeToVote,
          voting_pattern: this.analyzeVotingPattern(votingBehavior),
        },
      };

      await this.apiClient.post('/api/v1/statistics/enhanced/realtime/record', behaviorData);
      console.log(`✅ 投票行为数据推送成功: ${votingBehavior.proposalId} - ${votingBehavior.voterId}`);
    } catch (error) {
      console.error(`❌ 推送投票行为数据失败:`, error);
    }
  }

  /**
   * 生成洞察分析
   */
  private generateInsights(voteResult: DAOVoteResult): string {
    const insights = [];

    // 参与度分析
    if (voteResult.voterCount >= 4) {
      insights.push('高参与度：大部分成员参与了投票');
    } else if (voteResult.voterCount >= 2) {
      insights.push('中等参与度：部分成员参与了投票');
    } else {
      insights.push('低参与度：参与投票的成员较少');
    }

    // 共识分析
    if (voteResult.passRate >= 0.8) {
      insights.push('强共识：提案获得了广泛支持');
    } else if (voteResult.passRate >= 0.5) {
      insights.push('中等共识：提案获得了多数支持');
    } else {
      insights.push('分歧较大：提案存在较大争议');
    }

    // 类型分析
    if (voteResult.proposalType === 'GOVERNANCE') {
      insights.push('治理类提案：涉及组织治理规则');
    } else if (voteResult.proposalType === 'TECHNICAL') {
      insights.push('技术类提案：涉及技术决策');
    } else {
      insights.push('业务类提案：涉及业务发展');
    }

    return insights.join('；');
  }

  /**
   * 计算治理健康度
   */
  private calculateGovernanceHealth(voteResult: DAOVoteResult): number {
    const participationScore = Math.min(voteResult.voterCount / 5, 1) * 0.4; // 40%权重
    const consensusScore = voteResult.passRate * 0.3; // 30%权重
    const outcomeScore = voteResult.status === 'PASSED' ? 0.3 : 0; // 30%权重

    return participationScore + consensusScore + outcomeScore;
  }

  /**
   * 分析投票模式
   */
  private analyzeVotingPattern(votingBehavior: VotingBehaviorAnalysis): string {
    if (votingBehavior.timeToVote < 1) {
      return '快速决策';
    } else if (votingBehavior.timeToVote < 24) {
      return '积极投票';
    } else if (votingBehavior.timeToVote < 72) {
      return '谨慎考虑';
    } else {
      return '延迟投票';
    }
  }

  /**
   * 批量推送治理统计
   */
  async pushGovernanceStatistics(participationData: GovernanceParticipationData): Promise<void> {
    try {
      const statisticsData = {
        metric_type: 'dao_governance',
        metric_name: 'governance_overview',
        metric_value: participationData.averageParticipationRate,
        dimensions: {
          total_proposals: participationData.totalProposals,
          active_proposals: participationData.activeProposals,
          passed_proposals: participationData.passedProposals,
          rejected_proposals: participationData.rejectedProposals,
          total_votes: participationData.totalVotes,
          unique_voters: participationData.uniqueVoters,
          participation_rate: participationData.averageParticipationRate,
          top_voters: participationData.topVotingMembers.length,
        },
      };

      await this.apiClient.post('/api/v1/statistics/enhanced/realtime/record', statisticsData);
      console.log('✅ 治理统计数据推送成功');
    } catch (error) {
      console.error('❌ 推送治理统计数据失败:', error);
    }
  }
}

// 导出单例实例
export const zervigoStatistics = new ZervigoStatisticsIntegration();
