#!/usr/bin/env python3
"""
Future版简历上传服务
处理简历文件上传、验证和存储
"""

from sanic import Sanic, Request, json as sanic_json
from sanic.response import json as sanic_response
import os
import uuid
import mimetypes
from pathlib import Path
import logging
from datetime import datetime

# 配置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Sanic("ResumeUploadService")

# 配置
UPLOAD_DIR = "uploads"
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10MB
ALLOWED_EXTENSIONS = {'.pdf', '.doc', '.docx', '.txt'}

@app.route('/api/v1/upload', methods=['POST'])
async def upload_resume(request: Request):
    """简历上传接口"""
    try:
        logger.info("收到简历上传请求")
        
        # 获取上传的文件 - 使用正确的方式
        if 'file' not in request.files:
            return sanic_response({"error": "没有上传文件"}, status=400)
        
        file = request.files.get('file')
        
        # 验证文件
        if not file or not hasattr(file, 'name') or not file.name:
            return sanic_response({"error": "文件名不能为空"}, status=400)
        
        # 检查文件大小
        if len(file.body) > MAX_FILE_SIZE:
            return sanic_response({"error": f"文件大小超过限制 ({MAX_FILE_SIZE / 1024 / 1024:.1f}MB)"}, status=400)
        
        # 检查文件类型
        file_ext = Path(file.name).suffix.lower()
        if file_ext not in ALLOWED_EXTENSIONS:
            return sanic_response({"error": f"不支持的文件类型，支持的类型: {', '.join(ALLOWED_EXTENSIONS)}"}, status=400)
        
        # 生成唯一文件名
        file_id = str(uuid.uuid4())
        safe_filename = f"{file_id}{file_ext}"
        
        # 确保上传目录存在
        os.makedirs(UPLOAD_DIR, exist_ok=True)
        
        # 保存文件
        file_path = os.path.join(UPLOAD_DIR, safe_filename)
        with open(file_path, 'wb') as f:
            f.write(file.body)
        
        logger.info(f"文件上传成功: {file.name} -> {safe_filename}")
        
        return sanic_response({
            "success": True,
            "file_id": file_id,
            "filename": safe_filename,
            "original_filename": file.name,
            "size": len(file.body),
            "upload_time": datetime.now().isoformat(),
            "message": "文件上传成功"
        })
        
    except Exception as e:
        logger.error(f"文件上传失败: {e}")
        return sanic_response({"error": str(e)}, status=500)

@app.route('/api/v1/upload/<file_id>', methods=['GET'])
async def get_file_info(request: Request, file_id: str):
    """获取文件信息"""
    try:
        logger.info(f"获取文件信息: {file_id}")
        
        # 查找文件
        upload_dir = Path(UPLOAD_DIR)
        files = list(upload_dir.glob(f"{file_id}.*"))
        
        if not files:
            return sanic_response({"error": "文件不存在"}, status=404)
        
        file_path = files[0]
        file_size = file_path.stat().st_size
        file_mtime = datetime.fromtimestamp(file_path.stat().st_mtime)
        
        return sanic_response({
            "success": True,
            "file_id": file_id,
            "filename": file_path.name,
            "size": file_size,
            "path": str(file_path),
            "upload_time": file_mtime.isoformat(),
            "mime_type": mimetypes.guess_type(str(file_path))[0]
        })
        
    except Exception as e:
        logger.error(f"获取文件信息失败: {e}")
        return sanic_response({"error": str(e)}, status=500)

@app.route('/api/v1/upload/list', methods=['GET'])
async def list_files(request: Request):
    """列出所有上传的文件"""
    try:
        logger.info("获取文件列表")
        
        upload_dir = Path(UPLOAD_DIR)
        if not upload_dir.exists():
            return sanic_response({
                "success": True,
                "files": [],
                "count": 0
            })
        
        files = []
        for file_path in upload_dir.iterdir():
            if file_path.is_file():
                files.append({
                    "filename": file_path.name,
                    "size": file_path.stat().st_size,
                    "upload_time": datetime.fromtimestamp(file_path.stat().st_mtime).isoformat(),
                    "mime_type": mimetypes.guess_type(str(file_path))[0]
                })
        
        # 按上传时间排序
        files.sort(key=lambda x: x['upload_time'], reverse=True)
        
        return sanic_response({
            "success": True,
            "files": files,
            "count": len(files)
        })
        
    except Exception as e:
        logger.error(f"获取文件列表失败: {e}")
        return sanic_response({"error": str(e)}, status=500)

@app.route('/health', methods=['GET'])
async def health_check(request: Request):
    """健康检查"""
    return sanic_response({
        "service": "resume-upload-service",
        "version": "1.0.0",
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "upload_dir": UPLOAD_DIR,
        "max_file_size": MAX_FILE_SIZE,
        "allowed_extensions": list(ALLOWED_EXTENSIONS)
    })

if __name__ == "__main__":
    logger.info("启动简历上传服务...")
    logger.info(f"上传目录: {UPLOAD_DIR}")
    logger.info(f"最大文件大小: {MAX_FILE_SIZE / 1024 / 1024:.1f}MB")
    logger.info(f"支持的文件类型: {', '.join(ALLOWED_EXTENSIONS)}")
    
    app.run(host="0.0.0.0", port=7520, debug=True)
