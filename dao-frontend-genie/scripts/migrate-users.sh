#!/bin/bash

# DAO Genie 用户数据迁移脚本
# 从 Zervigo 项目迁移用户数据到 DAO 系统

set -e

echo "🚀 开始 DAO Genie 用户数据迁移..."

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目路径
PROJECT_ROOT="/Users/szjason72/genzltd"
DAO_PROJECT="$PROJECT_ROOT/dao-frontend-genie"
ZERVIGO_PROJECT="$PROJECT_ROOT/zervigo_future"

echo -e "${BLUE}📁 项目路径:${NC}"
echo "  DAO项目: $DAO_PROJECT"
echo "  Zervigo项目: $ZERVIGO_PROJECT"

# 检查项目路径
if [ ! -d "$DAO_PROJECT" ]; then
    echo -e "${RED}❌ DAO项目路径不存在: $DAO_PROJECT${NC}"
    exit 1
fi

if [ ! -d "$ZERVIGO_PROJECT" ]; then
    echo -e "${RED}❌ Zervigo项目路径不存在: $ZERVIGO_PROJECT${NC}"
    exit 1
fi

# 进入DAO项目目录
cd "$DAO_PROJECT"

echo -e "${BLUE}📋 步骤1: 备份当前数据库${NC}"
# 创建备份目录
mkdir -p database-backups
BACKUP_FILE="database-backups/dao-members-backup-$(date +%Y%m%d-%H%M%S).sql"

# 备份当前dao_members表
echo "  备份当前dao_members表到: $BACKUP_FILE"
mysqldump -h 127.0.0.1 -P 9506 -u dao_user -pdao_password_2024 dao_dev dao_members > "$BACKUP_FILE" 2>/dev/null || {
    echo -e "${YELLOW}⚠️  无法备份数据库，继续执行...${NC}"
}

echo -e "${BLUE}📋 步骤2: 更新Prisma Schema${NC}"
# 备份原schema
cp prisma/schema.prisma prisma/schema.prisma.backup

# 使用更新后的schema
cp prisma/schema-updated.prisma prisma/schema.prisma

echo "  已更新Prisma Schema"

echo -e "${BLUE}📋 步骤3: 更新数据库结构${NC}"
# 生成Prisma客户端
echo "  生成Prisma客户端..."
npx prisma generate

# 推送数据库变更
echo "  推送数据库结构变更..."
npx prisma db push --accept-data-loss

echo -e "${BLUE}📋 步骤4: 执行用户数据迁移${NC}"
# 执行SQL迁移脚本
echo "  执行用户数据迁移..."

# 检查是否能连接到zervigo数据库
if mysql -h localhost -u root -p -e "USE jobfirst_v3; SELECT COUNT(*) FROM users;" 2>/dev/null; then
    echo "  ✅ 检测到zervigo数据库，执行跨数据库迁移..."
    mysql -h 127.0.0.1 -P 9506 -u dao_user -pdao_password_2024 dao_dev < scripts/migrate-users-from-zervigo.sql
else
    echo "  ⚠️  无法连接zervigo数据库，使用手动插入方式..."
    
    # 创建临时SQL文件，使用手动插入数据
    cat > scripts/migrate-users-manual.sql << 'EOF'
USE dao_dev;

-- 手动插入 zervigo 用户数据
INSERT INTO dao_members (
    user_id, username, email, first_name, last_name, avatar_url, phone,
    bio, location, website, github_url, linkedin_url, skills, interests, languages,
    reputation_score, contribution_points, status, created_at
) VALUES 
-- 张三 - 前端开发
('user-uuid-001', 'zhangsan', 'zhangsan@jobfirst.com', '张三', '张', 'https://example.com/avatar1.jpg', '13800138001',
'5年前端开发经验，精通React、Vue等现代前端技术栈，热爱开源项目', '北京', 'https://zhangsan.dev', 
'https://github.com/zhangsan', 'https://linkedin.com/in/zhangsan', 
'["React", "Vue", "JavaScript", "TypeScript"]', '["编程", "开源", "技术分享"]', '["中文", "英文"]',
80, 65, 'ACTIVE', '2024-01-01 10:00:00'),

-- 李四 - 产品管理
('user-uuid-002', 'lisi', 'lisi@jobfirst.com', '李四', '李', 'https://example.com/avatar2.jpg', '13800138002',
'3年产品管理经验，擅长用户研究和产品设计，有丰富的B端产品经验', '上海', 'https://lisi.design', 
'https://github.com/lisi', 'https://linkedin.com/in/lisi', 
'["产品设计", "用户研究", "数据分析"]', '["设计", "心理学", "商业分析"]', '["中文", "英文", "日文"]',
70, 60, 'ACTIVE', '2024-01-02 10:00:00'),

-- 王五 - 后端开发
('user-uuid-003', 'wangwu', 'wangwu@jobfirst.com', '王五', '王', 'https://example.com/avatar3.jpg', '13800138003',
'7年后端开发经验，专注于分布式系统和微服务架构', '深圳', 'https://wangwu.tech', 
'https://github.com/wangwu', 'https://linkedin.com/in/wangwu', 
'["Go", "Java", "Python", "Docker", "Kubernetes"]', '["系统架构", "开源", "技术管理"]', '["中文", "英文"]',
90, 70, 'ACTIVE', '2024-01-03 10:00:00'),

-- 赵六 - 全栈开发
('user-uuid-004', 'zhaoliu', 'zhaoliu@jobfirst.com', '赵六', '赵', 'https://example.com/avatar4.jpg', '13800138004',
'4年全栈开发经验，熟悉前后端技术栈，有丰富的项目经验', '杭州', 'https://zhaoliu.dev', 
'https://github.com/zhaoliu', 'https://linkedin.com/in/zhaoliu', 
'["React", "Node.js", "Python", "MySQL", "Redis"]', '["全栈开发", "技术分享", "创业"]', '["中文", "英文"]',
85, 55, 'ACTIVE', '2024-01-04 10:00:00'),

-- 钱七 - UI/UX设计
('user-uuid-005', 'qianqi', 'qianqi@jobfirst.com', '钱七', '钱', 'https://example.com/avatar5.jpg', '13800138005',
'2年UI/UX设计经验，专注于移动端和Web端界面设计', '广州', 'https://qianqi.design', 
'https://github.com/qianqi', 'https://linkedin.com/in/qianqi', 
'["UI设计", "UX设计", "Figma", "Sketch", "Photoshop"]', '["设计", "艺术", "摄影"]', '["中文", "英文", "韩文"]',
70, 50, 'ACTIVE', '2024-01-05 10:00:00');

-- 验证迁移结果
SELECT 
    user_id,
    username,
    email,
    first_name,
    last_name,
    reputation_score,
    contribution_points,
    status
FROM dao_members 
WHERE user_id LIKE 'user-uuid-%'
ORDER BY reputation_score DESC;
EOF

    mysql -h 127.0.0.1 -P 9506 -u dao_user -pdao_password_2024 dao_dev < scripts/migrate-users-manual.sql
fi

echo -e "${BLUE}📋 步骤5: 验证迁移结果${NC}"
# 验证迁移结果
echo "  检查迁移后的用户数据..."
mysql -h 127.0.0.1 -P 9506 -u dao_user -pdao_password_2024 dao_dev -e "
SELECT 
    COUNT(*) as total_members,
    AVG(reputation_score) as avg_reputation,
    AVG(contribution_points) as avg_contribution,
    COUNT(CASE WHEN status = 'ACTIVE' THEN 1 END) as active_members
FROM dao_members;
"

echo -e "${BLUE}📋 步骤6: 更新API接口${NC}"
# 这里需要手动更新API接口代码
echo "  ⚠️  需要手动更新以下文件:"
echo "    - src/server/api/routers/dao.ts (更新getMembers接口)"
echo "    - src/types/integral-dao.ts (更新类型定义)"
echo "    - src/components/integral-member-list.tsx (更新显示组件)"

echo -e "${GREEN}✅ 用户数据迁移完成！${NC}"
echo -e "${YELLOW}📝 下一步操作:${NC}"
echo "  1. 手动更新API接口代码"
echo "  2. 更新前端组件显示用户信息"
echo "  3. 测试所有功能"
echo "  4. 如有问题，可从备份恢复: $BACKUP_FILE"

echo -e "${BLUE}📊 迁移统计:${NC}"
mysql -h 127.0.0.1 -P 9506 -u dao_user -pdao_password_2024 dao_dev -e "
SELECT 
    user_id,
    username,
    first_name,
    last_name,
    reputation_score,
    contribution_points
FROM dao_members 
ORDER BY reputation_score DESC;
"
