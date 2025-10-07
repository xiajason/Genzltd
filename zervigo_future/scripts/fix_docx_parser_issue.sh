#!/bin/bash

# 修复DOCX解析器问题脚本
# 解决DOCX文件被误识别为PDF的问题

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

# 检查Go解析器代码
check_parser_code() {
    log_info "检查Go解析器代码..."
    
    local parser_file="backend/internal/resume/file_parser.go"
    
    if [ ! -f "$parser_file" ]; then
        log_error "解析器文件不存在: $parser_file"
        return 1
    fi
    
    log_success "找到解析器文件: $parser_file"
    return 0
}

# 分析当前问题
analyze_current_issue() {
    log_info "分析当前DOCX解析问题..."
    
    # 检查最近的错误日志
    local error_logs=$(mysql -u root -e "USE jobfirst; SELECT parsing_error FROM resume_metadata WHERE parsing_error LIKE '%PDF%' ORDER BY created_at DESC LIMIT 5;" 2>/dev/null | tail -n +2)
    
    if [ -n "$error_logs" ]; then
        log_warning "发现DOCX文件被误识别为PDF的错误:"
        echo "$error_logs"
    else
        log_info "没有发现相关错误日志"
    fi
}

# 修复文件类型检测
fix_file_type_detection() {
    log_info "修复文件类型检测逻辑..."
    
    local parser_file="backend/internal/resume/file_parser.go"
    
    # 备份原文件
    cp "$parser_file" "${parser_file}.backup.$(date +%Y%m%d_%H%M%S)"
    log_success "已备份原文件"
    
    # 检查是否已有正确的文件类型检测
    if grep -q "detectFileType" "$parser_file"; then
        log_info "文件类型检测函数已存在"
    else
        log_info "添加文件类型检测函数..."
        
        # 在文件开头添加文件类型检测函数
        cat > /tmp/file_type_detection.go << 'EOF'
// 文件类型检测函数
func detectFileType(filePath string) (string, error) {
    file, err := os.Open(filePath)
    if err != nil {
        return "", err
    }
    defer file.Close()
    
    // 读取文件头
    header := make([]byte, 512)
    _, err = file.Read(header)
    if err != nil {
        return "", err
    }
    
    // 检测文件类型
    if bytes.HasPrefix(header, []byte{0x50, 0x4B}) {
        return "docx", nil
    } else if bytes.HasPrefix(header, []byte{0x25, 0x50, 0x44, 0x46}) {
        return "pdf", nil
    } else if bytes.HasPrefix(header, []byte{0xD0, 0xCF, 0x11, 0xE0}) {
        return "doc", nil
    }
    
    return "", errors.New("不支持的文件格式")
}
EOF
        
        # 将函数插入到文件中
        sed -i '/^package main/a\
\
// 文件类型检测函数\
func detectFileType(filePath string) (string, error) {\
    file, err := os.Open(filePath)\
    if err != nil {\
        return "", err\
    }\
    defer file.Close()\
    \
    // 读取文件头\
    header := make([]byte, 512)\
    _, err = file.Read(header)\
    if err != nil {\
        return "", err\
    }\
    \
    // 检测文件类型\
    if bytes.HasPrefix(header, []byte{0x50, 0x4B}) {\
        return "docx", nil\
    } else if bytes.HasPrefix(header, []byte{0x25, 0x50, 0x44, 0x46}) {\
        return "pdf", nil\
    } else if bytes.HasPrefix(header, []byte{0xD0, 0xCF, 0x11, 0xE0}) {\
        return "doc", nil\
    }\
    \
    return "", errors.New("不支持的文件格式")\
}' "$parser_file"
        
        log_success "已添加文件类型检测函数"
    fi
}

# 修复解析器路由逻辑
fix_parser_routing() {
    log_info "修复解析器路由逻辑..."
    
    local parser_file="backend/internal/resume/file_parser.go"
    
    # 检查是否有正确的路由逻辑
    if grep -q "detectFileType" "$parser_file" && grep -q "switch.*fileType" "$parser_file"; then
        log_info "解析器路由逻辑已存在"
    else
        log_info "修复解析器路由逻辑..."
        
        # 查找并替换解析逻辑
        sed -i 's/\/\/ 根据文件扩展名选择解析器/\/\/ 根据文件类型选择解析器\
    fileType, err := detectFileType(filePath)\
    if err != nil {\
        return nil, fmt.Errorf("文件类型检测失败: %v", err)\
    }\
    \
    switch fileType {/' "$parser_file"
        
        log_success "已修复解析器路由逻辑"
    fi
}

# 添加必要的导入
add_required_imports() {
    log_info "添加必要的导入..."
    
    local parser_file="backend/internal/resume/file_parser.go"
    
    # 检查是否已有必要的导入
    if grep -q "bytes" "$parser_file" && grep -q "os" "$parser_file"; then
        log_info "必要的导入已存在"
    else
        log_info "添加必要的导入..."
        
        # 在import部分添加必要的包
        sed -i '/^import (/a\
    "bytes"\
    "os"' "$parser_file"
        
        log_success "已添加必要的导入"
    fi
}

# 测试修复效果
test_fix() {
    log_info "测试修复效果..."
    
    # 重新编译解析器
    log_info "重新编译解析器..."
    cd backend/internal/resume
    go build -o file_parser_test file_parser.go
    cd ../../..
    
    if [ $? -eq 0 ]; then
        log_success "解析器编译成功"
    else
        log_error "解析器编译失败"
        return 1
    fi
    
    # 重启Resume服务
    log_info "重启Resume服务..."
    pkill -f "resume-service" || true
    sleep 2
    
    # 启动服务
    cd backend
    nohup ./resume-service > ../logs/resume-service.log 2>&1 &
    cd ..
    
    sleep 5
    
    # 检查服务状态
    if curl -s http://localhost:8082/health > /dev/null 2>&1; then
        log_success "Resume服务重启成功"
    else
        log_error "Resume服务重启失败"
        return 1
    fi
}

# 验证修复
verify_fix() {
    log_info "验证修复效果..."
    
    # 创建测试DOCX文件
    local test_file="/tmp/test_fix.docx"
    echo "姓名: 测试用户
电话: 13800138000
邮箱: test@example.com
技能: Python, Java, Go" > "$test_file"
    
    # 测试上传
    local response=$(curl -s -X POST \
        -F "file=@$test_file" \
        -F "creation_mode=upload" \
        -F "title=修复测试" \
        http://localhost:8082/api/v1/resume/resumes/upload)
    
    if echo "$response" | grep -q "resume_id"; then
        local resume_id=$(echo "$response" | jq -r '.data.resume_id')
        log_success "文件上传成功，简历ID: $resume_id"
        
        # 等待解析
        sleep 5
        
        # 检查解析状态
        local status_response=$(curl -s "http://localhost:8082/api/v1/resume/resumes/$resume_id/parsing-status")
        
        if echo "$status_response" | grep -q "completed"; then
            log_success "DOCX文件解析成功！"
            return 0
        elif echo "$status_response" | grep -q "failed"; then
            log_error "DOCX文件解析仍然失败"
            echo "错误信息: $status_response"
            return 1
        else
            log_warning "解析状态未知: $status_response"
            return 1
        fi
    else
        log_error "文件上传失败: $response"
        return 1
    fi
}

# 清理失败的解析记录
cleanup_failed_records() {
    log_info "清理失败的解析记录..."
    
    # 清理MySQL中的失败记录
    mysql -u root -e "USE jobfirst; UPDATE resume_metadata SET parsing_status = 'pending' WHERE parsing_status = 'failed' AND parsing_error LIKE '%PDF%';" 2>/dev/null
    
    log_success "已清理失败的解析记录"
}

# 主函数
main() {
    log_info "开始修复DOCX解析器问题..."
    
    # 检查解析器代码
    if ! check_parser_code; then
        log_error "无法找到解析器代码文件"
        exit 1
    fi
    
    # 分析当前问题
    analyze_current_issue
    
    # 修复文件类型检测
    fix_file_type_detection
    
    # 添加必要的导入
    add_required_imports
    
    # 修复解析器路由逻辑
    fix_parser_routing
    
    # 测试修复效果
    if test_fix; then
        log_success "修复测试通过"
    else
        log_error "修复测试失败"
        exit 1
    fi
    
    # 验证修复
    if verify_fix; then
        log_success "DOCX解析器问题修复成功！"
    else
        log_error "DOCX解析器问题修复失败"
        exit 1
    fi
    
    # 清理失败的解析记录
    cleanup_failed_records
    
    log_success "所有修复完成！"
}

# 执行主函数
main "$@"
