'use client';

import React, { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { api } from '@/trpc/react';
import { toast } from 'react-hot-toast';

// 表单验证schema
const daoSettingsSchema = z.object({
  daoId: z.string().min(1, 'DAO ID不能为空'),
  settingKey: z.string().min(1, '设置键不能为空'),
  settingValue: z.string().min(1, '设置值不能为空'),
  settingType: z.enum(['STRING', 'NUMBER', 'BOOLEAN', 'JSON', 'ARRAY']).default('STRING'),
  description: z.string().optional(),
  isPublic: z.boolean().default(false),
});

type DAOSettingsData = z.infer<typeof daoSettingsSchema>;

interface DAOSettingsManagementProps {
  daoId: string;
}

export function DAOSettingsManagement({ daoId }: DAOSettingsManagementProps) {
  const [isCreating, setIsCreating] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);

  // 获取DAO设置列表
  const { data: settingsData, refetch } = api.daoConfig.getSettings.useQuery(
    { daoId },
    { enabled: !!daoId }
  );

  // 创建设置
  const createSettingMutation = api.daoConfig.createSetting.useMutation({
    onSuccess: () => {
      toast.success('DAO设置创建成功');
      refetch();
      setIsCreating(false);
      reset();
    },
    onError: (error) => {
      toast.error(`创建设置失败: ${error.message}`);
    },
  });

  // 更新设置
  const updateSettingMutation = api.daoConfig.updateSetting.useMutation({
    onSuccess: () => {
      toast.success('DAO设置更新成功');
      refetch();
      setEditingId(null);
      reset();
    },
    onError: (error) => {
      toast.error(`更新设置失败: ${error.message}`);
    },
  });

  // 删除设置
  const deleteSettingMutation = api.daoConfig.deleteSetting.useMutation({
    onSuccess: () => {
      toast.success('DAO设置删除成功');
      refetch();
    },
    onError: (error) => {
      toast.error(`删除设置失败: ${error.message}`);
    },
  });

  const {
    register,
    handleSubmit,
    formState: { errors },
    reset,
    setValue,
    watch,
  } = useForm<DAOSettingsData>({
    resolver: zodResolver(daoSettingsSchema),
    defaultValues: {
      daoId,
      settingType: 'STRING',
      isPublic: false,
    },
  });

  const settingType = watch('settingType');

  const onSubmit = (data: DAOSettingsData) => {
    if (editingId) {
      updateSettingMutation.mutate({ ...data, id: editingId });
    } else {
      createSettingMutation.mutate(data);
    }
  };

  const handleCancel = () => {
    setIsCreating(false);
    setEditingId(null);
    reset();
  };

  const handleEdit = (setting: any) => {
    setEditingId(setting.id.toString());
    setValue('settingKey', setting.settingKey);
    setValue('settingValue', setting.settingValue);
    setValue('settingType', setting.settingType);
    setValue('description', setting.description || '');
    setValue('isPublic', setting.isPublic);
  };

  const handleDelete = (settingId: string) => {
    if (confirm('确定要删除这个设置吗？')) {
      deleteSettingMutation.mutate({ id: settingId });
    }
  };

  const renderSettingValue = (setting: any) => {
    try {
      switch (setting.settingType) {
        case 'JSON':
          return <pre className="text-sm bg-gray-100 p-2 rounded">{JSON.stringify(JSON.parse(setting.settingValue), null, 2)}</pre>;
        case 'BOOLEAN':
          return <span className={`px-2 py-1 rounded text-sm ${setting.settingValue === 'true' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'}`}>
            {setting.settingValue === 'true' ? '是' : '否'}
          </span>;
        case 'NUMBER':
          return <span className="font-mono">{setting.settingValue}</span>;
        case 'ARRAY':
          return <span className="text-sm">{setting.settingValue}</span>;
        default:
          return <span>{setting.settingValue}</span>;
      }
    } catch (error) {
      return <span className="text-red-500">格式错误</span>;
    }
  };

  const getSettingTypeLabel = (type: string) => {
    const labels = {
      STRING: '字符串',
      NUMBER: '数字',
      BOOLEAN: '布尔值',
      JSON: 'JSON对象',
      ARRAY: '数组',
    };
    return labels[type as keyof typeof labels] || type;
  };

  return (
    <div className="max-w-4xl mx-auto p-6 bg-white rounded-lg shadow-lg">
      <div className="mb-6">
        <div className="flex justify-between items-center">
          <div>
            <h2 className="text-2xl font-bold text-gray-900 mb-2">DAO设置管理</h2>
            <p className="text-gray-600">管理DAO的自定义设置项</p>
          </div>
          <button
            onClick={() => setIsCreating(true)}
            className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            添加设置
          </button>
        </div>
      </div>

      {/* 创建/编辑表单 */}
      {(isCreating || editingId) && (
        <div className="mb-6 p-4 bg-gray-50 rounded-lg">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">
            {editingId ? '编辑设置' : '创建新设置'}
          </h3>
          
          <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  设置键 *
                </label>
                <input
                  {...register('settingKey')}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="例如: max_proposal_amount"
                />
                {errors.settingKey && (
                  <p className="text-red-500 text-sm mt-1">{errors.settingKey.message}</p>
                )}
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  设置类型
                </label>
                <select
                  {...register('settingType')}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  <option value="STRING">字符串</option>
                  <option value="NUMBER">数字</option>
                  <option value="BOOLEAN">布尔值</option>
                  <option value="JSON">JSON对象</option>
                  <option value="ARRAY">数组</option>
                </select>
              </div>

              <div className="md:col-span-2">
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  设置值 *
                </label>
                {settingType === 'BOOLEAN' ? (
                  <select
                    {...register('settingValue')}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="true">是</option>
                    <option value="false">否</option>
                  </select>
                ) : settingType === 'JSON' ? (
                  <textarea
                    {...register('settingValue')}
                    rows={4}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 font-mono text-sm"
                    placeholder='{"key": "value"}'
                  />
                ) : (
                  <input
                    {...register('settingValue')}
                    type={settingType === 'NUMBER' ? 'number' : 'text'}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    placeholder={settingType === 'NUMBER' ? '123' : '输入设置值'}
                  />
                )}
                {errors.settingValue && (
                  <p className="text-red-500 text-sm mt-1">{errors.settingValue.message}</p>
                )}
              </div>

              <div className="md:col-span-2">
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  描述
                </label>
                <textarea
                  {...register('description')}
                  rows={2}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="描述这个设置的用途"
                />
              </div>

              <div className="flex items-center">
                <input
                  type="checkbox"
                  {...register('isPublic')}
                  className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                />
                <label className="ml-2 text-sm text-gray-700">
                  公开设置
                </label>
              </div>
            </div>

            <div className="flex justify-end space-x-3">
              <button
                type="button"
                onClick={handleCancel}
                className="px-4 py-2 border border-gray-300 text-gray-700 rounded-md hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                取消
              </button>
              <button
                type="submit"
                disabled={createSettingMutation.isLoading || updateSettingMutation.isLoading}
                className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:opacity-50"
              >
                {editingId ? '更新设置' : '创建设置'}
              </button>
            </div>
          </form>
        </div>
      )}

      {/* 设置列表 */}
      <div className="space-y-4">
        {settingsData?.data && settingsData.data.length > 0 ? (
          settingsData.data.map((setting) => (
            <div
              key={setting.id.toString()}
              className="border border-gray-200 rounded-lg p-4 hover:shadow-md transition-shadow"
            >
              <div className="flex justify-between items-start">
                <div className="flex-1">
                  <div className="flex items-center space-x-3 mb-2">
                    <h4 className="text-lg font-medium text-gray-900">
                      {setting.settingKey}
                    </h4>
                    <span className={`px-2 py-1 rounded-full text-xs font-medium ${
                      setting.isPublic 
                        ? 'bg-green-100 text-green-800' 
                        : 'bg-gray-100 text-gray-800'
                    }`}>
                      {setting.isPublic ? '公开' : '私有'}
                    </span>
                    <span className="px-2 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                      {getSettingTypeLabel(setting.settingType)}
                    </span>
                  </div>
                  
                  <div className="mb-2">
                    {renderSettingValue(setting)}
                  </div>
                  
                  {setting.description && (
                    <p className="text-sm text-gray-600 mb-2">
                      {setting.description}
                    </p>
                  )}
                  
                  <div className="text-xs text-gray-500">
                    创建于: {new Date(setting.createdAt).toLocaleString()}
                    {setting.updatedAt !== setting.createdAt && (
                      <span> | 更新于: {new Date(setting.updatedAt).toLocaleString()}</span>
                    )}
                  </div>
                </div>
                
                <div className="flex space-x-2 ml-4">
                  <button
                    onClick={() => handleEdit(setting)}
                    className="px-3 py-1 text-sm text-blue-600 hover:text-blue-800 hover:bg-blue-50 rounded"
                  >
                    编辑
                  </button>
                  <button
                    onClick={() => handleDelete(setting.id.toString())}
                    className="px-3 py-1 text-sm text-red-600 hover:text-red-800 hover:bg-red-50 rounded"
                  >
                    删除
                  </button>
                </div>
              </div>
            </div>
          ))
        ) : (
          <div className="text-center py-12">
            <div className="text-gray-400 text-6xl mb-4">⚙️</div>
            <h3 className="text-lg font-medium text-gray-900 mb-2">暂无自定义设置</h3>
            <p className="text-gray-500 mb-4">点击"添加设置"按钮创建第一个自定义设置</p>
          </div>
        )}
      </div>
    </div>
  );
}
