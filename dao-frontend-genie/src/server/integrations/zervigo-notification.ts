import axios from 'axios';

// Zervigo通知服务配置
const ZERVIGO_NOTIFICATION_URL = process.env.ZERVIGO_NOTIFICATION_URL || 'http://localhost:7534';
const ZERVIGO_API_TOKEN = process.env.ZERVIGO_API_TOKEN || 'dao-integration-token';

// 提案通知数据结构
interface ProposalNotificationData {
  proposalId: string;
  title: string;
  description: string;
  proposalType: string;
  proposerId: string;
  proposerName: string;
  status: string;
  startTime: Date;
  endTime: Date;
  votingDeadline: Date;
}

// 投票提醒数据结构
interface VotingReminderData {
  proposalId: string;
  title: string;
  remainingHours: number;
  totalVotes: number;
  voterCount: number;
  participationRate: number;
}

// 提案结果通知数据
interface ProposalResultNotificationData {
  proposalId: string;
  title: string;
  status: 'PASSED' | 'REJECTED';
  votesFor: number;
  votesAgainst: number;
  totalVotes: number;
  passRate: number;
  voterCount: number;
  message: string;
}

/**
 * DAO提案通知集成类
 */
export class ZervigoNotificationIntegration {
  private apiClient = axios.create({
    baseURL: ZERVIGO_NOTIFICATION_URL,
    headers: {
      'Authorization': `Bearer ${ZERVIGO_API_TOKEN}`,
      'Content-Type': 'application/json',
    },
    timeout: 10000,
  });

  /**
   * 发送提案创建通知
   */
  async sendProposalCreatedNotification(notificationData: ProposalNotificationData, targetUserIds: number[]): Promise<void> {
    try {
      console.log(`📢 发送提案创建通知: ${notificationData.proposalId}`);

      const metadata = {
        proposal_id: notificationData.proposalId,
        proposal_type: notificationData.proposalType,
        proposer_id: notificationData.proposerId,
        proposer_name: notificationData.proposerName,
        start_time: notificationData.startTime.toISOString(),
        end_time: notificationData.endTime.toISOString(),
        voting_deadline: notificationData.votingDeadline.toISOString(),
        notification_type: 'proposal_created',
        timestamp: new Date().toISOString(),
      };

      // 为每个目标用户发送通知
      for (const userId of targetUserIds) {
        await this.createNotification(
          userId,
          'proposal_created',
          `新提案：${notificationData.title}`,
          `用户 ${notificationData.proposerName} 提出了新提案："${notificationData.title}"。请及时查看并参与投票。`,
          'dao_governance',
          'high',
          metadata
        );
      }

      console.log(`✅ 提案创建通知发送完成: ${notificationData.proposalId}`);
    } catch (error) {
      console.error(`❌ 发送提案创建通知失败:`, error);
    }
  }

  /**
   * 发送投票提醒通知
   */
  async sendVotingReminderNotification(reminderData: VotingReminderData, targetUserIds: number[]): Promise<void> {
    try {
      console.log(`⏰ 发送投票提醒通知: ${reminderData.proposalId}`);

      const metadata = {
        proposal_id: reminderData.proposalId,
        remaining_hours: reminderData.remainingHours,
        total_votes: reminderData.totalVotes,
        voter_count: reminderData.voterCount,
        participation_rate: reminderData.participationRate,
        notification_type: 'voting_reminder',
        timestamp: new Date().toISOString(),
      };

      let priority = 'normal';
      let urgencyMessage = '';

      if (reminderData.remainingHours <= 24) {
        priority = 'high';
        urgencyMessage = '投票即将结束，请尽快参与！';
      } else if (reminderData.remainingHours <= 48) {
        priority = 'normal';
        urgencyMessage = '投票即将结束，请及时参与。';
      }

      const title = `投票提醒：${reminderData.title}`;
      const content = `提案 "${reminderData.title}" 还有 ${reminderData.remainingHours} 小时结束投票。${urgencyMessage} 当前参与率：${(reminderData.participationRate * 100).toFixed(1)}%`;

      // 为每个目标用户发送通知
      for (const userId of targetUserIds) {
        await this.createNotification(
          userId,
          'voting_reminder',
          title,
          content,
          'dao_governance',
          priority,
          metadata
        );
      }

      console.log(`✅ 投票提醒通知发送完成: ${reminderData.proposalId}`);
    } catch (error) {
      console.error(`❌ 发送投票提醒通知失败:`, error);
    }
  }

  /**
   * 发送提案结果通知
   */
  async sendProposalResultNotification(resultData: ProposalResultNotificationData, targetUserIds: number[]): Promise<void> {
    try {
      console.log(`📊 发送提案结果通知: ${resultData.proposalId}`);

      const metadata = {
        proposal_id: resultData.proposalId,
        status: resultData.status,
        votes_for: resultData.votesFor,
        votes_against: resultData.votesAgainst,
        total_votes: resultData.totalVotes,
        pass_rate: resultData.passRate,
        voter_count: resultData.voterCount,
        message: resultData.message,
        notification_type: 'proposal_result',
        timestamp: new Date().toISOString(),
      };

      const statusText = resultData.status === 'PASSED' ? '通过' : '被拒绝';
      const statusEmoji = resultData.status === 'PASSED' ? '✅' : '❌';
      
      const title = `${statusEmoji} 提案结果：${resultData.title}`;
      const content = `提案 "${resultData.title}" ${statusText}！\n\n` +
        `投票结果：支持 ${resultData.votesFor} 票，反对 ${resultData.votesAgainst} 票\n` +
        `通过率：${(resultData.passRate * 100).toFixed(1)}%\n` +
        `参与投票：${resultData.voterCount} 人\n\n` +
        `${resultData.message}`;

      // 为每个目标用户发送通知
      for (const userId of targetUserIds) {
        await this.createNotification(
          userId,
          'proposal_result',
          title,
          content,
          'dao_governance',
          'high',
          metadata
        );
      }

      console.log(`✅ 提案结果通知发送完成: ${resultData.proposalId}`);
    } catch (error) {
      console.error(`❌ 发送提案结果通知失败:`, error);
    }
  }

  /**
   * 发送治理参与度提醒
   */
  async sendGovernanceParticipationReminder(targetUserIds: number[], lowParticipationUsers: string[]): Promise<void> {
    try {
      console.log(`📈 发送治理参与度提醒`);

      const metadata = {
        low_participation_users: lowParticipationUsers,
        total_members: targetUserIds.length,
        notification_type: 'governance_participation',
        timestamp: new Date().toISOString(),
      };

      const title = '治理参与度提醒';
      const content = `DAO治理需要每个成员的积极参与。当前有 ${lowParticipationUsers.length} 名成员参与度较低，请关注并参与社区治理活动。`;

      // 为参与度低的用户发送提醒
      for (const userId of targetUserIds) {
        await this.createNotification(
          userId,
          'governance_participation',
          title,
          content,
          'dao_governance',
          'normal',
          metadata
        );
      }

      console.log(`✅ 治理参与度提醒发送完成`);
    } catch (error) {
      console.error(`❌ 发送治理参与度提醒失败:`, error);
    }
  }

  /**
   * 发送重要提案紧急通知
   */
  async sendUrgentProposalNotification(notificationData: ProposalNotificationData, targetUserIds: number[]): Promise<void> {
    try {
      console.log(`🚨 发送重要提案紧急通知: ${notificationData.proposalId}`);

      const metadata = {
        proposal_id: notificationData.proposalId,
        proposal_type: notificationData.proposalType,
        proposer_id: notificationData.proposerId,
        proposer_name: notificationData.proposerName,
        start_time: notificationData.startTime.toISOString(),
        end_time: notificationData.endTime.toISOString(),
        notification_type: 'urgent_proposal',
        urgency_level: 'critical',
        timestamp: new Date().toISOString(),
      };

      const title = `🚨 重要提案：${notificationData.title}`;
      const content = `重要治理提案需要您的关注！\n\n` +
        `提案标题：${notificationData.title}\n` +
        `提案类型：${this.getProposalTypeText(notificationData.proposalType)}\n` +
        `提出者：${notificationData.proposerName}\n` +
        `投票截止：${notificationData.votingDeadline.toLocaleString()}\n\n` +
        `请及时查看详情并参与投票决策。`;

      // 为每个目标用户发送紧急通知
      for (const userId of targetUserIds) {
        await this.createNotification(
          userId,
          'urgent_proposal',
          title,
          content,
          'dao_governance',
          'urgent',
          metadata
        );
      }

      console.log(`✅ 重要提案紧急通知发送完成: ${notificationData.proposalId}`);
    } catch (error) {
      console.error(`❌ 发送重要提案紧急通知失败:`, error);
    }
  }

  /**
   * 创建通知的核心方法
   */
  private async createNotification(
    userId: number,
    notificationType: string,
    title: string,
    content: string,
    category: string,
    priority: string,
    metadata: any
  ): Promise<void> {
    try {
      const notificationData = {
        user_id: userId,
        type: notificationType,
        title,
        content,
        category,
        priority,
        status: 'unread',
        is_read: false,
        metadata: JSON.stringify(metadata),
      };

      await this.apiClient.post('/api/v1/notification/create', notificationData);
      
      console.log(`📤 通知已发送给用户 ${userId}: ${title}`);
    } catch (error) {
      console.error(`❌ 发送通知失败 (用户 ${userId}):`, error);
      // 不抛出错误，避免影响其他通知的发送
    }
  }

  /**
   * 获取提案类型的中文描述
   */
  private getProposalTypeText(proposalType: string): string {
    const typeMap: Record<string, string> = {
      'GOVERNANCE': '治理提案',
      'TECHNICAL': '技术提案',
      'FINANCIAL': '财务提案',
      'POLICY': '政策提案',
      'MEMBERSHIP': '成员管理',
      'PROJECT': '项目提案',
      'OTHER': '其他提案',
    };
    
    return typeMap[proposalType] || proposalType;
  }

  /**
   * 批量获取活跃成员用户ID（从DAO成员中获取）
   */
  async getActiveMemberUserIds(): Promise<number[]> {
    // 这里应该从DAO数据库获取活跃成员
    // 暂时返回模拟数据，实际实现需要查询DAO成员表
    return [1, 2, 3, 4, 5]; // 对应DAO中的5个成员
  }

  /**
   * 检查用户是否已投票
   */
  async hasUserVoted(userId: number, proposalId: string): Promise<boolean> {
    // 这里应该查询DAO投票表
    // 暂时返回false，实际实现需要查询投票记录
    return false;
  }

  /**
   * 获取用户的参与度评分
   */
  async getUserParticipationScore(userId: number): Promise<number> {
    // 这里应该计算用户的治理参与度
    // 暂时返回随机值，实际实现需要统计投票历史
    return Math.random() * 100;
  }
}

// 导出单例实例
export const zervigoNotification = new ZervigoNotificationIntegration();
