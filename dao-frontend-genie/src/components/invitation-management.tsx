'use client';

import React, { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { api } from '@/trpc/react';
import { toast } from 'react-hot-toast';

// 表单验证schema
const createInvitationSchema = z.object({
  inviteeEmail: z.string().email('请输入有效的邮箱地址'),
  inviteeName: z.string().optional(),
  roleType: z.enum(['member', 'moderator', 'admin']).default('member'),
  invitationType: z.enum(['direct', 'referral', 'public']).default('direct'),
  expiresInDays: z.number().min(1).max(30).default(7)
});

type CreateInvitationData = z.infer<typeof createInvitationSchema>;

interface InvitationManagementProps {
  daoId: string;
  daoName: string;
}

interface Invitation {
  id: string;
  invitationId: string;
  daoId: string;
  inviterId: string;
  inviteeEmail: string;
  inviteeName?: string;
  roleType: 'member' | 'moderator' | 'admin';
  invitationType: 'direct' | 'referral' | 'public';
  status: 'pending' | 'accepted' | 'expired' | 'revoked';
  expiresAt: Date;
  acceptedAt?: Date;
  createdAt: Date;
  updatedAt: Date;
  inviter: {
    name: string;
    avatarUrl?: string;
  };
}

interface InvitationStats {
  totalInvitations: number;
  acceptedInvitations: number;
  pendingInvitations: number;
  expiredInvitations: number;
  acceptanceRate: number;
  lastUpdated: Date;
}

export const InvitationManagement: React.FC<InvitationManagementProps> = ({ 
  daoId, 
  daoName 
}) => {
  const [showCreateForm, setShowCreateForm] = useState(false);
  const [currentPage, setCurrentPage] = useState(1);
  const [statusFilter, setStatusFilter] = useState<string | undefined>();

  // 获取邀请列表
  const { data: invitationData, refetch: refetchInvitations } = api.invitation.getInvitations.useQuery({
    daoId,
    status: statusFilter as any,
    page: currentPage,
    limit: 20
  });

  // 获取邀请统计
  const { data: stats } = api.invitation.getInvitationStats.useQuery({ daoId });

  // 创建邀请mutation
  const createInvitationMutation = api.invitation.createInvitation.useMutation({
    onSuccess: () => {
      toast.success('邀请已发送');
      setShowCreateForm(false);
      refetchInvitations();
    },
    onError: (error) => {
      toast.error(error.message || '发送邀请失败');
    }
  });

  // 撤销邀请mutation
  const revokeInvitationMutation = api.invitation.revokeInvitation.useMutation({
    onSuccess: () => {
      toast.success('邀请已撤销');
      refetchInvitations();
    },
    onError: (error) => {
      toast.error(error.message || '撤销邀请失败');
    }
  });

  const handleCreateInvitation = async (data: CreateInvitationData) => {
    await createInvitationMutation.mutateAsync({
      daoId,
      ...data
    });
  };

  const handleRevokeInvitation = async (invitationId: string) => {
    if (confirm('确定要撤销此邀请吗？')) {
      await revokeInvitationMutation.mutateAsync({ invitationId });
    }
  };

  const getStatusColor = (status: string) => {
    const colors = {
      pending: 'bg-yellow-100 text-yellow-800',
      accepted: 'bg-green-100 text-green-800',
      expired: 'bg-red-100 text-red-800',
      revoked: 'bg-gray-100 text-gray-800'
    };
    return colors[status as keyof typeof colors] || 'bg-gray-100 text-gray-800';
  };

  const getStatusText = (status: string) => {
    const texts = {
      pending: '待处理',
      accepted: '已接受',
      expired: '已过期',
      revoked: '已撤销'
    };
    return texts[status as keyof typeof texts] || status;
  };

  const getRoleText = (role: string) => {
    const roles = {
      member: '普通成员',
      moderator: '版主',
      admin: '管理员'
    };
    return roles[role as keyof typeof roles] || role;
  };

  return (
    <div className="invitation-management">
      {/* 页面标题和操作按钮 */}
      <div className="flex justify-between items-center mb-6">
        <div>
          <h2 className="text-2xl font-bold text-gray-900">成员邀请管理</h2>
          <p className="text-gray-600 mt-1">{daoName}</p>
        </div>
        <button
          onClick={() => setShowCreateForm(true)}
          className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg font-medium transition-colors"
        >
          邀请新成员
        </button>
      </div>

      {/* 邀请统计卡片 */}
      {stats && (
        <div className="grid grid-cols-1 md:grid-cols-5 gap-4 mb-6">
          <div className="bg-white p-4 rounded-lg shadow-sm border">
            <div className="text-2xl font-bold text-gray-900">{stats.totalInvitations}</div>
            <div className="text-sm text-gray-600">总邀请数</div>
          </div>
          <div className="bg-white p-4 rounded-lg shadow-sm border">
            <div className="text-2xl font-bold text-green-600">{stats.acceptedInvitations}</div>
            <div className="text-sm text-gray-600">已接受</div>
          </div>
          <div className="bg-white p-4 rounded-lg shadow-sm border">
            <div className="text-2xl font-bold text-yellow-600">{stats.pendingInvitations}</div>
            <div className="text-sm text-gray-600">待处理</div>
          </div>
          <div className="bg-white p-4 rounded-lg shadow-sm border">
            <div className="text-2xl font-bold text-red-600">{stats.expiredInvitations}</div>
            <div className="text-sm text-gray-600">已过期</div>
          </div>
          <div className="bg-white p-4 rounded-lg shadow-sm border">
            <div className="text-2xl font-bold text-blue-600">{stats.acceptanceRate}%</div>
            <div className="text-sm text-gray-600">接受率</div>
          </div>
        </div>
      )}

      {/* 筛选器 */}
      <div className="bg-white p-4 rounded-lg shadow-sm border mb-6">
        <div className="flex items-center space-x-4">
          <label className="text-sm font-medium text-gray-700">状态筛选：</label>
          <select
            value={statusFilter || ''}
            onChange={(e) => {
              setStatusFilter(e.target.value || undefined);
              setCurrentPage(1);
            }}
            className="border border-gray-300 rounded-md px-3 py-1 text-sm"
          >
            <option value="">全部</option>
            <option value="pending">待处理</option>
            <option value="accepted">已接受</option>
            <option value="expired">已过期</option>
            <option value="revoked">已撤销</option>
          </select>
        </div>
      </div>

      {/* 邀请列表 */}
      <div className="bg-white rounded-lg shadow-sm border">
        <div className="px-6 py-4 border-b border-gray-200">
          <h3 className="text-lg font-medium text-gray-900">邀请列表</h3>
        </div>
        
        {invitationData?.invitations && invitationData.invitations.length > 0 ? (
          <div className="divide-y divide-gray-200">
            {invitationData.invitations.map((invitation: Invitation) => (
              <div key={invitation.id} className="px-6 py-4">
                <div className="flex items-center justify-between">
                  <div className="flex-1">
                    <div className="flex items-center space-x-3">
                      <div>
                        <h4 className="text-sm font-medium text-gray-900">
                          {invitation.inviteeName || invitation.inviteeEmail}
                        </h4>
                        <p className="text-sm text-gray-600">{invitation.inviteeEmail}</p>
                      </div>
                      <span className={`inline-flex px-2 py-1 text-xs font-medium rounded-full ${getStatusColor(invitation.status)}`}>
                        {getStatusText(invitation.status)}
                      </span>
                    </div>
                    
                    <div className="mt-2 flex items-center space-x-4 text-sm text-gray-500">
                      <span>角色：{getRoleText(invitation.roleType)}</span>
                      <span>邀请人：{invitation.inviter.name}</span>
                      <span>有效期：{new Date(invitation.expiresAt).toLocaleDateString()}</span>
                      {invitation.acceptedAt && (
                        <span>接受时间：{new Date(invitation.acceptedAt).toLocaleDateString()}</span>
                      )}
                    </div>
                  </div>
                  
                  <div className="flex items-center space-x-2">
                    {invitation.status === 'pending' && (
                      <button
                        onClick={() => handleRevokeInvitation(invitation.invitationId)}
                        className="text-red-600 hover:text-red-800 text-sm font-medium"
                      >
                        撤销
                      </button>
                    )}
                  </div>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="px-6 py-12 text-center">
            <p className="text-gray-500">暂无邀请记录</p>
          </div>
        )}

        {/* 分页 */}
        {invitationData?.pagination && invitationData.pagination.totalPages > 1 && (
          <div className="px-6 py-4 border-t border-gray-200 flex items-center justify-between">
            <div className="text-sm text-gray-700">
              显示第 {((currentPage - 1) * 20) + 1} - {Math.min(currentPage * 20, invitationData.pagination.total)} 条，
              共 {invitationData.pagination.total} 条
            </div>
            <div className="flex items-center space-x-2">
              <button
                onClick={() => setCurrentPage(currentPage - 1)}
                disabled={currentPage === 1}
                className="px-3 py-1 text-sm border border-gray-300 rounded-md disabled:opacity-50 disabled:cursor-not-allowed"
              >
                上一页
              </button>
              <span className="px-3 py-1 text-sm">
                {currentPage} / {invitationData.pagination.totalPages}
              </span>
              <button
                onClick={() => setCurrentPage(currentPage + 1)}
                disabled={currentPage === invitationData.pagination.totalPages}
                className="px-3 py-1 text-sm border border-gray-300 rounded-md disabled:opacity-50 disabled:cursor-not-allowed"
              >
                下一页
              </button>
            </div>
          </div>
        )}
      </div>

      {/* 创建邀请弹窗 */}
      {showCreateForm && (
        <CreateInvitationModal
          daoId={daoId}
          daoName={daoName}
          onSubmit={handleCreateInvitation}
          onClose={() => setShowCreateForm(false)}
          isLoading={createInvitationMutation.isLoading}
        />
      )}
    </div>
  );
};

// 创建邀请弹窗组件
interface CreateInvitationModalProps {
  daoId: string;
  daoName: string;
  onSubmit: (data: CreateInvitationData) => void;
  onClose: () => void;
  isLoading: boolean;
}

const CreateInvitationModal: React.FC<CreateInvitationModalProps> = ({
  daoId,
  daoName,
  onSubmit,
  onClose,
  isLoading
}) => {
  const form = useForm<CreateInvitationData>({
    resolver: zodResolver(createInvitationSchema),
    defaultValues: {
      inviteeEmail: '',
      inviteeName: '',
      roleType: 'member',
      invitationType: 'direct',
      expiresInDays: 7
    }
  });

  const handleSubmit = (data: CreateInvitationData) => {
    onSubmit(data);
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg shadow-xl max-w-md w-full mx-4">
        <div className="px-6 py-4 border-b border-gray-200">
          <h3 className="text-lg font-medium text-gray-900">邀请新成员加入 {daoName}</h3>
        </div>
        
        <form onSubmit={form.handleSubmit(handleSubmit)} className="px-6 py-4">
          <div className="space-y-4">
            {/* 邮箱地址 */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                邮箱地址 *
              </label>
              <input
                {...form.register('inviteeEmail')}
                type="email"
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="example@email.com"
              />
              {form.formState.errors.inviteeEmail && (
                <p className="text-red-500 text-sm mt-1">
                  {form.formState.errors.inviteeEmail.message}
                </p>
              )}
            </div>

            {/* 姓名 */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                姓名（可选）
              </label>
              <input
                {...form.register('inviteeName')}
                type="text"
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="被邀请人姓名"
              />
            </div>

            {/* 角色类型 */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                角色类型
              </label>
              <select
                {...form.register('roleType')}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="member">普通成员</option>
                <option value="moderator">版主</option>
                <option value="admin">管理员</option>
              </select>
            </div>

            {/* 邀请类型 */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                邀请类型
              </label>
              <select
                {...form.register('invitationType')}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="direct">直接邀请</option>
                <option value="referral">推荐邀请</option>
                <option value="public">公开邀请</option>
              </select>
            </div>

            {/* 有效期 */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                有效期（天）
              </label>
              <input
                {...form.register('expiresInDays', { valueAsNumber: true })}
                type="number"
                min="1"
                max="30"
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
              {form.formState.errors.expiresInDays && (
                <p className="text-red-500 text-sm mt-1">
                  {form.formState.errors.expiresInDays.message}
                </p>
              )}
            </div>
          </div>

          <div className="flex justify-end space-x-3 mt-6">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 hover:bg-gray-200 rounded-md transition-colors"
            >
              取消
            </button>
            <button
              type="submit"
              disabled={isLoading}
              className="px-4 py-2 text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed rounded-md transition-colors"
            >
              {isLoading ? '发送中...' : '发送邀请'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
