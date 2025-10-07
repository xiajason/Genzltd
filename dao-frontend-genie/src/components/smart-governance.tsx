'use client';

import React, { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { api } from '@/trpc/react';
import { toast } from 'react-hot-toast';

// 表单验证schema
const createDecisionRuleSchema = z.object({
  ruleName: z.string().min(1, '规则名称不能为空'),
  description: z.string().optional(),
  triggerConditions: z.object({
    proposalType: z.enum(['GOVERNANCE', 'FUNDING', 'TECHNICAL', 'POLICY']),
    minVoteThreshold: z.number().min(0).max(100).default(50),
    minParticipationRate: z.number().min(0).max(100).default(30),
    requiredRoles: z.array(z.string()).optional(),
  }),
  executionActions: z.array(z.object({
    actionType: z.enum(['FUNDING', 'CONFIG_CHANGE', 'MEMBER_MANAGEMENT', 'SYSTEM_UPGRADE', 'POLICY_CHANGE']),
    actionConfig: z.record(z.any()),
    executionDelay: z.number().min(0).default(0),
  })),
  isActive: z.boolean().default(true),
});

const executeDecisionSchema = z.object({
  proposalId: z.string().min(1, '提案ID不能为空'),
  executionType: z.enum(['AUTO', 'MANUAL', 'SCHEDULED']),
  scheduledTime: z.date().optional(),
});

type CreateDecisionRuleData = z.infer<typeof createDecisionRuleSchema>;
type ExecuteDecisionData = z.infer<typeof executeDecisionSchema>;

interface SmartGovernanceProps {
  daoId: string;
}

export function SmartGovernance({ daoId }: SmartGovernanceProps) {
  const [activeTab, setActiveTab] = useState<'rules' | 'executions' | 'stats' | 'create'>('rules');
  const [isCreatingRule, setIsCreatingRule] = useState(false);
  const [isExecutingDecision, setIsExecutingDecision] = useState(false);

  // 获取决策规则列表
  const { data: decisionRulesData, refetch: refetchRules } = api.smartGovernance.getDecisionRules.useQuery();

  // 获取智能治理统计
  const { data: statsData } = api.smartGovernance.getSmartGovernanceStats.useQuery({
    startDate: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000), // 最近30天
  });

  // 创建决策规则
  const createRuleMutation = api.smartGovernance.createDecisionRule.useMutation({
    onSuccess: () => {
      toast.success('智能决策规则创建成功');
      refetchRules();
      setIsCreatingRule(false);
      resetRuleForm();
    },
    onError: (error) => {
      toast.error(`创建失败: ${error.message}`);
    },
  });

  // 执行决策
  const executeDecisionMutation = api.smartGovernance.executeDecision.useMutation({
    onSuccess: () => {
      toast.success('智能决策执行已启动');
      setIsExecutingDecision(false);
      resetExecutionForm();
    },
    onError: (error) => {
      toast.error(`执行失败: ${error.message}`);
    },
  });

  // 决策规则表单
  const {
    register: registerRule,
    handleSubmit: handleSubmitRule,
    formState: { errors: errorsRule },
    reset: resetRuleForm,
    setValue: setRuleValue,
    watch: watchRule,
  } = useForm<CreateDecisionRuleData>({
    resolver: zodResolver(createDecisionRuleSchema),
    defaultValues: {
      triggerConditions: {
        proposalType: 'GOVERNANCE',
        minVoteThreshold: 50,
        minParticipationRate: 30,
      },
      executionActions: [],
      isActive: true,
    },
  });

  // 执行决策表单
  const {
    register: registerExecution,
    handleSubmit: handleSubmitExecution,
    formState: { errors: errorsExecution },
    reset: resetExecutionForm,
  } = useForm<ExecuteDecisionData>({
    resolver: zodResolver(executeDecisionSchema),
    defaultValues: {
      executionType: 'AUTO',
    },
  });

  const onSubmitRule = (data: CreateDecisionRuleData) => {
    createRuleMutation.mutate(data);
  };

  const onSubmitExecution = (data: ExecuteDecisionData) => {
    executeDecisionMutation.mutate(data);
  };

  const tabs = [
    { id: 'rules', label: '决策规则', icon: '⚙️' },
    { id: 'executions', label: '执行记录', icon: '📋' },
    { id: 'stats', label: '智能统计', icon: '📊' },
    { id: 'create', label: '创建规则', icon: '➕' },
  ] as const;

  const proposalTypes = [
    { value: 'GOVERNANCE', label: '治理提案' },
    { value: 'FUNDING', label: '资金提案' },
    { value: 'TECHNICAL', label: '技术提案' },
    { value: 'POLICY', label: '政策提案' },
  ];

  const actionTypes = [
    { value: 'FUNDING', label: '资金分配', description: '自动执行资金转账和分配' },
    { value: 'CONFIG_CHANGE', label: '配置变更', description: '自动更新系统配置参数' },
    { value: 'MEMBER_MANAGEMENT', label: '成员管理', description: '自动调整成员角色和权限' },
    { value: 'SYSTEM_UPGRADE', label: '系统升级', description: '自动执行系统升级流程' },
    { value: 'POLICY_CHANGE', label: '政策变更', description: '自动更新治理政策和规则' },
  ];

  const executionTypes = [
    { value: 'AUTO', label: '自动执行', description: '提案通过后立即自动执行' },
    { value: 'MANUAL', label: '手动执行', description: '需要管理员手动确认执行' },
    { value: 'SCHEDULED', label: '定时执行', description: '按计划时间执行' },
  ];

  const addExecutionAction = () => {
    const currentActions = watchRule('executionActions');
    setRuleValue('executionActions', [
      ...currentActions,
      {
        actionType: 'FUNDING',
        actionConfig: {},
        executionDelay: 0,
      },
    ]);
  };

  const removeExecutionAction = (index: number) => {
    const currentActions = watchRule('executionActions');
    setRuleValue('executionActions', currentActions.filter((_, i) => i !== index));
  };

  const updateExecutionAction = (index: number, field: string, value: any) => {
    const currentActions = watchRule('executionActions');
    const updatedActions = [...currentActions];
    updatedActions[index] = { ...updatedActions[index], [field]: value };
    setRuleValue('executionActions', updatedActions);
  };

  return (
    <div className="max-w-7xl mx-auto p-6 bg-white rounded-lg shadow-lg">
      <div className="mb-6">
        <h2 className="text-2xl font-bold text-gray-900 mb-2">智能治理系统</h2>
        <p className="text-gray-600">基于AI的智能决策执行和自动化治理机制</p>
      </div>

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

      {/* 决策规则 */}
      {activeTab === 'rules' && (
        <div className="space-y-6">
          <div className="flex justify-between items-center">
            <h3 className="text-lg font-semibold text-gray-900">智能决策规则</h3>
            <button
              onClick={() => setActiveTab('create')}
              className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
            >
              创建新规则
            </button>
          </div>

          {/* 规则列表 */}
          <div className="space-y-4">
            {decisionRulesData?.data && decisionRulesData.data.length > 0 ? (
              decisionRulesData.data.map((rule: any) => (
                <div
                  key={rule.id}
                  className="border border-gray-200 rounded-lg p-4 hover:shadow-md transition-shadow"
                >
                  <div className="flex justify-between items-start mb-2">
                    <div>
                      <h4 className="text-lg font-medium text-gray-900">{rule.ruleName}</h4>
                      <p className="text-sm text-gray-600">{rule.description}</p>
                    </div>
                    <span className={`px-2 py-1 rounded-full text-xs font-medium ${
                      rule.isActive ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
                    }`}>
                      {rule.isActive ? '活跃' : '非活跃'}
                    </span>
                  </div>
                  
                  <div className="text-sm text-gray-600 mb-3">
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      <div>
                        <h5 className="font-medium text-gray-900 mb-1">触发条件</h5>
                        <div className="space-y-1">
                          <div>提案类型: {proposalTypes.find(p => p.value === rule.triggerConditions.proposalType)?.label}</div>
                          <div>最低投票阈值: {rule.triggerConditions.minVoteThreshold}%</div>
                          <div>最低参与率: {rule.triggerConditions.minParticipationRate}%</div>
                        </div>
                      </div>
                      <div>
                        <h5 className="font-medium text-gray-900 mb-1">执行动作</h5>
                        <div className="space-y-1">
                          {rule.executionActions.map((action: any, index: number) => (
                            <div key={index} className="flex items-center space-x-2">
                              <span className="text-xs bg-blue-100 text-blue-800 px-2 py-1 rounded">
                                {actionTypes.find(a => a.value === action.actionType)?.label}
                              </span>
                              {action.executionDelay > 0 && (
                                <span className="text-xs text-gray-500">
                                  延迟 {action.executionDelay}h
                                </span>
                              )}
                            </div>
                          ))}
                        </div>
                      </div>
                    </div>
                  </div>
                  
                  <div className="text-xs text-gray-500">
                    创建时间: {new Date(rule.createdAt).toLocaleString()}
                  </div>
                </div>
              ))
            ) : (
              <div className="text-center py-8 text-gray-500">
                暂无智能决策规则
              </div>
            )}
          </div>
        </div>
      )}

      {/* 执行记录 */}
      {activeTab === 'executions' && (
        <div className="space-y-6">
          <div className="flex justify-between items-center">
            <h3 className="text-lg font-semibold text-gray-900">决策执行记录</h3>
            <button
              onClick={() => setIsExecutingDecision(true)}
              className="px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700"
            >
              执行决策
            </button>
          </div>

          {/* 执行决策表单 */}
          {isExecutingDecision && (
            <div className="p-4 bg-gray-50 rounded-lg">
              <h4 className="text-md font-semibold text-gray-900 mb-4">执行智能决策</h4>
              <form onSubmit={handleSubmitExecution(onSubmitExecution)} className="space-y-4">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      提案ID *
                    </label>
                    <input
                      {...registerExecution('proposalId')}
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder="输入提案ID"
                    />
                    {errorsExecution.proposalId && (
                      <p className="text-red-500 text-sm mt-1">{errorsExecution.proposalId.message}</p>
                    )}
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      执行类型 *
                    </label>
                    <select
                      {...registerExecution('executionType')}
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    >
                      {executionTypes.map((type) => (
                        <option key={type.value} value={type.value}>
                          {type.label} - {type.description}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      计划执行时间
                    </label>
                    <input
                      {...registerExecution('scheduledTime', { valueAsDate: true })}
                      type="datetime-local"
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                  </div>
                </div>

                <div className="flex justify-end space-x-3">
                  <button
                    type="button"
                    onClick={() => {
                      setIsExecutingDecision(false);
                      resetExecutionForm();
                    }}
                    className="px-4 py-2 border border-gray-300 text-gray-700 rounded-md hover:bg-gray-50"
                  >
                    取消
                  </button>
                  <button
                    type="submit"
                    disabled={executeDecisionMutation.isLoading}
                    className="px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700 disabled:opacity-50"
                  >
                    执行决策
                  </button>
                </div>
              </form>
            </div>
          )}

          {/* 执行记录列表 */}
          <div className="text-center py-8 text-gray-500">
            执行记录功能开发中...
          </div>
        </div>
      )}

      {/* 智能统计 */}
      {activeTab === 'stats' && (
        <div className="space-y-6">
          <h3 className="text-lg font-semibold text-gray-900">智能治理统计</h3>
          
          {statsData?.data ? (
            <div className="space-y-6">
              {/* 概览统计 */}
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                <div className="bg-blue-50 p-4 rounded-lg">
                  <div className="text-sm text-blue-600 font-medium">总执行次数</div>
                  <div className="text-2xl font-bold text-blue-900">
                    {statsData.data.overview.totalExecutions}
                  </div>
                </div>
                <div className="bg-green-50 p-4 rounded-lg">
                  <div className="text-sm text-green-600 font-medium">成功执行</div>
                  <div className="text-2xl font-bold text-green-900">
                    {statsData.data.overview.completedExecutions}
                  </div>
                </div>
                <div className="bg-red-50 p-4 rounded-lg">
                  <div className="text-sm text-red-600 font-medium">执行失败</div>
                  <div className="text-2xl font-bold text-red-900">
                    {statsData.data.overview.failedExecutions}
                  </div>
                </div>
                <div className="bg-yellow-50 p-4 rounded-lg">
                  <div className="text-sm text-yellow-600 font-medium">成功率</div>
                  <div className="text-2xl font-bold text-yellow-900">
                    {statsData.data.overview.successRate}%
                  </div>
                </div>
              </div>

              {/* 执行类型统计 */}
              <div className="bg-white border border-gray-200 rounded-lg p-4">
                <h4 className="text-md font-semibold text-gray-900 mb-4">执行类型分布</h4>
                <div className="space-y-2">
                  {statsData.data.executionTypes.map((type: any, index: number) => (
                    <div key={index} className="flex justify-between items-center">
                      <span className="text-sm text-gray-600">
                        {executionTypes.find(e => e.value === type.executionType)?.label || type.executionType}
                      </span>
                      <span className="text-sm font-medium text-gray-900">
                        {type._count.executionType}
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          ) : (
            <div className="text-center py-8 text-gray-500">
              暂无统计数据
            </div>
          )}
        </div>
      )}

      {/* 创建规则 */}
      {activeTab === 'create' && (
        <div className="space-y-6">
          <div className="flex justify-between items-center">
            <h3 className="text-lg font-semibold text-gray-900">创建智能决策规则</h3>
            <button
              onClick={() => setActiveTab('rules')}
              className="px-4 py-2 border border-gray-300 text-gray-700 rounded-md hover:bg-gray-50"
            >
              返回规则列表
            </button>
          </div>

          <form onSubmit={handleSubmitRule(onSubmitRule)} className="space-y-6">
            {/* 基本信息 */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  规则名称 *
                </label>
                <input
                  {...registerRule('ruleName')}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="例如: 资金提案自动执行规则"
                />
                {errorsRule.ruleName && (
                  <p className="text-red-500 text-sm mt-1">{errorsRule.ruleName.message}</p>
                )}
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  规则状态
                </label>
                <select
                  {...registerRule('isActive', { valueAsBoolean: true })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  <option value="true">活跃</option>
                  <option value="false">非活跃</option>
                </select>
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                规则描述
              </label>
              <textarea
                {...registerRule('description')}
                rows={3}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="描述这个规则的作用和用途"
              />
            </div>

            {/* 触发条件 */}
            <div className="border border-gray-200 rounded-lg p-4">
              <h4 className="text-md font-semibold text-gray-900 mb-4">触发条件</h4>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    提案类型 *
                  </label>
                  <select
                    {...registerRule('triggerConditions.proposalType')}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    {proposalTypes.map((type) => (
                      <option key={type.value} value={type.value}>
                        {type.label}
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    最低投票阈值 (%)
                  </label>
                  <input
                    {...registerRule('triggerConditions.minVoteThreshold', { valueAsNumber: true })}
                    type="number"
                    min="0"
                    max="100"
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    最低参与率 (%)
                  </label>
                  <input
                    {...registerRule('triggerConditions.minParticipationRate', { valueAsNumber: true })}
                    type="number"
                    min="0"
                    max="100"
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>
            </div>

            {/* 执行动作 */}
            <div className="border border-gray-200 rounded-lg p-4">
              <div className="flex justify-between items-center mb-4">
                <h4 className="text-md font-semibold text-gray-900">执行动作</h4>
                <button
                  type="button"
                  onClick={addExecutionAction}
                  className="px-3 py-1 text-sm bg-blue-600 text-white rounded hover:bg-blue-700"
                >
                  添加动作
                </button>
              </div>

              <div className="space-y-4">
                {watchRule('executionActions').map((action: any, index: number) => (
                  <div key={index} className="border border-gray-200 rounded-lg p-4">
                    <div className="flex justify-between items-start mb-3">
                      <h5 className="text-sm font-medium text-gray-900">动作 {index + 1}</h5>
                      <button
                        type="button"
                        onClick={() => removeExecutionAction(index)}
                        className="px-2 py-1 text-sm bg-red-600 text-white rounded hover:bg-red-700"
                      >
                        删除
                      </button>
                    </div>

                    <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">
                          动作类型 *
                        </label>
                        <select
                          value={action.actionType}
                          onChange={(e) => updateExecutionAction(index, 'actionType', e.target.value)}
                          className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                        >
                          {actionTypes.map((type) => (
                            <option key={type.value} value={type.value}>
                              {type.label}
                            </option>
                          ))}
                        </select>
                        <p className="text-xs text-gray-500 mt-1">
                          {actionTypes.find(t => t.value === action.actionType)?.description}
                        </p>
                      </div>

                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">
                          执行延迟 (小时)
                        </label>
                        <input
                          type="number"
                          min="0"
                          value={action.executionDelay}
                          onChange={(e) => updateExecutionAction(index, 'executionDelay', Number(e.target.value))}
                          className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                        />
                      </div>

                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">
                          动作配置
                        </label>
                        <textarea
                          rows={2}
                          className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                          placeholder="JSON格式配置参数"
                        />
                      </div>
                    </div>
                  </div>
                ))}

                {watchRule('executionActions').length === 0 && (
                  <div className="text-center py-8 text-gray-500">
                    暂无执行动作，点击"添加动作"开始创建
                  </div>
                )}
              </div>
            </div>

            <div className="flex justify-end space-x-3">
              <button
                type="button"
                onClick={() => setActiveTab('rules')}
                className="px-4 py-2 border border-gray-300 text-gray-700 rounded-md hover:bg-gray-50"
              >
                取消
              </button>
              <button
                type="submit"
                disabled={createRuleMutation.isLoading}
                className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50"
              >
                创建规则
              </button>
            </div>
          </form>
        </div>
      )}
    </div>
  );
}
