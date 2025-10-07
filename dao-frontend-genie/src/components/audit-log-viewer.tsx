'use client';

import React, { useState } from 'react';
import { api } from '@/trpc/react';
import { toast } from 'react-hot-toast';

interface AuditLogViewerProps {
  daoId?: string;
}

export function AuditLogViewer({ daoId }: AuditLogViewerProps) {
  const [activeTab, setActiveTab] = useState<'logs' | 'alerts' | 'stats' | 'rules'>('logs');
  const [filters, setFilters] = useState({
    userId: '',
    eventType: '',
    status: '',
    level: '',
    startDate: '',
    endDate: '',
  });
  const [currentPage, setCurrentPage] = useState(1);
  const [pageSize] = useState(20);

  // 获取审计日志
  const { data: auditLogsData, refetch: refetchLogs } = api.audit.getAuditLogs.useQuery({
    daoId,
    userId: filters.userId || undefined,
    eventType: filters.eventType as any || undefined,
    status: filters.status as any || undefined,
    level: filters.level as any || undefined,
    startDate: filters.startDate ? new Date(filters.startDate) : undefined,
    endDate: filters.endDate ? new Date(filters.endDate) : undefined,
    page: currentPage,
    limit: pageSize,
  });

  // 获取审计告警
  const { data: auditAlertsData, refetch: refetchAlerts } = api.audit.getAuditAlerts.useQuery({
    severity: undefined,
    isResolved: undefined,
    page: currentPage,
    limit: pageSize,
  });

  // 获取审计统计
  const { data: auditStatsData } = api.audit.getAuditStats.useQuery({
    daoId,
    startDate: filters.startDate ? new Date(filters.startDate) : undefined,
    endDate: filters.endDate ? new Date(filters.endDate) : undefined,
  });

  // 获取审计规则
  const { data: auditRulesData } = api.audit.getAuditRules.useQuery();

  // 解决告警
  const resolveAlertMutation = api.audit.resolveAlert.useMutation({
    onSuccess: () => {
      toast.success('告警已解决');
      refetchAlerts();
    },
    onError: (error) => {
      toast.error(`解决告警失败: ${error.message}`);
    },
  });

  const tabs = [
    { id: 'logs', label: '审计日志', icon: '📋' },
    { id: 'alerts', label: '安全告警', icon: '🚨' },
    { id: 'stats', label: '统计报告', icon: '📊' },
    { id: 'rules', label: '审计规则', icon: '⚙️' },
  ] as const;

  const eventTypes = [
    { value: 'LOGIN', label: '登录' },
    { value: 'LOGOUT', label: '登出' },
    { value: 'DATA_ACCESS', label: '数据访问' },
    { value: 'DATA_MODIFICATION', label: '数据修改' },
    { value: 'DATA_DELETION', label: '数据删除' },
    { value: 'PERMISSION_CHANGE', label: '权限变更' },
    { value: 'ROLE_ASSIGNMENT', label: '角色分配' },
    { value: 'SYSTEM_CONFIG', label: '系统配置' },
    { value: 'SECURITY_VIOLATION', label: '安全违规' },
    { value: 'API_ACCESS', label: 'API访问' },
    { value: 'PROPOSAL_CREATE', label: '提案创建' },
    { value: 'PROPOSAL_UPDATE', label: '提案更新' },
    { value: 'VOTE_CAST', label: '投票' },
    { value: 'MEMBER_INVITE', label: '成员邀请' },
    { value: 'CONFIG_CHANGE', label: '配置变更' },
  ];

  const statusTypes = [
    { value: 'SUCCESS', label: '成功', color: 'text-green-600' },
    { value: 'FAILURE', label: '失败', color: 'text-red-600' },
    { value: 'WARNING', label: '警告', color: 'text-yellow-600' },
    { value: 'SUSPICIOUS', label: '可疑', color: 'text-orange-600' },
  ];

  const levelTypes = [
    { value: 'LOW', label: '低', color: 'text-blue-600' },
    { value: 'MEDIUM', label: '中', color: 'text-yellow-600' },
    { value: 'HIGH', label: '高', color: 'text-orange-600' },
    { value: 'CRITICAL', label: '严重', color: 'text-red-600' },
  ];

  const handleFilterChange = (key: string, value: string) => {
    setFilters(prev => ({ ...prev, [key]: value }));
    setCurrentPage(1);
  };

  const clearFilters = () => {
    setFilters({
      userId: '',
      eventType: '',
      status: '',
      level: '',
      startDate: '',
      endDate: '',
    });
    setCurrentPage(1);
  };

  const handleResolveAlert = (alertId: string) => {
    if (confirm('确定要解决这个告警吗？')) {
      resolveAlertMutation.mutate({ alertId });
    }
  };

  return (
    <div className="max-w-7xl mx-auto p-6 bg-white rounded-lg shadow-lg">
      <div className="mb-6">
        <h2 className="text-2xl font-bold text-gray-900 mb-2">审计日志查看器</h2>
        <p className="text-gray-600">基于Looma CRM经验的完整审计日志和安全监控系统</p>
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

      {/* 审计日志 */}
      {activeTab === 'logs' && (
        <div className="space-y-6">
          <div className="flex justify-between items-center">
            <h3 className="text-lg font-semibold text-gray-900">审计日志</h3>
            <div className="flex space-x-2">
              <button
                onClick={clearFilters}
                className="px-3 py-1 text-sm border border-gray-300 text-gray-700 rounded-md hover:bg-gray-50"
              >
                清除筛选
              </button>
            </div>
          </div>

          {/* 筛选器 */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 p-4 bg-gray-50 rounded-lg">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                用户ID
              </label>
              <input
                type="text"
                value={filters.userId}
                onChange={(e) => handleFilterChange('userId', e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="输入用户ID"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                事件类型
              </label>
              <select
                value={filters.eventType}
                onChange={(e) => handleFilterChange('eventType', e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="">全部</option>
                {eventTypes.map((type) => (
                  <option key={type.value} value={type.value}>
                    {type.label}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                状态
              </label>
              <select
                value={filters.status}
                onChange={(e) => handleFilterChange('status', e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="">全部</option>
                {statusTypes.map((status) => (
                  <option key={status.value} value={status.value}>
                    {status.label}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                级别
              </label>
              <select
                value={filters.level}
                onChange={(e) => handleFilterChange('level', e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="">全部</option>
                {levelTypes.map((level) => (
                  <option key={level.value} value={level.value}>
                    {level.label}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                开始时间
              </label>
              <input
                type="datetime-local"
                value={filters.startDate}
                onChange={(e) => handleFilterChange('startDate', e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                结束时间
              </label>
              <input
                type="datetime-local"
                value={filters.endDate}
                onChange={(e) => handleFilterChange('endDate', e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
          </div>

          {/* 日志列表 */}
          <div className="space-y-4">
            {auditLogsData?.data?.auditLogs && auditLogsData.data.auditLogs.length > 0 ? (
              <>
                {auditLogsData.data.auditLogs.map((log: any) => (
                  <div
                    key={log.id}
                    className="border border-gray-200 rounded-lg p-4 hover:shadow-md transition-shadow"
                  >
                    <div className="flex justify-between items-start">
                      <div className="flex-1">
                        <div className="flex items-center space-x-3 mb-2">
                          <h4 className="text-lg font-medium text-gray-900">
                            {eventTypes.find(e => e.value === log.eventType)?.label || log.eventType}
                          </h4>
                          <span className={`px-2 py-1 rounded-full text-xs font-medium ${
                            log.status === 'SUCCESS' ? 'bg-green-100 text-green-800' :
                            log.status === 'FAILURE' ? 'bg-red-100 text-red-800' :
                            log.status === 'WARNING' ? 'bg-yellow-100 text-yellow-800' :
                            'bg-orange-100 text-orange-800'
                          }`}>
                            {statusTypes.find(s => s.value === log.status)?.label}
                          </span>
                          <span className={`px-2 py-1 rounded-full text-xs font-medium ${
                            log.level === 'LOW' ? 'bg-blue-100 text-blue-800' :
                            log.level === 'MEDIUM' ? 'bg-yellow-100 text-yellow-800' :
                            log.level === 'HIGH' ? 'bg-orange-100 text-orange-800' :
                            'bg-red-100 text-red-800'
                          }`}>
                            {levelTypes.find(l => l.value === log.level)?.label}
                          </span>
                        </div>
                        
                        <div className="text-sm text-gray-600 mb-2">
                          <div className="flex items-center space-x-4">
                            <span><strong>用户:</strong> {log.username} ({log.userId})</span>
                            {log.daoId && <span><strong>DAO:</strong> {log.daoId}</span>}
                            {log.resourceType && <span><strong>资源:</strong> {log.resourceType}</span>}
                            {log.action && <span><strong>操作:</strong> {log.action}</span>}
                          </div>
                          <div className="flex items-center space-x-4 mt-1">
                            <span><strong>时间:</strong> {new Date(log.timestamp).toLocaleString()}</span>
                            {log.ipAddress && <span><strong>IP:</strong> {log.ipAddress}</span>}
                            {log.durationMs && <span><strong>耗时:</strong> {log.durationMs}ms</span>}
                          </div>
                        </div>
                        
                        {log.errorMessage && (
                          <div className="text-sm text-red-600 bg-red-50 p-2 rounded">
                            <strong>错误信息:</strong> {log.errorMessage}
                          </div>
                        )}
                        
                        {log.details && Object.keys(log.details).length > 0 && (
                          <details className="mt-2">
                            <summary className="text-sm text-gray-600 cursor-pointer">
                              查看详细信息
                            </summary>
                            <pre className="text-xs bg-gray-100 p-2 rounded mt-1 overflow-x-auto">
                              {JSON.stringify(log.details, null, 2)}
                            </pre>
                          </details>
                        )}
                      </div>
                    </div>
                  </div>
                ))}

                {/* 分页 */}
                {auditLogsData.data.pagination && (
                  <div className="flex justify-between items-center mt-6">
                    <div className="text-sm text-gray-600">
                      显示第 {(currentPage - 1) * pageSize + 1} - {Math.min(currentPage * pageSize, auditLogsData.data.pagination.total)} 条，
                      共 {auditLogsData.data.pagination.total} 条记录
                    </div>
                    <div className="flex space-x-2">
                      <button
                        onClick={() => setCurrentPage(prev => Math.max(1, prev - 1))}
                        disabled={currentPage === 1}
                        className="px-3 py-1 text-sm border border-gray-300 text-gray-700 rounded-md hover:bg-gray-50 disabled:opacity-50"
                      >
                        上一页
                      </button>
                      <span className="px-3 py-1 text-sm text-gray-700">
                        {currentPage} / {auditLogsData.data.pagination.totalPages}
                      </span>
                      <button
                        onClick={() => setCurrentPage(prev => prev + 1)}
                        disabled={currentPage >= auditLogsData.data.pagination.totalPages}
                        className="px-3 py-1 text-sm border border-gray-300 text-gray-700 rounded-md hover:bg-gray-50 disabled:opacity-50"
                      >
                        下一页
                      </button>
                    </div>
                  </div>
                )}
              </>
            ) : (
              <div className="text-center py-8 text-gray-500">
                暂无审计日志数据
              </div>
            )}
          </div>
        </div>
      )}

      {/* 安全告警 */}
      {activeTab === 'alerts' && (
        <div className="space-y-6">
          <div className="flex justify-between items-center">
            <h3 className="text-lg font-semibold text-gray-900">安全告警</h3>
          </div>

          {/* 告警列表 */}
          <div className="space-y-4">
            {auditAlertsData?.data?.alerts && auditAlertsData.data.alerts.length > 0 ? (
              auditAlertsData.data.alerts.map((alert: any) => (
                <div
                  key={alert.id}
                  className={`border rounded-lg p-4 ${
                    alert.severity === 'CRITICAL' ? 'border-red-200 bg-red-50' :
                    alert.severity === 'HIGH' ? 'border-orange-200 bg-orange-50' :
                    alert.severity === 'MEDIUM' ? 'border-yellow-200 bg-yellow-50' :
                    'border-blue-200 bg-blue-50'
                  }`}
                >
                  <div className="flex justify-between items-start">
                    <div className="flex-1">
                      <div className="flex items-center space-x-3 mb-2">
                        <h4 className="text-lg font-medium text-gray-900">
                          {alert.message}
                        </h4>
                        <span className={`px-2 py-1 rounded-full text-xs font-medium ${
                          alert.severity === 'CRITICAL' ? 'bg-red-100 text-red-800' :
                          alert.severity === 'HIGH' ? 'bg-orange-100 text-orange-800' :
                          alert.severity === 'MEDIUM' ? 'bg-yellow-100 text-yellow-800' :
                          'bg-blue-100 text-blue-800'
                        }`}>
                          {levelTypes.find(l => l.value === alert.severity)?.label}
                        </span>
                        <span className={`px-2 py-1 rounded-full text-xs font-medium ${
                          alert.isResolved ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
                        }`}>
                          {alert.isResolved ? '已解决' : '未解决'}
                        </span>
                      </div>
                      
                      <div className="text-sm text-gray-600 mb-2">
                        <div className="flex items-center space-x-4">
                          <span><strong>规则ID:</strong> {alert.ruleId}</span>
                          <span><strong>事件ID:</strong> {alert.eventId}</span>
                          <span><strong>时间:</strong> {new Date(alert.timestamp).toLocaleString()}</span>
                        </div>
                        {alert.resolvedBy && (
                          <div className="flex items-center space-x-4 mt-1">
                            <span><strong>解决者:</strong> {alert.resolvedBy}</span>
                            <span><strong>解决时间:</strong> {new Date(alert.resolvedAt).toLocaleString()}</span>
                          </div>
                        )}
                      </div>
                      
                      {alert.details && Object.keys(alert.details).length > 0 && (
                        <details className="mt-2">
                          <summary className="text-sm text-gray-600 cursor-pointer">
                            查看详细信息
                          </summary>
                          <pre className="text-xs bg-gray-100 p-2 rounded mt-1 overflow-x-auto">
                            {JSON.stringify(alert.details, null, 2)}
                          </pre>
                        </details>
                      )}
                    </div>
                    
                    {!alert.isResolved && (
                      <button
                        onClick={() => handleResolveAlert(alert.alertId)}
                        className="px-3 py-1 text-sm bg-green-600 text-white rounded-md hover:bg-green-700"
                      >
                        解决
                      </button>
                    )}
                  </div>
                </div>
              ))
            ) : (
              <div className="text-center py-8 text-gray-500">
                暂无安全告警
              </div>
            )}
          </div>
        </div>
      )}

      {/* 统计报告 */}
      {activeTab === 'stats' && (
        <div className="space-y-6">
          <h3 className="text-lg font-semibold text-gray-900">统计报告</h3>
          
          {auditStatsData?.data ? (
            <div className="space-y-6">
              {/* 概览统计 */}
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                <div className="bg-blue-50 p-4 rounded-lg">
                  <div className="text-sm text-blue-600 font-medium">总事件数</div>
                  <div className="text-2xl font-bold text-blue-900">
                    {auditStatsData.data.overview.totalEvents}
                  </div>
                </div>
                <div className="bg-green-50 p-4 rounded-lg">
                  <div className="text-sm text-green-600 font-medium">成功事件</div>
                  <div className="text-2xl font-bold text-green-900">
                    {auditStatsData.data.overview.successEvents}
                  </div>
                </div>
                <div className="bg-red-50 p-4 rounded-lg">
                  <div className="text-sm text-red-600 font-medium">失败事件</div>
                  <div className="text-2xl font-bold text-red-900">
                    {auditStatsData.data.overview.failureEvents}
                  </div>
                </div>
                <div className="bg-orange-50 p-4 rounded-lg">
                  <div className="text-sm text-orange-600 font-medium">未解决告警</div>
                  <div className="text-2xl font-bold text-orange-900">
                    {auditStatsData.data.overview.unresolvedAlerts}
                  </div>
                </div>
              </div>

              {/* 事件类型统计 */}
              <div className="bg-white border border-gray-200 rounded-lg p-4">
                <h4 className="text-md font-semibold text-gray-900 mb-4">事件类型统计</h4>
                <div className="space-y-2">
                  {auditStatsData.data.eventTypeStats.map((stat: any, index: number) => (
                    <div key={index} className="flex justify-between items-center">
                      <span className="text-sm text-gray-600">
                        {eventTypes.find(e => e.value === stat.eventType)?.label || stat.eventType}
                      </span>
                      <span className="text-sm font-medium text-gray-900">
                        {stat._count.eventType}
                      </span>
                    </div>
                  ))}
                </div>
              </div>

              {/* 级别统计 */}
              <div className="bg-white border border-gray-200 rounded-lg p-4">
                <h4 className="text-md font-semibold text-gray-900 mb-4">级别统计</h4>
                <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                  {auditStatsData.data.levelStats.map((stat: any, index: number) => (
                    <div key={index} className="text-center">
                      <div className="text-2xl font-bold text-gray-900">
                        {stat._count.level}
                      </div>
                      <div className="text-sm text-gray-600">
                        {levelTypes.find(l => l.value === stat.level)?.label || stat.level}
                      </div>
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

      {/* 审计规则 */}
      {activeTab === 'rules' && (
        <div className="space-y-6">
          <h3 className="text-lg font-semibold text-gray-900">审计规则</h3>
          
          <div className="space-y-4">
            {auditRulesData?.data && auditRulesData.data.length > 0 ? (
              auditRulesData.data.map((rule: any) => (
                <div
                  key={rule.id}
                  className="border border-gray-200 rounded-lg p-4 hover:shadow-md transition-shadow"
                >
                  <div className="flex justify-between items-start">
                    <div className="flex-1">
                      <div className="flex items-center space-x-3 mb-2">
                        <h4 className="text-lg font-medium text-gray-900">
                          {rule.name}
                        </h4>
                        <span className={`px-2 py-1 rounded-full text-xs font-medium ${
                          rule.isActive ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
                        }`}>
                          {rule.isActive ? '活跃' : '非活跃'}
                        </span>
                      </div>
                      
                      <div className="text-sm text-gray-600 mb-2">
                        <p>{rule.description}</p>
                        <div className="mt-2">
                          <div><strong>事件类型:</strong> {Array.isArray(rule.eventTypes) ? rule.eventTypes.join(', ') : rule.eventTypes}</div>
                          <div><strong>动作:</strong> {Array.isArray(rule.actions) ? rule.actions.join(', ') : rule.actions}</div>
                        </div>
                      </div>
                      
                      {rule.conditions && Object.keys(rule.conditions).length > 0 && (
                        <details className="mt-2">
                          <summary className="text-sm text-gray-600 cursor-pointer">
                            查看规则条件
                          </summary>
                          <pre className="text-xs bg-gray-100 p-2 rounded mt-1 overflow-x-auto">
                            {JSON.stringify(rule.conditions, null, 2)}
                          </pre>
                        </details>
                      )}
                    </div>
                  </div>
                </div>
              ))
            ) : (
              <div className="text-center py-8 text-gray-500">
                暂无审计规则
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
