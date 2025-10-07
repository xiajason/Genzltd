#!/usr/bin/env python3
"""
Future版SQLite数据库结构创建脚本
版本: V1.0
日期: 2025年10月5日
描述: 为每个用户创建独立的SQLite数据库结构和表单 (用户内容存储)
"""

import sqlite3
import os
import json
from pathlib import Path
from datetime import datetime

class FutureSQLiteDatabaseCreator:
    """Future版SQLite数据库结构创建器"""
    
    def __init__(self, base_path="./data/users"):
        self.base_path = Path(base_path)
        self.base_path.mkdir(parents=True, exist_ok=True)
    
    def create_user_database(self, user_id):
        """为指定用户创建SQLite数据库结构"""
        # 创建用户目录
        user_dir = self.base_path / str(user_id)
        user_dir.mkdir(parents=True, exist_ok=True)
        
        # 数据库文件路径
        db_path = user_dir / "resume.db"
        
        # 连接数据库
        conn = sqlite3.connect(str(db_path))
        cursor = conn.cursor()
        
        try:
            # 执行数据库结构创建
            self._create_tables(cursor)
            self._create_indexes(cursor)
            self._insert_initial_data(cursor, user_id)
            
            conn.commit()
            print(f"✅ 用户 {user_id} 的SQLite数据库结构创建完成: {db_path}")
            return True
            
        except Exception as e:
            print(f"❌ 创建用户 {user_id} 数据库失败: {e}")
            conn.rollback()
            return False
        finally:
            conn.close()
    
    def _create_tables(self, cursor):
        """创建所有表结构"""
        
        # ==============================================
        # 1. 简历内容表 - 存储实际的简历内容和用户数据
        # ==============================================
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS resume_content (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                resume_metadata_id INTEGER NOT NULL, -- 对应MySQL中的resume_metadata.id
                title TEXT NOT NULL,
                content TEXT, -- Markdown格式的简历内容
                raw_content TEXT, -- 原始文件内容（如果是上传的文件）
                content_hash TEXT, -- 内容哈希，用于去重和版本控制
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                
                UNIQUE(resume_metadata_id) -- 确保一个元数据记录对应一个内容记录
            )
        """)
        
        # ==============================================
        # 2. 解析结果表 - 存储结构化的解析数据
        # ==============================================
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS parsed_resume_data (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                resume_content_id INTEGER NOT NULL,
                personal_info TEXT, -- JSON格式的个人信息
                work_experience TEXT, -- JSON格式的工作经历
                education TEXT, -- JSON格式的教育背景
                skills TEXT, -- JSON格式的技能列表
                projects TEXT, -- JSON格式的项目经验
                certifications TEXT, -- JSON格式的证书认证
                keywords TEXT, -- JSON格式的关键词
                confidence REAL, -- 解析置信度 0-1
                parsing_version TEXT, -- 解析器版本
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                
                FOREIGN KEY (resume_content_id) REFERENCES resume_content(id) ON DELETE CASCADE
            )
        """)
        
        # ==============================================
        # 3. 用户隐私设置表 - 详细的隐私控制
        # ==============================================
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS user_privacy_settings (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                setting_type VARCHAR(50) NOT NULL, -- 'resume_visibility', 'contact_info', 'work_history', etc.
                setting_value TEXT NOT NULL, -- JSON格式的设置值
                is_public BOOLEAN DEFAULT FALSE,
                allow_search BOOLEAN DEFAULT TRUE,
                allow_contact BOOLEAN DEFAULT TRUE,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                
                UNIQUE(user_id, setting_type)
            )
        """)
        
        # ==============================================
        # 4. 简历版本历史表 - 版本控制
        # ==============================================
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS resume_versions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                resume_content_id INTEGER NOT NULL,
                version_number INTEGER NOT NULL,
                content_snapshot TEXT NOT NULL, -- 该版本的内容快照
                change_summary TEXT, -- 变更摘要
                created_by VARCHAR(100), -- 创建者
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                
                FOREIGN KEY (resume_content_id) REFERENCES resume_content(id) ON DELETE CASCADE,
                UNIQUE(resume_content_id, version_number)
            )
        """)
        
        # ==============================================
        # 5. 用户自定义字段表 - 扩展字段
        # ==============================================
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS user_custom_fields (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                field_name VARCHAR(100) NOT NULL,
                field_type VARCHAR(50) NOT NULL, -- 'text', 'number', 'date', 'boolean', 'json'
                field_value TEXT,
                field_label VARCHAR(200),
                field_description TEXT,
                is_required BOOLEAN DEFAULT FALSE,
                display_order INTEGER DEFAULT 0,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                
                UNIQUE(user_id, field_name)
            )
        """)
        
        # ==============================================
        # 6. 简历访问日志表 - 访问记录
        # ==============================================
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS resume_access_logs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                resume_content_id INTEGER NOT NULL,
                accessor_id INTEGER, -- 访问者ID，NULL表示匿名访问
                access_type VARCHAR(50) NOT NULL, -- 'view', 'download', 'share', 'edit'
                ip_address VARCHAR(45),
                user_agent TEXT,
                referrer_url TEXT,
                access_duration INTEGER, -- 访问时长（秒）
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                
                FOREIGN KEY (resume_content_id) REFERENCES resume_content(id) ON DELETE CASCADE
            )
        """)
        
        # ==============================================
        # 7. 用户偏好设置表 - 个性化设置
        # ==============================================
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS user_preferences (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                preference_key VARCHAR(100) NOT NULL,
                preference_value TEXT,
                preference_type VARCHAR(50) DEFAULT 'string', -- 'string', 'number', 'boolean', 'json'
                description TEXT,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                
                UNIQUE(user_id, preference_key)
            )
        """)
    
    def _create_indexes(self, cursor):
        """创建索引"""
        
        # 简历内容表索引
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_resume_content_metadata_id ON resume_content(resume_metadata_id)")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_resume_content_created_at ON resume_content(created_at)")
        
        # 解析结果表索引
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_parsed_resume_data_content_id ON parsed_resume_data(resume_content_id)")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_parsed_resume_data_confidence ON parsed_resume_data(confidence)")
        
        # 用户隐私设置表索引
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_user_privacy_settings_user_id ON user_privacy_settings(user_id)")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_user_privacy_settings_type ON user_privacy_settings(setting_type)")
        
        # 简历版本历史表索引
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_resume_versions_content_id ON resume_versions(resume_content_id)")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_resume_versions_version ON resume_versions(version_number)")
        
        # 用户自定义字段表索引
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_user_custom_fields_user_id ON user_custom_fields(user_id)")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_user_custom_fields_name ON user_custom_fields(field_name)")
        
        # 简历访问日志表索引
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_resume_access_logs_content_id ON resume_access_logs(resume_content_id)")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_resume_access_logs_accessor ON resume_access_logs(accessor_id)")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_resume_access_logs_created_at ON resume_access_logs(created_at)")
        
        # 用户偏好设置表索引
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_user_preferences_user_id ON user_preferences(user_id)")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_user_preferences_key ON user_preferences(preference_key)")
    
    def _insert_initial_data(self, cursor, user_id):
        """插入初始数据"""
        
        # 插入默认隐私设置
        default_privacy_settings = [
            ('resume_visibility', '{"visibility": "private", "allow_search": false}', False, True, True),
            ('contact_info', '{"show_email": false, "show_phone": false, "show_address": false}', False, True, True),
            ('work_history', '{"show_company": true, "show_position": true, "show_duration": true}', True, True, True),
            ('education', '{"show_school": true, "show_degree": true, "show_gpa": false}', True, True, True),
            ('skills', '{"show_skills": true, "show_proficiency": true}', True, True, True)
        ]
        
        for setting_type, setting_value, is_public, allow_search, allow_contact in default_privacy_settings:
            cursor.execute("""
                INSERT OR IGNORE INTO user_privacy_settings 
                (user_id, setting_type, setting_value, is_public, allow_search, allow_contact)
                VALUES (?, ?, ?, ?, ?, ?)
            """, (user_id, setting_type, setting_value, is_public, allow_search, allow_contact))
        
        # 插入默认用户偏好设置
        default_preferences = [
            ('theme', 'light', 'string', '界面主题设置'),
            ('language', 'zh-CN', 'string', '界面语言设置'),
            ('notifications', '{"email": true, "push": true, "sms": false}', 'json', '通知设置'),
            ('privacy_level', 'medium', 'string', '隐私级别设置'),
            ('auto_save', 'true', 'boolean', '自动保存设置')
        ]
        
        for pref_key, pref_value, pref_type, description in default_preferences:
            cursor.execute("""
                INSERT OR IGNORE INTO user_preferences 
                (user_id, preference_key, preference_value, preference_type, description)
                VALUES (?, ?, ?, ?, ?)
            """, (user_id, pref_key, pref_value, pref_type, description))
    
    def create_all_users_databases(self, user_ids):
        """为多个用户创建数据库"""
        success_count = 0
        total_count = len(user_ids)
        
        print(f"🚀 开始为 {total_count} 个用户创建SQLite数据库结构...")
        
        for user_id in user_ids:
            if self.create_user_database(user_id):
                success_count += 1
        
        print(f"✅ 完成！成功创建 {success_count}/{total_count} 个用户数据库")
        return success_count, total_count
    
    def verify_database_structure(self, user_id):
        """验证数据库结构"""
        user_dir = self.base_path / str(user_id)
        db_path = user_dir / "resume.db"
        
        if not db_path.exists():
            return False, "数据库文件不存在"
        
        try:
            conn = sqlite3.connect(str(db_path))
            cursor = conn.cursor()
            
            # 检查表是否存在
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
            tables = [row[0] for row in cursor.fetchall()]
            
            expected_tables = [
                'resume_content', 'parsed_resume_data', 'user_privacy_settings',
                'resume_versions', 'user_custom_fields', 'resume_access_logs', 'user_preferences'
            ]
            
            missing_tables = set(expected_tables) - set(tables)
            if missing_tables:
                return False, f"缺少表: {missing_tables}"
            
            # 检查记录数
            cursor.execute("SELECT COUNT(*) FROM user_privacy_settings WHERE user_id = ?", (user_id,))
            privacy_count = cursor.fetchone()[0]
            
            cursor.execute("SELECT COUNT(*) FROM user_preferences WHERE user_id = ?", (user_id,))
            preferences_count = cursor.fetchone()[0]
            
            conn.close()
            
            return True, f"数据库结构验证通过，隐私设置: {privacy_count}条，偏好设置: {preferences_count}条"
            
        except Exception as e:
            return False, f"验证失败: {e}"

def main():
    """主函数"""
    print("🎯 Future版SQLite数据库结构创建脚本")
    print("=" * 50)
    
    # 创建数据库创建器
    creator = FutureSQLiteDatabaseCreator()
    
    # 示例：为测试用户创建数据库
    test_user_ids = [1, 2, 3, 4, 5]
    
    # 创建所有用户数据库
    success_count, total_count = creator.create_all_users_databases(test_user_ids)
    
    # 验证数据库结构
    print("\n🔍 验证数据库结构...")
    for user_id in test_user_ids:
        is_valid, message = creator.verify_database_structure(user_id)
        status = "✅" if is_valid else "❌"
        print(f"{status} 用户 {user_id}: {message}")
    
    print(f"\n🎉 Future版SQLite数据库结构创建完成！")
    print(f"📊 统计: 成功创建 {success_count}/{total_count} 个用户数据库")
    print(f"📁 数据库位置: {creator.base_path}")

if __name__ == "__main__":
    main()
