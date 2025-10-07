"use client";

import { useEffect, useState } from 'react';
import { useIntegralDAOStore } from '../stores/integral-dao-store';
import { IntegralProposalCard } from './integral-proposal-card';
import { IntegralMemberList } from './integral-member-list';
import { CreateProposalUi } from './create-proposal-ui';
import { api } from "@/trpc/react";
import toast from "react-hot-toast";

interface IntegralDAOMainProps {
  daoId: number;
}

export function IntegralDAOMain({ daoId }: IntegralDAOMainProps) {
  const [showCreateProposal, setShowCreateProposal] = useState(false);
  
  // 使用新的API获取数据
  const { data: proposalsData, isLoading: proposalsLoading, refetch: refetchProposals } = api.dao.getProposals.useQuery({
    page: 1,
    limit: 10,
  });

  const { data: membersData, isLoading: membersLoading, refetch: refetchMembers } = api.dao.getMembers.useQuery({
    page: 1,
    limit: 10,
  });

  const { data: statsData, isLoading: statsLoading, refetch: refetchStats } = api.dao.getStats.useQuery();

  // 模拟当前用户数据
  const currentUser = {
    id: "user_001",
    username: "demo_user",
    email: "demo@example.com",
    reputationScore: 100,
    contributionPoints: 50,
    votingPower: 85,
    isAuthenticated: true
  };

  const proposals = proposalsData?.data || [];
  const members = membersData?.data || [];
  const stats = statsData?.data || {};
  const loading = proposalsLoading || membersLoading || statsLoading;

  const handleProposalCreated = () => {
    setShowCreateProposal(false);
    refetchProposals();
    toast.success("提案创建成功！");
  };

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-purple-500"></div>
      </div>
    );
  }

  return (
    <div className="p-6 bg-gray-50 min-h-screen">
      <div className="max-w-7xl mx-auto">
        {/* 欢迎信息 */}
        <div className="mb-8">
          <div className="flex justify-between items-center">
            <div>
              <h1 className="text-3xl font-bold text-gray-900">
                积分制DAO治理系统
              </h1>
              <p className="mt-2 text-gray-600">
                欢迎，{currentUser?.username || '用户'}！您的投票权重：{currentUser?.votingPower || 0} 分
              </p>
              <div className="mt-4 flex space-x-4 text-sm text-gray-500">
                <span>声誉积分: {currentUser?.reputationScore || 0}</span>
                <span>贡献积分: {currentUser?.contributionPoints || 0}</span>
              </div>
            </div>
            <button
              onClick={() => setShowCreateProposal(true)}
              className="rounded-lg bg-[#5B51F6] px-6 py-2 text-white hover:bg-[#4A41E0] focus:outline-none focus:ring-2 focus:ring-[#5B51F6] focus:ring-offset-2"
            >
              创建提案
            </button>
          </div>
        </div>

        {/* 统计卡片 */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <div className="bg-white overflow-hidden shadow rounded-lg">
            <div className="p-5">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <svg className="h-6 w-6 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z" />
                  </svg>
                </div>
                <div className="ml-5 w-0 flex-1">
                  <dl>
                    <dt className="text-sm font-medium text-gray-500 truncate">总成员数</dt>
                    <dd className="text-lg font-medium text-gray-900">{stats.totalMembers || 0}</dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>

          <div className="bg-white overflow-hidden shadow rounded-lg">
            <div className="p-5">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <svg className="h-6 w-6 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                  </svg>
                </div>
                <div className="ml-5 w-0 flex-1">
                  <dl>
                    <dt className="text-sm font-medium text-gray-500 truncate">活跃提案</dt>
                    <dd className="text-lg font-medium text-gray-900">{stats.activeProposals || 0}</dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>

          <div className="bg-white overflow-hidden shadow rounded-lg">
            <div className="p-5">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <svg className="h-6 w-6 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
                  </svg>
                </div>
                <div className="ml-5 w-0 flex-1">
                  <dl>
                    <dt className="text-sm font-medium text-gray-500 truncate">总提案数</dt>
                    <dd className="text-lg font-medium text-gray-900">{stats.totalProposals || 0}</dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>

          <div className="bg-white overflow-hidden shadow rounded-lg">
            <div className="p-5">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <svg className="h-6 w-6 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11.049 2.927c.3-.921 1.603-.921 1.902 0l1.519 4.674a1 1 0 00.95.69h4.915c.969 0 1.371 1.24.588 1.81l-3.976 2.888a1 1 0 00-.363 1.118l1.518 4.674c.3.922-.755 1.688-1.538 1.118l-3.976-2.888a1 1 0 00-1.176 0l-3.976 2.888c-.783.57-1.838-.197-1.538-1.118l1.518-4.674a1 1 0 00-.363-1.118l-3.976-2.888c-.784-.57-.38-1.81.588-1.81h4.914a1 1 0 00.951-.69l1.519-4.674z" />
                  </svg>
                </div>
                <div className="ml-5 w-0 flex-1">
                  <dl>
                    <dt className="text-sm font-medium text-gray-500 truncate">平均声誉</dt>
                    <dd className="text-lg font-medium text-gray-900">{stats.avgReputation || 0}</dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* 主要内容区域 */}
        {showCreateProposal ? (
          <div className="max-w-2xl mx-auto">
            <div className="bg-white shadow rounded-lg">
              <div className="px-4 py-5 sm:p-6">
                <CreateProposalUi OnSubmitProposal={handleProposalCreated} />
              </div>
            </div>
          </div>
        ) : (
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
            {/* 最新提案 */}
            <div className="lg:col-span-2">
              <div className="bg-white shadow rounded-lg">
                <div className="px-4 py-5 sm:p-6">
                  <h3 className="text-lg leading-6 font-medium text-gray-900 mb-4">
                    最新提案
                  </h3>
                  <div className="space-y-4">
                    {proposals.length > 0 ? (
                      proposals.slice(0, 5).map((proposal) => (
                        <IntegralProposalCard 
                          key={proposal.id} 
                          proposal={proposal}
                          currentUser={currentUser}
                          showVoting={true}
                        />
                      ))
                    ) : (
                      <div className="text-center py-8 text-gray-500">
                        <p>暂无提案数据</p>
                        <button
                          onClick={() => setShowCreateProposal(true)}
                          className="mt-4 rounded-lg bg-[#5B51F6] px-4 py-2 text-white hover:bg-[#4A41E0]"
                        >
                          创建第一个提案
                        </button>
                      </div>
                    )}
                  </div>
                </div>
              </div>
            </div>

            {/* 活跃成员 */}
            <div className="lg:col-span-1">
              <div className="bg-white shadow rounded-lg">
                <div className="px-4 py-5 sm:p-6">
                  <h3 className="text-lg leading-6 font-medium text-gray-900 mb-4">
                    活跃成员
                  </h3>
                  <IntegralMemberList members={members.slice(0, 5)} />
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
