#!/bin/bash

# 三环境数据一致性测试脚本
# 基于 CLUSTER_TESTING_VALIDATION_REPORT.md 和 DAO_DATABASE_VERIFICATION_REPORT.md

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1"
}

# 环境配置
LOCAL_HOST="localhost"
TENCENT_HOST="101.33.251.158"
ALIBABA_HOST="47.115.168.107"

LOCAL_PORT="3000"
TENCENT_PORT="9200"
ALIBABA_PORT="9200"

# 数据库配置
LOCAL_DB_HOST="localhost"
LOCAL_DB_PORT="3306"
TENCENT_DB_HOST="101.33.251.158"
TENCENT_DB_PORT="3306"
ALIBABA_DB_HOST="47.115.168.107"
ALIBABA_DB_PORT="3306"

# DAO数据库配置
LOCAL_DAO_PORT="9506"
TENCENT_DAO_PORT="9506"
ALIBABA_DAO_PORT="9507"

# 测试结果目录
TEST_RESULTS_DIR="data-consistency-test-results"
mkdir -p "$TEST_RESULTS_DIR"

# 测试报告文件
REPORT_FILE="$TEST_RESULTS_DIR/data-consistency-test-report.md"

# 初始化测试报告
init_report() {
    log_info "初始化测试报告..."
    cat > "$REPORT_FILE" << EOF
# 三环境数据一致性测试报告

**测试时间**: $(date '+%Y-%m-%d %H:%M:%S')  
**测试版本**: v1.0  
**测试目标**: 三环境数据一致性验证  

---

## 📊 测试环境

### 环境配置
- **本地环境**: http://$LOCAL_HOST:$LOCAL_PORT
- **腾讯云环境**: http://$TENCENT_HOST:$TENCENT_PORT  
- **阿里云环境**: http://$ALIBABA_HOST:$ALIBABA_PORT

### 数据库配置
- **本地数据库**: $LOCAL_DB_HOST:$LOCAL_DB_PORT
- **腾讯云数据库**: $TENCENT_DB_HOST:$TENCENT_DB_PORT
- **阿里云数据库**: $ALIBABA_DB_HOST:$ALIBABA_DB_PORT

### DAO数据库配置
- **本地DAO数据库**: $LOCAL_DB_HOST:$LOCAL_DAO_PORT
- **腾讯云DAO数据库**: $TENCENT_DB_HOST:$TENCENT_DAO_PORT
- **阿里云DAO数据库**: $ALIBABA_DB_HOST:$ALIBABA_DAO_PORT

---

## 🔍 测试结果

EOF
}

# 检查环境连通性
check_connectivity() {
    log_info "检查三环境连通性..."
    
    local connectivity_results=()
    
    # 检查本地环境
    if curl -s --connect-timeout 5 "http://$LOCAL_HOST:$LOCAL_PORT" > /dev/null 2>&1; then
        log_success "本地环境连通正常"
        connectivity_results+=("✅ 本地环境: 连通正常")
    else
        log_error "本地环境连通失败"
        connectivity_results+=("❌ 本地环境: 连通失败")
    fi
    
    # 检查腾讯云环境
    if curl -s --connect-timeout 10 "http://$TENCENT_HOST:$TENCENT_PORT" > /dev/null 2>&1; then
        log_success "腾讯云环境连通正常"
        connectivity_results+=("✅ 腾讯云环境: 连通正常")
    else
        log_error "腾讯云环境连通失败"
        connectivity_results+=("❌ 腾讯云环境: 连通失败")
    fi
    
    # 检查阿里云环境
    if curl -s --connect-timeout 10 "http://$ALIBABA_HOST:$ALIBABA_PORT" > /dev/null 2>&1; then
        log_success "阿里云环境连通正常"
        connectivity_results+=("✅ 阿里云环境: 连通正常")
    else
        log_error "阿里云环境连通失败"
        connectivity_results+=("❌ 阿里云环境: 连通失败")
    fi
    
    # 记录连通性结果
    cat >> "$REPORT_FILE" << EOF

### 1. 环境连通性检查

\`\`\`
$(printf '%s\n' "${connectivity_results[@]}")
\`\`\`

EOF
}

# 检查数据库连接
check_database_connection() {
    log_info "检查数据库连接..."
    
    local db_results=()
    
    # 检查本地数据库
    if mysql -h "$LOCAL_DB_HOST" -P "$LOCAL_DB_PORT" -u root -p123456 -e "SELECT 1" > /dev/null 2>&1; then
        log_success "本地数据库连接正常"
        db_results+=("✅ 本地数据库: 连接正常")
    else
        log_error "本地数据库连接失败"
        db_results+=("❌ 本地数据库: 连接失败")
    fi
    
    # 检查腾讯云数据库
    if mysql -h "$TENCENT_DB_HOST" -P "$TENCENT_DB_PORT" -u root -p123456 -e "SELECT 1" > /dev/null 2>&1; then
        log_success "腾讯云数据库连接正常"
        db_results+=("✅ 腾讯云数据库: 连接正常")
    else
        log_error "腾讯云数据库连接失败"
        db_results+=("❌ 腾讯云数据库: 连接失败")
    fi
    
    # 检查阿里云数据库
    if mysql -h "$ALIBABA_DB_HOST" -P "$ALIBABA_DB_PORT" -u root -p123456 -e "SELECT 1" > /dev/null 2>&1; then
        log_success "阿里云数据库连接正常"
        db_results+=("✅ 阿里云数据库: 连接正常")
    else
        log_error "阿里云数据库连接失败"
        db_results+=("❌ 阿里云数据库: 连接失败")
    fi
    
    # 记录数据库连接结果
    cat >> "$REPORT_FILE" << EOF

### 2. 数据库连接检查

\`\`\`
$(printf '%s\n' "${db_results[@]}")
\`\`\`

EOF
}

# 检查数据库表结构一致性
check_database_schema() {
    log_info "检查数据库表结构一致性..."
    
    local schema_results=()
    
    # 获取本地数据库表结构
    local local_tables=$(mysql -h "$LOCAL_DB_HOST" -P "$LOCAL_DB_PORT" -u root -p123456 -e "SHOW TABLES" 2>/dev/null | tail -n +2 | sort)
    local tencent_tables=$(mysql -h "$TENCENT_DB_HOST" -P "$TENCENT_DB_PORT" -u root -p123456 -e "SHOW TABLES" 2>/dev/null | tail -n +2 | sort)
    local alibaba_tables=$(mysql -h "$ALIBABA_DB_HOST" -P "$ALIBABA_DB_PORT" -u root -p123456 -e "SHOW TABLES" 2>/dev/null | tail -n +2 | sort)
    
    # 比较表结构
    if [ "$local_tables" = "$tencent_tables" ] && [ "$local_tables" = "$alibaba_tables" ]; then
        log_success "数据库表结构一致性检查通过"
        schema_results+=("✅ 表结构一致性: 通过")
    else
        log_error "数据库表结构不一致"
        schema_results+=("❌ 表结构一致性: 不一致")
        
        # 详细比较
        log_info "本地环境表: $(echo "$local_tables" | wc -l) 个"
        log_info "腾讯云环境表: $(echo "$tencent_tables" | wc -l) 个"
        log_info "阿里云环境表: $(echo "$alibaba_tables" | wc -l) 个"
    fi
    
    # 记录表结构检查结果
    cat >> "$REPORT_FILE" << EOF

### 3. 数据库表结构一致性检查

\`\`\`
$(printf '%s\n' "${schema_results[@]}")
\`\`\`

#### 表结构详情
- **本地环境表数量**: $(echo "$local_tables" | wc -l)
- **腾讯云环境表数量**: $(echo "$tencent_tables" | wc -l)
- **阿里云环境表数量**: $(echo "$alibaba_tables" | wc -l)

\`\`\`yaml
本地环境表列表:
$(echo "$local_tables" | sed 's/^/  - /')

腾讯云环境表列表:
$(echo "$tencent_tables" | sed 's/^/  - /')

阿里云环境表列表:
$(echo "$alibaba_tables" | sed 's/^/  - /')
\`\`\`

EOF
}

# 检查API数据一致性
check_api_consistency() {
    log_info "检查API数据一致性..."
    
    local api_results=()
    
    # 测试API端点
    local api_endpoints=(
        "/api/health"
        "/api/trpc/daoConfig.getDAOTypes"
        "/api/users"
    )
    
    for endpoint in "${api_endpoints[@]}"; do
        log_info "测试端点: $endpoint"
        
        # 获取各环境响应
        local local_response=$(curl -s --connect-timeout 5 "http://$LOCAL_HOST:$LOCAL_PORT$endpoint" 2>/dev/null || echo "ERROR")
        local tencent_response=$(curl -s --connect-timeout 10 "http://$TENCENT_HOST:$TENCENT_PORT$endpoint" 2>/dev/null || echo "ERROR")
        local alibaba_response=$(curl -s --connect-timeout 10 "http://$ALIBABA_HOST:$ALIBABA_PORT$endpoint" 2>/dev/null || echo "ERROR")
        
        # 比较响应
        if [ "$local_response" = "$tencent_response" ] && [ "$local_response" = "$alibaba_response" ]; then
            log_success "API端点 $endpoint 响应一致"
            api_results+=("✅ $endpoint: 响应一致")
        else
            log_warning "API端点 $endpoint 响应不一致"
            api_results+=("⚠️ $endpoint: 响应不一致")
        fi
    done
    
    # 记录API一致性检查结果
    cat >> "$REPORT_FILE" << EOF

### 4. API数据一致性检查

\`\`\`
$(printf '%s\n' "${api_results[@]}")
\`\`\`

EOF
}

# 检查DAO数据库一致性
check_dao_database_consistency() {
    log_info "检查DAO数据库一致性..."
    
    local dao_results=()
    
    # 检查DAO数据库表
    local dao_tables=("dao_configs" "dao_settings" "dao_members" "dao_proposals")
    
    for table in "${dao_tables[@]}"; do
        log_info "检查DAO表: $table"
        
        # 检查本地DAO数据库
        local local_count=$(mysql -h "$LOCAL_DB_HOST" -P "$LOCAL_DAO_PORT" -u dao_user -pdao_password_2024 -e "SELECT COUNT(*) FROM $table" 2>/dev/null | tail -1 || echo "0")
        local tencent_count=$(mysql -h "$TENCENT_DB_HOST" -P "$TENCENT_DAO_PORT" -u dao_user -pdao_password_2024 -e "SELECT COUNT(*) FROM $table" 2>/dev/null | tail -1 || echo "0")
        local alibaba_count=$(mysql -h "$ALIBABA_DB_HOST" -P "$ALIBABA_DAO_PORT" -u dao_user -pdao_password_2024 -e "SELECT COUNT(*) FROM $table" 2>/dev/null | tail -1 || echo "0")
        
        if [ "$local_count" = "$tencent_count" ] && [ "$local_count" = "$alibaba_count" ]; then
            log_success "DAO表 $table 数据一致 ($local_count 条记录)"
            dao_results+=("✅ $table: 数据一致 ($local_count 条记录)")
        else
            log_warning "DAO表 $table 数据不一致 (本地:$local_count, 腾讯云:$tencent_count, 阿里云:$alibaba_count)"
            dao_results+=("⚠️ $table: 数据不一致 (本地:$local_count, 腾讯云:$tencent_count, 阿里云:$alibaba_count)")
        fi
    done
    
    # 记录DAO数据库一致性检查结果
    cat >> "$REPORT_FILE" << EOF

### 5. DAO数据库一致性检查

\`\`\`
$(printf '%s\n' "${dao_results[@]}")
\`\`\`

EOF
}

# 生成测试总结
generate_summary() {
    log_info "生成测试总结..."
    
    local total_tests=0
    local passed_tests=0
    
    # 统计测试结果
    if grep -q "✅" "$REPORT_FILE"; then
        passed_tests=$((passed_tests + $(grep -c "✅" "$REPORT_FILE")))
    fi
    total_tests=$((total_tests + $(grep -c -E "(✅|❌|⚠️)" "$REPORT_FILE")))
    
    local pass_rate=0
    if [ $total_tests -gt 0 ]; then
        pass_rate=$((passed_tests * 100 / total_tests))
    fi
    
    # 添加测试总结
    cat >> "$REPORT_FILE" << EOF

---

## 📊 测试总结

### 测试统计
- **总测试项**: $total_tests
- **通过测试**: $passed_tests
- **通过率**: $pass_rate%

### 测试结论
EOF

    if [ $pass_rate -ge 90 ]; then
        log_success "数据一致性测试通过率: $pass_rate%"
        cat >> "$REPORT_FILE" << EOF
- ✅ **测试通过**: 数据一致性良好
- ✅ **系统状态**: 三环境数据同步正常
- ✅ **建议**: 可以继续后续测试
EOF
    elif [ $pass_rate -ge 70 ]; then
        log_warning "数据一致性测试通过率: $pass_rate%"
        cat >> "$REPORT_FILE" << EOF
- ⚠️ **测试部分通过**: 存在少量不一致项
- ⚠️ **系统状态**: 需要修复不一致项
- ⚠️ **建议**: 修复问题后重新测试
EOF
    else
        log_error "数据一致性测试通过率: $pass_rate%"
        cat >> "$REPORT_FILE" << EOF
- ❌ **测试未通过**: 存在严重不一致问题
- ❌ **系统状态**: 需要全面检查和修复
- ❌ **建议**: 停止后续测试，优先修复问题
EOF
    fi
    
    cat >> "$REPORT_FILE" << EOF

---

**测试完成时间**: $(date '+%Y-%m-%d %H:%M:%S')  
**测试报告**: $REPORT_FILE  
**下一步**: 根据测试结果决定后续行动

EOF
}

# 主函数
main() {
    log_info "开始三环境数据一致性测试..."
    log_info "测试结果将保存到: $TEST_RESULTS_DIR"
    
    # 初始化测试报告
    init_report
    
    # 执行各项测试
    check_connectivity
    check_database_connection
    check_database_schema
    check_api_consistency
    check_dao_database_consistency
    
    # 生成测试总结
    generate_summary
    
    log_success "数据一致性测试完成！"
    log_info "测试报告: $REPORT_FILE"
    
    # 显示测试报告摘要
    echo ""
    log_info "=== 测试报告摘要 ==="
    tail -20 "$REPORT_FILE"
}

# 执行主函数
main "$@"
