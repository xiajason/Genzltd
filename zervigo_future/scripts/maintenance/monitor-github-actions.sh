#!/bin/bash

# GitHub Actions 监控脚本
# 用于监控CI/CD部署状态

echo "=== GitHub Actions 监控脚本 ==="
echo "仓库: xiajason/zervi-basic"
echo "时间: $(date)"

echo ""
echo "🌐 请访问以下链接查看详细状态："
echo "   GitHub Actions: https://github.com/xiajason/zervi-basic/actions"
echo ""

echo "📊 检查最近的workflow执行情况..."

# 尝试获取最新的workflow状态
LATEST_RUN=$(curl -s "https://api.github.com/repos/xiajason/zervi-basic/actions/runs?per_page=1" 2>/dev/null)

if [ $? -eq 0 ] && [ -n "$LATEST_RUN" ]; then
    echo "✅ GitHub API连接成功"
    
    # 检查是否有workflow runs
    RUN_COUNT=$(echo "$LATEST_RUN" | jq '.total_count // 0' 2>/dev/null || echo "0")
    
    if [ "$RUN_COUNT" -gt 0 ]; then
        echo "📈 找到 $RUN_COUNT 个workflow执行记录"
        
        # 获取最新run的信息
        STATUS=$(echo "$LATEST_RUN" | jq -r '.workflow_runs[0].status // "unknown"' 2>/dev/null)
        CONCLUSION=$(echo "$LATEST_RUN" | jq -r '.workflow_runs[0].conclusion // "unknown"' 2>/dev/null)
        CREATED_AT=$(echo "$LATEST_RUN" | jq -r '.workflow_runs[0].created_at // "unknown"' 2>/dev/null)
        HTML_URL=$(echo "$LATEST_RUN" | jq -r '.workflow_runs[0].html_url // "unknown"' 2>/dev/null)
        
        echo "最新workflow状态:"
        echo "  状态: $STATUS"
        echo "  结论: $CONCLUSION"
        echo "  创建时间: $CREATED_AT"
        echo "  链接: $HTML_URL"
        
        # 根据状态给出建议
        case "$STATUS" in
            "queued")
                echo "⏳ Workflow已排队，等待执行..."
                ;;
            "in_progress")
                echo "🔄 Workflow正在执行中..."
                echo "   建议：等待执行完成，通常需要5-15分钟"
                ;;
            "completed")
                case "$CONCLUSION" in
                    "success")
                        echo "✅ Workflow执行成功！"
                        echo "   🎉 部署可能已完成，请检查阿里云服务器"
                        ;;
                    "failure")
                        echo "❌ Workflow执行失败"
                        echo "   建议：查看详细日志，修复问题后重新推送"
                        ;;
                    "cancelled")
                        echo "⚠️ Workflow被取消"
                        ;;
                    *)
                        echo "❓ Workflow完成，但结论未知: $CONCLUSION"
                        ;;
                esac
                ;;
            *)
                echo "❓ Workflow状态未知: $STATUS"
                ;;
        esac
    else
        echo "❓ 没有找到workflow执行记录"
        echo "   可能的原因："
        echo "   - 刚刚推送，workflow还未触发"
        echo "   - GitHub Actions未启用"
        echo "   - API访问受限"
    fi
else
    echo "⚠️ 无法连接到GitHub API"
    echo "   可能的原因："
    echo "   - 网络连接问题"
    echo "   - GitHub API限制"
    echo "   - 仓库权限问题"
fi

echo ""
echo "🔧 如果需要手动触发workflow："
echo "   1. 访问: https://github.com/xiajason/zervi-basic/actions"
echo "   2. 点击 'Smart CI/CD Pipeline'"
echo "   3. 点击 'Run workflow'"
echo "   4. 选择分支和参数"

echo ""
echo "📋 下一步操作："
echo "   1. 检查GitHub Secrets是否已配置"
echo "   2. 确认阿里云服务器准备就绪"
echo "   3. 监控workflow执行进度"
echo "   4. 验证部署结果"

echo ""
echo "⏰ 监控完成时间: $(date)"
