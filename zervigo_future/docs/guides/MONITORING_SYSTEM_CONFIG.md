# 监控系统配置指南

## 🎯 概述

本文档详细说明JobFirst系统的监控系统配置，包括应用性能监控、日志聚合、告警系统等。

## 🏗️ 监控架构

### 监控系统架构图
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   应用层监控     │    │   基础设施监控   │    │   业务层监控     │
├─────────────────┤    ├─────────────────┤    ├─────────────────┤
│ • API响应时间   │    │ • CPU使用率     │    │ • 用户活跃度     │
│ • 请求成功率     │    │ • 内存使用率    │    │ • 功能使用率     │
│ • 错误率        │    │ • 磁盘使用率    │    │ • 业务指标       │
│ • 吞吐量        │    │ • 网络流量      │    │ • 转化率         │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   监控数据收集   │
                    ├─────────────────┤
                    │ • Prometheus    │
                    │ • Grafana       │
                    │ • ELK Stack     │
                    │ • 自定义指标     │
                    └─────────────────┘
```

## 🔧 监控组件配置

### 环境分层监控策略

#### 开发环境监控
- **日志级别**: debug
- **监控方式**: 控制台输出 + 简单文件日志
- **告警**: 无
- **存储**: 本地文件

#### 测试环境监控
- **日志级别**: info
- **监控方式**: 文件日志 + 基础健康检查
- **告警**: 邮件通知
- **存储**: 本地文件 + 简单指标

#### 生产环境监控
- **日志级别**: warn
- **监控方式**: 完整监控栈 (Prometheus + Grafana + ELK)
- **告警**: 多渠道通知 (邮件、Slack、钉钉)
- **存储**: 时序数据库 + 日志聚合

### 1. 生产环境 Prometheus配置

#### 1.1 Prometheus配置文件
```yaml
# monitoring/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "rules/*.yml"

scrape_configs:
  # JobFirst后端服务监控
  - job_name: 'jobfirst-backend'
    static_configs:
      - targets: ['localhost:8080']
    metrics_path: '/metrics'
    scrape_interval: 10s

  # JobFirst AI服务监控
  - job_name: 'jobfirst-ai'
    static_configs:
      - targets: ['localhost:8206']
    metrics_path: '/metrics'
    scrape_interval: 10s

  # 数据库监控
  - job_name: 'mysql'
    static_configs:
      - targets: ['localhost:9104']
    scrape_interval: 30s

  # Redis监控
  - job_name: 'redis'
    static_configs:
      - targets: ['localhost:9121']
    scrape_interval: 30s

  # 系统监控
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['localhost:9100']
    scrape_interval: 30s
```

#### 1.2 告警规则配置
```yaml
# monitoring/rules/jobfirst.yml
groups:
  - name: jobfirst.rules
    rules:
      # API响应时间告警
      - alert: HighAPILatency
        expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 1
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "API响应时间过高"
          description: "API响应时间P95超过1秒，当前值: {{ $value }}秒"

      # 错误率告警
      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) > 0.05
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "错误率过高"
          description: "5xx错误率超过5%，当前值: {{ $value | humanizePercentage }}"

      # 数据库连接数告警
      - alert: HighDatabaseConnections
        expr: mysql_global_status_threads_connected > 80
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "数据库连接数过高"
          description: "数据库连接数超过80，当前值: {{ $value }}"

      # 内存使用率告警
      - alert: HighMemoryUsage
        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "内存使用率过高"
          description: "内存使用率超过85%，当前值: {{ $value }}%"
```

### 2. Grafana配置

#### 2.1 仪表板配置
```json
{
  "dashboard": {
    "title": "JobFirst系统监控",
    "panels": [
      {
        "title": "API响应时间",
        "type": "graph",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))",
            "legendFormat": "P95响应时间"
          }
        ]
      },
      {
        "title": "请求成功率",
        "type": "singlestat",
        "targets": [
          {
            "expr": "rate(http_requests_total{status=~\"2..\"}[5m]) / rate(http_requests_total[5m]) * 100",
            "legendFormat": "成功率"
          }
        ]
      },
      {
        "title": "系统资源使用率",
        "type": "graph",
        "targets": [
          {
            "expr": "100 - (avg(rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)",
            "legendFormat": "CPU使用率"
          },
          {
            "expr": "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100",
            "legendFormat": "内存使用率"
          }
        ]
      }
    ]
  }
}
```

### 3. 日志聚合配置

#### 3.1 ELK Stack配置
```yaml
# docker-compose.monitoring.yml
version: '3.8'

services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.15.0
    environment:
      - discovery.type=single-node
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ports:
      - "9200:9200"
    volumes:
      - elasticsearch_data:/usr/share/elasticsearch/data

  logstash:
    image: docker.elastic.co/logstash/logstash:7.15.0
    volumes:
      - ./monitoring/logstash.conf:/usr/share/logstash/pipeline/logstash.conf
    ports:
      - "5044:5044"
    depends_on:
      - elasticsearch

  kibana:
    image: docker.elastic.co/kibana/kibana:7.15.0
    ports:
      - "5601:5601"
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
    depends_on:
      - elasticsearch

  filebeat:
    image: docker.elastic.co/beats/filebeat:7.15.0
    volumes:
      - ./monitoring/filebeat.yml:/usr/share/filebeat/filebeat.yml
      - /opt/jobfirst/logs:/var/log/jobfirst:ro
    depends_on:
      - logstash

volumes:
  elasticsearch_data:
```

#### 3.2 Logstash配置
```ruby
# monitoring/logstash.conf
input {
  beats {
    port => 5044
  }
}

filter {
  if [fields][service] == "jobfirst-backend" {
    grok {
      match => { "message" => "%{TIMESTAMP_ISO8601:timestamp} %{LOGLEVEL:level} %{GREEDYDATA:message}" }
    }
    
    date {
      match => [ "timestamp", "ISO8601" ]
    }
  }
}

output {
  elasticsearch {
    hosts => ["elasticsearch:9200"]
    index => "jobfirst-logs-%{+YYYY.MM.dd}"
  }
}
```

### 4. 应用监控集成

#### 4.1 Go应用监控
```go
// backend/internal/monitoring/metrics.go
package monitoring

import (
    "github.com/prometheus/client_golang/prometheus"
    "github.com/prometheus/client_golang/prometheus/promauto"
)

var (
    // HTTP请求总数
    httpRequestsTotal = promauto.NewCounterVec(
        prometheus.CounterOpts{
            Name: "http_requests_total",
            Help: "Total number of HTTP requests",
        },
        []string{"method", "endpoint", "status"},
    )

    // HTTP请求持续时间
    httpRequestDuration = promauto.NewHistogramVec(
        prometheus.HistogramOpts{
            Name: "http_request_duration_seconds",
            Help: "HTTP request duration in seconds",
        },
        []string{"method", "endpoint"},
    )

    // 数据库连接数
    dbConnections = promauto.NewGauge(
        prometheus.GaugeOpts{
            Name: "database_connections_active",
            Help: "Number of active database connections",
        },
    )
)

// RecordHTTPRequest 记录HTTP请求指标
func RecordHTTPRequest(method, endpoint, status string, duration float64) {
    httpRequestsTotal.WithLabelValues(method, endpoint, status).Inc()
    httpRequestDuration.WithLabelValues(method, endpoint).Observe(duration)
}

// UpdateDBConnections 更新数据库连接数
func UpdateDBConnections(count int) {
    dbConnections.Set(float64(count))
}
```

#### 4.2 中间件集成
```go
// backend/internal/middleware/metrics.go
package middleware

import (
    "time"
    "github.com/gin-gonic/gin"
    "jobfirst/internal/monitoring"
)

func MetricsMiddleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        start := time.Now()
        
        c.Next()
        
        duration := time.Since(start).Seconds()
        monitoring.RecordHTTPRequest(
            c.Request.Method,
            c.FullPath(),
            string(rune(c.Writer.Status())),
            duration,
        )
    }
}
```

## 📊 监控指标

### 1. 应用层指标
- **API响应时间**: P50, P95, P99响应时间
- **请求成功率**: 2xx, 4xx, 5xx状态码分布
- **吞吐量**: 每秒请求数(QPS)
- **错误率**: 错误请求占比
- **并发数**: 当前并发请求数

### 2. 基础设施指标
- **CPU使用率**: 系统CPU使用百分比
- **内存使用率**: 系统内存使用百分比
- **磁盘使用率**: 磁盘空间使用百分比
- **网络流量**: 入站/出站网络流量
- **进程数**: 系统进程数量

### 3. 数据库指标
- **连接数**: 活跃数据库连接数
- **查询性能**: 慢查询统计
- **锁等待**: 数据库锁等待时间
- **缓存命中率**: Redis缓存命中率
- **事务数**: 数据库事务统计

### 4. 业务指标
- **用户活跃度**: 日活、月活用户数
- **功能使用率**: 各功能模块使用统计
- **转化率**: 用户行为转化统计
- **收入指标**: 业务收入相关指标

## 🚨 告警配置

### 1. 告警级别
- **Critical**: 系统不可用，需要立即处理
- **Warning**: 系统异常，需要关注
- **Info**: 系统状态变化，需要记录

### 2. 告警规则
```yaml
# 关键告警规则
critical_alerts:
  - name: "服务不可用"
    condition: "up == 0"
    duration: "1m"
    
  - name: "数据库连接失败"
    condition: "mysql_up == 0"
    duration: "30s"
    
  - name: "内存使用率过高"
    condition: "memory_usage > 95%"
    duration: "2m"

warning_alerts:
  - name: "API响应时间过长"
    condition: "api_latency_p95 > 2s"
    duration: "5m"
    
  - name: "错误率过高"
    condition: "error_rate > 5%"
    duration: "3m"
```

### 3. 通知配置
```yaml
# 通知渠道配置
notifications:
  email:
    enabled: true
    recipients: ["admin@jobfirst.com", "ops@jobfirst.com"]
    
  slack:
    enabled: true
    webhook_url: "https://hooks.slack.com/services/..."
    channel: "#alerts"
    
  dingtalk:
    enabled: true
    webhook_url: "https://oapi.dingtalk.com/robot/send?access_token=..."
```

## 🔧 部署配置

### 1. Docker Compose配置
```yaml
# docker-compose.monitoring.yml
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
      - ./monitoring/rules:/etc/prometheus/rules
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin123
    volumes:
      - grafana_data:/var/lib/grafana
      - ./monitoring/grafana/dashboards:/etc/grafana/provisioning/dashboards
      - ./monitoring/grafana/datasources:/etc/grafana/provisioning/datasources

  alertmanager:
    image: prom/alertmanager:latest
    ports:
      - "9093:9093"
    volumes:
      - ./monitoring/alertmanager.yml:/etc/alertmanager/alertmanager.yml

volumes:
  grafana_data:
```

### 2. 启动脚本
```bash
#!/bin/bash
# scripts/start-monitoring.sh
echo "启动监控系统..."

# 启动监控服务
docker-compose -f docker-compose.monitoring.yml up -d

# 等待服务启动
sleep 30

# 检查服务状态
echo "检查监控服务状态..."
curl -f http://localhost:9090/-/healthy || echo "Prometheus启动失败"
curl -f http://localhost:3000/api/health || echo "Grafana启动失败"
curl -f http://localhost:9093/-/healthy || echo "Alertmanager启动失败"

echo "监控系统启动完成！"
echo "访问地址:"
echo "  Prometheus: http://localhost:9090"
echo "  Grafana: http://localhost:3000 (admin/admin123)"
echo "  Alertmanager: http://localhost:9093"
```

## 📈 性能优化

### 1. 监控数据优化
- 合理设置采集间隔，平衡精度和性能
- 使用数据聚合，减少存储空间
- 定期清理历史数据，保持系统性能

### 2. 告警优化
- 设置合理的告警阈值，避免告警风暴
- 使用告警抑制，避免重复告警
- 定期审查告警规则，优化告警策略

### 3. 可视化优化
- 设计清晰的仪表板布局
- 使用合适的图表类型展示数据
- 设置自动刷新，保持数据实时性

## 📋 监控检查清单

### 配置检查
- [ ] Prometheus配置正确
- [ ] Grafana仪表板配置完成
- [ ] 告警规则配置正确
- [ ] 通知渠道配置完成
- [ ] 日志聚合配置正确

### 功能检查
- [ ] 指标采集正常
- [ ] 仪表板显示正确
- [ ] 告警触发正常
- [ ] 通知发送正常
- [ ] 日志聚合正常

### 性能检查
- [ ] 监控系统资源使用合理
- [ ] 数据采集性能良好
- [ ] 告警响应及时
- [ ] 可视化加载快速

---

**配置完成时间**: 2024年9月10日  
**配置状态**: ✅ 完成  
**下一步**: 配置备份和恢复策略
