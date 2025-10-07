#!/bin/bash

# 简历解析器综合测试脚本
# 用于验证Go解析器的解析能力和质量

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 测试结果统计
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 测试结果记录
TEST_RESULTS=()

# 记录测试结果
record_test_result() {
    local test_name="$1"
    local result="$2"
    local details="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [ "$result" = "PASS" ]; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
        log_success "测试通过: $test_name"
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
        log_error "测试失败: $test_name - $details"
    fi
    
    TEST_RESULTS+=("$test_name|$result|$details")
}

# 检查Go解析器服务状态
check_parser_service() {
    log_info "检查Go解析器服务状态..."
    
    if curl -s http://localhost:8082/health > /dev/null 2>&1; then
        log_success "Go解析器服务运行正常"
        return 0
    else
        log_error "Go解析器服务未运行或无法访问"
        return 1
    fi
}

# 测试文件上传功能
test_file_upload() {
    log_info "测试文件上传功能..."
    
    # 创建测试文件
    local test_file="/tmp/test_resume.pdf"
    echo "测试简历内容" > "$test_file"
    
    # 测试上传
    local response=$(curl -s -X POST \
        -F "file=@$test_file" \
        -F "creation_mode=upload" \
        -F "title=测试简历" \
        http://localhost:8082/api/v1/resume/resumes/upload)
    
    if echo "$response" | grep -q "resume_id"; then
        record_test_result "文件上传" "PASS" "上传成功"
        echo "$response" | jq -r '.data.resume_id'
    else
        record_test_result "文件上传" "FAIL" "上传失败: $response"
        return 1
    fi
}

# 测试PDF文件解析
test_pdf_parsing() {
    log_info "测试PDF文件解析..."
    
    # 创建测试PDF文件（简单文本）
    local test_file="/tmp/test_resume.pdf"
    echo "姓名: 张三
电话: 13800138000
邮箱: zhangsan@example.com
技能: Python, Java, Go
工作经历: 腾讯科技 软件工程师 2020-2023" > "$test_file"
    
    # 上传并解析
    local response=$(curl -s -X POST \
        -F "file=@$test_file" \
        -F "creation_mode=upload" \
        -F "title=PDF测试简历" \
        http://localhost:8082/api/v1/resume/resumes/upload)
    
    if echo "$response" | grep -q "resume_id"; then
        local resume_id=$(echo "$response" | jq -r '.data.resume_id')
        
        # 等待解析完成
        sleep 5
        
        # 检查解析状态
        local status_response=$(curl -s "http://localhost:8082/api/v1/resume/resumes/$resume_id/parsing-status")
        
        if echo "$status_response" | grep -q "completed"; then
            record_test_result "PDF解析" "PASS" "解析完成"
        else
            record_test_result "PDF解析" "FAIL" "解析失败: $status_response"
        fi
    else
        record_test_result "PDF解析" "FAIL" "上传失败: $response"
    fi
}

# 测试DOCX文件解析
test_docx_parsing() {
    log_info "测试DOCX文件解析..."
    
    # 创建测试DOCX文件（使用简单文本模拟）
    local test_file="/tmp/test_resume.docx"
    echo "姓名: 李四
电话: 13900139000
邮箱: lisi@example.com
技能: JavaScript, React, Node.js
工作经历: 阿里巴巴 前端工程师 2019-2022" > "$test_file"
    
    # 上传并解析
    local response=$(curl -s -X POST \
        -F "file=@$test_file" \
        -F "creation_mode=upload" \
        -F "title=DOCX测试简历" \
        http://localhost:8082/api/v1/resume/resumes/upload)
    
    if echo "$response" | grep -q "resume_id"; then
        local resume_id=$(echo "$response" | jq -r '.data.resume_id')
        
        # 等待解析完成
        sleep 5
        
        # 检查解析状态
        local status_response=$(curl -s "http://localhost:8082/api/v1/resume/resumes/$resume_id/parsing-status")
        
        if echo "$status_response" | grep -q "completed"; then
            record_test_result "DOCX解析" "PASS" "解析完成"
        else
            record_test_result "DOCX解析" "FAIL" "解析失败: $status_response"
        fi
    else
        record_test_result "DOCX解析" "FAIL" "上传失败: $response"
    fi
}

# 测试解析结果质量
test_parsing_quality() {
    log_info "测试解析结果质量..."
    
    # 获取最新的解析结果
    local latest_resume=$(mysql -u root -e "USE jobfirst; SELECT id FROM resume_metadata WHERE parsing_status = 'completed' ORDER BY created_at DESC LIMIT 1;" 2>/dev/null | tail -n 1)
    
    if [ -z "$latest_resume" ]; then
        record_test_result "解析质量" "FAIL" "没有找到已完成的解析结果"
        return 1
    fi
    
    # 检查SQLite中的解析结果
    local sqlite_db="data/users/4/resume.db"
    if [ -f "$sqlite_db" ]; then
        local parsed_data=$(sqlite3 "$sqlite_db" "SELECT personal_info, skills, confidence FROM parsed_resume_data WHERE resume_content_id = (SELECT id FROM resume_content WHERE resume_metadata_id = $latest_resume);")
        
        if [ -n "$parsed_data" ]; then
            # 检查解析结果质量
            local confidence=$(echo "$parsed_data" | cut -d'|' -f3)
            if (( $(echo "$confidence >= 0.7" | bc -l) )); then
                record_test_result "解析质量" "PASS" "置信度: $confidence"
            else
                record_test_result "解析质量" "FAIL" "置信度过低: $confidence"
            fi
        else
            record_test_result "解析质量" "FAIL" "没有找到解析数据"
        fi
    else
        record_test_result "解析质量" "FAIL" "SQLite数据库不存在"
    fi
}

# 测试AI服务集成
test_ai_service_integration() {
    log_info "测试AI服务集成..."
    
    # 检查AI服务状态
    if curl -s http://localhost:8206/health > /dev/null 2>&1; then
        log_success "AI服务运行正常"
        
        # 测试AI服务调用
        local ai_response=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -d '{"resume_id": "test", "job_description": "软件工程师"}' \
            http://localhost:8206/api/v1/job-matching)
        
        if echo "$ai_response" | grep -q "match_score"; then
            record_test_result "AI服务集成" "PASS" "AI服务调用成功"
        else
            record_test_result "AI服务集成" "FAIL" "AI服务调用失败: $ai_response"
        fi
    else
        record_test_result "AI服务集成" "FAIL" "AI服务未运行"
    fi
}

# 测试错误处理
test_error_handling() {
    log_info "测试错误处理..."
    
    # 测试无效文件上传
    local test_file="/tmp/invalid_file.txt"
    echo "这不是简历文件" > "$test_file"
    
    local response=$(curl -s -X POST \
        -F "file=@$test_file" \
        -F "creation_mode=upload" \
        -F "title=无效文件测试" \
        http://localhost:8082/api/v1/resume/resumes/upload)
    
    if echo "$response" | grep -q "error\|不支持"; then
        record_test_result "错误处理" "PASS" "正确拒绝无效文件"
    else
        record_test_result "错误处理" "FAIL" "未正确处理无效文件: $response"
    fi
}

# 生成测试报告
generate_test_report() {
    log_info "生成测试报告..."
    
    local report_file="logs/parser_test_report_$(date +%Y%m%d_%H%M%S).md"
    
    cat > "$report_file" << EOF
# 简历解析器综合测试报告

## 测试概览
- **测试时间**: $(date)
- **总测试数**: $TOTAL_TESTS
- **通过测试**: $PASSED_TESTS
- **失败测试**: $FAILED_TESTS
- **成功率**: $(echo "scale=2; $PASSED_TESTS * 100 / $TOTAL_TESTS" | bc)%

## 测试结果详情

| 测试项目 | 结果 | 详情 |
|---------|------|------|
EOF

    for result in "${TEST_RESULTS[@]}"; do
        IFS='|' read -r test_name result_status details <<< "$result"
        echo "| $test_name | $result_status | $details |" >> "$report_file"
    done
    
    cat >> "$report_file" << EOF

## 问题分析

### 主要问题
EOF

    if [ $FAILED_TESTS -gt 0 ]; then
        echo "- 发现 $FAILED_TESTS 个测试失败" >> "$report_file"
        echo "- 需要修复相关问题" >> "$report_file"
    else
        echo "- 所有测试通过" >> "$report_file"
        echo "- 系统运行正常" >> "$report_file"
    fi
    
    cat >> "$report_file" << EOF

### 建议
1. 修复失败的测试项目
2. 优化解析器性能
3. 完善错误处理机制
4. 提升解析质量

## 下一步行动
1. 根据测试结果修复问题
2. 优化解析算法
3. 完善测试用例
4. 建立持续集成测试

---
**报告生成时间**: $(date)
**测试环境**: 本地开发环境
EOF

    log_success "测试报告已生成: $report_file"
}

# 主函数
main() {
    log_info "开始简历解析器综合测试..."
    
    # 检查服务状态
    if ! check_parser_service; then
        log_error "解析器服务未运行，请先启动服务"
        exit 1
    fi
    
    # 执行测试
    test_file_upload
    test_pdf_parsing
    test_docx_parsing
    test_parsing_quality
    test_ai_service_integration
    test_error_handling
    
    # 生成报告
    generate_test_report
    
    # 输出总结
    log_info "测试完成!"
    log_info "总测试数: $TOTAL_TESTS"
    log_success "通过测试: $PASSED_TESTS"
    if [ $FAILED_TESTS -gt 0 ]; then
        log_error "失败测试: $FAILED_TESTS"
    else
        log_success "失败测试: $FAILED_TESTS"
    fi
    
    # 返回适当的退出码
    if [ $FAILED_TESTS -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

# 执行主函数
main "$@"
