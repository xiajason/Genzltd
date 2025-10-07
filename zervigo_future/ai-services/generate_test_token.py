#!/usr/bin/env python3
"""
生成测试用的JWT token
"""

import jwt
import time
from datetime import datetime, timedelta

def generate_test_token():
    """生成测试用的JWT token"""
    # 使用与AI服务相同的密钥
    secret = "your-secret-key-change-in-production"
    
    # 创建payload
    payload = {
        "user_id": 1,
        "username": "test_user",
        "email": "test@example.com",
        "roles": ["user"],
        "iat": int(time.time()),
        "exp": int(time.time()) + 3600,  # 1小时后过期
        "iss": "ai-service-test"
    }
    
    # 生成token
    token = jwt.encode(payload, secret, algorithm="HS256")
    return token

if __name__ == "__main__":
    token = generate_test_token()
    print(f"测试Token: {token}")
    print(f"Token长度: {len(token)}")
    
    # 验证token
    try:
        decoded = jwt.decode(token, "your-secret-key-change-in-production", algorithms=["HS256"])
        print(f"Token验证成功: {decoded}")
    except Exception as e:
        print(f"Token验证失败: {e}")
