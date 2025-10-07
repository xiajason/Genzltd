package registry

import (
	"testing"
	"time"

	"github.com/jobfirst/jobfirst-core/errors"
)

func TestNewServiceRegistry(t *testing.T) {
	config := &RegistryConfig{
		ConsulHost:    "localhost",
		ConsulPort:    8500,
		CheckInterval: 30 * time.Second,
		Timeout:       5 * time.Second,
		TTL:           60 * time.Second,
	}

	registry, err := NewSimpleServiceRegistry(config)
	if err != nil {
		t.Fatalf("Failed to create service registry: %v", err)
	}

	if registry == nil {
		t.Fatal("Registry should not be nil")
	}

	if registry.config == nil {
		t.Fatal("Registry config should not be nil")
	}

	registry.Close()
}

func TestServiceRegistry_Register(t *testing.T) {
	config := &RegistryConfig{
		CheckInterval: 30 * time.Second,
		Timeout:       5 * time.Second,
		TTL:           60 * time.Second,
	}

	registry, err := NewSimpleServiceRegistry(config)
	if err != nil {
		t.Fatalf("Failed to create service registry: %v", err)
	}
	defer registry.Close()

	service := &ServiceInfo{
		ID:       "test-service-1",
		Name:     "test-service",
		Version:  "1.0.0",
		Endpoint: "localhost:8080",
		Tags:     []string{"test", "api"},
		Metadata: map[string]string{
			"environment": "test",
		},
	}

	err = registry.Register(service)
	if err != nil {
		t.Fatalf("Failed to register service: %v", err)
	}

	// 验证服务已注册
	registeredService, err := registry.GetService("test-service-1")
	if err != nil {
		t.Fatalf("Failed to get registered service: %v", err)
	}

	if registeredService.ID != service.ID {
		t.Errorf("Expected service ID %s, got %s", service.ID, registeredService.ID)
	}

	if registeredService.Name != service.Name {
		t.Errorf("Expected service name %s, got %s", service.Name, registeredService.Name)
	}
}

func TestServiceRegistry_Deregister(t *testing.T) {
	config := &RegistryConfig{
		CheckInterval: 30 * time.Second,
		Timeout:       5 * time.Second,
		TTL:           60 * time.Second,
	}

	registry, err := NewSimpleServiceRegistry(config)
	if err != nil {
		t.Fatalf("Failed to create service registry: %v", err)
	}
	defer registry.Close()

	service := &ServiceInfo{
		ID:       "test-service-2",
		Name:     "test-service",
		Version:  "1.0.0",
		Endpoint: "localhost:8081",
	}

	// 注册服务
	err = registry.Register(service)
	if err != nil {
		t.Fatalf("Failed to register service: %v", err)
	}

	// 注销服务
	err = registry.Deregister("test-service-2")
	if err != nil {
		t.Fatalf("Failed to deregister service: %v", err)
	}

	// 验证服务已注销
	_, err = registry.GetService("test-service-2")
	if err == nil {
		t.Fatal("Service should not exist after deregistration")
	}

	if !errors.IsJobFirstError(err) {
		t.Fatal("Error should be a JobFirstError")
	}

	jfErr := err.(*errors.JobFirstError)
	if jfErr.Code != errors.ErrCodeNotFound {
		t.Errorf("Expected error code %d, got %d", errors.ErrCodeNotFound, jfErr.Code)
	}
}

func TestServiceRegistry_GetServicesByName(t *testing.T) {
	config := &RegistryConfig{
		CheckInterval: 30 * time.Second,
		Timeout:       5 * time.Second,
		TTL:           60 * time.Second,
	}

	registry, err := NewSimpleServiceRegistry(config)
	if err != nil {
		t.Fatalf("Failed to create service registry: %v", err)
	}
	defer registry.Close()

	// 注册多个服务
	services := []*ServiceInfo{
		{
			ID:       "service-1",
			Name:     "api-service",
			Version:  "1.0.0",
			Endpoint: "localhost:8080",
		},
		{
			ID:       "service-2",
			Name:     "api-service",
			Version:  "1.0.0",
			Endpoint: "localhost:8081",
		},
		{
			ID:       "service-3",
			Name:     "db-service",
			Version:  "1.0.0",
			Endpoint: "localhost:8082",
		},
	}

	for _, service := range services {
		err = registry.Register(service)
		if err != nil {
			t.Fatalf("Failed to register service %s: %v", service.ID, err)
		}
	}

	// 获取api-service
	apiServices, err := registry.GetServicesByName("api-service")
	if err != nil {
		t.Fatalf("Failed to get services by name: %v", err)
	}

	if len(apiServices) != 2 {
		t.Errorf("Expected 2 api services, got %d", len(apiServices))
	}

	// 获取db-service
	dbServices, err := registry.GetServicesByName("db-service")
	if err != nil {
		t.Fatalf("Failed to get services by name: %v", err)
	}

	if len(dbServices) != 1 {
		t.Errorf("Expected 1 db service, got %d", len(dbServices))
	}
}

func TestServiceRegistry_SelectService(t *testing.T) {
	config := &RegistryConfig{
		CheckInterval: 30 * time.Second,
		Timeout:       5 * time.Second,
		TTL:           60 * time.Second,
	}

	registry, err := NewSimpleServiceRegistry(config)
	if err != nil {
		t.Fatalf("Failed to create service registry: %v", err)
	}
	defer registry.Close()

	// 注册健康的服务
	healthyService := &ServiceInfo{
		ID:       "healthy-service",
		Name:     "test-service",
		Version:  "1.0.0",
		Endpoint: "localhost:8080",
		Health: &HealthStatus{
			Status:    "healthy",
			Message:   "ok",
			Timestamp: time.Now(),
		},
	}

	// 注册不健康的服务
	unhealthyService := &ServiceInfo{
		ID:       "unhealthy-service",
		Name:     "test-service",
		Version:  "1.0.0",
		Endpoint: "localhost:8081",
		Health: &HealthStatus{
			Status:    "unhealthy",
			Message:   "error",
			Timestamp: time.Now(),
		},
	}

	err = registry.Register(healthyService)
	if err != nil {
		t.Fatalf("Failed to register healthy service: %v", err)
	}

	err = registry.Register(unhealthyService)
	if err != nil {
		t.Fatalf("Failed to register unhealthy service: %v", err)
	}

	// 选择服务（应该选择健康的服务）
	selectedService, err := registry.SelectService("test-service")
	if err != nil {
		t.Fatalf("Failed to select service: %v", err)
	}

	if selectedService.ID != "healthy-service" {
		t.Errorf("Expected to select healthy service, got %s", selectedService.ID)
	}
}

func TestServiceRegistry_UpdateServiceHealth(t *testing.T) {
	config := &RegistryConfig{
		CheckInterval: 30 * time.Second,
		Timeout:       5 * time.Second,
		TTL:           60 * time.Second,
	}

	registry, err := NewSimpleServiceRegistry(config)
	if err != nil {
		t.Fatalf("Failed to create service registry: %v", err)
	}
	defer registry.Close()

	service := &ServiceInfo{
		ID:       "test-service",
		Name:     "test-service",
		Version:  "1.0.0",
		Endpoint: "localhost:8080",
	}

	err = registry.Register(service)
	if err != nil {
		t.Fatalf("Failed to register service: %v", err)
	}

	// 更新健康状态
	health := &HealthStatus{
		Status:    "healthy",
		Message:   "all checks passed",
		Timestamp: time.Now(),
		Details: map[string]string{
			"http": "ok",
			"tcp":  "ok",
		},
	}

	err = registry.UpdateServiceHealth("test-service", health)
	if err != nil {
		t.Fatalf("Failed to update service health: %v", err)
	}

	// 验证健康状态已更新
	updatedService, err := registry.GetService("test-service")
	if err != nil {
		t.Fatalf("Failed to get updated service: %v", err)
	}

	if updatedService.Health == nil {
		t.Fatal("Service health should not be nil")
	}

	if updatedService.Health.Status != "healthy" {
		t.Errorf("Expected health status 'healthy', got '%s'", updatedService.Health.Status)
	}
}

func TestServiceRegistry_GetRegistryStatus(t *testing.T) {
	config := &RegistryConfig{
		CheckInterval: 30 * time.Second,
		Timeout:       5 * time.Second,
		TTL:           60 * time.Second,
	}

	registry, err := NewSimpleServiceRegistry(config)
	if err != nil {
		t.Fatalf("Failed to create service registry: %v", err)
	}
	defer registry.Close()

	// 注册一些服务
	services := []*ServiceInfo{
		{
			ID:       "service-1",
			Name:     "test-service",
			Version:  "1.0.0",
			Endpoint: "localhost:8080",
			Health: &HealthStatus{
				Status: "healthy",
			},
		},
		{
			ID:       "service-2",
			Name:     "test-service",
			Version:  "1.0.0",
			Endpoint: "localhost:8081",
			Health: &HealthStatus{
				Status: "unhealthy",
			},
		},
	}

	for _, service := range services {
		err = registry.Register(service)
		if err != nil {
			t.Fatalf("Failed to register service %s: %v", service.ID, err)
		}
	}

	// 获取注册中心状态
	status := registry.GetRegistryStatus()

	if status["total_services"] != 2 {
		t.Errorf("Expected 2 total services, got %v", status["total_services"])
	}

	if status["healthy_services"] != 1 {
		t.Errorf("Expected 1 healthy service, got %v", status["healthy_services"])
	}

	if status["unhealthy_services"] != 1 {
		t.Errorf("Expected 1 unhealthy service, got %v", status["unhealthy_services"])
	}
}

func TestServiceRegistry_Validation(t *testing.T) {
	config := &RegistryConfig{
		CheckInterval: 30 * time.Second,
		Timeout:       5 * time.Second,
		TTL:           60 * time.Second,
	}

	registry, err := NewSimpleServiceRegistry(config)
	if err != nil {
		t.Fatalf("Failed to create service registry: %v", err)
	}
	defer registry.Close()

	// 测试空服务注册
	err = registry.Register(nil)
	if err == nil {
		t.Fatal("Should fail when registering nil service")
	}

	// 测试无效服务ID
	invalidService := &ServiceInfo{
		ID:       "",
		Name:     "test-service",
		Endpoint: "localhost:8080",
	}
	err = registry.Register(invalidService)
	if err == nil {
		t.Fatal("Should fail when registering service with empty ID")
	}

	// 测试无效服务名
	invalidService.ID = "test-service"
	invalidService.Name = ""
	err = registry.Register(invalidService)
	if err == nil {
		t.Fatal("Should fail when registering service with empty name")
	}

	// 测试无效端点
	invalidService.Name = "test-service"
	invalidService.Endpoint = ""
	err = registry.Register(invalidService)
	if err == nil {
		t.Fatal("Should fail when registering service with empty endpoint")
	}
}
