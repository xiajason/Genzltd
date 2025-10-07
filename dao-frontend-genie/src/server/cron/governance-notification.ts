import cron from 'node-cron';
import { db } from '@/server/db';
import { zervigoNotification } from '@/server/integrations/zervigo-notification';
import { zervigoBanner } from '@/server/integrations/zervigo-banner';

// 启动治理通知器
export const startGovernanceNotification = () => {
  console.log('📢 启动治理通知器...');
  
  // 每天上午10点检查治理参与度并发送提醒
  cron.schedule('0 10 * * *', async () => {
    try {
      await checkAndSendGovernanceParticipationReminder();
    } catch (error) {
      console.error('治理参与度提醒失败:', error);
    }
  });

  // 每周一上午9点发送治理周报
  cron.schedule('0 9 * * 1', async () => {
    try {
      await sendGovernanceWeeklyReport();
    } catch (error) {
      console.error('发送治理周报失败:', error);
    }
  });

  console.log('✅ 治理通知器已启动');
};

// 检查并发送治理参与度提醒
const checkAndSendGovernanceParticipationReminder = async () => {
  try {
    console.log('🔍 检查治理参与度...');

    // 获取所有活跃成员
    const activeMembers = await db.dAOMember.findMany({
      where: { status: 'ACTIVE' }
    });

    // 获取过去7天的投票记录
    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    const recentVotes = await db.dAOVote.findMany({
      where: {
        voteTimestamp: {
          gte: sevenDaysAgo
        }
      }
    });

    // 统计每个成员的参与度
    const memberParticipation = new Map<string, number>();
    recentVotes.forEach(vote => {
      const count = memberParticipation.get(vote.voterId) || 0;
      memberParticipation.set(vote.voterId, count + 1);
    });

    // 识别参与度低的成员
    const lowParticipationMembers: string[] = [];
    const targetUserIds: number[] = [];

    activeMembers.forEach(member => {
      const participationCount = memberParticipation.get(member.userId) || 0;
      const participationRate = participationCount / 7; // 7天内的投票次数

      if (participationRate < 0.5) { // 参与度低于50%
        lowParticipationMembers.push(member.username || member.firstName || member.userId);
        targetUserIds.push(Number(member.id));
      }
    });

    // 发送参与度提醒
    if (lowParticipationMembers.length > 0) {
      await zervigoNotification.sendGovernanceParticipationReminder(
        targetUserIds,
        lowParticipationMembers
      );

      console.log(`📢 治理参与度提醒已发送给 ${lowParticipationMembers.length} 名成员`);

      // 创建参与度提醒Banner
      await zervigoBanner.createParticipationReminderBanner(lowParticipationMembers.length);
    } else {
      console.log('✅ 所有成员参与度良好，无需发送提醒');
    }

  } catch (error) {
    console.error('❌ 检查治理参与度失败:', error);
  }
};

// 发送治理周报
const sendGovernanceWeeklyReport = async () => {
  try {
    console.log('📊 生成治理周报...');

    // 获取过去7天的数据
    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    
    // 统计提案数据
    const weeklyProposals = await db.dAOProposal.findMany({
      where: {
        createdAt: {
          gte: sevenDaysAgo
        }
      }
    });

    // 统计投票数据
    const weeklyVotes = await db.dAOVote.findMany({
      where: {
        voteTimestamp: {
          gte: sevenDaysAgo
        }
      }
    });

    // 统计成员数据
    const activeMembers = await db.dAOMember.findMany({
      where: { status: 'ACTIVE' }
    });

    // 生成周报数据
    const reportData = {
      period: '过去7天',
      totalProposals: weeklyProposals.length,
      activeProposals: weeklyProposals.filter(p => p.status === 'ACTIVE').length,
      passedProposals: weeklyProposals.filter(p => p.status === 'PASSED').length,
      rejectedProposals: weeklyProposals.filter(p => p.status === 'REJECTED').length,
      totalVotes: weeklyVotes.length,
      uniqueVoters: new Set(weeklyVotes.map(v => v.voterId)).size,
      totalMembers: activeMembers.length,
      participationRate: activeMembers.length > 0 ? 
        (new Set(weeklyVotes.map(v => v.voterId)).size / activeMembers.length) * 100 : 0,
    };

    // 获取所有活跃成员的用户ID
    const targetUserIds = activeMembers.map(member => Number(member.id));

    // 发送周报通知
    await sendWeeklyReportNotification(reportData, targetUserIds);

    // 创建治理周报Banner
    await zervigoBanner.createGovernanceWeeklyBanner(reportData);

    // 创建治理周报Markdown内容
    await zervigoBanner.createGovernanceWeeklyMarkdown(reportData);

    console.log('✅ 治理周报发送完成');

  } catch (error) {
    console.error('❌ 发送治理周报失败:', error);
  }
};

// 发送周报通知
const sendWeeklyReportNotification = async (reportData: any, targetUserIds: number[]) => {
  try {
    const title = '📊 DAO治理周报';
    const content = `
📈 治理活动统计 (${reportData.period})

📋 提案统计：
• 新增提案：${reportData.totalProposals} 个
• 活跃提案：${reportData.activeProposals} 个
• 通过提案：${reportData.passedProposals} 个
• 被拒提案：${reportData.rejectedProposals} 个

🗳️ 投票统计：
• 总投票数：${reportData.totalVotes} 次
• 参与投票：${reportData.uniqueVoters} 人
• 参与率：${reportData.participationRate.toFixed(1)}%

👥 成员统计：
• 活跃成员：${reportData.totalMembers} 人

感谢您对DAO治理的参与和支持！
    `.trim();

    const metadata = {
      report_type: 'weekly_governance',
      period: reportData.period,
      data: reportData,
      timestamp: new Date().toISOString(),
    };

    // 为每个成员发送周报
    for (const userId of targetUserIds) {
      await createNotification(
        userId,
        'governance_weekly_report',
        title,
        content,
        'dao_governance',
        'normal',
        metadata
      );
    }

    console.log(`📊 治理周报已发送给 ${targetUserIds.length} 名成员`);

  } catch (error) {
    console.error('❌ 发送周报通知失败:', error);
  }
};

// 创建通知的辅助函数
const createNotification = async (
  userId: number,
  notificationType: string,
  title: string,
  content: string,
  category: string,
  priority: string,
  metadata: any
): Promise<void> => {
  try {
    // 这里应该调用Zervigo通知服务的API
    // 暂时使用console.log模拟
    console.log(`📤 通知发送给用户 ${userId}: ${title}`);
  } catch (error) {
    console.error(`❌ 发送通知失败 (用户 ${userId}):`, error);
  }
};

// 手动触发治理参与度检查（用于测试）
export const triggerGovernanceParticipationCheck = async () => {
  await checkAndSendGovernanceParticipationReminder();
};

// 手动发送治理周报（用于测试）
export const triggerGovernanceWeeklyReport = async () => {
  await sendGovernanceWeeklyReport();
};
