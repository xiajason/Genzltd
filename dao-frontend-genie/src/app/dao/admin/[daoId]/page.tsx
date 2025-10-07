import { PermissionManagement } from '@/components/permission-management';
import { AuditLogViewer } from '@/components/audit-log-viewer';

interface DAOAdminPageProps {
  params: {
    daoId: string;
  };
  searchParams: {
    tab?: string;
  };
}

export default function DAOAdminPage({ params, searchParams }: DAOAdminPageProps) {
  const { daoId } = params;
  const activeTab = searchParams.tab || 'permissions';

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* 页面标题 */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900">DAO系统管理</h1>
          <p className="mt-2 text-gray-600">
            基于Zervigo和Looma CRM经验的完整系统管理平台
          </p>
        </div>

        {/* 标签页导航 */}
        <div className="mb-8">
          <nav className="flex space-x-8" aria-label="Tabs">
            <a
              href={`/dao/admin/${daoId}?tab=permissions`}
              className={`py-2 px-1 border-b-2 font-medium text-sm ${
                activeTab === 'permissions'
                  ? 'border-blue-500 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              🔐 权限管理
            </a>
            <a
              href={`/dao/admin/${daoId}?tab=audit`}
              className={`py-2 px-1 border-b-2 font-medium text-sm ${
                activeTab === 'audit'
                  ? 'border-blue-500 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              📋 审计日志
            </a>
            <a
              href={`/dao/admin/${daoId}?tab=system`}
              className={`py-2 px-1 border-b-2 font-medium text-sm ${
                activeTab === 'system'
                  ? 'border-blue-500 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              ⚙️ 系统设置
            </a>
          </nav>
        </div>

        {/* 内容区域 */}
        {activeTab === 'permissions' && (
          <PermissionManagement daoId={daoId} />
        )}

        {activeTab === 'audit' && (
          <AuditLogViewer daoId={daoId} />
        )}

        {activeTab === 'system' && (
          <div className="bg-white rounded-lg shadow-lg p-6">
            <h2 className="text-2xl font-bold text-gray-900 mb-4">系统设置</h2>
            <div className="text-center py-12 text-gray-500">
              <div className="text-6xl mb-4">⚙️</div>
              <h3 className="text-lg font-medium text-gray-900 mb-2">系统设置功能开发中</h3>
              <p className="text-gray-500">更多系统配置功能即将推出</p>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
