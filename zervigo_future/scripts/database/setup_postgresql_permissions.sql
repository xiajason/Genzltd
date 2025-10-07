-- PostgreSQL权限配置脚本
-- 按照项目权限分配方案设置：
-- 1. 系统超级管理员（szjason72）可以访问所有数据
-- 2. 项目团队成员可以访问
-- 3. 用户只能访问自己的向量数据

-- 创建项目团队成员角色
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'jobfirst_team') THEN
        CREATE ROLE jobfirst_team;
    END IF;
END
$$;

-- 设置jobfirst_team角色权限
GRANT CONNECT ON DATABASE jobfirst_vector TO jobfirst_team;
GRANT USAGE ON SCHEMA public TO jobfirst_team;

-- 为所有表设置权限
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO jobfirst_team;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO jobfirst_team;

-- 设置默认权限，确保新创建的表也有相应权限
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO jobfirst_team;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO jobfirst_team;

-- 为特定用户数据表设置行级安全策略（RLS）
-- 例如：用户只能访问自己的简历向量数据
ALTER TABLE resume_vectors ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_embeddings ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_ai_profiles ENABLE ROW LEVEL SECURITY;

-- 创建策略：用户只能访问自己的数据
-- resume_vectors表没有user_id字段，需要通过resume_id关联到MySQL的resume_metadata表
-- 这里先设置基本的RLS，具体策略需要在应用层实现

-- user_embeddings表已经有user_id字段和策略，跳过
-- user_ai_profiles表检查是否有user_id字段
DO $$
BEGIN
    -- 检查user_ai_profiles表是否有user_id字段
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'user_ai_profiles' AND column_name = 'user_id') THEN
        CREATE POLICY user_ai_profiles_policy ON user_ai_profiles
            FOR ALL TO PUBLIC
            USING (user_id = current_setting('app.current_user_id', true)::bigint);
    END IF;
END
$$;

-- 超级管理员可以绕过所有RLS策略
ALTER ROLE szjason72 BYPASSRLS;
ALTER ROLE jobfirst_team BYPASSRLS;

-- 显示权限配置结果
SELECT 
    t.schemaname,
    t.tablename,
    s.hasinserts,
    s.hasselects,
    s.hasupdates,
    s.hasdeletes
FROM pg_tables t
JOIN pg_stat_user_tables s ON t.tablename = s.relname
WHERE t.schemaname = 'public'
ORDER BY t.tablename;
