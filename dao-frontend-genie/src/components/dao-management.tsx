"use client";
import { useState } from "react";
import { CreateDAOUI } from "./create-dao-ui";
import { IntegralMemberList } from "./integral-member-list";
import { api } from "@/trpc/react";

interface DAO {
  id: string;
  name: string;
  description: string;
  creatorId: string;
  createdAt: string;
  memberCount: number;
  proposalCount: number;
}

export function DAOManagement() {
  const [showCreateDAO, setShowCreateDAO] = useState(false);
  const [selectedDAO, setSelectedDAO] = useState<string | null>(null);
  const [showMemberList, setShowMemberList] = useState(false);

  // 获取真实的DAO数据
  const { data: membersData, isLoading: membersLoading } = api.dao.getMembers.useQuery({
    page: 1,
    limit: 100, // 获取所有成员
  });
  const { data: proposalsData, isLoading: proposalsLoading } = api.dao.getProposals.useQuery({
    page: 1,
    limit: 100, // 获取所有提案
  });

  // 计算真实统计数据
  const totalMembers = membersData?.data?.length || 0;
  const totalProposals = proposalsData?.data?.length || 0;
  const totalDAOs = 1; // 当前只有一个DAO系统

  // 模拟DAO数据（暂时保留，因为数据库中没有DAO表）
  const mockDAOs: DAO[] = [
    {
      id: "dao_001",
      name: "积分制DAO治理系统",
      description: "基于积分制的去中心化治理平台",
      creatorId: "admin",
      createdAt: new Date().toISOString().split('T')[0],
      memberCount: totalMembers,
      proposalCount: totalProposals,
    },
  ];

  const handleCreateDAOSuccess = (daoData: any) => {
    setShowCreateDAO(false);
    // 这里可以刷新DAO列表
    console.log("DAO创建成功！", daoData);
  };

  const handleSelectDAO = (daoId: string) => {
    setSelectedDAO(daoId);
    // 这里可以导航到具体的DAO页面
  };

  if (showCreateDAO) {
    return (
      <div className="max-w-2xl mx-auto p-6">
        <CreateDAOUI 
          onCreateDAOSuccess={handleCreateDAOSuccess}
          onCancel={() => setShowCreateDAO(false)}
        />
      </div>
    );
  }

  if (showMemberList) {
    return (
      <div className="p-6 bg-gray-50 min-h-screen">
        <div className="max-w-7xl mx-auto">
          <div className="mb-6">
            <button
              onClick={() => setShowMemberList(false)}
              className="flex items-center text-gray-600 hover:text-gray-900 mb-4"
            >
              <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
              </svg>
              返回DAO管理
            </button>
            <h1 className="text-3xl font-bold text-gray-900">DAO成员列表</h1>
            <p className="mt-2 text-gray-600">查看所有DAO成员的详细信息</p>
          </div>
          
          {membersLoading ? (
            <div className="text-center py-8">
              <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600 mx-auto"></div>
              <p className="mt-4 text-gray-600">加载成员信息中...</p>
            </div>
          ) : membersData?.data ? (
            <IntegralMemberList members={membersData.data} />
          ) : (
            <div className="text-center py-8">
              <p className="text-gray-500">暂无成员数据</p>
            </div>
          )}
        </div>
      </div>
    );
  }

  return (
    <div className="p-6 bg-gray-50 min-h-screen">
      <div className="max-w-7xl mx-auto">
        {/* 页面头部 */}
        <div className="mb-8">
          <div className="flex justify-between items-center">
            <div>
              <h1 className="text-3xl font-bold text-gray-900">
                DAO 管理
              </h1>
              <p className="mt-2 text-gray-600">
                管理和参与去中心化自治组织
              </p>
            </div>
            <button
              onClick={() => setShowCreateDAO(true)}
              className="rounded-lg bg-[#5B51F6] px-6 py-2 text-white hover:bg-[#4A41E0] focus:outline-none focus:ring-2 focus:ring-[#5B51F6] focus:ring-offset-2"
            >
              创建新DAO
            </button>
          </div>
        </div>

        {/* DAO统计 */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
          <div className="bg-white overflow-hidden shadow rounded-lg">
            <div className="p-5">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <svg className="h-6 w-6 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
                  </svg>
                </div>
                <div className="ml-5 w-0 flex-1">
                  <dl>
                    <dt className="text-sm font-medium text-gray-500 truncate">总DAO数</dt>
                    <dd className="text-lg font-medium text-gray-900">{totalDAOs}</dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>

          <div 
            className="bg-white overflow-hidden shadow rounded-lg cursor-pointer hover:shadow-md transition-shadow"
            onClick={() => setShowMemberList(true)}
          >
            <div className="p-5">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <svg className="h-6 w-6 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z" />
                  </svg>
                </div>
                <div className="ml-5 w-0 flex-1">
                  <dl>
                    <dt className="text-sm font-medium text-gray-500 truncate">总成员数</dt>
                    <dd className="text-lg font-medium text-gray-900">
                      {membersLoading ? "加载中..." : totalMembers}
                    </dd>
                  </dl>
                </div>
                <div className="flex-shrink-0">
                  <svg className="h-5 w-5 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                  </svg>
                </div>
              </div>
            </div>
          </div>

          <div className="bg-white overflow-hidden shadow rounded-lg">
            <div className="p-5">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <svg className="h-6 w-6 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                  </svg>
                </div>
                <div className="ml-5 w-0 flex-1">
                  <dl>
                    <dt className="text-sm font-medium text-gray-500 truncate">总提案数</dt>
                    <dd className="text-lg font-medium text-gray-900">
                      {proposalsLoading ? "加载中..." : totalProposals}
                    </dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* DAO列表 */}
        <div className="bg-white shadow rounded-lg">
          <div className="px-4 py-5 sm:p-6">
            <h3 className="text-lg leading-6 font-medium text-gray-900 mb-4">
              DAO 列表
            </h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {mockDAOs.map((dao) => (
                <div
                  key={dao.id}
                  className="border border-gray-200 rounded-lg p-6 hover:shadow-md transition-shadow cursor-pointer"
                  onClick={() => handleSelectDAO(dao.id)}
                >
                  <div className="flex justify-between items-start mb-3">
                    <h4 className="text-lg font-semibold text-gray-900">
                      {dao.name}
                    </h4>
                    <span className="text-xs text-gray-500">
                      {new Date(dao.createdAt).toLocaleDateString("zh-CN")}
                    </span>
                  </div>
                  
                  <p className="text-gray-600 text-sm mb-4 line-clamp-2">
                    {dao.description}
                  </p>
                  
                  <div className="flex justify-between items-center text-sm text-gray-500">
                    <div className="flex space-x-4">
                      <span>成员: {dao.memberCount}</span>
                      <span>提案: {dao.proposalCount}</span>
                    </div>
                    <button className="text-[#5B51F6] hover:text-[#4A41E0] font-medium">
                      进入DAO →
                    </button>
                  </div>
                </div>
              ))}
            </div>

            {mockDAOs.length === 0 && (
              <div className="text-center py-12">
                <svg className="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
                </svg>
                <h3 className="mt-2 text-sm font-medium text-gray-900">暂无DAO</h3>
                <p className="mt-1 text-sm text-gray-500">开始创建您的第一个DAO</p>
                <div className="mt-6">
                  <button
                    onClick={() => setShowCreateDAO(true)}
                    className="rounded-lg bg-[#5B51F6] px-4 py-2 text-white hover:bg-[#4A41E0]"
                  >
                    创建DAO
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

