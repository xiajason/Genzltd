#!/usr/bin/env python3
"""
AI模型服务 - 容器化版本
提供模型管理和推理服务
"""

import asyncio
import logging
import os
from typing import Dict, List, Optional
from sanic import Sanic, Request, response
from sanic.response import json
import numpy as np
from transformers import AutoTokenizer, AutoModel
import torch
import structlog

# 配置日志
structlog.configure(
    processors=[
        structlog.stdlib.filter_by_level,
        structlog.stdlib.add_logger_name,
        structlog.stdlib.add_log_level,
        structlog.stdlib.PositionalArgumentsFormatter(),
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
        structlog.processors.UnicodeDecoder(),
        structlog.processors.JSONRenderer()
    ],
    context_class=dict,
    logger_factory=structlog.stdlib.LoggerFactory(),
    wrapper_class=structlog.stdlib.BoundLogger,
    cache_logger_on_first_use=True,
)

logger = structlog.get_logger()

# 创建Sanic应用
app = Sanic("ai-models-service")

# 全局变量
models = {}
tokenizers = {}

class AIModelsService:
    """AI模型服务类"""
    
    def __init__(self):
        self.model_path = os.getenv("MODEL_PATH", "/app/models")
        self.max_memory = os.getenv("MAX_MEMORY", "3GB")
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        logger.info("AI模型服务初始化", device=self.device, model_path=self.model_path)
    
    async def load_model(self, model_name: str) -> bool:
        """加载模型"""
        try:
            logger.info("开始加载模型", model_name=model_name)
            
            # 加载分词器
            tokenizer = AutoTokenizer.from_pretrained(model_name)
            tokenizers[model_name] = tokenizer
            
            # 加载模型
            model = AutoModel.from_pretrained(model_name)
            model.to(self.device)
            models[model_name] = model
            
            logger.info("模型加载成功", model_name=model_name, device=self.device)
            return True
            
        except Exception as e:
            logger.error("模型加载失败", model_name=model_name, error=str(e))
            return False
    
    async def get_embedding(self, text: str, model_name: str = "sentence-transformers/all-MiniLM-L6-v2") -> Optional[List[float]]:
        """获取文本嵌入向量"""
        try:
            if model_name not in models:
                await self.load_model(model_name)
            
            if model_name not in models:
                logger.error("模型未加载", model_name=model_name)
                return None
            
            tokenizer = tokenizers[model_name]
            model = models[model_name]
            
            # 编码文本
            inputs = tokenizer(text, return_tensors="pt", truncation=True, padding=True, max_length=512)
            inputs = {k: v.to(self.device) for k, v in inputs.items()}
            
            # 获取嵌入
            with torch.no_grad():
                outputs = model(**inputs)
                embeddings = outputs.last_hidden_state.mean(dim=1)
                embedding = embeddings.cpu().numpy().flatten().tolist()
            
            logger.info("文本嵌入生成成功", text_length=len(text), embedding_dim=len(embedding))
            return embedding
            
        except Exception as e:
            logger.error("文本嵌入生成失败", error=str(e))
            return None
    
    async def batch_embedding(self, texts: List[str], model_name: str = "sentence-transformers/all-MiniLM-L6-v2") -> List[Optional[List[float]]]:
        """批量获取文本嵌入向量"""
        try:
            embeddings = []
            for text in texts:
                embedding = await self.get_embedding(text, model_name)
                embeddings.append(embedding)
            
            logger.info("批量文本嵌入生成完成", batch_size=len(texts))
            return embeddings
            
        except Exception as e:
            logger.error("批量文本嵌入生成失败", error=str(e))
            return [None] * len(texts)

# 创建服务实例
ai_models_service = AIModelsService()

@app.route("/health", methods=["GET"])
async def health_check(request: Request):
    """健康检查"""
    return json({
        "status": "healthy",
        "service": "ai-models-service",
        "models_loaded": len(models),
        "device": ai_models_service.device
    })

@app.route("/api/v1/models/load", methods=["POST"])
async def load_model(request: Request):
    """加载模型"""
    try:
        data = request.json
        model_name = data.get("model_name")
        
        if not model_name:
            return json({"error": "模型名称不能为空"}, status=400)
        
        success = await ai_models_service.load_model(model_name)
        
        if success:
            return json({
                "status": "success",
                "message": f"模型 {model_name} 加载成功",
                "model_name": model_name
            })
        else:
            return json({
                "status": "error",
                "message": f"模型 {model_name} 加载失败"
            }, status=500)
            
    except Exception as e:
        logger.error("加载模型失败", error=str(e))
        return json({"error": str(e)}, status=500)

@app.route("/api/v1/models/embedding", methods=["POST"])
async def get_embedding(request: Request):
    """获取文本嵌入向量"""
    try:
        data = request.json
        text = data.get("text")
        model_name = data.get("model_name", "sentence-transformers/all-MiniLM-L6-v2")
        
        if not text:
            return json({"error": "文本不能为空"}, status=400)
        
        embedding = await ai_models_service.get_embedding(text, model_name)
        
        if embedding:
            return json({
                "status": "success",
                "embedding": embedding,
                "dimension": len(embedding),
                "model_name": model_name
            })
        else:
            return json({
                "status": "error",
                "message": "文本嵌入生成失败"
            }, status=500)
            
    except Exception as e:
        logger.error("获取文本嵌入失败", error=str(e))
        return json({"error": str(e)}, status=500)

@app.route("/api/v1/models/batch-embedding", methods=["POST"])
async def batch_embedding(request: Request):
    """批量获取文本嵌入向量"""
    try:
        data = request.json
        texts = data.get("texts", [])
        model_name = data.get("model_name", "sentence-transformers/all-MiniLM-L6-v2")
        
        if not texts:
            return json({"error": "文本列表不能为空"}, status=400)
        
        embeddings = await ai_models_service.batch_embedding(texts, model_name)
        
        return json({
            "status": "success",
            "embeddings": embeddings,
            "count": len(embeddings),
            "model_name": model_name
        })
        
    except Exception as e:
        logger.error("批量获取文本嵌入失败", error=str(e))
        return json({"error": str(e)}, status=500)

@app.route("/api/v1/models/list", methods=["GET"])
async def list_models(request: Request):
    """列出已加载的模型"""
    return json({
        "status": "success",
        "models": list(models.keys()),
        "count": len(models)
    })

if __name__ == "__main__":
    # 启动服务
    logger.info("启动AI模型服务", port=8002)
    app.run(host="0.0.0.0", port=8002, workers=1)
