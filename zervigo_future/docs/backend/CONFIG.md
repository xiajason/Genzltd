# AI服务配置说明

## 环境变量配置

创建 `.env` 文件来配置AI服务：

```bash
# AI服务环境配置
AI_SERVICE_PORT=8206

# PostgreSQL配置
POSTGRES_HOST=localhost
POSTGRES_USER=szjason72
POSTGRES_DB=jobfirst_vector
POSTGRES_PASSWORD=

# OpenAI配置（可选）
OPENAI_API_KEY=your-openai-api-key-here

# 日志配置
LOG_LEVEL=INFO
LOG_FILE=../../../logs/ai-service.log

# 性能配置
WORKERS=4
MAX_REQUESTS=1000
MAX_REQUESTS_JITTER=100
```

## 依赖安装

```bash
# 安装Python依赖
pip3 install -r requirements.txt

# 或者使用虚拟环境
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

## 启动服务

```bash
# 使用启动脚本
./scripts/start-ai-service.sh

# 或直接启动
cd backend/internal/ai-service
python3 ai_service.py
```

## API接口

### 健康检查
- `GET /health` - 服务健康状态

### 简历分析
- `POST /api/v1/analyze/resume` - 分析简历内容

### 向量操作
- `GET /api/v1/vectors/:resume_id` - 获取简历向量
- `POST /api/v1/vectors/search` - 搜索相似简历

## 数据库要求

确保PostgreSQL数据库已启动，并创建了 `resume_vectors` 表：

```sql
CREATE TABLE resume_vectors (
    id SERIAL PRIMARY KEY,
    resume_id VARCHAR(255) UNIQUE NOT NULL,
    content_vector vector(1536),
    skills_vector vector(1536),
    experience_vector vector(1536),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 创建向量索引
CREATE INDEX ON resume_vectors USING ivfflat (content_vector vector_cosine_ops);
CREATE INDEX ON resume_vectors USING ivfflat (skills_vector vector_cosine_ops);
CREATE INDEX ON resume_vectors USING ivfflat (experience_vector vector_cosine_ops);
```
