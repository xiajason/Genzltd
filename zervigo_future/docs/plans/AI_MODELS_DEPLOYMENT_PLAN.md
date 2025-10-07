# AI大模型部署实施方案

## 🎯 回答您的问题：模型下载策略

### 是的，这些模型都需要下载到本地！

**原因**：
1. **性能要求**: 本地模型响应时间<100ms，在线API通常>1s
2. **稳定性**: 避免网络波动影响服务可用性
3. **成本控制**: 避免频繁调用外部API产生费用
4. **数据安全**: 敏感数据不离开本地环境

## 📊 当前模型下载情况

### 已下载模型
- **模型**: `sentence-transformers/all-MiniLM-L6-v2`
- **大小**: 909MB
- **位置**: `/home/appuser/.cache/torch/sentence_transformers/`
- **状态**: ✅ 已可用

### 下载方式分析
```bash
# 当前方式：容器内动态下载
# 优点：按需下载，节省空间
# 缺点：首次使用慢，网络依赖
```

## 🚀 推荐部署方案

### 方案一：预下载到容器镜像 (推荐)

#### 1. 修改Dockerfile
```dockerfile
# 在AI服务Dockerfile中添加
FROM python:3.11-slim

# 安装依赖
COPY requirements.txt .
RUN pip install -r requirements.txt

# 预下载核心模型
RUN python -c "
from sentence_transformers import SentenceTransformer
models = [
    'sentence-transformers/all-MiniLM-L6-v2',      # 快速模型
    'sentence-transformers/all-MiniLM-L12-v2',     # 平衡模型  
    'sentence-transformers/all-mpnet-base-v2'      # 高精度模型
]
for model in models:
    print(f'Downloading {model}...')
    SentenceTransformer(model)
    print(f'{model} downloaded successfully')
"

# 复制应用代码
COPY . /app
WORKDIR /app
```

#### 2. 更新docker-compose.yml
```yaml
services:
  ai-models:
    build: ./ai-services/ai-models
    ports:
      - "8002:8002"
    volumes:
      - ./models:/app/models  # 持久化模型存储
      - ./cache:/root/.cache/huggingface  # 缓存目录
    environment:
      - TRANSFORMERS_CACHE=/root/.cache/huggingface
      - HF_HOME=/root/.cache/huggingface
```

### 方案二：外部存储挂载 (生产推荐)

#### 1. 创建模型存储目录
```bash
# 在宿主机创建模型目录
mkdir -p /Users/szjason72/zervi-basic/basic/models
mkdir -p /Users/szjason72/zervi-basic/basic/cache
```

#### 2. 预下载模型到宿主机
```bash
# 创建模型下载脚本
cat > /Users/szjason72/zervi-basic/basic/scripts/download_models.sh << 'EOF'
#!/bin/bash
echo "=== 下载AI模型到本地 ==="

# 设置环境变量
export HF_HOME="/Users/szjason72/zervi-basic/basic/cache"
export TRANSFORMERS_CACHE="/Users/szjason72/zervi-basic/basic/cache"

# 下载核心模型
python3 -c "
from sentence_transformers import SentenceTransformer
import os

models = {
    'fast': 'sentence-transformers/all-MiniLM-L6-v2',
    'balanced': 'sentence-transformers/all-MiniLM-L12-v2', 
    'accurate': 'sentence-transformers/all-mpnet-base-v2',
    'multilingual': 'sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2'
}

for name, model_id in models.items():
    print(f'正在下载 {name} 模型: {model_id}')
    try:
        model = SentenceTransformer(model_id)
        print(f'✅ {name} 模型下载成功')
    except Exception as e:
        print(f'❌ {name} 模型下载失败: {e}')

print('模型下载完成！')
"

echo "模型已下载到: $HF_HOME"
EOF

chmod +x /Users/szjason72/zervi-basic/basic/scripts/download_models.sh
```

#### 3. 更新docker-compose.yml
```yaml
services:
  ai-models:
    image: ai-services-ai-models:latest
    ports:
      - "8002:8002"
    volumes:
      - /Users/szjason72/zervi-basic/basic/models:/app/models
      - /Users/szjason72/zervi-basic/basic/cache:/root/.cache/huggingface
    environment:
      - HF_HOME=/root/.cache/huggingface
      - TRANSFORMERS_CACHE=/root/.cache/huggingface
      - MODEL_PATH=/app/models
```

## 🔧 模型管理服务实现

### 1. 创建模型管理器
```python
# /app/model_manager.py
import os
import asyncio
from typing import Dict, List, Optional
from sentence_transformers import SentenceTransformer
import logging

logger = logging.getLogger(__name__)

class ModelManager:
    """AI模型管理器"""
    
    def __init__(self):
        self.models = {}
        self.model_configs = {
            "fast": {
                "name": "sentence-transformers/all-MiniLM-L6-v2",
                "size": "90MB",
                "dimension": 384,
                "use_case": "实时匹配，高并发"
            },
            "balanced": {
                "name": "sentence-transformers/all-MiniLM-L12-v2", 
                "size": "120MB",
                "dimension": 384,
                "use_case": "平衡性能和精度"
            },
            "accurate": {
                "name": "sentence-transformers/all-mpnet-base-v2",
                "size": "438MB", 
                "dimension": 768,
                "use_case": "高精度匹配"
            },
            "multilingual": {
                "name": "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2",
                "size": "120MB",
                "dimension": 384,
                "use_case": "多语言支持"
            }
        }
    
    async def initialize_models(self):
        """初始化常用模型"""
        logger.info("开始初始化AI模型...")
        
        # 预加载快速模型
        await self.load_model("fast")
        logger.info("AI模型初始化完成")
    
    async def load_model(self, model_type: str) -> bool:
        """加载指定类型的模型"""
        if model_type not in self.model_configs:
            logger.error(f"未知的模型类型: {model_type}")
            return False
        
        if model_type in self.models:
            logger.info(f"模型 {model_type} 已加载")
            return True
        
        try:
            model_config = self.model_configs[model_type]
            model_name = model_config["name"]
            
            logger.info(f"正在加载模型: {model_name}")
            model = SentenceTransformer(model_name)
            self.models[model_type] = model
            
            logger.info(f"模型 {model_type} 加载成功")
            return True
            
        except Exception as e:
            logger.error(f"模型 {model_type} 加载失败: {e}")
            return False
    
    async def get_embedding(self, text: str, model_type: str = "fast") -> Optional[List[float]]:
        """获取文本嵌入向量"""
        try:
            # 确保模型已加载
            if model_type not in self.models:
                success = await self.load_model(model_type)
                if not success:
                    return None
            
            model = self.models[model_type]
            embedding = model.encode(text)
            
            return embedding.tolist()
            
        except Exception as e:
            logger.error(f"生成嵌入向量失败: {e}")
            return None
    
    async def batch_embedding(self, texts: List[str], model_type: str = "fast") -> List[Optional[List[float]]]:
        """批量获取文本嵌入向量"""
        try:
            if model_type not in self.models:
                success = await self.load_model(model_type)
                if not success:
                    return [None] * len(texts)
            
            model = self.models[model_type]
            embeddings = model.encode(texts)
            
            return [emb.tolist() for emb in embeddings]
            
        except Exception as e:
            logger.error(f"批量生成嵌入向量失败: {e}")
            return [None] * len(texts)
    
    def get_model_info(self, model_type: str) -> Optional[Dict]:
        """获取模型信息"""
        return self.model_configs.get(model_type)
    
    def list_available_models(self) -> List[str]:
        """列出可用的模型类型"""
        return list(self.model_configs.keys())
    
    def get_loaded_models(self) -> List[str]:
        """获取已加载的模型"""
        return list(self.models.keys())

# 全局模型管理器实例
model_manager = ModelManager()
```

### 2. 更新AI Models服务
```python
# 在ai_models_service.py中集成模型管理器
from model_manager import model_manager

class AIModelsService:
    def __init__(self):
        self.model_path = os.getenv("MODEL_PATH", "/app/models")
        self.max_memory = os.getenv("MAX_MEMORY", "3GB")
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        
        # 初始化模型管理器
        asyncio.create_task(model_manager.initialize_models())
        
        logger.info("AI模型服务初始化", device=self.device, model_path=self.model_path)
    
    async def get_embedding(self, text: str, model_type: str = "fast") -> Optional[List[float]]:
        """获取文本嵌入向量"""
        return await model_manager.get_embedding(text, model_type)
    
    async def batch_embedding(self, texts: List[str], model_type: str = "fast") -> List[Optional[List[float]]]:
        """批量获取文本嵌入向量"""
        return await model_manager.batch_embedding(texts, model_type)
```

### 3. 添加模型管理API
```python
# 在ai_models_service.py中添加新的API端点

@app.route("/api/v1/models/info", methods=["GET"])
async def get_model_info(request: Request):
    """获取模型信息"""
    model_type = request.args.get("type", "fast")
    info = model_manager.get_model_info(model_type)
    
    if info:
        return json({
            "status": "success",
            "model_type": model_type,
            "info": info
        })
    else:
        return json({
            "status": "error",
            "message": f"未知的模型类型: {model_type}"
        }, status=400)

@app.route("/api/v1/models/list", methods=["GET"])
async def list_models(request: Request):
    """列出所有可用模型"""
    available = model_manager.list_available_models()
    loaded = model_manager.get_loaded_models()
    
    return json({
        "status": "success",
        "available_models": available,
        "loaded_models": loaded,
        "count": len(available)
    })

@app.route("/api/v1/models/load", methods=["POST"])
async def load_model(request: Request):
    """加载指定模型"""
    try:
        data = request.json
        model_type = data.get("model_type", "fast")
        
        success = await model_manager.load_model(model_type)
        
        if success:
            return json({
                "status": "success",
                "message": f"模型 {model_type} 加载成功",
                "model_type": model_type
            })
        else:
            return json({
                "status": "error",
                "message": f"模型 {model_type} 加载失败"
            }, status=500)
            
    except Exception as e:
        logger.error("加载模型失败", error=str(e))
        return json({"error": str(e)}, status=500)
```

## 📋 实施步骤

### 第一步：下载模型到本地 (30分钟)
```bash
# 1. 创建模型目录
mkdir -p /Users/szjason72/zervi-basic/basic/models
mkdir -p /Users/szjason72/zervi-basic/basic/cache

# 2. 执行模型下载脚本
cd /Users/szjason72/zervi-basic/basic
./scripts/download_models.sh

# 3. 验证下载结果
ls -la /Users/szjason72/zervi-basic/basic/cache/
```

### 第二步：更新Docker配置 (15分钟)
```bash
# 1. 更新docker-compose.yml
# 2. 重新构建AI Models服务
docker-compose build ai-models

# 3. 重启AI服务
docker-compose restart ai-models
```

### 第三步：测试模型服务 (15分钟)
```bash
# 1. 测试模型列表API
curl http://localhost:8002/api/v1/models/list

# 2. 测试嵌入生成API
curl -X POST http://localhost:8002/api/v1/models/embedding \
  -H "Content-Type: application/json" \
  -d '{"text": "Python开发工程师", "model_type": "fast"}'

# 3. 测试模型信息API
curl http://localhost:8002/api/v1/models/info?type=fast
```

## 💰 成本估算

### 存储成本
- **模型文件**: 约1GB (4个核心模型)
- **缓存文件**: 约500MB
- **总计**: 约1.5GB存储空间

### 内存成本
- **单个模型**: 200-800MB内存
- **并发加载**: 最多3个模型 = 1-2GB内存
- **推荐配置**: 4GB内存足够

### 网络成本
- **首次下载**: 1.5GB数据
- **后续更新**: 按需下载
- **建议**: 使用本地网络或CDN

## 🎯 总结

**回答您的问题**: 是的，模型需要下载到本地，但这是必要的投资：

1. **性能提升**: 本地模型响应时间<100ms vs 在线API>1s
2. **稳定性**: 避免网络波动影响服务
3. **成本控制**: 避免频繁API调用费用
4. **数据安全**: 敏感数据不离开本地

**推荐方案**: 使用外部存储挂载 + 预下载核心模型
**预期效果**: 支持4个核心模型，响应时间<100ms，准确率>85%

通过这个方案，我们可以构建一个强大、稳定、高效的AI模型服务！
