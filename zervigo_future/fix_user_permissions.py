#!/usr/bin/env python3
"""
修复用户权限配置脚本
基于Zervigo设计，为普通用户配置基本权限
"""

import mysql.connector
import json
import logging
from typing import Dict, List

# 配置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# 数据库配置
DB_CONFIG = {
    'host': 'localhost',
    'user': 'root',
    'password': '',  # 空密码
    'database': 'jobfirst',
    'charset': 'utf8mb4'
}

# 角色权限配置 - 基于Zervigo设计
ROLE_PERMISSIONS = {
    'super_admin': [
        'system:manage',
        'user:manage',
        'user:read',
        'user:create',
        'user:update',
        'user:delete',
        'resume:manage',
        'resume:read',
        'resume:create',
        'resume:update',
        'resume:delete',
        'job:manage',
        'job:read',
        'job:create',
        'job:update',
        'job:delete',
        'company:manage',
        'company:read',
        'company:create',
        'company:update',
        'company:delete',
        'ai:resume_analysis',
        'ai:chat',
        'ai:job_matching',
        'ai:all',
        'admin'
    ],
    'admin': [
        'user:manage',
        'user:read',
        'user:create',
        'user:update',
        'resume:manage',
        'resume:read',
        'resume:create',
        'resume:update',
        'job:manage',
        'job:read',
        'job:create',
        'job:update',
        'company:manage',
        'company:read',
        'company:create',
        'company:update',
        'ai:resume_analysis',
        'ai:chat',
        'ai:job_matching'
    ],
    'user': [
        'user:read',
        'user:update',
        'resume:manage',
        'resume:read',
        'resume:create',
        'resume:update',
        'resume:delete',
        'job:read',
        'job:apply',
        'company:read',
        'ai:resume_analysis',
        'ai:chat',
        'ai:job_matching'
    ],
    'guest': [
        'user:read',
        'resume:read',
        'job:read',
        'company:read',
        'ai:chat'
    ]
}

def connect_database():
    """连接数据库"""
    try:
        connection = mysql.connector.connect(**DB_CONFIG)
        return connection
    except mysql.connector.Error as e:
        logger.error(f"数据库连接失败: {e}")
        return None

def get_user_role(user_id: int, connection) -> str:
    """获取用户角色"""
    try:
        cursor = connection.cursor()
        cursor.execute("SELECT role FROM users WHERE id = %s", (user_id,))
        result = cursor.fetchone()
        cursor.close()
        
        if result:
            return result[0]
        return None
    except mysql.connector.Error as e:
        logger.error(f"获取用户角色失败: {e}")
        return None

def create_permission_if_not_exists(permission_name: str, connection):
    """创建权限记录（如果不存在）"""
    try:
        cursor = connection.cursor()
        
        # 检查权限是否存在
        cursor.execute("SELECT id FROM permissions WHERE name = %s", (permission_name,))
        result = cursor.fetchone()
        
        if result:
            permission_id = result[0]
        else:
            # 解析权限名称
            if ':' in permission_name:
                resource, action = permission_name.split(':', 1)
            else:
                resource = 'system'
                action = permission_name
            
            # 创建新权限
            cursor.execute("""
                INSERT INTO permissions (name, display_name, description, resource, action, level, is_system, is_active) 
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """, (permission_name, permission_name, f"{action} {resource}", resource, action, 1, 0, 1))
            
            permission_id = cursor.lastrowid
        
        cursor.close()
        return permission_id
        
    except mysql.connector.Error as e:
        logger.error(f"创建权限失败: {e}")
        return None

def update_user_permissions(user_id: int, role: str, connection):
    """更新用户权限"""
    try:
        permissions = ROLE_PERMISSIONS.get(role, [])
        
        cursor = connection.cursor()
        
        # 先删除用户现有的权限
        cursor.execute("DELETE FROM user_permissions WHERE user_id = %s", (user_id,))
        
        # 为每个权限创建记录
        for permission_name in permissions:
            permission_id = create_permission_if_not_exists(permission_name, connection)
            if permission_id:
                cursor.execute("""
                    INSERT INTO user_permissions (user_id, permission_id, is_active, granted_by, granted_at) 
                    VALUES (%s, %s, %s, %s, NOW())
                """, (user_id, permission_id, 1, 1))  # granted_by设为1（admin）
        
        connection.commit()
        cursor.close()
        
        logger.info(f"用户 {user_id} ({role}) 权限更新成功: {len(permissions)} 个权限")
        return True
        
    except mysql.connector.Error as e:
        logger.error(f"更新用户权限失败: {e}")
        return False

def get_all_users(connection) -> List[Dict]:
    """获取所有用户"""
    try:
        cursor = connection.cursor(dictionary=True)
        cursor.execute("SELECT id, username, role FROM users WHERE status = 'active'")
        users = cursor.fetchall()
        cursor.close()
        return users
    except mysql.connector.Error as e:
        logger.error(f"获取用户列表失败: {e}")
        return []

def main():
    """主函数"""
    logger.info("开始修复用户权限配置...")
    
    # 连接数据库
    connection = connect_database()
    if not connection:
        logger.error("无法连接数据库，退出")
        return
    
    try:
        # 获取所有用户
        users = get_all_users(connection)
        logger.info(f"找到 {len(users)} 个活跃用户")
        
        success_count = 0
        failed_count = 0
        
        # 为每个用户更新权限
        for user in users:
            user_id = user['id']
            username = user['username']
            role = user['role']
            
            logger.info(f"处理用户: {username} (ID: {user_id}, 角色: {role})")
            
            if update_user_permissions(user_id, role, connection):
                success_count += 1
            else:
                failed_count += 1
        
        logger.info(f"权限配置完成: 成功 {success_count} 个，失败 {failed_count} 个")
        
        # 验证权限配置
        logger.info("验证权限配置...")
        cursor = connection.cursor(dictionary=True)
        cursor.execute("""
            SELECT u.username, u.role, COUNT(up.permission_id) as permission_count
            FROM users u 
            LEFT JOIN user_permissions up ON u.id = up.user_id AND up.is_active = 1
            WHERE u.status = 'active'
            GROUP BY u.id, u.username, u.role
        """)
        
        results = cursor.fetchall()
        for result in results:
            username = result['username']
            role = result['role']
            permission_count = result['permission_count']
            logger.info(f"用户 {username} ({role}): {permission_count} 个权限")
        
        cursor.close()
        
    except Exception as e:
        logger.error(f"权限配置过程发生错误: {e}")
    finally:
        connection.close()
    
    logger.info("权限配置修复完成")

if __name__ == "__main__":
    main()
