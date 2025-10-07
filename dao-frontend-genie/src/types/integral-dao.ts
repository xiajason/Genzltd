// 积分制DAO治理系统类型定义

// DAO成员类型 - 基于积分制（扩展版本，整合zervigo用户数据）
export interface IntegralDAOMember {
  id: string | bigint;
  userId: string;
  
  // 基础用户信息（从zervigo整合）
  username?: string | null; // 用户名
  email?: string | null; // 邮箱
  firstName?: string | null; // 名字
  lastName?: string | null; // 姓氏
  avatarUrl?: string | null; // 头像URL
  phone?: string | null; // 电话
  
  // 扩展用户资料（从zervigo整合）
  bio?: string | null; // 个人简介
  location?: string | null; // 位置
  website?: string | null; // 网站
  githubUrl?: string | null; // GitHub链接
  linkedinUrl?: string | null; // LinkedIn链接
  twitterUrl?: string | null; // Twitter链接
  skills?: string[] | null; // 技能列表
  interests?: string[] | null; // 兴趣列表
  languages?: string[] | null; // 语言列表
  
  // DAO特有字段
  walletAddress?: string; // 可选，未来扩展
  reputationScore: number; // 声誉积分
  contributionPoints: number; // 贡献积分
  joinDate: string;
  status: 'active' | 'inactive' | 'suspended';
  votingPower: number; // 计算得出的投票权重
  createdAt: string;
  updatedAt: string;
}

// DAO提案类型
export interface IntegralDAOProposal {
  id: string | bigint;
  proposalId: string;
  title: string;
  description: string | null;
  proposerId: string;
  proposer: IntegralDAOMember;
  proposalType: 'governance' | 'funding' | 'technical' | 'policy';
  status: 'draft' | 'active' | 'passed' | 'rejected' | 'executed';
  startTime?: string;
  endTime?: string;
  votesFor: number;
  votesAgainst: number;
  totalVotes: number;
  createdAt: string;
  updatedAt: string;
}

// DAO投票类型
export interface IntegralDAOVote {
  id: string;
  proposalId: string;
  voterId: string;
  voter: IntegralDAOMember;
  voteChoice: 'for' | 'against' | 'abstain';
  votingPower: number; // 基于积分计算的投票权重
  voteTimestamp: string;
}

// DAO奖励类型
export interface IntegralDAOReward {
  id: string;
  recipientId: string;
  recipient: IntegralDAOMember;
  rewardType: 'contribution' | 'voting' | 'proposal' | 'governance';
  amount: number;
  currency: string;
  description: string;
  status: 'pending' | 'approved' | 'distributed';
  createdAt: string;
  distributedAt?: string;
}

// DAO活动类型
export interface IntegralDAOActivity {
  id: string;
  userId: string;
  user: IntegralDAOMember;
  activityType: string;
  activityDescription: string;
  metadata?: any;
  timestamp: string;
}

// 投票权重计算函数类型
export interface VotingPowerCalculator {
  (member: IntegralDAOMember): number;
}

// DAO配置类型
export interface IntegralDAOConfig {
  mode: 'integral';
  baseReputationScore: number;
  contributionWeight: number;
  reputationWeight: number;
  minimumVotingPower: number;
}

// 认证用户类型
export interface AuthenticatedUser {
  id: string;
  username: string;
  email: string;
  reputationScore: number;
  contributionPoints: number;
  votingPower: number;
  isAuthenticated: boolean;
}

// API响应类型
export interface IntegralDAOApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
}

// 分页响应类型
export interface PaginatedResponse<T> {
  data: T[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
}
