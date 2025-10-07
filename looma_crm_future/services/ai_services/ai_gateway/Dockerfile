# AI网关服务 Dockerfile
FROM python:3.12-slim

# 设置工作目录
WORKDIR /app

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 复制依赖文件
COPY ../../requirements.txt /app/requirements.txt

# 安装Python依赖
RUN pip install --no-cache-dir -r requirements.txt

# 复制应用代码
COPY . /app/ai_gateway/
COPY ../shared /app/shared/

# 设置环境变量
ENV PYTHONPATH=/app
ENV AI_GATEWAY_PORT=8206

# 暴露端口
EXPOSE 8206

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8206/health || exit 1

# 启动命令
CMD ["python", "ai_gateway/main.py"]
