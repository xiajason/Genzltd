#!/bin/bash
# 本地开发环境配置脚本

echo "=== 本地开发环境配置 ==="
echo "1. 数据库端口配置:"
echo "  - MySQL: 3306 (标准端口)"
echo "  - PostgreSQL: 5434 (自定义端口)"
echo "  - Redis: 6382 (自定义端口)"
echo "  - Neo4j: 7475 (自定义端口)"
echo "  - Elasticsearch: 9202 (自定义端口)"
echo "  - Weaviate: 8091 (自定义端口)"

echo "2. 服务端口配置:"
echo "  - API Gateway: 8601"
echo "  - User Service: 8602"
echo "  - Resume Service: 8603"
echo "  - Company Service: 8604"
echo "  - AI Service: 8620"

echo "3. 网络配置:"
echo "  - 网络名称: dev-network"
echo "  - 驱动: bridge"
echo "  - 隔离: 本地开发环境"
