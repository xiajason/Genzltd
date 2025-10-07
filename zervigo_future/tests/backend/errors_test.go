package errors

import (
	"errors"
	"net/http"
	"testing"
)

func TestErrorCode(t *testing.T) {
	tests := []struct {
		code     ErrorCode
		expected string
	}{
		{ErrCodeSuccess, "操作成功"},
		{ErrCodeDatabase, "数据库错误"},
		{ErrCodeAuth, "认证错误"},
		{ErrCodeValidation, "验证错误"},
		{ErrCodeService, "服务错误"},
		{ErrCodeNetwork, "网络错误"},
		{ErrCodeConfig, "配置错误"},
		{ErrCodeFile, "文件错误"},
		{ErrCodeBusiness, "业务错误"},
	}

	for _, test := range tests {
		message := GetErrorMessage(test.code)
		if message != test.expected {
			t.Errorf("错误码 %d 的消息不匹配，期望: %s, 实际: %s", test.code, test.expected, message)
		}
	}
}

func TestHTTPStatus(t *testing.T) {
	tests := []struct {
		code     ErrorCode
		expected int
	}{
		{ErrCodeSuccess, http.StatusOK},
		{ErrCodeDatabase, http.StatusInternalServerError},
		{ErrCodeUnauthorized, http.StatusUnauthorized},
		{ErrCodeForbidden, http.StatusForbidden},
		{ErrCodeValidation, http.StatusBadRequest},
		{ErrCodeNotFound, http.StatusNotFound},
		{ErrCodeAlreadyExists, http.StatusConflict},
		{ErrCodeTimeout, http.StatusRequestTimeout},
		{ErrCodeRateLimit, http.StatusTooManyRequests},
		{ErrCodeNetwork, http.StatusBadGateway},
	}

	for _, test := range tests {
		status := GetHTTPStatus(test.code)
		if status != test.expected {
			t.Errorf("错误码 %d 的HTTP状态码不匹配，期望: %d, 实际: %d", test.code, test.expected, status)
		}
	}
}

func TestJobFirstError(t *testing.T) {
	// 测试基本错误
	err := NewError(ErrCodeDatabase, "数据库连接失败")
	if err.Code != ErrCodeDatabase {
		t.Errorf("错误码不匹配，期望: %d, 实际: %d", ErrCodeDatabase, err.Code)
	}
	if err.Message != "数据库连接失败" {
		t.Errorf("错误消息不匹配，期望: 数据库连接失败, 实际: %s", err.Message)
	}

	// 测试带详情的错误
	err = NewErrorWithDetails(ErrCodeValidation, "输入验证失败", "用户名不能为空")
	if err.Details != "用户名不能为空" {
		t.Errorf("错误详情不匹配，期望: 用户名不能为空, 实际: %s", err.Details)
	}

	// 测试包装错误
	originalErr := errors.New("原始错误")
	wrappedErr := WrapError(ErrCodeService, "服务调用失败", originalErr)
	if wrappedErr.Cause != originalErr {
		t.Error("包装错误的原因不匹配")
	}

	// 测试错误字符串
	errorStr := wrappedErr.Error()
	expectedStr := "[4000] 服务调用失败: 原始错误"
	if errorStr != expectedStr {
		t.Errorf("错误字符串不匹配，期望: %s, 实际: %s", expectedStr, errorStr)
	}
}

func TestIsJobFirstError(t *testing.T) {
	// 测试JobFirst错误
	jfErr := NewError(ErrCodeDatabase, "数据库错误")
	if !IsJobFirstError(jfErr) {
		t.Error("应该识别为JobFirst错误")
	}

	// 测试普通错误
	normalErr := errors.New("普通错误")
	if IsJobFirstError(normalErr) {
		t.Error("不应该识别为JobFirst错误")
	}
}

func TestGetErrorCode(t *testing.T) {
	// 测试JobFirst错误
	jfErr := NewError(ErrCodeAuth, "认证失败")
	code := GetErrorCode(jfErr)
	if code != ErrCodeAuth {
		t.Errorf("错误码不匹配，期望: %d, 实际: %d", ErrCodeAuth, code)
	}

	// 测试普通错误
	normalErr := errors.New("普通错误")
	code = GetErrorCode(normalErr)
	if code != ErrCodeInternal {
		t.Errorf("普通错误应该返回内部错误码，期望: %d, 实际: %d", ErrCodeInternal, code)
	}
}

func TestGetErrorDetails(t *testing.T) {
	// 测试JobFirst错误
	jfErr := NewErrorWithDetails(ErrCodeValidation, "验证失败", "详细错误信息")
	details := GetErrorDetails(jfErr)
	if details != "详细错误信息" {
		t.Errorf("错误详情不匹配，期望: 详细错误信息, 实际: %s", details)
	}

	// 测试普通错误
	normalErr := errors.New("普通错误")
	details = GetErrorDetails(normalErr)
	if details != "普通错误" {
		t.Errorf("普通错误详情不匹配，期望: 普通错误, 实际: %s", details)
	}
}

func TestErrorResponse(t *testing.T) {
	err := NewErrorWithDetails(ErrCodeDatabase, "数据库连接失败", "连接超时")
	response := &ErrorResponse{
		Code:      err.Code,
		Message:   err.Message,
		Details:   err.Details,
		RequestID: "test-request-id",
		Path:      "/api/test",
		Method:    "GET",
	}

	if response.Code != ErrCodeDatabase {
		t.Errorf("响应错误码不匹配，期望: %d, 实际: %d", ErrCodeDatabase, response.Code)
	}
	if response.RequestID != "test-request-id" {
		t.Errorf("请求ID不匹配，期望: test-request-id, 实际: %s", response.RequestID)
	}
}

// 基准测试
func BenchmarkNewError(b *testing.B) {
	for i := 0; i < b.N; i++ {
		_ = NewError(ErrCodeDatabase, "数据库错误")
	}
}

func BenchmarkGetErrorMessage(b *testing.B) {
	for i := 0; i < b.N; i++ {
		_ = GetErrorMessage(ErrCodeDatabase)
	}
}

func BenchmarkGetHTTPStatus(b *testing.B) {
	for i := 0; i < b.N; i++ {
		_ = GetHTTPStatus(ErrCodeDatabase)
	}
}
