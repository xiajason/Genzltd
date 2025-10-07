import axios from 'axios';

// Zervigo Banner服务配置
const ZERVIGO_BANNER_URL = process.env.ZERVIGO_BANNER_URL || 'http://localhost:7535';
const ZERVIGO_API_TOKEN = process.env.ZERVIGO_API_TOKEN || 'dao-integration-token';

// Banner数据结构
interface BannerData {
  title: string;
  description: string;
  image_url?: string;
  link_url?: string;
  sort_order?: number;
  status: 'draft' | 'active' | 'inactive';
  start_date?: Date;
  end_date?: Date;
  created_by: number;
}

// Markdown内容数据结构
interface MarkdownContentData {
  title: string;
  slug: string;
  content: string;
  excerpt?: string;
  category: string;
  tags?: string[];
  status: 'draft' | 'published' | 'archived';
  published_at?: Date;
  created_by: number;
}

// 提案公告数据结构
interface ProposalAnnouncementData {
  proposalId: string;
  title: string;
  description: string;
  proposalType: string;
  proposerName: string;
  status: string;
  startTime: Date;
  endTime: Date;
  votesFor: number;
  votesAgainst: number;
  totalVotes: number;
  passRate: number;
  voterCount: number;
  message?: string;
}

// 治理公告数据结构
interface GovernanceAnnouncementData {
  type: 'weekly_report' | 'participation_reminder' | 'system_update' | 'governance_rule';
  title: string;
  content: string;
  priority: 'low' | 'normal' | 'high' | 'urgent';
  targetAudience: 'all' | 'active_members' | 'low_participation';
  metadata?: any;
}

/**
 * DAO治理内容与Zervigo Banner服务集成类
 */
export class ZervigoBannerIntegration {
  private apiClient = axios.create({
    baseURL: ZERVIGO_BANNER_URL,
    headers: {
      'Authorization': `Bearer ${ZERVIGO_API_TOKEN}`,
      'Content-Type': 'application/json',
    },
    timeout: 10000,
  });

  /**
   * 创建提案Banner公告
   */
  async createProposalBanner(announcementData: ProposalAnnouncementData): Promise<void> {
    try {
      console.log(`📢 创建提案Banner公告: ${announcementData.proposalId}`);

      const bannerData: BannerData = {
        title: `🗳️ 新提案：${announcementData.title}`,
        description: `${announcementData.proposerName} 提出了新提案，请及时查看并参与投票。投票截止时间：${announcementData.endTime.toLocaleString()}`,
        link_url: `/dao/proposals/${announcementData.proposalId}`,
        sort_order: 1,
        status: 'active',
        start_date: new Date(),
        end_date: announcementData.endTime,
        created_by: 1, // DAO系统用户ID
      };

      await this.apiClient.post('/api/v1/content/banners/', bannerData);
      console.log(`✅ 提案Banner公告创建成功: ${announcementData.proposalId}`);

    } catch (error) {
      console.error(`❌ 创建提案Banner公告失败:`, error);
    }
  }

  /**
   * 创建提案详情Markdown内容
   */
  async createProposalMarkdownContent(announcementData: ProposalAnnouncementData): Promise<void> {
    try {
      console.log(`📝 创建提案Markdown内容: ${announcementData.proposalId}`);

      const markdownContent = this.generateProposalMarkdown(announcementData);

      const contentData: MarkdownContentData = {
        title: `DAO治理提案：${announcementData.title}`,
        slug: `dao-proposal-${announcementData.proposalId}`,
        content: markdownContent,
        excerpt: announcementData.description.substring(0, 200) + '...',
        category: 'dao_governance',
        tags: ['DAO治理', '提案', announcementData.proposalType, '社区治理'],
        status: 'published',
        published_at: new Date(),
        created_by: 1, // DAO系统用户ID
      };

      await this.apiClient.post('/api/v1/content/markdown/', contentData);
      console.log(`✅ 提案Markdown内容创建成功: ${announcementData.proposalId}`);

    } catch (error) {
      console.error(`❌ 创建提案Markdown内容失败:`, error);
    }
  }

  /**
   * 创建提案结果Banner公告
   */
  async createProposalResultBanner(announcementData: ProposalAnnouncementData): Promise<void> {
    try {
      console.log(`📊 创建提案结果Banner公告: ${announcementData.proposalId}`);

      const statusEmoji = announcementData.status === 'PASSED' ? '✅' : '❌';
      const statusText = announcementData.status === 'PASSED' ? '通过' : '被拒绝';

      const bannerData: BannerData = {
        title: `${statusEmoji} 提案结果：${announcementData.title}`,
        description: `提案 ${statusText}！支持 ${announcementData.votesFor} 票，反对 ${announcementData.votesAgainst} 票，通过率 ${(announcementData.passRate * 100).toFixed(1)}%`,
        link_url: `/dao/proposals/${announcementData.proposalId}`,
        sort_order: 1,
        status: 'active',
        start_date: new Date(),
        end_date: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7天后过期
        created_by: 1, // DAO系统用户ID
      };

      await this.apiClient.post('/api/v1/content/banners/', bannerData);
      console.log(`✅ 提案结果Banner公告创建成功: ${announcementData.proposalId}`);

    } catch (error) {
      console.error(`❌ 创建提案结果Banner公告失败:`, error);
    }
  }

  /**
   * 创建治理周报Banner
   */
  async createGovernanceWeeklyBanner(reportData: any): Promise<void> {
    try {
      console.log(`📊 创建治理周报Banner`);

      const bannerData: BannerData = {
        title: `📊 DAO治理周报 - ${new Date().toLocaleDateString()}`,
        description: `本周新增提案 ${reportData.totalProposals} 个，通过 ${reportData.passedProposals} 个，参与率 ${reportData.averageParticipationRate.toFixed(1)}%`,
        link_url: `/dao/governance/weekly-report`,
        sort_order: 2,
        status: 'active',
        start_date: new Date(),
        end_date: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000), // 3天后过期
        created_by: 1, // DAO系统用户ID
      };

      await this.apiClient.post('/api/v1/content/banners/', bannerData);
      console.log(`✅ 治理周报Banner创建成功`);

    } catch (error) {
      console.error(`❌ 创建治理周报Banner失败:`, error);
    }
  }

  /**
   * 创建治理周报Markdown内容
   */
  async createGovernanceWeeklyMarkdown(reportData: any): Promise<void> {
    try {
      console.log(`📝 创建治理周报Markdown内容`);

      const markdownContent = this.generateWeeklyReportMarkdown(reportData);

      const contentData: MarkdownContentData = {
        title: `DAO治理周报 - ${new Date().toLocaleDateString()}`,
        slug: `dao-weekly-report-${Date.now()}`,
        content: markdownContent,
        excerpt: `本周治理活动统计：新增提案 ${reportData.totalProposals} 个，参与率 ${reportData.averageParticipationRate.toFixed(1)}%`,
        category: 'dao_governance',
        tags: ['DAO治理', '周报', '统计', '社区活动'],
        status: 'published',
        published_at: new Date(),
        created_by: 1, // DAO系统用户ID
      };

      await this.apiClient.post('/api/v1/content/markdown/', contentData);
      console.log(`✅ 治理周报Markdown内容创建成功`);

    } catch (error) {
      console.error(`❌ 创建治理周报Markdown内容失败:`, error);
    }
  }

  /**
   * 创建参与度提醒Banner
   */
  async createParticipationReminderBanner(lowParticipationCount: number): Promise<void> {
    try {
      console.log(`📢 创建参与度提醒Banner`);

      const bannerData: BannerData = {
        title: `📢 治理参与度提醒`,
        description: `当前有 ${lowParticipationCount} 名成员参与度较低，请关注并参与社区治理活动`,
        link_url: `/dao/governance/participation`,
        sort_order: 3,
        status: 'active',
        start_date: new Date(),
        end_date: new Date(Date.now() + 24 * 60 * 60 * 1000), // 24小时后过期
        created_by: 1, // DAO系统用户ID
      };

      await this.apiClient.post('/api/v1/content/banners/', bannerData);
      console.log(`✅ 参与度提醒Banner创建成功`);

    } catch (error) {
      console.error(`❌ 创建参与度提醒Banner失败:`, error);
    }
  }

  /**
   * 创建系统更新公告Banner
   */
  async createSystemUpdateBanner(updateInfo: any): Promise<void> {
    try {
      console.log(`🔧 创建系统更新公告Banner`);

      const bannerData: BannerData = {
        title: `🔧 系统更新公告`,
        description: updateInfo.description || 'DAO治理系统已更新，请查看最新功能和改进',
        link_url: updateInfo.link_url || '/dao/system/updates',
        sort_order: 1,
        status: 'active',
        start_date: new Date(),
        end_date: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7天后过期
        created_by: 1, // DAO系统用户ID
      };

      await this.apiClient.post('/api/v1/content/banners/', bannerData);
      console.log(`✅ 系统更新公告Banner创建成功`);

    } catch (error) {
      console.error(`❌ 创建系统更新公告Banner失败:`, error);
    }
  }

  /**
   * 生成提案Markdown内容
   */
  private generateProposalMarkdown(data: ProposalAnnouncementData): string {
    const statusEmoji = data.status === 'PASSED' ? '✅' : data.status === 'REJECTED' ? '❌' : '🔄';
    const statusText = data.status === 'PASSED' ? '已通过' : data.status === 'REJECTED' ? '已拒绝' : '进行中';

    return `# ${data.title}

${statusEmoji} **状态**: ${statusText}

## 📋 提案信息

- **提案ID**: ${data.proposalId}
- **提案类型**: ${this.getProposalTypeText(data.proposalType)}
- **提出者**: ${data.proposerName}
- **开始时间**: ${data.startTime.toLocaleString()}
- **结束时间**: ${data.endTime.toLocaleString()}

## 📝 提案描述

${data.description}

## 📊 投票统计

- **支持票数**: ${data.votesFor}
- **反对票数**: ${data.votesAgainst}
- **总票数**: ${data.totalVotes}
- **通过率**: ${(data.passRate * 100).toFixed(1)}%
- **参与投票**: ${data.voterCount} 人

${data.message ? `## 💬 结果说明\n\n${data.message}` : ''}

## 🔗 相关链接

- [查看详细投票记录](/dao/proposals/${data.proposalId}/votes)
- [参与讨论](/dao/proposals/${data.proposalId}/comments)
- [返回提案列表](/dao/proposals)

---

*此内容由DAO治理系统自动生成*
`;
  }

  /**
   * 生成周报Markdown内容
   */
  private generateWeeklyReportMarkdown(data: any): string {
    return `# DAO治理周报

**报告期间**: ${data.period}  
**生成时间**: ${new Date().toLocaleString()}

## 📊 提案统计

| 指标 | 数量 |
|------|------|
| 新增提案 | ${data.totalProposals} 个 |
| 活跃提案 | ${data.activeProposals} 个 |
| 通过提案 | ${data.passedProposals} 个 |
| 被拒提案 | ${data.rejectedProposals} 个 |

## 🗳️ 投票统计

| 指标 | 数量 |
|------|------|
| 总投票数 | ${data.totalVotes} 次 |
| 参与投票 | ${data.uniqueVoters} 人 |
| 参与率 | ${data.averageParticipationRate.toFixed(1)}% |
| 活跃成员 | ${data.totalMembers} 人 |

## 📈 治理健康度分析

### 参与度分析
- **高参与度成员**: ${data.totalMembers - data.uniqueVoters} 人
- **参与度提升**: ${data.averageParticipationRate > 0.8 ? '优秀' : data.averageParticipationRate > 0.5 ? '良好' : '需要改进'}

### 提案效率
- **平均处理时间**: ${this.calculateAverageProcessingTime(data)} 天
- **通过率**: ${data.passedProposals > 0 ? ((data.passedProposals / data.totalProposals) * 100).toFixed(1) : 0}%

## 🎯 本周亮点

${this.generateWeeklyHighlights(data)}

## 📋 下周计划

- 继续监控治理参与度
- 优化提案流程
- 提升社区活跃度

---

*此报告由DAO治理系统自动生成，数据实时更新*
`;
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
   * 计算平均处理时间
   */
  private calculateAverageProcessingTime(data: any): string {
    // 模拟计算，实际应该基于真实数据
    return '3.2';
  }

  /**
   * 生成周报亮点
   */
  private generateWeeklyHighlights(data: any): string {
    const highlights = [];
    
    if (data.totalProposals > 0) {
      highlights.push(`- 本周新增 ${data.totalProposals} 个治理提案`);
    }
    
    if (data.averageParticipationRate > 0.8) {
      highlights.push('- 治理参与度达到优秀水平');
    }
    
    if (data.passedProposals > 0) {
      highlights.push(`- 成功通过 ${data.passedProposals} 个重要提案`);
    }
    
    if (highlights.length === 0) {
      highlights.push('- 治理系统运行稳定');
      highlights.push('- 社区活动正常进行');
    }
    
    return highlights.join('\n');
  }

  /**
   * 批量创建治理内容
   */
  async createGovernanceContentBatch(contentList: GovernanceAnnouncementData[]): Promise<void> {
    try {
      console.log(`📦 批量创建治理内容，共 ${contentList.length} 项`);

      for (const content of contentList) {
        await this.createSingleGovernanceContent(content);
      }

      console.log(`✅ 批量创建治理内容完成`);

    } catch (error) {
      console.error(`❌ 批量创建治理内容失败:`, error);
    }
  }

  /**
   * 创建单个治理内容
   */
  private async createSingleGovernanceContent(content: GovernanceAnnouncementData): Promise<void> {
    try {
      const bannerData: BannerData = {
        title: content.title,
        description: content.content.substring(0, 150) + '...',
        link_url: `/dao/governance/${content.type}`,
        sort_order: this.getSortOrder(content.priority),
        status: 'active',
        start_date: new Date(),
        end_date: new Date(Date.now() + this.getExpirationHours(content.priority) * 60 * 60 * 1000),
        created_by: 1, // DAO系统用户ID
      };

      await this.apiClient.post('/api/v1/content/banners/', bannerData);

      // 如果是重要内容，也创建Markdown内容
      if (content.priority === 'high' || content.priority === 'urgent') {
        const contentData: MarkdownContentData = {
          title: content.title,
          slug: `dao-${content.type}-${Date.now()}`,
          content: content.content,
          excerpt: content.content.substring(0, 200) + '...',
          category: 'dao_governance',
          tags: ['DAO治理', content.type],
          status: 'published',
          published_at: new Date(),
          created_by: 1, // DAO系统用户ID
        };

        await this.apiClient.post('/api/v1/content/markdown/', contentData);
      }

    } catch (error) {
      console.error(`❌ 创建治理内容失败:`, error);
    }
  }

  /**
   * 根据优先级获取排序顺序
   */
  private getSortOrder(priority: string): number {
    const orderMap: Record<string, number> = {
      'urgent': 1,
      'high': 2,
      'normal': 3,
      'low': 4,
    };
    
    return orderMap[priority] || 3;
  }

  /**
   * 根据优先级获取过期时间（小时）
   */
  private getExpirationHours(priority: string): number {
    const hoursMap: Record<string, number> = {
      'urgent': 24,
      'high': 72,
      'normal': 168, // 7天
      'low': 336, // 14天
    };
    
    return hoursMap[priority] || 168;
  }
}

// 导出单例实例
export const zervigoBanner = new ZervigoBannerIntegration();
