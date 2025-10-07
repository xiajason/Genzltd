#!/bin/bash

# 修复测试数据一致性问题
# 确保MySQL和SQLite之间的数据映射正确

set -e
set -x  # 启用调试模式，显示每个执行的命令

# 强制输出到终端
exec > >(tee /tmp/fix_data_consistency.log) 2>&1

echo "🔧 开始修复测试数据一致性问题..."
echo "📅 执行时间: $(date)"
echo "📂 当前工作目录: $(pwd)"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 数据库配置
MYSQL_HOST="localhost"
MYSQL_PORT="3306"
MYSQL_USER="root"
MYSQL_PASSWORD=""
MYSQL_DATABASE="jobfirst"

# 用户配置
TEST_USER_ID=4
TEST_USERNAME="szjason72"

echo -e "${BLUE}📋 检查当前数据状态...${NC}"

# 1. 检查MySQL中的简历元数据
echo -e "${YELLOW}1. 检查MySQL中的简历元数据...${NC}"
echo "🔍 正在连接MySQL数据库: $MYSQL_HOST:$MYSQL_PORT, 数据库: $MYSQL_DATABASE"
mysql -h $MYSQL_HOST -P $MYSQL_PORT -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE -e "
SELECT id, user_id, title, sqlite_db_path, parsing_status 
FROM resume_metadata 
WHERE user_id = $TEST_USER_ID 
ORDER BY id;
" || {
    echo -e "${RED}❌ MySQL连接失败或查询失败${NC}"
    exit 1
}
echo -e "${GREEN}✅ MySQL查询完成${NC}"

# 2. 检查SQLite中的简历内容
echo -e "${YELLOW}2. 检查SQLite中的简历内容...${NC}"
SQLITE_DB="/Users/szjason72/zervi-basic/basic/data/users/$TEST_USER_ID/resume.db"
if [ -f "$SQLITE_DB" ]; then
    echo "SQLite数据库存在: $SQLITE_DB"
    sqlite3 "$SQLITE_DB" "
    SELECT id, resume_metadata_id, title, 
           CASE WHEN content IS NULL OR content = '' THEN 'empty' ELSE 'has_content' END as content_status
    FROM resume_content 
    ORDER BY id;
    "
else
    echo -e "${RED}❌ SQLite数据库不存在: $SQLITE_DB${NC}"
    exit 1
fi

# 3. 检查隐私设置
echo -e "${YELLOW}3. 检查隐私设置...${NC}"
sqlite3 "$SQLITE_DB" "
SELECT resume_content_id, is_public, share_with_companies, allow_search, 
       CASE WHEN view_permissions IS NULL THEN 'no_permissions' ELSE view_permissions END as view_permissions
FROM user_privacy_settings 
ORDER BY resume_content_id;
"

echo -e "${BLUE}🔍 分析数据一致性问题...${NC}"

# 4. 分析数据映射问题
echo -e "${YELLOW}4. 分析数据映射问题...${NC}"
MYSQL_IDS=$(mysql -h $MYSQL_HOST -P $MYSQL_PORT -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE -s -N -e "
SELECT GROUP_CONCAT(id) FROM resume_metadata WHERE user_id = $TEST_USER_ID;
")

SQLITE_METADATA_IDS=$(sqlite3 "$SQLITE_DB" "
SELECT GROUP_CONCAT(resume_metadata_id) FROM resume_content;
")

echo "MySQL中的resume_metadata IDs: $MYSQL_IDS"
echo "SQLite中的resume_metadata_id: $SQLITE_METADATA_IDS"

# 5. 修复数据一致性问题
echo -e "${BLUE}🔧 开始修复数据一致性问题...${NC}"

# 5.1 确保SQLite中有对应的简历内容记录
echo -e "${YELLOW}5.1 检查并创建缺失的简历内容记录...${NC}"

# 获取MySQL中所有简历元数据的ID
mysql -h $MYSQL_HOST -P $MYSQL_PORT -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE -s -N -e "
SELECT id, title, sqlite_db_path FROM resume_metadata WHERE user_id = $TEST_USER_ID;
" | while read mysql_id mysql_title sqlite_path; do
    echo "处理MySQL简历ID: $mysql_id, 标题: $mysql_title"
    
    # 检查SQLite中是否存在对应的记录
    sqlite_exists=$(sqlite3 "$SQLITE_DB" "SELECT COUNT(*) FROM resume_content WHERE resume_metadata_id = $mysql_id;")
    
    if [ "$sqlite_exists" -eq 0 ]; then
        echo -e "${YELLOW}  ⚠️  创建缺失的SQLite记录...${NC}"
        sqlite3 "$SQLITE_DB" "
        INSERT INTO resume_content (resume_metadata_id, title, content, raw_content, content_hash, created_at, updated_at)
        VALUES ($mysql_id, '$mysql_title', '', '', 'd41d8cd98f00b204e9800998ecf8427e', datetime('now'), datetime('now'));
        "
        echo -e "${GREEN}  ✅ 已创建SQLite记录: resume_metadata_id=$mysql_id${NC}"
    else
        echo -e "${GREEN}  ✅ SQLite记录已存在: resume_metadata_id=$mysql_id${NC}"
    fi
done

# 5.2 确保每个简历内容都有隐私设置
echo -e "${YELLOW}5.2 检查并创建缺失的隐私设置...${NC}"

# 获取SQLite中所有简历内容的ID
sqlite3 "$SQLITE_DB" "SELECT id, resume_metadata_id, title FROM resume_content;" | while read sqlite_id metadata_id title; do
    echo "处理SQLite简历内容ID: $sqlite_id, 对应MySQL ID: $metadata_id, 标题: $title"
    
    # 检查是否存在隐私设置
    privacy_exists=$(sqlite3 "$SQLITE_DB" "SELECT COUNT(*) FROM user_privacy_settings WHERE resume_content_id = $sqlite_id;")
    
    if [ "$privacy_exists" -eq 0 ]; then
        echo -e "${YELLOW}  ⚠️  创建缺失的隐私设置...${NC}"
        sqlite3 "$SQLITE_DB" "
        INSERT INTO user_privacy_settings (
            resume_content_id, 
            is_public, 
            share_with_companies, 
            allow_search, 
            allow_download,
            view_permissions,
            download_permissions,
            created_at, 
            updated_at
        ) VALUES (
            $sqlite_id,
            0,  -- is_public: 默认不公开
            1,  -- share_with_companies: 允许公司查看
            1,  -- allow_search: 允许被搜索
            0,  -- allow_download: 默认不允许下载
            '{\"ai_service\": \"allowed\", \"default\": \"private\"}',  -- view_permissions: 允许AI服务访问
            '{\"default\": \"denied\"}',  -- download_permissions: 默认不允许下载
            datetime('now'),
            datetime('now')
        );
        "
        echo -e "${GREEN}  ✅ 已创建隐私设置: resume_content_id=$sqlite_id${NC}"
    else
        echo -e "${GREEN}  ✅ 隐私设置已存在: resume_content_id=$sqlite_id${NC}"
    fi
done

# 6. 验证修复结果
echo -e "${BLUE}🔍 验证修复结果...${NC}"

echo -e "${YELLOW}6.1 验证数据映射关系...${NC}"
sqlite3 "$SQLITE_DB" "
SELECT 
    rc.id as sqlite_id,
    rc.resume_metadata_id as mysql_id,
    rc.title,
    CASE WHEN ps.resume_content_id IS NOT NULL THEN 'has_privacy' ELSE 'no_privacy' END as privacy_status,
    ps.is_public,
    ps.share_with_companies,
    ps.allow_search,
    ps.view_permissions
FROM resume_content rc
LEFT JOIN user_privacy_settings ps ON rc.id = ps.resume_content_id
ORDER BY rc.resume_metadata_id;
"

echo -e "${YELLOW}6.2 验证AI服务访问权限...${NC}"
sqlite3 "$SQLITE_DB" "
SELECT 
    rc.resume_metadata_id as mysql_id,
    rc.title,
    ps.view_permissions,
    CASE 
        WHEN ps.view_permissions LIKE '%ai_service%' AND ps.view_permissions LIKE '%allowed%' THEN 'AI服务可访问'
        WHEN ps.share_with_companies = 1 OR ps.allow_search = 1 THEN '默认权限可访问'
        ELSE '无访问权限'
    END as ai_access_status
FROM resume_content rc
LEFT JOIN user_privacy_settings ps ON rc.id = ps.resume_content_id
ORDER BY rc.resume_metadata_id;
"

# 7. 创建测试数据验证脚本
echo -e "${BLUE}📝 创建测试数据验证脚本...${NC}"

cat > /tmp/test_data_consistency.sh << 'EOF'
#!/bin/bash

# 测试数据一致性验证脚本
echo "🧪 开始测试数据一致性..."

# 测试参数
TEST_USER_ID=4
MYSQL_DB="jobfirst"
SQLITE_DB="/Users/szjason72/zervi-basic/basic/data/users/4/resume.db"

# 获取MySQL中的第一个简历ID进行测试
TEST_RESUME_ID=$(mysql -h localhost -u root $MYSQL_DB -s -N -e "
SELECT id FROM resume_metadata WHERE user_id = $TEST_USER_ID ORDER BY id LIMIT 1;
")

echo "测试简历ID: $TEST_RESUME_ID"

if [ -z "$TEST_RESUME_ID" ]; then
    echo "❌ 没有找到测试简历"
    exit 1
fi

# 验证SQLite中是否存在对应的记录
SQLITE_EXISTS=$(sqlite3 "$SQLITE_DB" "SELECT COUNT(*) FROM resume_content WHERE resume_metadata_id = $TEST_RESUME_ID;")

if [ "$SQLITE_EXISTS" -eq 0 ]; then
    echo "❌ SQLite中不存在对应的简历内容记录"
    exit 1
fi

# 验证隐私设置
PRIVACY_EXISTS=$(sqlite3 "$SQLITE_DB" "
SELECT COUNT(*) FROM user_privacy_settings ps
JOIN resume_content rc ON ps.resume_content_id = rc.id
WHERE rc.resume_metadata_id = $TEST_RESUME_ID;
")

if [ "$PRIVACY_EXISTS" -eq 0 ]; then
    echo "❌ 不存在隐私设置"
    exit 1
fi

# 验证AI服务访问权限
AI_ACCESS=$(sqlite3 "$SQLITE_DB" "
SELECT CASE 
    WHEN ps.view_permissions LIKE '%ai_service%' AND ps.view_permissions LIKE '%allowed%' THEN 'allowed'
    WHEN ps.share_with_companies = 1 OR ps.allow_search = 1 THEN 'default_allowed'
    ELSE 'denied'
END as access_status
FROM user_privacy_settings ps
JOIN resume_content rc ON ps.resume_content_id = rc.id
WHERE rc.resume_metadata_id = $TEST_RESUME_ID;
")

echo "AI服务访问权限: $AI_ACCESS"

if [ "$AI_ACCESS" = "allowed" ] || [ "$AI_ACCESS" = "default_allowed" ]; then
    echo "✅ 数据一致性验证通过，可以开始端到端测试"
    exit 0
else
    echo "❌ AI服务访问权限不足"
    exit 1
fi
EOF

chmod +x /tmp/test_data_consistency.sh

echo -e "${GREEN}✅ 数据一致性修复完成！${NC}"
echo -e "${BLUE}📋 下一步操作：${NC}"
echo "1. 运行验证脚本: /tmp/test_data_consistency.sh"
echo "2. 如果验证通过，可以开始端到端测试"
echo "3. 使用修复后的简历ID进行AI服务测试"

# 显示可用于测试的简历ID
echo -e "${BLUE}📋 可用于测试的简历ID：${NC}"
mysql -h $MYSQL_HOST -P $MYSQL_PORT -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE -e "
SELECT id, title, parsing_status 
FROM resume_metadata 
WHERE user_id = $TEST_USER_ID 
ORDER BY id;
"

echo -e "${GREEN}🎉 数据一致性修复脚本执行完成！${NC}"
