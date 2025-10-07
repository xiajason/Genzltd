import { DAOConfigManagement } from '@/components/dao-config-management';
import { DAOSettingsManagement } from '@/components/dao-settings-management';

interface DAOConfigPageProps {
  params: {
    daoId: string;
  };
  searchParams: {
    tab?: string;
  };
}

export default function DAOConfigPage({ params, searchParams }: DAOConfigPageProps) {
  const { daoId } = params;
  const activeTab = searchParams.tab || 'config';

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* 页面标题 */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900">DAO配置管理</h1>
          <p className="mt-2 text-gray-600">
            管理DAO的基础配置、治理参数、成员设置和权限控制
          </p>
        </div>

        {/* 标签页导航 */}
        <div className="mb-8">
          <nav className="flex space-x-8" aria-label="Tabs">
            <a
              href={`/dao/config/${daoId}?tab=config`}
              className={`py-2 px-1 border-b-2 font-medium text-sm ${
                activeTab === 'config'
                  ? 'border-blue-500 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              ⚙️ 基础配置
            </a>
            <a
              href={`/dao/config/${daoId}?tab=settings`}
              className={`py-2 px-1 border-b-2 font-medium text-sm ${
                activeTab === 'settings'
                  ? 'border-blue-500 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              🔧 自定义设置
            </a>
          </nav>
        </div>

        {/* 内容区域 */}
        {activeTab === 'config' && (
          <DAOConfigManagement daoId={daoId} />
        )}

        {activeTab === 'settings' && (
          <DAOSettingsManagement daoId={daoId} />
        )}
      </div>
    </div>
  );
}
