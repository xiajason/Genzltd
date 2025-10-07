'use client';

import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { api } from '@/trpc/react';
import { toast } from 'react-hot-toast';

interface InvitationAcceptPageProps {
  token: string;
}

interface InvitationData {
  invitationId: string;
  daoId: string;
  inviteeEmail: string;
  inviteeName?: string;
  roleType: 'member' | 'moderator' | 'admin';
  invitationType: 'direct' | 'referral' | 'public';
  expiresAt: Date;
  inviter: {
    name: string;
    avatarUrl?: string;
  };
}

export const InvitationAcceptPage: React.FC<InvitationAcceptPageProps> = ({ token }) => {
  const router = useRouter();
  const [invitation, setInvitation] = useState<InvitationData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // 验证邀请链接
  const { data: validationResult, isLoading: isValidating } = api.invitation.validateInvitation.useQuery(
    { token },
    {
      onSuccess: (data) => {
        setInvitation(data.invitation);
        setLoading(false);
      },
      onError: (error) => {
        setError(error.message);
        setLoading(false);
      },
      retry: false
    }
  );

  // 接受邀请mutation
  const acceptInvitationMutation = api.invitation.acceptInvitation.useMutation({
    onSuccess: (data) => {
      toast.success(data.message || '成功加入DAO');
      router.push(`/dao/${data.daoId}`);
    },
    onError: (error) => {
      toast.error(error.message || '接受邀请失败');
    }
  });

  const handleAcceptInvitation = async () => {
    if (!invitation) return;
    
    await acceptInvitationMutation.mutateAsync({
      token,
      userData: {
        name: invitation.inviteeName,
        avatar: undefined // 可以在这里添加头像处理逻辑
      }
    });
  };

  const getRoleDisplayName = (roleType: string) => {
    const roles = {
      member: '普通成员',
      moderator: '版主',
      admin: '管理员'
    };
    return roles[roleType as keyof typeof roles] || roleType;
  };

  const formatDate = (date: Date) => {
    return new Intl.DateTimeFormat('zh-CN', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    }).format(new Date(date));
  };

  const isExpired = invitation && new Date() > new Date(invitation.expiresAt);

  if (loading || isValidating) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">正在验证邀请链接...</p>
        </div>
      </div>
    );
  }

  if (error || !invitation) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="max-w-md w-full mx-4">
          <div className="bg-white rounded-lg shadow-lg p-8 text-center">
            <div className="w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-4">
              <svg className="w-8 h-8 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </div>
            <h2 className="text-2xl font-bold text-gray-900 mb-2">邀请无效</h2>
            <p className="text-gray-600 mb-6">
              {error || '邀请链接无效或已过期'}
            </p>
            <button
              onClick={() => router.push('/')}
              className="bg-blue-600 hover:bg-blue-700 text-white px-6 py-2 rounded-lg font-medium transition-colors"
            >
              返回首页
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center py-12">
      <div className="max-w-md w-full mx-4">
        <div className="bg-white rounded-lg shadow-lg overflow-hidden">
          {/* 头部 */}
          <div className="bg-gradient-to-r from-blue-600 to-purple-600 px-8 py-6 text-white">
            <div className="flex items-center space-x-3">
              <div className="w-12 h-12 bg-white bg-opacity-20 rounded-lg flex items-center justify-center">
                <span className="text-xl font-bold">DAO</span>
              </div>
              <div>
                <h1 className="text-xl font-bold">DAO邀请</h1>
                <p className="text-blue-100">来自 {invitation.inviter.name}</p>
              </div>
            </div>
          </div>

          {/* 内容 */}
          <div className="px-8 py-6">
            {/* 过期警告 */}
            {isExpired && (
              <div className="bg-red-50 border border-red-200 rounded-lg p-4 mb-6">
                <div className="flex items-center">
                  <svg className="w-5 h-5 text-red-600 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z" />
                  </svg>
                  <p className="text-red-800 font-medium">邀请已过期</p>
                </div>
                <p className="text-red-700 text-sm mt-1">
                  此邀请于 {formatDate(invitation.expiresAt)} 过期
                </p>
              </div>
            )}

            {/* DAO信息 */}
            <div className="text-center mb-6">
              <h2 className="text-2xl font-bold text-gray-900 mb-2">
                欢迎加入DAO
              </h2>
              <p className="text-gray-600">
                {invitation.inviter.name} 邀请您加入他们的DAO
              </p>
            </div>

            {/* 邀请详情 */}
            <div className="bg-gray-50 rounded-lg p-4 mb-6">
              <h3 className="font-medium text-gray-900 mb-3">邀请详情</h3>
              <div className="space-y-2 text-sm">
                <div className="flex justify-between">
                  <span className="text-gray-600">邀请人：</span>
                  <span className="font-medium">{invitation.inviter.name}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">角色：</span>
                  <span className="font-medium">{getRoleDisplayName(invitation.roleType)}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">邀请类型：</span>
                  <span className="font-medium">
                    {invitation.invitationType === 'direct' ? '直接邀请' :
                     invitation.invitationType === 'referral' ? '推荐邀请' : '公开邀请'}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">有效期至：</span>
                  <span className={`font-medium ${isExpired ? 'text-red-600' : 'text-gray-900'}`}>
                    {formatDate(invitation.expiresAt)}
                  </span>
                </div>
              </div>
            </div>

            {/* 角色说明 */}
            <div className="mb-6">
              <h4 className="font-medium text-gray-900 mb-2">
                {getRoleDisplayName(invitation.roleType)} 权限
              </h4>
              <div className="text-sm text-gray-600">
                {invitation.roleType === 'member' && (
                  <ul className="space-y-1">
                    <li>• 参与治理投票</li>
                    <li>• 创建和讨论提案</li>
                    <li>• 获得积分奖励</li>
                    <li>• 参与社区活动</li>
                  </ul>
                )}
                {invitation.roleType === 'moderator' && (
                  <ul className="space-y-1">
                    <li>• 所有成员权限</li>
                    <li>• 管理社区内容</li>
                    <li>• 审核提案</li>
                    <li>• 管理成员权限</li>
                  </ul>
                )}
                {invitation.roleType === 'admin' && (
                  <ul className="space-y-1">
                    <li>• 所有版主权限</li>
                    <li>• 管理DAO设置</li>
                    <li>• 邀请新成员</li>
                    <li>• 管理资金和奖励</li>
                  </ul>
                )}
              </div>
            </div>

            {/* 操作按钮 */}
            <div className="space-y-3">
              {!isExpired ? (
                <button
                  onClick={handleAcceptInvitation}
                  disabled={acceptInvitationMutation.isLoading}
                  className="w-full bg-blue-600 hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed text-white py-3 px-4 rounded-lg font-medium transition-colors"
                >
                  {acceptInvitationMutation.isLoading ? '处理中...' : '接受邀请'}
                </button>
              ) : (
                <button
                  disabled
                  className="w-full bg-gray-300 text-gray-500 py-3 px-4 rounded-lg font-medium cursor-not-allowed"
                >
                  邀请已过期
                </button>
              )}
              
              <button
                onClick={() => router.push('/')}
                className="w-full bg-gray-100 hover:bg-gray-200 text-gray-700 py-3 px-4 rounded-lg font-medium transition-colors"
              >
                返回首页
              </button>
            </div>

            {/* 安全提示 */}
            <div className="mt-6 p-3 bg-blue-50 border border-blue-200 rounded-lg">
              <div className="flex items-start">
                <svg className="w-4 h-4 text-blue-600 mt-0.5 mr-2 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                <div className="text-sm text-blue-800">
                  <p className="font-medium mb-1">安全提示</p>
                  <p>请确保您信任邀请人，并了解加入此DAO的权益和义务。</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
