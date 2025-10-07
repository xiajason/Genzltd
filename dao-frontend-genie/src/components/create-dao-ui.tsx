"use client";
import { useState } from "react";
import { api } from "@/trpc/react";
import toast from "react-hot-toast";

export type CreateDAOUIProps = {
  onCreateDAOSuccess?: (daoData: any) => void;
  onCancel?: () => void;
};

export function CreateDAOUI({ onCreateDAOSuccess, onCancel }: CreateDAOUIProps) {
  const [daoName, setDaoName] = useState("");
  const [daoDescription, setDaoDescription] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);

  const createDAOMutation = api.dao.createDAO.useMutation({
    onSuccess: (data) => {
      toast.success("DAO创建成功！");
      setDaoName("");
      setDaoDescription("");
      if (onCreateDAOSuccess) {
        onCreateDAOSuccess(data.data);
      }
    },
    onError: (error) => {
      toast.error(`创建DAO失败: ${error.message}`);
    },
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!daoName.trim() || !daoDescription.trim()) {
      toast.error("请填写完整的DAO信息");
      return;
    }

    setIsSubmitting(true);
    
    try {
      // 使用默认的创建者ID（在实际应用中应该从认证状态获取）
      const creatorId = "user_001";
      
      await createDAOMutation.mutateAsync({
        name: daoName,
        description: daoDescription,
        creatorId,
      });
    } catch (error) {
      console.error("创建DAO失败:", error);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="h-full">
      <h1 className="mb-6 text-2xl font-bold">创建新DAO</h1>
      <div className="overflow-hidden rounded-lg border border-gray-200 bg-white">
        <form onSubmit={handleSubmit} className="space-y-6">
          <div className="p-6">
            <label
              htmlFor="daoName"
              className="mb-2 block text-sm font-medium text-gray-900"
            >
              DAO名称
            </label>
            <input
              type="text"
              id="daoName"
              value={daoName}
              onChange={(e) => setDaoName(e.target.value)}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 focus:border-[#5B51F6] focus:outline-none focus:ring-1 focus:ring-[#5B51F6]"
              placeholder="请输入DAO名称"
              required
            />
          </div>

          <div className="px-6">
            <label
              htmlFor="daoDescription"
              className="mb-2 block text-sm font-medium text-gray-900"
            >
              DAO描述
            </label>
            <textarea
              id="daoDescription"
              value={daoDescription}
              onChange={(e) => setDaoDescription(e.target.value)}
              rows={6}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 focus:border-[#5B51F6] focus:outline-none focus:ring-1 focus:ring-[#5B51F6]"
              placeholder="请详细描述您的DAO，包括目标、治理机制、成员要求等"
              required
            />
          </div>

          {/* DAO配置说明 */}
          <div className="px-6 bg-blue-50 border-t">
            <h3 className="text-sm font-medium text-blue-900 mb-2">默认配置</h3>
            <div className="text-sm text-blue-700 space-y-1">
              <p>• 投票阈值: 50%</p>
              <p>• 提案有效期: 7天</p>
              <p>• 治理模式: 积分制</p>
              <p>• 初始成员: 创建者</p>
            </div>
          </div>
          
          <div className="flex items-center justify-end bg-white px-6 py-4 space-x-3">
            {onCancel && (
              <button
                type="button"
                onClick={onCancel}
                className="rounded-lg border border-gray-300 px-6 py-2 text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-gray-500 focus:ring-offset-2"
              >
                取消
              </button>
            )}
            <button
              type="submit"
              disabled={isSubmitting}
              className="rounded-lg bg-[#5B51F6] px-6 py-2 text-white hover:bg-[#4A41E0] focus:outline-none focus:ring-2 focus:ring-[#5B51F6] focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isSubmitting ? "创建中..." : "创建DAO"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

