"use client";
import { useState } from "react";
import { api } from "@/trpc/react";
import toast from "react-hot-toast";

export type CreateProposalUiInput = {
  OnSubmitProposal?: (title: string, description: string, type: string) => void;
};

export function CreateProposalUi({ OnSubmitProposal }: CreateProposalUiInput) {
  const [proposalTitle, setProposalTitle] = useState("");
  const [proposalDescription, setProposalDescription] = useState("");
  const [proposalType, setProposalType] = useState("GOVERNANCE");
  const [isSubmitting, setIsSubmitting] = useState(false);

  const createProposalMutation = api.dao.createProposal.useMutation({
    onSuccess: () => {
      toast.success("提案创建成功！");
      setProposalTitle("");
      setProposalDescription("");
      setProposalType("GOVERNANCE");
    },
    onError: (error) => {
      toast.error(`创建提案失败: ${error.message}`);
    },
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!proposalTitle.trim() || !proposalDescription.trim()) {
      toast.error("请填写完整的提案信息");
      return;
    }

    setIsSubmitting(true);
    
    try {
      // 使用默认的提案者ID（在实际应用中应该从认证状态获取）
      const proposerId = "user_001";
      
      await createProposalMutation.mutateAsync({
        title: proposalTitle,
        description: proposalDescription,
        proposalType: proposalType as "GOVERNANCE" | "FUNDING" | "TECHNICAL" | "POLICY",
        proposerId,
      });

      // 如果传入了回调函数，也调用它
      if (OnSubmitProposal) {
        OnSubmitProposal(proposalTitle, proposalDescription, proposalType);
      }
    } catch (error) {
      console.error("创建提案失败:", error);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="h-full">
      <h1 className="mb-6 text-2xl font-bold">New Proposal</h1>
      <div className="overflow-hidden rounded-lg border border-gray-200 bg-white">
        <form onSubmit={handleSubmit} className="space-y-6">
          <div className="p-6">
            <label
              htmlFor="title"
              className="mb-2 block text-sm font-medium text-gray-900"
            >
              提案标题
            </label>
            <input
              type="text"
              id="title"
              value={proposalTitle}
              onChange={(e) => setProposalTitle(e.target.value)}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 focus:border-[#5B51F6] focus:outline-none focus:ring-1 focus:ring-[#5B51F6]"
              placeholder="请输入提案标题"
              required
            />
          </div>
          
          <div className="px-6">
            <label
              htmlFor="type"
              className="mb-2 block text-sm font-medium text-gray-900"
            >
              提案类型
            </label>
            <select
              id="type"
              value={proposalType}
              onChange={(e) => setProposalType(e.target.value)}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 focus:border-[#5B51F6] focus:outline-none focus:ring-1 focus:ring-[#5B51F6]"
            >
              <option value="GOVERNANCE">治理提案</option>
              <option value="FUNDING">资金提案</option>
              <option value="TECHNICAL">技术提案</option>
              <option value="POLICY">政策提案</option>
            </select>
          </div>

          <div className="px-6">
            <label
              htmlFor="description"
              className="mb-2 block text-sm font-medium text-gray-900"
            >
              提案描述
            </label>
            <textarea
              id="description"
              value={proposalDescription}
              onChange={(e) => setProposalDescription(e.target.value)}
              rows={6}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 focus:border-[#5B51F6] focus:outline-none focus:ring-1 focus:ring-[#5B51F6]"
              placeholder="请详细描述您的提案内容，包括背景、目标、实施计划等"
              required
            />
          </div>
          
          <div className="flex items-center justify-end bg-white px-6 py-4">
            <button
              type="submit"
              disabled={isSubmitting}
              className="rounded-lg bg-[#5B51F6] px-6 py-2 text-white hover:bg-[#4A41E0] focus:outline-none focus:ring-2 focus:ring-[#5B51F6] focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isSubmitting ? "创建中..." : "提交提案"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
