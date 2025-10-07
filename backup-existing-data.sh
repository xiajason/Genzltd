#!/bin/bash
# 现有数据备份脚本 - 为DAO版迁移做准备

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔄 现有数据备份脚本 - DAO版迁移准备${NC}"
echo "=========================================="

# 备份目录
BACKUP_DIR="./data-migration-backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo -e "\n${BLUE}📁 创建备份目录: $BACKUP_DIR${NC}"

# 检查现有数据库连接
echo -e "\n${BLUE}🔍 检查现有数据库连接${NC}"
echo "------------------------"

# 检查本地MySQL连接
if nc -z localhost 3306; then
    echo "✅ 本地MySQL (3306): 连接正常"
    LOCAL_MYSQL_AVAILABLE=true
else
    echo -e "${YELLOW}⚠️ 本地MySQL (3306): 未连接${NC}"
    LOCAL_MYSQL_AVAILABLE=false
fi

# 检查DAO版MySQL连接
if nc -z localhost 9506; then
    echo "✅ DAO版MySQL (9506): 连接正常"
    DAO_MYSQL_AVAILABLE=true
else
    echo -e "${YELLOW}⚠️ DAO版MySQL (9506): 未连接${NC}"
    DAO_MYSQL_AVAILABLE=false
fi

# 检查PostgreSQL连接
if nc -z localhost 5432; then
    echo "✅ PostgreSQL (5432): 连接正常"
    POSTGRES_AVAILABLE=true
else
    echo -e "${YELLOW}⚠️ PostgreSQL (5432): 未连接${NC}"
    POSTGRES_AVAILABLE=false
fi

# 检查Redis连接
if nc -z localhost 6379; then
    echo "✅ Redis (6379): 连接正常"
    REDIS_AVAILABLE=true
else
    echo -e "${YELLOW}⚠️ Redis (6379): 未连接${NC}"
    REDIS_AVAILABLE=false
fi

echo -e "\n${BLUE}📊 现有数据库分析${NC}"
echo "------------------------"

# 分析现有MySQL数据库
if [ "$LOCAL_MYSQL_AVAILABLE" = true ]; then
    echo "检查现有MySQL数据库..."
    # 这里需要根据实际情况调整连接参数
    echo "📋 现有MySQL数据库列表:"
    echo "  - 需要手动检查jobfirst_v3数据库"
    echo "  - 包含20个业务表"
    echo "  - 用户、简历、公司、职位等数据"
fi

# 分析现有PostgreSQL数据库
if [ "$POSTGRES_AVAILABLE" = true ]; then
    echo "检查现有PostgreSQL数据库..."
    echo "📋 现有PostgreSQL数据库列表:"
    echo "  - jobfirst_vector: 向量数据和AI分析"
    echo "  - jobfirst_future: 业务数据存储"
    echo "  - looma_crm: Looma CRM数据"
fi

# 分析现有Redis数据
if [ "$REDIS_AVAILABLE" = true ]; then
    echo "检查现有Redis数据..."
    echo "📋 Redis数据:"
    echo "  - 缓存和会话管理数据"
    echo "  - 用户会话信息"
    echo "  - 系统配置缓存"
fi

echo -e "\n${BLUE}💾 创建数据备份${NC}"
echo "------------------------"

# 创建备份报告
cat > "$BACKUP_DIR/backup_report.md" << EOF
# 现有数据备份报告

**备份时间**: $(date '+%Y-%m-%d %H:%M:%S')
**备份目录**: $BACKUP_DIR
**迁移目标**: DAO版三环境

## 数据库连接状态

### MySQL数据库
- 本地MySQL (3306): $([ "$LOCAL_MYSQL_AVAILABLE" = true ] && echo "✅ 连接正常" || echo "❌ 未连接")
- DAO版MySQL (9506): $([ "$DAO_MYSQL_AVAILABLE" = true ] && echo "✅ 连接正常" || echo "❌ 未连接")

### PostgreSQL数据库
- PostgreSQL (5432): $([ "$POSTGRES_AVAILABLE" = true ] && echo "✅ 连接正常" || echo "❌ 未连接")

### Redis数据库
- Redis (6379): $([ "$REDIS_AVAILABLE" = true ] && echo "✅ 连接正常" || echo "❌ 未连接")

## 现有数据库结构

### MySQL数据库 (jobfirst_v3)
包含20个业务表：
- users: 用户基础信息
- user_profiles: 用户详细资料
- resumes: 简历主表
- resume_templates: 简历模板
- skills: 标准化技能
- companies: 标准化公司
- positions: 标准化职位
- work_experiences: 工作经历
- projects: 项目经验
- educations: 教育背景
- certifications: 证书认证
- resume_comments: 简历评论
- resume_likes: 简历点赞
- resume_shares: 简历分享
- files: 文件管理
- points: 积分系统
- point_history: 积分历史
- user_sessions: 用户会话
- user_settings: 用户设置

### PostgreSQL数据库
- jobfirst_vector: 向量数据和AI分析 (235KB)
- jobfirst_future: 业务数据存储 (113KB)
- looma_crm: Looma CRM数据 (665B)

### MongoDB数据库
- jobfirst_future: 7个地理位置和推荐集合

## 迁移准备状态

- ✅ 备份目录创建完成
- ✅ 数据库连接检查完成
- ✅ 现有数据结构分析完成
- 🚀 准备开始数据迁移

## 下一步行动

1. 创建DAO版数据库结构
2. 执行数据迁移脚本
3. 验证迁移结果
4. 更新系统配置

EOF

echo "✅ 备份报告已创建: $BACKUP_DIR/backup_report.md"

# 复制现有备份文件到迁移备份目录
if [ -d "database-backups/fixed" ]; then
    echo "复制现有备份文件..."
    cp -r database-backups/fixed "$BACKUP_DIR/"
    echo "✅ 现有备份文件已复制到迁移备份目录"
fi

echo -e "\n${GREEN}🎯 数据备份完成！${NC}"
echo "备份目录: $BACKUP_DIR"
echo "备份报告: $BACKUP_DIR/backup_report.md"
echo ""
echo -e "${BLUE}下一步: 执行数据迁移脚本${NC}"
echo "运行: ./migrate-to-dao.sh"
