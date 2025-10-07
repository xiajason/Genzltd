// 积分制DAO治理系统状态管理
import { create } from 'zustand';
import { integralDAOApi } from '../services/integral-dao-api';
import type { 
  IntegralDAOMember, 
  IntegralDAOProposal, 
  IntegralDAOVote, 
  IntegralDAOReward,
  AuthenticatedUser 
} from '../types/integral-dao';

interface IntegralDAOStore {
  // 状态
  members: IntegralDAOMember[];
  proposals: IntegralDAOProposal[];
  votes: IntegralDAOVote[];
  rewards: IntegralDAOReward[];
  currentUser: AuthenticatedUser | null;
  loading: boolean;
  error: string | null;
  
  // 统计信息
  stats: {
    totalMembers: number;
    activeProposals: number;
    totalProposals: number;
    avgReputation: number;
    totalRewards: number;
  };
  
  // 操作
  // 认证相关
  login: (credentials: { username: string; password: string }) => Promise<void>;
  logout: () => void;
  getCurrentUser: () => Promise<void>;
  
  // 成员管理
  fetchMembers: () => Promise<void>;
  updateMemberReputation: (id: string, score: number) => Promise<void>;
  updateMemberContribution: (id: string, points: number) => Promise<void>;
  
  // 提案管理
  fetchProposals: () => Promise<void>;
  createProposal: (proposal: {
    title: string;
    description: string;
    proposalType: string;
    startTime?: string;
    endTime?: string;
  }) => Promise<void>;
  updateProposal: (id: string, proposal: any) => Promise<void>;
  activateProposal: (id: string) => Promise<void>;
  
  // 投票管理
  fetchVotes: (proposalId: string) => Promise<void>;
  voteOnProposal: (proposalId: string, choice: 'for' | 'against' | 'abstain') => Promise<void>;
  
  // 奖励管理
  fetchRewards: () => Promise<void>;
  createReward: (reward: {
    recipientId: string;
    rewardType: string;
    amount: number;
    description: string;
  }) => Promise<void>;
  
  // 统计信息
  fetchStats: () => Promise<void>;
  
  // 工具方法
  setLoading: (loading: boolean) => void;
  setError: (error: string | null) => void;
  calculateVotingPower: (member: IntegralDAOMember) => number;
}

export const useIntegralDAOStore = create<IntegralDAOStore>((set, get) => ({
  // 初始状态
  members: [],
  proposals: [],
  votes: [],
  rewards: [],
  currentUser: null,
  loading: false,
  error: null,
  stats: {
    totalMembers: 0,
    activeProposals: 0,
    totalProposals: 0,
    avgReputation: 0,
    totalRewards: 0,
  },
  
  // 认证相关
  login: async (credentials) => {
    set({ loading: true, error: null });
    try {
      const response = await integralDAOApi.auth.login(credentials);
      if (response.data.success) {
        const token = response.data.data.token;
        localStorage.setItem('auth_token', token);
        set({ currentUser: response.data.data.user, loading: false });
      } else {
        set({ error: response.data.error || response.data.message, loading: false });
      }
    } catch (error: any) {
      set({ error: error.message, loading: false });
    }
  },
  
  logout: () => {
    localStorage.removeItem('auth_token');
    set({ currentUser: null, members: [], proposals: [], votes: [], rewards: [] });
  },
  
  getCurrentUser: async () => {
    try {
      const token = localStorage.getItem('auth_token');
      if (!token) {
        throw new Error("未找到认证token");
      }
      const response = await integralDAOApi.auth.getCurrentUser(token);
      set({ currentUser: response.data.data });
    } catch (error: any) {
      set({ error: error.message });
    }
  },
  
  // 成员管理
  fetchMembers: async () => {
    set({ loading: true, error: null });
    try {
      const response = await integralDAOApi.members.getAll();
      const members = response.data.map((member: any) => ({
        ...member,
        votingPower: get().calculateVotingPower(member)
      }));
      set({ members, loading: false });
    } catch (error: any) {
      set({ error: error.message, loading: false });
    }
  },
  
  updateMemberReputation: async (id: string, score: number) => {
    set({ loading: true, error: null });
    try {
      await integralDAOApi.members.updateReputation(id, score);
      await get().fetchMembers();
      set({ loading: false });
    } catch (error: any) {
      set({ error: error.message, loading: false });
    }
  },
  
  updateMemberContribution: async (id: string, points: number) => {
    set({ loading: true, error: null });
    try {
      await integralDAOApi.members.updateContribution(id, points);
      await get().fetchMembers();
      set({ loading: false });
    } catch (error: any) {
      set({ error: error.message, loading: false });
    }
  },
  
  // 提案管理
  fetchProposals: async () => {
    set({ loading: true, error: null });
    try {
      const response = await integralDAOApi.proposals.getAll();
      set({ proposals: response.data, loading: false });
    } catch (error: any) {
      set({ error: error.message, loading: false });
    }
  },
  
  createProposal: async (proposal) => {
    set({ loading: true, error: null });
    try {
      await integralDAOApi.proposals.create(proposal);
      await get().fetchProposals();
      set({ loading: false });
    } catch (error: any) {
      set({ error: error.message, loading: false });
    }
  },
  
  updateProposal: async (id: string, proposal) => {
    set({ loading: true, error: null });
    try {
      await integralDAOApi.proposals.update(id, proposal);
      await get().fetchProposals();
      set({ loading: false });
    } catch (error: any) {
      set({ error: error.message, loading: false });
    }
  },
  
  activateProposal: async (id: string) => {
    set({ loading: true, error: null });
    try {
      await integralDAOApi.proposals.activate(id);
      await get().fetchProposals();
      set({ loading: false });
    } catch (error: any) {
      set({ error: error.message, loading: false });
    }
  },
  
  // 投票管理
  fetchVotes: async (proposalId: string) => {
    try {
      const response = await integralDAOApi.votes.getByProposal(proposalId);
      set({ votes: response.data });
    } catch (error: any) {
      set({ error: error.message });
    }
  },
  
  voteOnProposal: async (proposalId: string, choice) => {
    set({ loading: true, error: null });
    try {
      await integralDAOApi.votes.vote({ proposalId, voteChoice: choice });
      await get().fetchVotes(proposalId);
      await get().fetchProposals(); // 刷新提案状态
      set({ loading: false });
    } catch (error: any) {
      set({ error: error.message, loading: false });
    }
  },
  
  // 奖励管理
  fetchRewards: async () => {
    set({ loading: true, error: null });
    try {
      const response = await integralDAOApi.rewards.getAll();
      set({ rewards: response.data, loading: false });
    } catch (error: any) {
      set({ error: error.message, loading: false });
    }
  },
  
  createReward: async (reward) => {
    set({ loading: true, error: null });
    try {
      await integralDAOApi.rewards.create(reward);
      await get().fetchRewards();
      set({ loading: false });
    } catch (error: any) {
      set({ error: error.message, loading: false });
    }
  },
  
  // 统计信息
  fetchStats: async () => {
    try {
      const response = await integralDAOApi.stats.getOverview();
      set({ stats: response.data });
    } catch (error: any) {
      set({ error: error.message });
    }
  },
  
  // 工具方法
  setLoading: (loading: boolean) => set({ loading }),
  setError: (error: string | null) => set({ error }),
  
  // 投票权重计算 - 基于积分的核心算法
  calculateVotingPower: (member: IntegralDAOMember) => {
    // 基础投票权重计算：声誉积分 * 0.7 + 贡献积分 * 0.3
    const basePower = member.reputationScore * 0.7 + member.contributionPoints * 0.3;
    
    // 状态调整
    const statusMultiplier = member.status === 'active' ? 1.0 : 0.5;
    
    // 时间衰减（可选）
    const daysSinceJoin = (Date.now() - new Date(member.joinDate).getTime()) / (1000 * 60 * 60 * 24);
    const timeMultiplier = Math.min(1.0, daysSinceJoin / 30); // 30天后达到最大权重
    
    return Math.max(1, Math.floor(basePower * statusMultiplier * timeMultiplier));
  },
}));
