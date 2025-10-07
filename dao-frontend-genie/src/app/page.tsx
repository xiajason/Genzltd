"use client";

import { useState, useEffect } from "react";
import { useIntegralDAOStore } from "../stores/integral-dao-store";
import { IntegralAuth } from "../components/integral-auth";
import { DaoSelect } from "@/components/dao-select";
import { ShowDao } from "@/components/show-dao";
import { DAOManagement } from "@/components/dao-management";

export default function Home() {
  const [selectedDaoId, setSelectedDaoId] = useState<number | null>(null);
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [currentView, setCurrentView] = useState<'select' | 'dao' | 'management'>('select');
  
  const { currentUser, getCurrentUser, loading } = useIntegralDAOStore();

  useEffect(() => {
    // 检查用户是否已登录
    const checkAuth = async () => {
      const token = localStorage.getItem('auth_token');
      if (token) {
        await getCurrentUser();
        if (currentUser) {
          setIsAuthenticated(true);
        }
      }
    };
    
    checkAuth();
  }, [currentUser, getCurrentUser]);

  // 认证成功回调
  const handleAuthSuccess = () => {
    setIsAuthenticated(true);
  };

  // 如果未认证，显示登录界面
  if (!isAuthenticated) {
    return <IntegralAuth onSuccess={handleAuthSuccess} />;
  }

  // 如果已认证，显示主界面
  return (
    <div className="min-h-screen bg-gray-50">
      {/* 导航栏 */}
      <nav className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-16">
            <div className="flex items-center">
              <h1 className="text-xl font-semibold text-gray-900">
                积分制DAO治理系统
              </h1>
            </div>
            <div className="flex items-center space-x-4">
              <button
                onClick={() => setCurrentView('management')}
                className={`px-4 py-2 rounded-md text-sm font-medium ${
                  currentView === 'management'
                    ? 'bg-[#5B51F6] text-white'
                    : 'text-gray-700 hover:text-[#5B51F6]'
                }`}
              >
                DAO管理
              </button>
              <button
                onClick={() => setCurrentView('select')}
                className={`px-4 py-2 rounded-md text-sm font-medium ${
                  currentView === 'select'
                    ? 'bg-[#5B51F6] text-white'
                    : 'text-gray-700 hover:text-[#5B51F6]'
                }`}
              >
                选择DAO
              </button>
              <div className="text-sm text-gray-500">
                欢迎，{currentUser?.username || '用户'}
              </div>
            </div>
          </div>
        </div>
      </nav>

      {/* 主内容区域 */}
      <main>
        {currentView === 'management' && <DAOManagement />}
        {currentView === 'select' && (
          selectedDaoId === null ? (
            <DaoSelect onSelect={setSelectedDaoId} />
          ) : (
            <ShowDao daoId={selectedDaoId} />
          )
        )}
        {currentView === 'dao' && selectedDaoId && <ShowDao daoId={selectedDaoId} />}
      </main>
    </div>
  );
}
