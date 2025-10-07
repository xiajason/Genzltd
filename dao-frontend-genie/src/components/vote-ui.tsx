"use client";
import { useState } from "react";
import { api } from "@/trpc/react";
import toast from "react-hot-toast";
import { IntegralDAOProposal } from "@/types/integral-dao";

interface VoteUIProps {
  proposal: IntegralDAOProposal;
  currentUserId: string;
  userVote?: {
    voteChoice: string;
    votingPower: number;
  } | null;
  onVoteSuccess?: () => void;
}

export function VoteUI({ proposal, currentUserId, userVote, onVoteSuccess }: VoteUIProps) {
  const [selectedChoice, setSelectedChoice] = useState<string>("");
  const [isSubmitting, setIsSubmitting] = useState(false);

  const voteMutation = api.dao.vote.useMutation({
    onSuccess: () => {
      toast.success("投票成功！");
      setSelectedChoice("");
      if (onVoteSuccess) {
        onVoteSuccess();
      }
    },
    onError: (error) => {
      toast.error(`投票失败: ${error.message}`);
    },
  });

  const handleVote = async () => {
    if (!selectedChoice) {
      toast.error("请选择投票选项");
      return;
    }

    setIsSubmitting(true);
    
    try {
      await voteMutation.mutateAsync({
        proposalId: proposal.proposalId,
        voterId: currentUserId,
        voteChoice: selectedChoice as "FOR" | "AGAINST" | "ABSTAIN",
      });
    } catch (error) {
      console.error("投票失败:", error);
    } finally {
      setIsSubmitting(false);
    }
  };

  // 如果用户已经投票，显示投票结果
  if (userVote) {
    return (
      <div className="bg-green-50 border border-green-200 rounded-lg p-4">
        <div className="flex items-center justify-between">
          <div>
            <h4 className="text-sm font-medium text-green-800">您的投票</h4>
            <p className="text-sm text-green-600">
              选择: {
                userVote.voteChoice === "FOR" ? "支持" :
                userVote.voteChoice === "AGAINST" ? "反对" : "弃权"
              }
            </p>
            <p className="text-xs text-green-500">
              投票权重: {userVote.votingPower} 分
            </p>
          </div>
          <div className="text-green-600">
            <svg className="w-6 h-6" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
            </svg>
          </div>
        </div>
      </div>
    );
  }

  // 如果提案未激活或已结束，显示状态
  if (proposal.status !== "active") {
    return (
      <div className="bg-gray-50 border border-gray-200 rounded-lg p-4">
        <p className="text-sm text-gray-600">
          {proposal.status === "draft" ? "提案尚未激活" : 
           proposal.status === "passed" ? "提案已通过" :
           proposal.status === "rejected" ? "提案已拒绝" :
           proposal.status === "executed" ? "提案已执行" : "提案状态未知"}
        </p>
      </div>
    );
  }

  // 检查投票是否已结束
  const isVotingEnded = proposal.endTime && new Date(proposal.endTime) < new Date();
  
  if (isVotingEnded) {
    return (
      <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
        <p className="text-sm text-yellow-600">投票已结束</p>
      </div>
    );
  }

  return (
    <div className="bg-white border border-gray-200 rounded-lg p-4">
      <h4 className="text-sm font-medium text-gray-900 mb-3">投票</h4>
      
      <div className="space-y-2 mb-4">
        <label className="flex items-center">
          <input
            type="radio"
            name="vote"
            value="FOR"
            checked={selectedChoice === "FOR"}
            onChange={(e) => setSelectedChoice(e.target.value)}
            className="h-4 w-4 text-green-600 focus:ring-green-500 border-gray-300"
          />
          <span className="ml-2 text-sm text-gray-700">支持</span>
        </label>
        
        <label className="flex items-center">
          <input
            type="radio"
            name="vote"
            value="AGAINST"
            checked={selectedChoice === "AGAINST"}
            onChange={(e) => setSelectedChoice(e.target.value)}
            className="h-4 w-4 text-red-600 focus:ring-red-500 border-gray-300"
          />
          <span className="ml-2 text-sm text-gray-700">反对</span>
        </label>
        
        <label className="flex items-center">
          <input
            type="radio"
            name="vote"
            value="ABSTAIN"
            checked={selectedChoice === "ABSTAIN"}
            onChange={(e) => setSelectedChoice(e.target.value)}
            className="h-4 w-4 text-gray-600 focus:ring-gray-500 border-gray-300"
          />
          <span className="ml-2 text-sm text-gray-700">弃权</span>
        </label>
      </div>

      <button
        onClick={handleVote}
        disabled={isSubmitting || !selectedChoice}
        className="w-full rounded-lg bg-[#5B51F6] px-4 py-2 text-white hover:bg-[#4A41E0] focus:outline-none focus:ring-2 focus:ring-[#5B51F6] focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed"
      >
        {isSubmitting ? "投票中..." : "提交投票"}
      </button>
    </div>
  );
}

