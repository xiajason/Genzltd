#!/usr/bin/env python3
import json
import sys
from datetime import datetime

def update_independence_status(phase, milestone, status, progress=0):
    """更新独立化状态"""
    try:
        with open('docs/INDEPENDENCE_STATUS.json', 'r') as f:
            data = json.load(f)
        
        if phase in data['independence']['phases'] and milestone in data['independence']['phases'][phase]['milestones']:
            data['independence']['phases'][phase]['milestones'][milestone]['status'] = status
            data['independence']['phases'][phase]['milestones'][milestone]['progress'] = progress
            
            if status == 'in_progress' and not data['independence']['phases'][phase]['milestones'][milestone]['start_date']:
                data['independence']['phases'][phase]['milestones'][milestone]['start_date'] = datetime.now().isoformat()
            elif status == 'completed':
                data['independence']['phases'][phase]['milestones'][milestone]['end_date'] = datetime.now().isoformat()
            
            with open('docs/INDEPENDENCE_STATUS.json', 'w') as f:
                json.dump(data, f, indent=2)
            
            print(f"里程碑 {phase}.{milestone} 状态已更新为: {status} ({progress}%)")
        else:
            print(f"里程碑 {phase}.{milestone} 不存在")
    except Exception as e:
        print(f"更新独立化状态失败: {e}")

if __name__ == "__main__":
    if len(sys.argv) >= 4:
        update_independence_status(sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4]) if len(sys.argv) > 4 else 0)
    else:
        print("用法: python update_independence_status.py <phase> <milestone> <status> [progress]")
