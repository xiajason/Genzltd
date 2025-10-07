"use client";

import { useState } from "react";

interface DaoSelectProps {
  onSelect: (daoId: number) => void;
}

export function DaoSelect({ onSelect }: DaoSelectProps) {
  // 模拟DAO列表
  const daos = [
    { id: 1, name: "积分制治理DAO", description: "基于用户积分和声誉的治理系统" },
    { id: 2, name: "社区治理DAO", description: "社区成员共同决策的平台" },
  ];

  return (
    <div className="min-h-screen bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md mx-auto">
        <div className="text-center mb-8">
          <h1 className="text-3xl font-bold text-gray-900">
            选择DAO治理平台
          </h1>
          <p className="mt-2 text-gray-600">
            选择您要参与的治理平台
          </p>
        </div>

        <div className="space-y-4">
          {daos.map((dao) => (
            <div
              key={dao.id}
              className="bg-white rounded-lg shadow-md p-6 cursor-pointer hover:shadow-lg transition-shadow"
              onClick={() => onSelect(dao.id)}
            >
              <h3 className="text-lg font-semibold text-gray-900 mb-2">
                {dao.name}
              </h3>
              <p className="text-gray-600 text-sm">
                {dao.description}
              </p>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
