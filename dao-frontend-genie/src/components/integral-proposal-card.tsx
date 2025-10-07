"use client";

import { useState, useEffect } from "react";
import { IntegralDAOProposal, AuthenticatedUser } from '../types/integral-dao';
import { VoteUI } from './vote-ui';
import { api } from "@/trpc/react";

interface IntegralProposalCardProps {
  proposal: IntegralDAOProposal;
  currentUser: AuthenticatedUser | null;
  showVoting?: boolean;
}

export function IntegralProposalCard({ proposal, currentUser, showVoting = true }: IntegralProposalCardProps) {
  const [userVote, setUserVote] = useState<any>(null);
  const [showVoteForm, setShowVoteForm] = useState(false);

  // 获取用户投票记录
  const { data: voteData, refetch: refetchVote } = api.dao.getUserVote.useQuery(
    {
      proposalId: proposal.proposalId,
      voterId: currentUser?.id || "",
    },
    {
      enabled: !!currentUser && showVoting,
    }
  );

  useEffect(() => {
    if (voteData?.data) {
      setUserVote(voteData.data);
    } else {
      setUserVote(null);
    }
  }, [voteData]);

  const handleVoteSuccess = () => {
    refetchVote();
    setShowVoteForm(false);
  };

  const formatDate = (dateString?: string) => {
    if (!dateString) return "未设置";
    return new Date(dateString).toLocaleDateString("zh-CN");
  };

  const getStatusText = (status: string) => {
    switch (status) {
      case "active": return "进行中";
      case "draft": return "草稿";
      case "passed": return "已通过";
      case "rejected": return "已拒绝";
      case "executed": return "已执行";
      default: return status;
    }
  };

  const getTypeText = (type: string) => {
    switch (type) {
      case "governance": return "治理";
      case "funding": return "资金";
      case "technical": return "技术";
      case "policy": return "政策";
      default: return type;
    }
  };
  return (
    <div className="bg-white border border-gray-200 rounded-lg p-6 hover:shadow-md transition-shadow">
      {/* 提案头部 */}
      <div className="flex justify-between items-start mb-3">
        <div className="flex-1">
          <h4 className="text-lg font-semibold text-gray-900 mb-1">
            {proposal.title}
          </h4>
          <div className="flex items-center space-x-2 text-sm text-gray-500">
            <span className="bg-blue-100 text-blue-800 px-2 py-1 rounded-full text-xs">
              {getTypeText(proposal.proposalType)}
            </span>
            <span>提案人: {proposal.proposer?.username || "未知"}</span>
          </div>
        </div>
        <span className={`px-3 py-1 rounded-full text-xs font-medium ${
          proposal.status === 'active' ? 'bg-green-100 text-green-800' :
          proposal.status === 'passed' ? 'bg-blue-100 text-blue-800' :
          proposal.status === 'rejected' ? 'bg-red-100 text-red-800' :
          'bg-gray-100 text-gray-800'
        }`}>
          {getStatusText(proposal.status)}
        </span>
      </div>
      
      {/* 提案描述 */}
      <p className="text-gray-600 text-sm mb-4 line-clamp-3">
        {proposal.description}
      </p>
      
      {/* 投票统计 */}
      <div className="mb-4">
        <div className="flex justify-between items-center text-sm mb-2">
          <span className="text-gray-500">投票进度</span>
          <span className="text-gray-500">总投票: {proposal.totalVotes}</span>
        </div>
        <div className="flex space-x-4 text-sm">
          <div className="flex items-center space-x-1">
            <div className="w-3 h-3 bg-green-500 rounded-full"></div>
            <span>支持: {proposal.votesFor}</span>
          </div>
          <div className="flex items-center space-x-1">
            <div className="w-3 h-3 bg-red-500 rounded-full"></div>
            <span>反对: {proposal.votesAgainst}</span>
          </div>
        </div>
      </div>
      
      {/* 时间信息 */}
      <div className="text-xs text-gray-400 mb-4">
        <div>开始时间: {formatDate(proposal.startTime)}</div>
        <div>结束时间: {formatDate(proposal.endTime)}</div>
      </div>
      
      {/* 投票区域 */}
      {showVoting && currentUser && (
        <div className="border-t pt-4">
          {!userVote && !showVoteForm && proposal.status === 'active' && (
            <button
              onClick={() => setShowVoteForm(true)}
              className="w-full rounded-lg bg-[#5B51F6] px-4 py-2 text-white hover:bg-[#4A41E0] focus:outline-none focus:ring-2 focus:ring-[#5B51F6] focus:ring-offset-2"
            >
              参与投票
            </button>
          )}
          
          {showVoteForm && (
            <VoteUI
              proposal={proposal}
              currentUserId={currentUser.id}
              userVote={userVote}
              onVoteSuccess={handleVoteSuccess}
            />
          )}
          
          {userVote && (
            <VoteUI
              proposal={proposal}
              currentUserId={currentUser.id}
              userVote={userVote}
              onVoteSuccess={handleVoteSuccess}
            />
          )}
        </div>
      )}
    </div>
  );
}
