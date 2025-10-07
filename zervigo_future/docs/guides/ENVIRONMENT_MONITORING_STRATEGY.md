# 环境分层监控策略

## 🎯 概述

本文档详细说明JobFirst系统在不同环境下的监控策略，确保开发、测试、生产环境使用合适的监控方案。

## 🏗️ 环境分层监控架构

### 监控复杂度分层
```
开发环境 (简单)    测试环境 (中等)    生产环境 (完整)
     ↓                ↓                ↓
  控制台日志        文件日志+健康检查   完整监控栈
  基础错误输出      简单指标收集       Prometheus+Grafana
  无告警           邮件告警          多渠道告警
  本地存储         本地存储           时序数据库
```

## 🔧 开发环境监控

### 1. 监控目标
- **主要目的**: 开发调试、快速定位问题
- **监控重点**: 错误日志、调试信息、性能瓶颈
- **资源消耗**: 最小化，不影响开发效率

### 2. 监控配置
```yaml
# config/development.yaml
logging:
  level: "debug"
  format: "text"
  output: "console"
  file: ""

monitoring:
  enabled: false
  metrics: false
  alerts: false
  prometheus: false
  grafana: false

# 简单的健康检查
health_check:
  enabled: true
  endpoint: "/health"
  interval: 30s
```

### 3. 日志配置
```go
// 开发环境日志配置
func setupDevLogging() {
    log.SetLevel(log.DebugLevel)
    log.SetFormatter(&log.TextFormatter{
        FullTimestamp: true,
        DisableColors: false,
    })
    log.SetOutput(os.Stdout)
}
```

### 4. 简单监控脚本
```bash
#!/bin/bash
# scripts/dev-monitor.sh
echo "=== 开发环境监控 ==="

# 检查服务状态
echo "检查服务状态..."
curl -f http://localhost:8080/health || echo "后端服务异常"
curl -f http://localhost:8206/health || echo "AI服务异常"

# 检查日志错误
echo "检查最近错误..."
tail -n 50 /opt/jobfirst/logs/app.log | grep -i error || echo "无错误日志"

# 检查资源使用
echo "检查资源使用..."
echo "内存使用: $(free -h | grep Mem | awk '{print $3"/"$2}')"
echo "磁盘使用: $(df -h / | tail -1 | awk '{print $3"/"$2" ("$5")"}')"

echo "开发环境监控完成"
```

## 🧪 测试环境监控

### 1. 监控目标
- **主要目的**: 功能验证、性能测试、质量保证
- **监控重点**: 功能正确性、性能指标、错误统计
- **资源消耗**: 中等，平衡监控需求和资源使用

### 2. 监控配置
```yaml
# config/testing.yaml
logging:
  level: "info"
  format: "json"
  output: "file"
  file: "/opt/jobfirst/logs/test.log"
  max_size: 50
  max_age: 7

monitoring:
  enabled: true
  metrics: true
  alerts: true
  prometheus: false  # 测试环境不使用Prometheus
  grafana: false     # 测试环境不使用Grafana

# 基础指标收集
metrics:
  enabled: true
  port: "9090"
  path: "/metrics"
  collect_interval: 30s

# 简单告警
alerts:
  enabled: true
  email:
    enabled: true
    recipients: ["test@jobfirst.com"]
  slack: false
  dingtalk: false
```

### 3. 基础指标收集
```go
// 测试环境指标收集
package monitoring

import (
    "net/http"
    "github.com/prometheus/client_golang/prometheus"
    "github.com/prometheus/client_golang/prometheus/promhttp"
)

var (
    // 简单的HTTP请求计数
    httpRequests = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "http_requests_total",
            Help: "Total HTTP requests",
        },
        []string{"method", "endpoint", "status"},
    )
    
    // 简单的响应时间
    httpDuration = prometheus.NewHistogramVec(
        prometheus.HistogramOpts{
            Name: "http_request_duration_seconds",
            Help: "HTTP request duration",
        },
        []string{"method", "endpoint"},
    )
)

func init() {
    prometheus.MustRegister(httpRequests)
    prometheus.MustRegister(httpDuration)
}

// 启动简单的指标服务
func StartMetricsServer(port string) {
    http.Handle("/metrics", promhttp.Handler())
    go http.ListenAndServe(":"+port, nil)
}
```

### 4. 测试环境监控脚本
```bash
#!/bin/bash
# scripts/test-monitor.sh
echo "=== 测试环境监控 ==="

# 检查服务健康状态
echo "检查服务健康状态..."
curl -f http://localhost:8080/health || {
    echo "后端服务健康检查失败"
    # 发送邮件告警
    echo "后端服务异常" | mail -s "测试环境告警" test@jobfirst.com
}

curl -f http://localhost:8206/health || {
    echo "AI服务健康检查失败"
    echo "AI服务异常" | mail -s "测试环境告警" test@jobfirst.com
}

# 收集基础指标
echo "收集基础指标..."
curl -s http://localhost:9090/metrics > /tmp/metrics.txt

# 检查错误率
ERROR_COUNT=$(grep 'http_requests_total.*status="5' /tmp/metrics.txt | wc -l)
if [ $ERROR_COUNT -gt 10 ]; then
    echo "错误率过高: $ERROR_COUNT 个5xx错误"
    echo "测试环境错误率过高: $ERROR_COUNT 个5xx错误" | mail -s "测试环境告警" test@jobfirst.com
fi

# 检查响应时间
echo "检查API响应时间..."
RESPONSE_TIME=$(curl -o /dev/null -s -w '%{time_total}' http://localhost:8080/api/v1/health)
if (( $(echo "$RESPONSE_TIME > 2.0" | bc -l) )); then
    echo "API响应时间过长: ${RESPONSE_TIME}s"
    echo "测试环境API响应时间过长: ${RESPONSE_TIME}s" | mail -s "测试环境告警" test@jobfirst.com
fi

echo "测试环境监控完成"
```

## 🏭 生产环境监控

### 1. 监控目标
- **主要目的**: 业务连续性、性能优化、故障预防
- **监控重点**: 系统稳定性、业务指标、用户体验
- **资源消耗**: 完整监控栈，确保业务稳定

### 2. 监控配置
```yaml
# config/production.yaml
logging:
  level: "warn"
  format: "json"
  output: "file"
  file: "/opt/jobfirst/logs/prod.log"
  max_size: 100
  max_age: 30
  max_backups: 10

monitoring:
  enabled: true
  metrics: true
  alerts: true
  prometheus: true
  grafana: true
  elk: true

# 完整监控栈
metrics:
  enabled: true
  port: "9090"
  path: "/metrics"
  collect_interval: 15s

# 多渠道告警
alerts:
  enabled: true
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

### 3. 完整监控栈
```yaml
# docker-compose.monitoring.yml (仅生产环境)
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

volumes:
  grafana_data:
  elasticsearch_data:
```

## 📊 监控指标对比

### 开发环境指标
- ✅ 错误日志输出
- ✅ 调试信息
- ✅ 基础健康检查
- ❌ 性能指标
- ❌ 告警通知
- ❌ 历史数据

### 测试环境指标
- ✅ 错误日志记录
- ✅ 基础性能指标
- ✅ 健康检查
- ✅ 简单告警
- ✅ 基础统计
- ❌ 复杂告警规则
- ❌ 可视化仪表板

### 生产环境指标
- ✅ 完整日志聚合
- ✅ 详细性能指标
- ✅ 业务指标
- ✅ 多渠道告警
- ✅ 可视化仪表板
- ✅ 历史数据分析
- ✅ 趋势预测

## 🚀 部署策略

### 1. 开发环境部署
```bash
# 开发环境不需要额外监控组件
# 只需要基础的健康检查
./scripts/dev-monitor.sh
```

### 2. 测试环境部署
```bash
# 测试环境部署基础监控
docker-compose -f docker-compose.testing.yml up -d

# 启动基础指标收集
./scripts/test-monitor.sh
```

### 3. 生产环境部署
```bash
# 生产环境部署完整监控栈
docker-compose -f docker-compose.monitoring.yml up -d

# 启动完整监控
./scripts/prod-monitor.sh
```

## 📋 环境检查清单

### 开发环境检查
- [ ] 控制台日志输出正常
- [ ] 错误信息清晰可见
- [ ] 调试信息完整
- [ ] 健康检查端点可用
- [ ] 无额外资源消耗

### 测试环境检查
- [ ] 文件日志记录正常
- [ ] 基础指标收集正常
- [ ] 健康检查通过
- [ ] 邮件告警配置正确
- [ ] 性能指标在合理范围

### 生产环境检查
- [ ] Prometheus指标采集正常
- [ ] Grafana仪表板显示正确
- [ ] 告警规则配置正确
- [ ] 多渠道通知正常
- [ ] ELK日志聚合正常
- [ ] 监控系统高可用

## 🎯 最佳实践

### 1. 环境隔离
- 开发环境：最小化监控，专注开发效率
- 测试环境：基础监控，确保功能正确
- 生产环境：完整监控，确保业务稳定

### 2. 资源优化
- 开发环境：不部署重型监控组件
- 测试环境：使用轻量级监控方案
- 生产环境：投入足够资源确保监控完整

### 3. 告警策略
- 开发环境：无告警，避免干扰开发
- 测试环境：简单告警，及时发现问题
- 生产环境：完整告警，确保业务连续性

---

**配置完成时间**: 2024年9月10日  
**配置状态**: ✅ 完成  
**适用环境**: 开发、测试、生产环境分层监控
