"use client";

import { IntegralDAOMember } from '../types/integral-dao';
import { useState } from 'react';

interface IntegralMemberListProps {
  members: IntegralDAOMember[];
}

export function IntegralMemberList({ members }: IntegralMemberListProps) {
  const [expandedMember, setExpandedMember] = useState<string | null>(null);

  const toggleExpanded = (memberId: string | bigint) => {
    const idStr = memberId.toString();
    setExpandedMember(expandedMember === idStr ? null : idStr);
  };

  const getDisplayName = (member: IntegralDAOMember) => {
    if (member.firstName && member.lastName) {
      return `${member.firstName} ${member.lastName}`;
    }
    if (member.username) {
      return member.username;
    }
    return member.userId;
  };

  const getInitials = (member: IntegralDAOMember) => {
    if (member.firstName && member.lastName) {
      return `${member.firstName.charAt(0)}${member.lastName.charAt(0)}`.toUpperCase();
    }
    if (member.username) {
      return member.username.charAt(0).toUpperCase();
    }
    return member.userId.charAt(0).toUpperCase();
  };

  const getSkillColor = (skill: string) => {
    const colors = {
      'React': 'bg-blue-100 text-blue-800',
      'Vue': 'bg-green-100 text-green-800',
      'JavaScript': 'bg-yellow-100 text-yellow-800',
      'TypeScript': 'bg-blue-100 text-blue-800',
      'Go': 'bg-cyan-100 text-cyan-800',
      'Java': 'bg-red-100 text-red-800',
      'Python': 'bg-green-100 text-green-800',
      'Node.js': 'bg-green-100 text-green-800',
      'Docker': 'bg-blue-100 text-blue-800',
      'Kubernetes': 'bg-purple-100 text-purple-800',
      'UI设计': 'bg-pink-100 text-pink-800',
      'UX设计': 'bg-purple-100 text-purple-800',
      '产品设计': 'bg-indigo-100 text-indigo-800',
      '用户研究': 'bg-orange-100 text-orange-800',
      '数据分析': 'bg-teal-100 text-teal-800',
    };
    return colors[skill as keyof typeof colors] || 'bg-gray-100 text-gray-800';
  };

  return (
    <div className="space-y-4">
      {members.map((member) => {
        const isExpanded = expandedMember === member.id;
        const skillsList = (member as any).skillsList || [];
        const interestsList = (member as any).interestsList || [];
        
        return (
          <div key={member.id} className="bg-white border border-gray-200 rounded-lg shadow-sm hover:shadow-md transition-shadow">
            {/* 主要信息行 */}
            <div 
              className="flex items-center justify-between p-4 cursor-pointer"
              onClick={() => toggleExpanded(member.id)}
            >
              <div className="flex items-center space-x-4">
                {/* 头像 */}
                <div className="relative">
                  {member.avatarUrl ? (
                    <img 
                      src={member.avatarUrl} 
                      alt={getDisplayName(member)}
                      className="w-12 h-12 rounded-full object-cover"
                    />
                  ) : (
                    <div className="w-12 h-12 bg-gradient-to-br from-purple-500 to-blue-600 rounded-full flex items-center justify-center">
                      <span className="text-white font-semibold text-lg">
                        {getInitials(member)}
                      </span>
                    </div>
                  )}
                  {/* 在线状态指示器 */}
                  <div className="absolute bottom-0 right-0 w-3 h-3 bg-green-400 border-2 border-white rounded-full"></div>
                </div>

                {/* 基本信息 */}
                <div className="flex-1">
                  <div className="flex items-center space-x-2">
                    <h3 className="text-lg font-semibold text-gray-900">
                      {getDisplayName(member)}
                    </h3>
                    {member.location && (
                      <span className="text-sm text-gray-500">📍 {member.location}</span>
                    )}
                  </div>
                  
                  <div className="flex items-center space-x-4 mt-1">
                    {member.email && (
                      <span className="text-sm text-gray-600">📧 {member.email}</span>
                    )}
                    {member.phone && (
                      <span className="text-sm text-gray-600">📱 {member.phone}</span>
                    )}
                  </div>

                  {/* 技能标签（显示前3个） */}
                  {skillsList.length > 0 && (
                    <div className="flex flex-wrap gap-1 mt-2">
                      {skillsList.slice(0, 3).map((skill: string, index: number) => (
                        <span 
                          key={index}
                          className={`px-2 py-1 text-xs rounded-full ${getSkillColor(skill)}`}
                        >
                          {skill}
                        </span>
                      ))}
                      {skillsList.length > 3 && (
                        <span className="px-2 py-1 text-xs rounded-full bg-gray-100 text-gray-600">
                          +{skillsList.length - 3}
                        </span>
                      )}
                    </div>
                  )}
                </div>
              </div>

              {/* 右侧信息 */}
              <div className="flex items-center space-x-6">
                {/* 积分信息 */}
                <div className="text-center">
                  <div className="text-2xl font-bold text-purple-600">
                    {member.votingPower}
                  </div>
                  <div className="text-xs text-gray-500">投票权重</div>
                </div>

                {/* 积分详情 */}
                <div className="text-center">
                  <div className="text-sm font-semibold text-blue-600">
                    {member.reputationScore}
                  </div>
                  <div className="text-xs text-gray-500">声誉积分</div>
                </div>

                <div className="text-center">
                  <div className="text-sm font-semibold text-green-600">
                    {member.contributionPoints}
                  </div>
                  <div className="text-xs text-gray-500">贡献积分</div>
                </div>

                {/* 展开按钮 */}
                <button className="p-2 text-gray-400 hover:text-gray-600 transition-colors">
                  <svg 
                    className={`w-5 h-5 transition-transform ${isExpanded ? 'rotate-180' : ''}`}
                    fill="none" 
                    stroke="currentColor" 
                    viewBox="0 0 24 24"
                  >
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                  </svg>
                </button>
              </div>
            </div>

            {/* 展开的详细信息 */}
            {isExpanded && (
              <div className="px-4 pb-4 border-t border-gray-100">
                <div className="pt-4 grid grid-cols-1 md:grid-cols-2 gap-6">
                  {/* 左侧：个人简介和链接 */}
                  <div className="space-y-4">
                    {member.bio && (
                      <div>
                        <h4 className="text-sm font-semibold text-gray-900 mb-2">个人简介</h4>
                        <p className="text-sm text-gray-600 leading-relaxed">{member.bio}</p>
                      </div>
                    )}

                    {/* 社交链接 */}
                    <div>
                      <h4 className="text-sm font-semibold text-gray-900 mb-2">社交链接</h4>
                      <div className="flex flex-wrap gap-2">
                        {member.githubUrl && (
                          <a 
                            href={member.githubUrl} 
                            target="_blank" 
                            rel="noopener noreferrer"
                            className="inline-flex items-center px-3 py-1 text-xs bg-gray-800 text-white rounded-full hover:bg-gray-700 transition-colors"
                          >
                            <svg className="w-3 h-3 mr-1" fill="currentColor" viewBox="0 0 20 20">
                              <path fillRule="evenodd" d="M10 0C4.477 0 0 4.484 0 10.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.531 1.032 1.531 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0110 4.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.203 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.942.359.31.678.921.678 1.856 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0020 10.017C20 4.484 15.522 0 10 0z" clipRule="evenodd" />
                            </svg>
                            GitHub
                          </a>
                        )}
                        {member.linkedinUrl && (
                          <a 
                            href={member.linkedinUrl} 
                            target="_blank" 
                            rel="noopener noreferrer"
                            className="inline-flex items-center px-3 py-1 text-xs bg-blue-600 text-white rounded-full hover:bg-blue-700 transition-colors"
                          >
                            <svg className="w-3 h-3 mr-1" fill="currentColor" viewBox="0 0 20 20">
                              <path fillRule="evenodd" d="M16.338 16.338H13.67V12.16c0-.995-.017-2.277-1.387-2.277-1.39 0-1.601 1.086-1.601 2.207v4.248H8.014v-8.59h2.559v1.174h.037c.356-.675 1.227-1.387 2.526-1.387 2.703 0 3.203 1.778 3.203 4.092v4.711zM5.005 6.575a1.548 1.548 0 11-.003-3.096 1.548 1.548 0 01.003 3.096zm-1.337 9.763H6.34v-8.59H3.667v8.59zM17.668 1H2.328C1.595 1 1 1.581 1 2.298v15.403C1 18.418 1.595 19 2.328 19h15.34c.734 0 1.332-.582 1.332-1.299V2.298C19 1.581 18.402 1 17.668 1z" clipRule="evenodd" />
                            </svg>
                            LinkedIn
                          </a>
                        )}
                        {member.website && (
                          <a 
                            href={member.website} 
                            target="_blank" 
                            rel="noopener noreferrer"
                            className="inline-flex items-center px-3 py-1 text-xs bg-gray-600 text-white rounded-full hover:bg-gray-700 transition-colors"
                          >
                            <svg className="w-3 h-3 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
                            </svg>
                            网站
                          </a>
                        )}
                      </div>
                    </div>
                  </div>

                  {/* 右侧：技能和兴趣 */}
                  <div className="space-y-4">
                    {/* 完整技能列表 */}
                    {skillsList.length > 0 && (
                      <div>
                        <h4 className="text-sm font-semibold text-gray-900 mb-2">技能专长</h4>
                        <div className="flex flex-wrap gap-2">
                          {skillsList.map((skill: string, index: number) => (
                            <span 
                              key={index}
                              className={`px-3 py-1 text-sm rounded-full ${getSkillColor(skill)}`}
                            >
                              {skill}
                            </span>
                          ))}
                        </div>
                      </div>
                    )}

                    {/* 兴趣列表 */}
                    {interestsList.length > 0 && (
                      <div>
                        <h4 className="text-sm font-semibold text-gray-900 mb-2">兴趣爱好</h4>
                        <div className="flex flex-wrap gap-2">
                          {interestsList.map((interest: string, index: number) => (
                            <span 
                              key={index}
                              className="px-3 py-1 text-sm rounded-full bg-purple-100 text-purple-800"
                            >
                              {interest}
                            </span>
                          ))}
                        </div>
                      </div>
                    )}

                    {/* 语言能力 */}
                    {(member as any).languagesList && (member as any).languagesList.length > 0 && (
                      <div>
                        <h4 className="text-sm font-semibold text-gray-900 mb-2">语言能力</h4>
                        <div className="flex flex-wrap gap-2">
                          {(member as any).languagesList.map((language: string, index: number) => (
                            <span 
                              key={index}
                              className="px-3 py-1 text-sm rounded-full bg-blue-100 text-blue-800"
                            >
                              {language}
                            </span>
                          ))}
                        </div>
                      </div>
                    )}
                  </div>
                </div>
              </div>
            )}
          </div>
        );
      })}
      
      {members.length === 0 && (
        <div className="text-center py-12 text-gray-500">
          <div className="w-16 h-16 mx-auto mb-4 bg-gray-100 rounded-full flex items-center justify-center">
            <svg className="w-8 h-8 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z" />
            </svg>
          </div>
          <p className="text-lg font-medium">暂无成员数据</p>
          <p className="text-sm">等待更多成员加入DAO治理</p>
        </div>
      )}
    </div>
  );
}
