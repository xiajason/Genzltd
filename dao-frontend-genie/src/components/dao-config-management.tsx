'use client';

import React, { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { api } from '@/trpc/react';
import { toast } from 'react-hot-toast';

// 表单验证schema
const daoConfigSchema = z.object({
  daoId: z.string().min(1, 'DAO ID不能为空'),
  daoName: z.string().min(1, 'DAO名称不能为空'),
  daoDescription: z.string().optional(),
  daoLogo: z.string().optional(),
  daoType: z.enum(['COMMUNITY', 'CORPORATE', 'INVESTMENT', 'GOVERNANCE', 'SOCIAL', 'DEFI', 'NFT', 'GAMING', 'EDUCATION', 'RESEARCH']).default('COMMUNITY'),
  
  // 治理参数配置
  votingThreshold: z.number().min(0).max(100).default(50.0),
  proposalThreshold: z.number().min(0).default(1000),
  votingPeriod: z.number().min(1).max(30).default(7),
  executionDelay: z.number().min(0).max(7).default(1),
  minProposalAmount: z.number().min(0).optional(),
  
  // 成员管理配置
  maxMembers: z.number().min(1).optional(),
  allowMemberInvite: z.boolean().default(true),
  requireApproval: z.boolean().default(false),
  autoApproveThreshold: z.number().min(0).optional(),
  
  // 权限配置
  allowProposalCreation: z.boolean().default(true),
  allowVoting: z.boolean().default(true),
  allowTreasuryAccess: z.boolean().default(false),
  
  // 通知配置
  enableNotifications: z.boolean().default(true),
  
  // 高级配置
  governanceToken: z.string().optional(),
  contractAddress: z.string().optional(),
});

type DAOConfigData = z.infer<typeof daoConfigSchema>;

interface DAOConfigManagementProps {
  daoId: string;
  initialConfig?: any;
}

export function DAOConfigManagement({ daoId, initialConfig }: DAOConfigManagementProps) {
  const [activeTab, setActiveTab] = useState<'basic' | 'governance' | 'members' | 'permissions' | 'advanced'>('basic');
  const [isEditing, setIsEditing] = useState(false);

  // 获取DAO配置
  const { data: configData, refetch } = api.daoConfig.getConfig.useQuery(
    { daoId },
    { enabled: !!daoId }
  );

  // 获取DAO类型列表
  const { data: daoTypesData } = api.daoConfig.getDAOTypes.useQuery();

  // 获取DAO设置列表
  const { data: settingsData } = api.daoConfig.getSettings.useQuery(
    { daoId },
    { enabled: !!daoId }
  );

  // 获取配置统计
  const { data: statsData } = api.daoConfig.getConfigStats.useQuery(
    { daoId },
    { enabled: !!daoId }
  );

  // 创建配置
  const createConfigMutation = api.daoConfig.createConfig.useMutation({
    onSuccess: () => {
      toast.success('DAO配置创建成功');
      refetch();
      setIsEditing(false);
    },
    onError: (error) => {
      toast.error(`创建失败: ${error.message}`);
    },
  });

  // 更新配置
  const updateConfigMutation = api.daoConfig.updateConfig.useMutation({
    onSuccess: () => {
      toast.success('DAO配置更新成功');
      refetch();
      setIsEditing(false);
    },
    onError: (error) => {
      toast.error(`更新失败: ${error.message}`);
    },
  });

  // 创建设置
  const createSettingMutation = api.daoConfig.createSetting.useMutation({
    onSuccess: () => {
      toast.success('DAO设置创建成功');
      refetch();
    },
    onError: (error) => {
      toast.error(`创建设置失败: ${error.message}`);
    },
  });

  const {
    register,
    handleSubmit,
    formState: { errors },
    reset,
    watch,
  } = useForm<DAOConfigData>({
    resolver: zodResolver(daoConfigSchema),
    defaultValues: configData?.data || {
      daoId,
      daoType: 'COMMUNITY',
      votingThreshold: 50.0,
      proposalThreshold: 1000,
      votingPeriod: 7,
      executionDelay: 1,
      allowMemberInvite: true,
      requireApproval: false,
      allowProposalCreation: true,
      allowVoting: true,
      allowTreasuryAccess: false,
      enableNotifications: true,
    },
  });

  const onSubmit = (data: DAOConfigData) => {
    if (configData?.data) {
      updateConfigMutation.mutate({ ...data, id: configData.data.id.toString() });
    } else {
      createConfigMutation.mutate(data);
    }
  };

  const handleCancel = () => {
    reset();
    setIsEditing(false);
  };

  const tabs = [
    { id: 'basic', label: '基础配置', icon: '⚙️' },
    { id: 'governance', label: '治理参数', icon: '🏛️' },
    { id: 'members', label: '成员管理', icon: '👥' },
    { id: 'permissions', label: '权限设置', icon: '🔐' },
    { id: 'advanced', label: '高级配置', icon: '🚀' },
  ] as const;

  if (!daoTypesData?.data) {
    return <div className="flex justify-center items-center h-64">加载中...</div>;
  }

  return (
    <div className="max-w-6xl mx-auto p-6 bg-white rounded-lg shadow-lg">
      <div className="mb-6">
        <h2 className="text-2xl font-bold text-gray-900 mb-2">DAO配置管理</h2>
        <p className="text-gray-600">管理DAO的基础配置、治理参数、成员设置和权限控制</p>
      </div>

      {/* 配置统计 */}
      {statsData?.data && (
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
          <div className="bg-blue-50 p-4 rounded-lg">
            <div className="text-sm text-blue-600 font-medium">总设置数</div>
            <div className="text-2xl font-bold text-blue-900">{statsData.data.totalSettings}</div>
          </div>
          <div className="bg-green-50 p-4 rounded-lg">
            <div className="text-sm text-green-600 font-medium">公开设置</div>
            <div className="text-2xl font-bold text-green-900">{statsData.data.publicSettings}</div>
          </div>
          <div className="bg-yellow-50 p-4 rounded-lg">
            <div className="text-sm text-yellow-600 font-medium">私有设置</div>
            <div className="text-2xl font-bold text-yellow-900">{statsData.data.privateSettings}</div>
          </div>
          <div className="bg-purple-50 p-4 rounded-lg">
            <div className="text-sm text-purple-600 font-medium">配置天数</div>
            <div className="text-2xl font-bold text-purple-900">{statsData.data.configAge}天</div>
          </div>
        </div>
      )}

      {/* 标签页导航 */}
      <div className="border-b border-gray-200 mb-6">
        <nav className="-mb-px flex space-x-8">
          {tabs.map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`py-2 px-1 border-b-2 font-medium text-sm ${
                activeTab === tab.id
                  ? 'border-blue-500 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              <span className="mr-2">{tab.icon}</span>
              {tab.label}
            </button>
          ))}
        </nav>
      </div>

      <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
        {/* 基础配置 */}
        {activeTab === 'basic' && (
          <div className="space-y-4">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">基础配置</h3>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  DAO名称 *
                </label>
                <input
                  {...register('daoName')}
                  disabled={!isEditing}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-100"
                  placeholder="输入DAO名称"
                />
                {errors.daoName && (
                  <p className="text-red-500 text-sm mt-1">{errors.daoName.message}</p>
                )}
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  DAO类型
                </label>
                <select
                  {...register('daoType')}
                  disabled={!isEditing}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-100"
                >
                  {daoTypesData.data.map((type) => (
                    <option key={type.value} value={type.value}>
                      {type.label}
                    </option>
                  ))}
                </select>
              </div>

              <div className="md:col-span-2">
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  DAO描述
                </label>
                <textarea
                  {...register('daoDescription')}
                  disabled={!isEditing}
                  rows={3}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-100"
                  placeholder="描述DAO的使命和目标"
                />
              </div>

              <div className="md:col-span-2">
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  DAO图标URL
                </label>
                <input
                  {...register('daoLogo')}
                  disabled={!isEditing}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-100"
                  placeholder="https://example.com/logo.png"
                />
              </div>
            </div>
          </div>
        )}

        {/* 治理参数配置 */}
        {activeTab === 'governance' && (
          <div className="space-y-4">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">治理参数配置</h3>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  投票通过阈值 (%) *
                </label>
                <input
                  type="number"
                  {...register('votingThreshold', { valueAsNumber: true })}
                  disabled={!isEditing}
                  min="0"
                  max="100"
                  step="0.1"
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-100"
                />
                <p className="text-sm text-gray-500 mt-1">提案通过所需的最低支持率</p>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  提案创建阈值 (积分)
                </label>
                <input
                  type="number"
                  {...register('proposalThreshold', { valueAsNumber: true })}
                  disabled={!isEditing}
                  min="0"
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-100"
                />
                <p className="text-sm text-gray-500 mt-1">创建提案所需的最低积分</p>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  投票期限 (天)
                </label>
                <input
                  type="number"
                  {...register('votingPeriod', { valueAsNumber: true })}
                  disabled={!isEditing}
                  min="1"
                  max="30"
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-100"
                />
                <p className="text-sm text-gray-500 mt-1">提案投票的时间期限</p>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  执行延迟 (天)
                </label>
                <input
                  type="number"
                  {...register('executionDelay', { valueAsNumber: true })}
                  disabled={!isEditing}
                  min="0"
                  max="7"
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-100"
                />
                <p className="text-sm text-gray-500 mt-1">提案通过后的执行延迟时间</p>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  最小提案金额
                </label>
                <input
                  type="number"
                  {...register('minProposalAmount', { valueAsNumber: true })}
                  disabled={!isEditing}
                  min="0"
                  step="0.01"
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-100"
                />
                <p className="text-sm text-gray-500 mt-1">提案涉及资金的最小金额</p>
              </div>
            </div>
          </div>
        )}

        {/* 成员管理配置 */}
        {activeTab === 'members' && (
          <div className="space-y-4">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">成员管理配置</h3>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  最大成员数
                </label>
                <input
                  type="number"
                  {...register('maxMembers', { valueAsNumber: true })}
                  disabled={!isEditing}
                  min="1"
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-100"
                  placeholder="不限制"
                />
                <p className="text-sm text-gray-500 mt-1">DAO的最大成员数量限制</p>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  自动审批阈值 (积分)
                </label>
                <input
                  type="number"
                  {...register('autoApproveThreshold', { valueAsNumber: true })}
                  disabled={!isEditing}
                  min="0"
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-100"
                  placeholder="不启用"
                />
                <p className="text-sm text-gray-500 mt-1">达到此积分的成员可自动审批</p>
              </div>

              <div className="md:col-span-2 space-y-3">
                <div className="flex items-center">
                  <input
                    type="checkbox"
                    {...register('allowMemberInvite')}
                    disabled={!isEditing}
                    className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded disabled:bg-gray-100"
                  />
                  <label className="ml-2 text-sm text-gray-700">
                    允许成员邀请新成员
                  </label>
                </div>

                <div className="flex items-center">
                  <input
                    type="checkbox"
                    {...register('requireApproval')}
                    disabled={!isEditing}
                    className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded disabled:bg-gray-100"
                  />
                  <label className="ml-2 text-sm text-gray-700">
                    新成员加入需要审批
                  </label>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* 权限设置 */}
        {activeTab === 'permissions' && (
          <div className="space-y-4">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">权限设置</h3>
            
            <div className="space-y-4">
              <div className="bg-gray-50 p-4 rounded-lg">
                <h4 className="font-medium text-gray-900 mb-3">基础权限</h4>
                <div className="space-y-3">
                  <div className="flex items-center">
                    <input
                      type="checkbox"
                      {...register('allowProposalCreation')}
                      disabled={!isEditing}
                      className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded disabled:bg-gray-100"
                    />
                    <label className="ml-2 text-sm text-gray-700">
                      允许成员创建提案
                    </label>
                  </div>

                  <div className="flex items-center">
                    <input
                      type="checkbox"
                      {...register('allowVoting')}
                      disabled={!isEditing}
                      className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded disabled:bg-gray-100"
                    />
                    <label className="ml-2 text-sm text-gray-700">
                      允许成员参与投票
                    </label>
                  </div>

                  <div className="flex items-center">
                    <input
                      type="checkbox"
                      {...register('allowTreasuryAccess')}
                      disabled={!isEditing}
                      className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded disabled:bg-gray-100"
                    />
                    <label className="ml-2 text-sm text-gray-700">
                      允许成员访问国库
                    </label>
                  </div>
                </div>
              </div>

              <div className="bg-gray-50 p-4 rounded-lg">
                <h4 className="font-medium text-gray-900 mb-3">通知设置</h4>
                <div className="flex items-center">
                  <input
                    type="checkbox"
                    {...register('enableNotifications')}
                    disabled={!isEditing}
                    className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded disabled:bg-gray-100"
                  />
                  <label className="ml-2 text-sm text-gray-700">
                    启用系统通知
                  </label>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* 高级配置 */}
        {activeTab === 'advanced' && (
          <div className="space-y-4">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">高级配置</h3>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  治理代币
                </label>
                <input
                  {...register('governanceToken')}
                  disabled={!isEditing}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-100"
                  placeholder="DAO治理代币符号"
                />
                <p className="text-sm text-gray-500 mt-1">DAO的治理代币符号</p>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  合约地址
                </label>
                <input
                  {...register('contractAddress')}
                  disabled={!isEditing}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-100"
                  placeholder="0x..."
                />
                <p className="text-sm text-gray-500 mt-1">智能合约地址</p>
              </div>
            </div>

            {/* 自定义设置 */}
            <div className="mt-6">
              <h4 className="font-medium text-gray-900 mb-3">自定义设置</h4>
              <p className="text-sm text-gray-500 mb-4">
                添加自定义的DAO设置项，支持字符串、数字、布尔值、JSON等类型
              </p>
              
              {/* 这里可以添加自定义设置的UI组件 */}
              <div className="text-center py-8 text-gray-500">
                自定义设置功能开发中...
              </div>
            </div>
          </div>
        )}

        {/* 操作按钮 */}
        <div className="flex justify-end space-x-3 pt-6 border-t border-gray-200">
          {!isEditing ? (
            <button
              type="button"
              onClick={() => setIsEditing(true)}
              className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              编辑配置
            </button>
          ) : (
            <>
              <button
                type="button"
                onClick={handleCancel}
                className="px-4 py-2 border border-gray-300 text-gray-700 rounded-md hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                取消
              </button>
              <button
                type="submit"
                disabled={createConfigMutation.isLoading || updateConfigMutation.isLoading}
                className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:opacity-50"
              >
                {configData?.data ? '更新配置' : '创建配置'}
              </button>
            </>
          )}
        </div>
      </form>
    </div>
  );
}
