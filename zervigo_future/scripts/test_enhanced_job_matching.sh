#!/bin/bash
# 增强版职位匹配功能测试脚本
# 基于Resume-Matcher最佳实践的完整测试

echo "=== 🚀 增强版职位匹配功能测试 ==="
echo "测试目标: 验证基于Resume-Matcher的职位匹配算法"
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 测试配置
JOB_SERVICE_URL="http://localhost:8089"
AI_SERVICE_URL="http://localhost:8208"
AUTH_SERVICE_URL="http://localhost:8207"

# 测试用户信息
TEST_USER="szjason72"
TEST_PASSWORD="@SZxym2006"

echo -e "${BLUE}📋 测试配置:${NC}"
echo "  Job服务: $JOB_SERVICE_URL"
echo "  AI服务: $AI_SERVICE_URL"
echo "  认证服务: $AUTH_SERVICE_URL"
echo "  测试用户: $TEST_USER"
echo ""

# 1. 获取认证Token
echo -e "${YELLOW}1. 获取认证Token...${NC}"
TOKEN=$(curl -s -X POST $AUTH_SERVICE_URL/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"username\": \"$TEST_USER\", \"password\": \"$TEST_PASSWORD\"}" | \
  jq -r '.token')

if [ "$TOKEN" = "null" ] || [ -z "$TOKEN" ]; then
    echo -e "${RED}❌ 获取Token失败${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Token获取成功: ${TOKEN:0:50}...${NC}"

# 2. 测试AI服务健康状态
echo ""
echo -e "${YELLOW}2. 测试AI服务健康状态...${NC}"
AI_HEALTH=$(curl -s $AI_SERVICE_URL/health | jq -r '.status')
if [ "$AI_HEALTH" = "healthy" ]; then
    echo -e "${GREEN}✅ AI服务健康状态正常${NC}"
else
    echo -e "${RED}❌ AI服务健康状态异常: $AI_HEALTH${NC}"
    exit 1
fi

# 3. 测试Job服务健康状态
echo ""
echo -e "${YELLOW}3. 测试Job服务健康状态...${NC}"
JOB_HEALTH=$(curl -s $JOB_SERVICE_URL/health | jq -r '.status')
if [ "$JOB_HEALTH" = "healthy" ]; then
    echo -e "${GREEN}✅ Job服务健康状态正常${NC}"
else
    echo -e "${RED}❌ Job服务健康状态异常: $JOB_HEALTH${NC}"
    exit 1
fi

# 4. 测试基础职位匹配功能
echo ""
echo -e "${YELLOW}4. 测试基础职位匹配功能...${NC}"
MATCH_RESULT=$(curl -s -X POST $JOB_SERVICE_URL/api/v1/job/matching/jobs \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"resume_id": 1, "limit": 5}' | \
  jq -r '.success')

if [ "$MATCH_RESULT" = "true" ]; then
    echo -e "${GREEN}✅ 基础职位匹配功能正常${NC}"
else
    echo -e "${RED}❌ 基础职位匹配功能异常${NC}"
    echo "响应: $(curl -s -X POST $JOB_SERVICE_URL/api/v1/job/matching/jobs \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $TOKEN" \
      -d '{"resume_id": 1, "limit": 5}')"
fi

# 5. 测试AI服务嵌入向量生成
echo ""
echo -e "${YELLOW}5. 测试AI服务嵌入向量生成...${NC}"
EMBEDDING_RESULT=$(curl -s -X POST $AI_SERVICE_URL/api/v1/ai/embedding \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"text": "具有5年Python开发经验，熟悉Docker和Kubernetes"}' | \
  jq -r '.success // false')

if [ "$EMBEDDING_RESULT" = "true" ]; then
    echo -e "${GREEN}✅ 嵌入向量生成功能正常${NC}"
else
    echo -e "${RED}❌ 嵌入向量生成功能异常${NC}"
fi

# 6. 测试AI服务简历分析
echo ""
echo -e "${YELLOW}6. 测试AI服务简历分析...${NC}"
RESUME_ANALYSIS=$(curl -s -X POST $AI_SERVICE_URL/api/v1/ai/resume-analysis \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "name": "张三",
    "email": "zhangsan@example.com",
    "summary": "具有5年软件开发经验，熟悉Python、Java等编程语言",
    "experience": [
      {
        "title": "高级软件工程师",
        "company": "ABC科技有限公司",
        "description": "负责后端系统开发和维护"
      }
    ],
    "skills": ["Python", "Java", "MySQL", "Docker", "团队协作"]
  }' | \
  jq -r '.success // false')

if [ "$RESUME_ANALYSIS" = "true" ]; then
    echo -e "${GREEN}✅ 简历分析功能正常${NC}"
else
    echo -e "${RED}❌ 简历分析功能异常${NC}"
fi

# 7. 测试AI服务职位匹配
echo ""
echo -e "${YELLOW}7. 测试AI服务职位匹配...${NC}"
AI_MATCHING=$(curl -s -X POST $AI_SERVICE_URL/api/v1/ai/job-matching \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"limit": 3}' | \
  jq -r '.success // false')

if [ "$AI_MATCHING" = "true" ]; then
    echo -e "${GREEN}✅ AI服务职位匹配功能正常${NC}"
else
    echo -e "${RED}❌ AI服务职位匹配功能异常${NC}"
fi

# 8. 测试匹配历史查询
echo ""
echo -e "${YELLOW}8. 测试匹配历史查询...${NC}"
HISTORY_RESULT=$(curl -s -X GET $JOB_SERVICE_URL/api/v1/job/matching/history \
  -H "Authorization: Bearer $TOKEN" | \
  jq -r '.success // false')

if [ "$HISTORY_RESULT" = "true" ]; then
    echo -e "${GREEN}✅ 匹配历史查询功能正常${NC}"
else
    echo -e "${RED}❌ 匹配历史查询功能异常${NC}"
fi

# 9. 测试匹配统计查询
echo ""
echo -e "${YELLOW}9. 测试匹配统计查询...${NC}"
STATS_RESULT=$(curl -s -X GET $JOB_SERVICE_URL/api/v1/job/matching/stats \
  -H "Authorization: Bearer $TOKEN" | \
  jq -r '.success // false')

if [ "$STATS_RESULT" = "true" ]; then
    echo -e "${GREEN}✅ 匹配统计查询功能正常${NC}"
else
    echo -e "${RED}❌ 匹配统计查询功能异常${NC}"
fi

# 10. 性能测试 - 并发匹配请求
echo ""
echo -e "${YELLOW}10. 性能测试 - 并发匹配请求...${NC}"
echo "发送5个并发匹配请求..."

# 创建临时文件存储结果
TEMP_DIR=$(mktemp -d)
for i in {1..5}; do
    curl -s -X POST $JOB_SERVICE_URL/api/v1/job/matching/jobs \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $TOKEN" \
      -d "{\"resume_id\": 1, \"limit\": 3}" \
      -o "$TEMP_DIR/result_$i.json" &
done

# 等待所有请求完成
wait

# 检查结果
SUCCESS_COUNT=0
for i in {1..5}; do
    if [ -f "$TEMP_DIR/result_$i.json" ]; then
        SUCCESS=$(jq -r '.success // false' "$TEMP_DIR/result_$i.json")
        if [ "$SUCCESS" = "true" ]; then
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        fi
    fi
done

# 清理临时文件
rm -rf "$TEMP_DIR"

if [ $SUCCESS_COUNT -eq 5 ]; then
    echo -e "${GREEN}✅ 并发性能测试通过 (5/5)${NC}"
else
    echo -e "${YELLOW}⚠️  并发性能测试部分通过 ($SUCCESS_COUNT/5)${NC}"
fi

# 11. 测试结果汇总
echo ""
echo -e "${BLUE}📊 测试结果汇总:${NC}"
echo "=================================="

# 统计测试结果
TOTAL_TESTS=10
PASSED_TESTS=0

# 检查各项测试结果
if [ "$AI_HEALTH" = "healthy" ]; then PASSED_TESTS=$((PASSED_TESTS + 1)); fi
if [ "$JOB_HEALTH" = "healthy" ]; then PASSED_TESTS=$((PASSED_TESTS + 1)); fi
if [ "$MATCH_RESULT" = "true" ]; then PASSED_TESTS=$((PASSED_TESTS + 1)); fi
if [ "$EMBEDDING_RESULT" = "true" ]; then PASSED_TESTS=$((PASSED_TESTS + 1)); fi
if [ "$RESUME_ANALYSIS" = "true" ]; then PASSED_TESTS=$((PASSED_TESTS + 1)); fi
if [ "$AI_MATCHING" = "true" ]; then PASSED_TESTS=$((PASSED_TESTS + 1)); fi
if [ "$HISTORY_RESULT" = "true" ]; then PASSED_TESTS=$((PASSED_TESTS + 1)); fi
if [ "$STATS_RESULT" = "true" ]; then PASSED_TESTS=$((PASSED_TESTS + 1)); fi
if [ $SUCCESS_COUNT -ge 3 ]; then PASSED_TESTS=$((PASSED_TESTS + 1)); fi

echo "总测试数: $TOTAL_TESTS"
echo "通过测试: $PASSED_TESTS"
echo "成功率: $((PASSED_TESTS * 100 / TOTAL_TESTS))%"

if [ $PASSED_TESTS -eq $TOTAL_TESTS ]; then
    echo -e "${GREEN}🎉 所有测试通过！增强版职位匹配功能运行正常。${NC}"
    exit 0
elif [ $PASSED_TESTS -ge 7 ]; then
    echo -e "${YELLOW}⚠️  大部分测试通过，系统基本功能正常。${NC}"
    exit 0
else
    echo -e "${RED}❌ 多项测试失败，请检查系统配置。${NC}"
    exit 1
fi
