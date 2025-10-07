#!/bin/bash
# Job Service 修复验证脚本

echo "=== 验证Job Service修复结果 ==="

# 1. 获取szjason72用户token
echo "1. 获取用户token..."
TOKEN=$(curl -s -X POST http://localhost:8207/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "szjason72", "password": "@SZxym2006"}' | \
  jq -r '.token')

if [ "$TOKEN" = "null" ] || [ -z "$TOKEN" ]; then
    echo "❌ 获取token失败"
    exit 1
fi
echo "✅ Token获取成功: ${TOKEN:0:50}..."

# 2. 测试职位申请功能
echo ""
echo "2. 测试职位申请功能..."
APPLY_RESULT=$(curl -s -X POST http://localhost:8089/api/v1/job/jobs/3/apply \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"resume_id": 1, "cover_letter": "我对这个职位很感兴趣"}' | \
  jq -r '.success')

if [ "$APPLY_RESULT" = "true" ]; then
    echo "✅ 职位申请功能正常"
else
    echo "❌ 职位申请功能异常"
    echo "响应: $(curl -s -X POST http://localhost:8089/api/v1/job/jobs/3/apply \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $TOKEN" \
      -d '{"resume_id": 1, "cover_letter": "我对这个职位很感兴趣"}')"
fi

# 3. 测试职位详情查询
echo ""
echo "3. 测试职位详情查询..."
DETAIL_RESULT=$(curl -s -X GET http://localhost:8089/api/v1/job/public/jobs/3 \
  -H "Authorization: Bearer $TOKEN" | \
  jq -r '.success')

if [ "$DETAIL_RESULT" = "true" ]; then
    echo "✅ 职位详情查询正常"
else
    echo "❌ 职位详情查询异常"
    echo "响应: $(curl -s -X GET http://localhost:8089/api/v1/job/public/jobs/3 \
      -H "Authorization: Bearer $TOKEN")"
fi

# 4. 测试AI智能匹配
echo ""
echo "4. 测试AI智能匹配..."
MATCH_RESULT=$(curl -s -X POST http://localhost:8089/api/v1/job/matching/jobs \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"resume_id": 1, "limit": 3}' | \
  jq -r '.success')

if [ "$MATCH_RESULT" = "true" ]; then
    echo "✅ AI智能匹配功能正常"
else
    echo "❌ AI智能匹配功能异常"
    echo "响应: $(curl -s -X POST http://localhost:8089/api/v1/job/matching/jobs \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $TOKEN" \
      -d '{"resume_id": 1, "limit": 3}')"
fi

# 5. 测试数据库表
echo ""
echo "5. 验证数据库表..."
RESUME_COUNT=$(mysql -u root jobfirst -e "SELECT COUNT(*) FROM resume_metadata WHERE user_id = 4;" -s -N)
COMPANY_COUNT=$(mysql -u root jobfirst -e "SELECT COUNT(*) FROM company_infos;" -s -N)

echo "szjason72用户的简历数量: $RESUME_COUNT"
echo "公司信息数量: $COMPANY_COUNT"

if [ "$RESUME_COUNT" -gt 0 ] && [ "$COMPANY_COUNT" -gt 0 ]; then
    echo "✅ 数据库表和数据正常"
else
    echo "❌ 数据库表或数据异常"
fi

echo ""
echo "=== 验证完成 ==="
