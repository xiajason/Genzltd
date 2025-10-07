# Consul Brew Services 问题解决方案

## 🔍 问题分析

### **根本原因**

1. **Consul 安装方式问题**：
   - Consul 是通过 `homebrew-cask` 安装的，不是通过 `homebrew-core`
   - Cask 安装的软件通常不提供 `brew services` 支持
   - 从 Homebrew 1.0 开始，Consul 被迁移到 Cask 仓库

2. **缺少系统服务配置**：
   - 没有标准的 plist 文件
   - 没有自动启动配置
   - 无法通过 `brew services` 管理

3. **当前的手动启动方式**：
   - 使用 `consul agent -dev -config-dir=config -data-dir=data` 手动启动
   - 这是开发模式，不适合生产环境管理

## 🔧 解决方案

### **1. 创建系统服务配置**

#### **Consul 配置文件** (`/opt/homebrew/etc/consul.d/consul.hcl`)
```hcl
# Consul 配置文件
datacenter = "dc1"
data_dir = "/opt/homebrew/var/consul"
log_level = "INFO"
node_name = "consul-dev"
server = true
bootstrap_expect = 1
ui_config {
  enabled = true
}
bind_addr = "127.0.0.1"
client_addr = "127.0.0.1"
ports {
  grpc = 8502
}
connect {
  enabled = true
}
```

#### **系统服务配置文件** (`/opt/homebrew/etc/consul.plist`)
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
    </dict>
    <key>Label</key>
    <string>consul</string>
    <key>ProgramArguments</key>
    <array>
        <string>/opt/homebrew/bin/consul</string>
        <string>agent</string>
        <string>-config-dir</string>
        <string>/opt/homebrew/etc/consul.d</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardErrorPath</key>
    <string>/opt/homebrew/var/log/consul.log</string>
    <key>StandardOutPath</key>
    <string>/opt/homebrew/var/log/consul.log</string>
    <key>WorkingDirectory</key>
    <string>/opt/homebrew/var</string>
</dict>
</plist>
```

### **2. 创建必要的目录**
```bash
mkdir -p /opt/homebrew/var/consul /opt/homebrew/var/log
```

### **3. 更新启动脚本**

#### **safe-startup.sh 修改**
```bash
# 启动Consul
if ! curl -s http://localhost:8500/v1/status/leader >/dev/null 2>&1; then
    log_info "启动Consul服务..."
    # 尝试使用系统服务启动Consul
    if launchctl load /opt/homebrew/etc/consul.plist 2>/dev/null; then
        log_success "Consul启动成功 (系统服务)"
        sleep 5  # 等待Consul完全启动
    else
        # 尝试手动启动Consul
        log_info "尝试手动启动Consul..."
        cd "$PROJECT_ROOT/consul"
        if consul agent -dev -config-dir=config -data-dir=data > "$LOG_DIR/consul.log" 2>&1 &
        then
            local consul_pid=$!
            echo $consul_pid > "$LOG_DIR/consul.pid"
            log_success "Consul启动成功 (手动启动, PID: $consul_pid)"
            sleep 5  # 等待Consul完全启动
        else
            log_error "Consul启动失败"
            exit 1
        fi
    fi
else
    log_info "Consul已在运行"
fi
```

### **4. 更新关闭脚本**

#### **safe-shutdown.sh 修改**
```bash
# 停止Consul (如果运行)
if curl -s http://localhost:8500/v1/status/leader >/dev/null 2>&1; then
    log_info "停止Consul服务..."
    # 尝试使用系统服务停止Consul
    if launchctl unload /opt/homebrew/etc/consul.plist 2>/dev/null; then
        log_success "Consul已停止 (系统服务)"
        sleep 2
    else
        # 尝试手动停止Consul进程
        local consul_pid=$(pgrep -f "consul agent")
        if [[ -n "$consul_pid" ]]; then
            log_info "尝试手动停止Consul进程 (PID: $consul_pid)..."
            kill -TERM "$consul_pid" 2>/dev/null && sleep 2
            if pgrep -f "consul agent" >/dev/null; then
                kill -KILL "$consul_pid" 2>/dev/null
            fi
            log_success "Consul进程已手动停止"
        else
            log_info "Consul服务未运行或已停止"
        fi
    fi
fi
```

## ✅ 解决方案优势

### **1. 标准化管理**
- 使用 macOS 标准的 `launchctl` 系统
- 支持自动启动和停止
- 符合 macOS 服务管理最佳实践

### **2. 双重保障**
- 优先使用系统服务启动/停止
- 如果系统服务失败，自动回退到手动方式
- 确保 Consul 能够正常管理

### **3. 生产环境友好**
- 使用配置文件而不是开发模式
- 支持日志管理和监控
- 支持自动重启

### **4. 兼容性**
- 保持与现有脚本的兼容性
- 支持多种启动方式
- 不影响其他服务的运行

## 🧪 测试验证

### **启动测试**
```bash
# 启动 Consul
launchctl load /opt/homebrew/etc/consul.plist

# 验证状态
curl -s http://localhost:8500/v1/status/leader
```

### **停止测试**
```bash
# 停止 Consul
launchctl unload /opt/homebrew/etc/consul.plist

# 验证停止
curl -s http://localhost:8500/v1/status/leader || echo "Consul已停止"
```

## 📝 总结

通过创建标准的 macOS 系统服务配置，我们解决了 Consul 无法通过 `brew services` 管理的问题。现在：

1. ✅ **Consul 可以通过系统服务正常启动和停止**
2. ✅ **支持自动重启和日志管理**
3. ✅ **保持与现有脚本的兼容性**
4. ✅ **提供双重保障机制**
5. ✅ **符合生产环境管理标准**

这个解决方案彻底解决了 Consul 启动管理的问题，让我们的微服务系统更加稳定和可靠。
