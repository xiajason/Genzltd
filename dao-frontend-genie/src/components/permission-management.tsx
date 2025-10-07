'use client';

import React, { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { api } from '@/trpc/react';
import { toast } from 'react-hot-toast';

// 表单验证schema
const createPermissionSchema = z.object({
  permissionKey: z.string().min(1, '权限标识不能为空'),
  name: z.string().min(1, '权限名称不能为空'),
  description: z.string().optional(),
  resourceType: z.enum(['USER', 'PROPOSAL', 'VOTE', 'MEMBER', 'CONFIG', 'TREASURY', 'ANALYTICS', 'SYSTEM']),
  action: z.enum(['CREATE', 'READ', 'UPDATE', 'DELETE', 'LIST', 'EXPORT', 'IMPORT', 'EXECUTE', 'MANAGE']),
  scope: z.enum(['OWN', 'ORGANIZATION', 'TENANT', 'GLOBAL']).default('OWN'),
});

const createRoleSchema = z.object({
  roleKey: z.string().min(1, '角色标识不能为空'),
  name: z.string().min(1, '角色名称不能为空'),
  description: z.string().optional(),
  level: z.number().min(1).max(6).default(1),
  inheritsFrom: z.string().optional(),
});

const assignRoleSchema = z.object({
  userId: z.string().min(1, '用户ID不能为空'),
  roleId: z.string().min(1, '角色ID不能为空'),
  daoId: z.string().min(1, 'DAO ID不能为空'),
  expiresAt: z.date().optional(),
});

type CreatePermissionData = z.infer<typeof createPermissionSchema>;
type CreateRoleData = z.infer<typeof createRoleSchema>;
type AssignRoleData = z.infer<typeof assignRoleSchema>;

interface PermissionManagementProps {
  daoId: string;
}

export function PermissionManagement({ daoId }: PermissionManagementProps) {
  const [activeTab, setActiveTab] = useState<'permissions' | 'roles' | 'assignments' | 'check'>('permissions');
  const [isCreatingPermission, setIsCreatingPermission] = useState(false);
  const [isCreatingRole, setIsCreatingRole] = useState(false);
  const [isAssigningRole, setIsAssigningRole] = useState(false);

  // 获取权限列表
  const { data: permissionsData, refetch: refetchPermissions } = api.permission.getPermissions.useQuery();

  // 获取角色列表
  const { data: rolesData, refetch: refetchRoles } = api.permission.getRoles.useQuery();

  // 获取默认权限列表
  const { data: defaultPermissionsData } = api.permission.getDefaultPermissions.useQuery();

  // 获取默认角色列表
  const { data: defaultRolesData } = api.permission.getDefaultRoles.useQuery();

  // 获取用户角色
  const { data: userRolesData, refetch: refetchUserRoles } = api.permission.getUserRoles.useQuery({
    userId: '', // 这里应该从用户上下文获取
    daoId,
  });

  // 创建权限
  const createPermissionMutation = api.permission.createPermission.useMutation({
    onSuccess: () => {
      toast.success('权限创建成功');
      refetchPermissions();
      setIsCreatingPermission(false);
      resetPermissionForm();
    },
    onError: (error) => {
      toast.error(`创建失败: ${error.message}`);
    },
  });

  // 创建角色
  const createRoleMutation = api.permission.createRole.useMutation({
    onSuccess: () => {
      toast.success('角色创建成功');
      refetchRoles();
      setIsCreatingRole(false);
      resetRoleForm();
    },
    onError: (error) => {
      toast.error(`创建失败: ${error.message}`);
    },
  });

  // 分配角色
  const assignRoleMutation = api.permission.assignRoleToUser.useMutation({
    onSuccess: () => {
      toast.success('角色分配成功');
      refetchUserRoles();
      setIsAssigningRole(false);
      resetAssignRoleForm();
    },
    onError: (error) => {
      toast.error(`分配失败: ${error.message}`);
    },
  });

  // 权限表单
  const {
    register: registerPermission,
    handleSubmit: handleSubmitPermission,
    formState: { errors: errorsPermission },
    reset: resetPermissionForm,
  } = useForm<CreatePermissionData>({
    resolver: zodResolver(createPermissionSchema),
    defaultValues: {
      scope: 'OWN',
    },
  });

  // 角色表单
  const {
    register: registerRole,
    handleSubmit: handleSubmitRole,
    formState: { errors: errorsRole },
    reset: resetRoleForm,
  } = useForm<CreateRoleData>({
    resolver: zodResolver(createRoleSchema),
    defaultValues: {
      level: 1,
    },
  });

  // 分配角色表单
  const {
    register: registerAssignRole,
    handleSubmit: handleSubmitAssignRole,
    formState: { errors: errorsAssignRole },
    reset: resetAssignRoleForm,
  } = useForm<AssignRoleData>({
    resolver: zodResolver(assignRoleSchema),
    defaultValues: {
      daoId,
    },
  });

  const onSubmitPermission = (data: CreatePermissionData) => {
    createPermissionMutation.mutate(data);
  };

  const onSubmitRole = (data: CreateRoleData) => {
    createRoleMutation.mutate(data);
  };

  const onSubmitAssignRole = (data: AssignRoleData) => {
    assignRoleMutation.mutate(data);
  };

  const tabs = [
    { id: 'permissions', label: '权限管理', icon: '🔐' },
    { id: 'roles', label: '角色管理', icon: '👥' },
    { id: 'assignments', label: '角色分配', icon: '⚡' },
    { id: 'check', label: '权限检查', icon: '🔍' },
  ] as const;

  const resourceTypes = [
    { value: 'USER', label: '用户' },
    { value: 'PROPOSAL', label: '提案' },
    { value: 'VOTE', label: '投票' },
    { value: 'MEMBER', label: '成员' },
    { value: 'CONFIG', label: '配置' },
    { value: 'TREASURY', label: '国库' },
    { value: 'ANALYTICS', label: '分析' },
    { value: 'SYSTEM', label: '系统' },
  ];

  const actions = [
    { value: 'CREATE', label: '创建' },
    { value: 'READ', label: '读取' },
    { value: 'UPDATE', label: '更新' },
    { value: 'DELETE', label: '删除' },
    { value: 'LIST', label: '列表' },
    { value: 'EXPORT', label: '导出' },
    { value: 'IMPORT', label: '导入' },
    { value: 'EXECUTE', label: '执行' },
    { value: 'MANAGE', label: '管理' },
  ];

  const scopes = [
    { value: 'OWN', label: '自己的资源' },
    { value: 'ORGANIZATION', label: '组织内资源' },
    { value: 'TENANT', label: '租户内资源' },
    { value: 'GLOBAL', label: '全局资源' },
  ];

  return (
    <div className="max-w-7xl mx-auto p-6 bg-white rounded-lg shadow-lg">
      <div className="mb-6">
        <h2 className="text-2xl font-bold text-gray-900 mb-2">权限管理系统</h2>
        <p className="text-gray-600">基于Zervigo经验的细粒度权限控制和角色管理</p>
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

      {/* 权限管理 */}
      {activeTab === 'permissions' && (
        <div className="space-y-6">
          <div className="flex justify-between items-center">
            <h3 className="text-lg font-semibold text-gray-900">权限管理</h3>
            <button
              onClick={() => setIsCreatingPermission(true)}
              className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
            >
              创建权限
            </button>
          </div>

          {/* 创建权限表单 */}
          {isCreatingPermission && (
            <div className="p-4 bg-gray-50 rounded-lg">
              <h4 className="text-md font-semibold text-gray-900 mb-4">创建新权限</h4>
              <form onSubmit={handleSubmitPermission(onSubmitPermission)} className="space-y-4">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      权限标识 *
                    </label>
                    <input
                      {...registerPermission('permissionKey')}
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder="例如: user:read"
                    />
                    {errorsPermission.permissionKey && (
                      <p className="text-red-500 text-sm mt-1">{errorsPermission.permissionKey.message}</p>
                    )}
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      权限名称 *
                    </label>
                    <input
                      {...registerPermission('name')}
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder="例如: 查看用户"
                    />
                    {errorsPermission.name && (
                      <p className="text-red-500 text-sm mt-1">{errorsPermission.name.message}</p>
                    )}
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      资源类型 *
                    </label>
                    <select
                      {...registerPermission('resourceType')}
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    >
                      {resourceTypes.map((type) => (
                        <option key={type.value} value={type.value}>
                          {type.label}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      操作类型 *
                    </label>
                    <select
                      {...registerPermission('action')}
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    >
                      {actions.map((action) => (
                        <option key={action.value} value={action.value}>
                          {action.label}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      权限范围
                    </label>
                    <select
                      {...registerPermission('scope')}
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    >
                      {scopes.map((scope) => (
                        <option key={scope.value} value={scope.value}>
                          {scope.label}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div className="md:col-span-2">
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      权限描述
                    </label>
                    <textarea
                      {...registerPermission('description')}
                      rows={3}
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder="描述这个权限的用途"
                    />
                  </div>
                </div>

                <div className="flex justify-end space-x-3">
                  <button
                    type="button"
                    onClick={() => {
                      setIsCreatingPermission(false);
                      resetPermissionForm();
                    }}
                    className="px-4 py-2 border border-gray-300 text-gray-700 rounded-md hover:bg-gray-50"
                  >
                    取消
                  </button>
                  <button
                    type="submit"
                    disabled={createPermissionMutation.isLoading}
                    className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50"
                  >
                    创建权限
                  </button>
                </div>
              </form>
            </div>
          )}

          {/* 权限列表 */}
          <div className="space-y-4">
            <h4 className="text-md font-semibold text-gray-900">权限列表</h4>
            {permissionsData?.data && permissionsData.data.length > 0 ? (
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                {permissionsData.data.map((permission: any) => (
                  <div
                    key={permission.id}
                    className="border border-gray-200 rounded-lg p-4 hover:shadow-md transition-shadow"
                  >
                    <div className="flex justify-between items-start mb-2">
                      <h5 className="text-lg font-medium text-gray-900">
                        {permission.name}
                      </h5>
                      <span className={`px-2 py-1 rounded-full text-xs font-medium ${
                        permission.scope === 'GLOBAL' ? 'bg-red-100 text-red-800' :
                        permission.scope === 'ORGANIZATION' ? 'bg-yellow-100 text-yellow-800' :
                        permission.scope === 'TENANT' ? 'bg-blue-100 text-blue-800' :
                        'bg-green-100 text-green-800'
                      }`}>
                        {scopes.find(s => s.value === permission.scope)?.label}
                      </span>
                    </div>
                    
                    <div className="text-sm text-gray-600 mb-2">
                      <div className="flex items-center space-x-2">
                        <span className="font-medium">标识:</span>
                        <span className="font-mono bg-gray-100 px-2 py-1 rounded text-xs">
                          {permission.permissionKey}
                        </span>
                      </div>
                      <div className="flex items-center space-x-2 mt-1">
                        <span className="font-medium">资源:</span>
                        <span>{resourceTypes.find(r => r.value === permission.resourceType)?.label}</span>
                      </div>
                      <div className="flex items-center space-x-2 mt-1">
                        <span className="font-medium">操作:</span>
                        <span>{actions.find(a => a.value === permission.action)?.label}</span>
                      </div>
                    </div>
                    
                    {permission.description && (
                      <p className="text-sm text-gray-500">{permission.description}</p>
                    )}
                  </div>
                ))}
              </div>
            ) : (
              <div className="text-center py-8 text-gray-500">
                暂无权限数据
              </div>
            )}
          </div>

          {/* 默认权限模板 */}
          {defaultPermissionsData?.data && (
            <div className="mt-6">
              <h4 className="text-md font-semibold text-gray-900 mb-4">默认权限模板</h4>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {defaultPermissionsData.data.map((permission: any, index: number) => (
                  <div
                    key={index}
                    className="border border-gray-200 rounded-lg p-3 bg-gray-50"
                  >
                    <div className="flex justify-between items-start">
                      <div>
                        <h6 className="font-medium text-gray-900">{permission.name}</h6>
                        <p className="text-sm text-gray-600 font-mono">{permission.permissionKey}</p>
                      </div>
                      <button
                        onClick={() => {
                          createPermissionMutation.mutate(permission);
                        }}
                        className="px-3 py-1 text-sm bg-blue-600 text-white rounded hover:bg-blue-700"
                      >
                        添加
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      )}

      {/* 角色管理 */}
      {activeTab === 'roles' && (
        <div className="space-y-6">
          <div className="flex justify-between items-center">
            <h3 className="text-lg font-semibold text-gray-900">角色管理</h3>
            <button
              onClick={() => setIsCreatingRole(true)}
              className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
            >
              创建角色
            </button>
          </div>

          {/* 创建角色表单 */}
          {isCreatingRole && (
            <div className="p-4 bg-gray-50 rounded-lg">
              <h4 className="text-md font-semibold text-gray-900 mb-4">创建新角色</h4>
              <form onSubmit={handleSubmitRole(onSubmitRole)} className="space-y-4">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      角色标识 *
                    </label>
                    <input
                      {...registerRole('roleKey')}
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder="例如: moderator"
                    />
                    {errorsRole.roleKey && (
                      <p className="text-red-500 text-sm mt-1">{errorsRole.roleKey.message}</p>
                    )}
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      角色名称 *
                    </label>
                    <input
                      {...registerRole('name')}
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder="例如: 版主"
                    />
                    {errorsRole.name && (
                      <p className="text-red-500 text-sm mt-1">{errorsRole.name.message}</p>
                    )}
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      角色级别
                    </label>
                    <select
                      {...registerRole('level', { valueAsNumber: true })}
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    >
                      <option value={1}>1 - 访客</option>
                      <option value={2}>2 - 普通用户</option>
                      <option value={3}>3 - VIP用户</option>
                      <option value={4}>4 - 版主</option>
                      <option value={5}>5 - 管理员</option>
                      <option value={6}>6 - 超级管理员</option>
                    </select>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      继承角色
                    </label>
                    <input
                      {...registerRole('inheritsFrom')}
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder="可选，继承其他角色的权限"
                    />
                  </div>

                  <div className="md:col-span-2">
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      角色描述
                    </label>
                    <textarea
                      {...registerRole('description')}
                      rows={3}
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder="描述这个角色的职责和权限"
                    />
                  </div>
                </div>

                <div className="flex justify-end space-x-3">
                  <button
                    type="button"
                    onClick={() => {
                      setIsCreatingRole(false);
                      resetRoleForm();
                    }}
                    className="px-4 py-2 border border-gray-300 text-gray-700 rounded-md hover:bg-gray-50"
                  >
                    取消
                  </button>
                  <button
                    type="submit"
                    disabled={createRoleMutation.isLoading}
                    className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50"
                  >
                    创建角色
                  </button>
                </div>
              </form>
            </div>
          )}

          {/* 角色列表 */}
          <div className="space-y-4">
            <h4 className="text-md font-semibold text-gray-900">角色列表</h4>
            {rolesData?.data && rolesData.data.length > 0 ? (
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                {rolesData.data.map((role: any) => (
                  <div
                    key={role.id}
                    className="border border-gray-200 rounded-lg p-4 hover:shadow-md transition-shadow"
                  >
                    <div className="flex justify-between items-start mb-2">
                      <h5 className="text-lg font-medium text-gray-900">
                        {role.name}
                      </h5>
                      <span className={`px-2 py-1 rounded-full text-xs font-medium ${
                        role.level >= 5 ? 'bg-red-100 text-red-800' :
                        role.level >= 4 ? 'bg-orange-100 text-orange-800' :
                        role.level >= 3 ? 'bg-yellow-100 text-yellow-800' :
                        role.level >= 2 ? 'bg-blue-100 text-blue-800' :
                        'bg-gray-100 text-gray-800'
                      }`}>
                        级别 {role.level}
                      </span>
                    </div>
                    
                    <div className="text-sm text-gray-600 mb-2">
                      <div className="flex items-center space-x-2">
                        <span className="font-medium">标识:</span>
                        <span className="font-mono bg-gray-100 px-2 py-1 rounded text-xs">
                          {role.roleKey}
                        </span>
                      </div>
                      {role.inheritsFrom && (
                        <div className="flex items-center space-x-2 mt-1">
                          <span className="font-medium">继承:</span>
                          <span>{role.inheritsFrom}</span>
                        </div>
                      )}
                      <div className="flex items-center space-x-2 mt-1">
                        <span className="font-medium">权限数:</span>
                        <span>{role.rolePermissions?.length || 0}</span>
                      </div>
                    </div>
                    
                    {role.description && (
                      <p className="text-sm text-gray-500">{role.description}</p>
                    )}
                  </div>
                ))}
              </div>
            ) : (
              <div className="text-center py-8 text-gray-500">
                暂无角色数据
              </div>
            )}
          </div>

          {/* 默认角色模板 */}
          {defaultRolesData?.data && (
            <div className="mt-6">
              <h4 className="text-md font-semibold text-gray-900 mb-4">默认角色模板</h4>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {defaultRolesData.data.map((role: any, index: number) => (
                  <div
                    key={index}
                    className="border border-gray-200 rounded-lg p-3 bg-gray-50"
                  >
                    <div className="flex justify-between items-start">
                      <div>
                        <h6 className="font-medium text-gray-900">{role.name}</h6>
                        <p className="text-sm text-gray-600 font-mono">{role.roleKey}</p>
                        <p className="text-sm text-gray-500">级别 {role.level}</p>
                      </div>
                      <button
                        onClick={() => {
                          createRoleMutation.mutate(role);
                        }}
                        className="px-3 py-1 text-sm bg-blue-600 text-white rounded hover:bg-blue-700"
                      >
                        添加
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      )}

      {/* 角色分配 */}
      {activeTab === 'assignments' && (
        <div className="space-y-6">
          <div className="flex justify-between items-center">
            <h3 className="text-lg font-semibold text-gray-900">角色分配</h3>
            <button
              onClick={() => setIsAssigningRole(true)}
              className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
            >
              分配角色
            </button>
          </div>

          {/* 分配角色表单 */}
          {isAssigningRole && (
            <div className="p-4 bg-gray-50 rounded-lg">
              <h4 className="text-md font-semibold text-gray-900 mb-4">分配角色给用户</h4>
              <form onSubmit={handleSubmitAssignRole(onSubmitAssignRole)} className="space-y-4">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      用户ID *
                    </label>
                    <input
                      {...registerAssignRole('userId')}
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder="输入用户ID"
                    />
                    {errorsAssignRole.userId && (
                      <p className="text-red-500 text-sm mt-1">{errorsAssignRole.userId.message}</p>
                    )}
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      角色 *
                    </label>
                    <select
                      {...registerAssignRole('roleId')}
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    >
                      <option value="">选择角色</option>
                      {rolesData?.data?.map((role: any) => (
                        <option key={role.id} value={role.id}>
                          {role.name} (级别 {role.level})
                        </option>
                      ))}
                    </select>
                    {errorsAssignRole.roleId && (
                      <p className="text-red-500 text-sm mt-1">{errorsAssignRole.roleId.message}</p>
                    )}
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      过期时间
                    </label>
                    <input
                      {...registerAssignRole('expiresAt', { valueAsDate: true })}
                      type="datetime-local"
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                  </div>
                </div>

                <div className="flex justify-end space-x-3">
                  <button
                    type="button"
                    onClick={() => {
                      setIsAssigningRole(false);
                      resetAssignRoleForm();
                    }}
                    className="px-4 py-2 border border-gray-300 text-gray-700 rounded-md hover:bg-gray-50"
                  >
                    取消
                  </button>
                  <button
                    type="submit"
                    disabled={assignRoleMutation.isLoading}
                    className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50"
                  >
                    分配角色
                  </button>
                </div>
              </form>
            </div>
          )}

          {/* 用户角色列表 */}
          <div className="space-y-4">
            <h4 className="text-md font-semibold text-gray-900">用户角色分配</h4>
            {userRolesData?.data && userRolesData.data.length > 0 ? (
              <div className="space-y-4">
                {userRolesData.data.map((userRole: any) => (
                  <div
                    key={userRole.id}
                    className="border border-gray-200 rounded-lg p-4"
                  >
                    <div className="flex justify-between items-start">
                      <div>
                        <h5 className="text-lg font-medium text-gray-900">
                          {userRole.userId}
                        </h5>
                        <div className="text-sm text-gray-600 mt-1">
                          <div>角色: {userRole.role.name} (级别 {userRole.role.level})</div>
                          <div>分配者: {userRole.assignedBy}</div>
                          <div>分配时间: {new Date(userRole.assignedAt).toLocaleString()}</div>
                          {userRole.expiresAt && (
                            <div>过期时间: {new Date(userRole.expiresAt).toLocaleString()}</div>
                          )}
                        </div>
                      </div>
                      <span className={`px-2 py-1 rounded-full text-xs font-medium ${
                        userRole.isActive ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
                      }`}>
                        {userRole.isActive ? '活跃' : '已失效'}
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <div className="text-center py-8 text-gray-500">
                暂无角色分配数据
              </div>
            )}
          </div>
        </div>
      )}

      {/* 权限检查 */}
      {activeTab === 'check' && (
        <div className="space-y-6">
          <h3 className="text-lg font-semibold text-gray-900">权限检查</h3>
          <div className="text-center py-8 text-gray-500">
            权限检查功能开发中...
          </div>
        </div>
      )}
    </div>
  );
}
