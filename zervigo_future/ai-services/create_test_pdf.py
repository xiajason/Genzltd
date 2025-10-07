#!/usr/bin/env python3
"""
创建测试PDF文件
"""

from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import letter
import os

def create_test_pdf():
    """创建测试PDF文件"""
    pdf_path = "/tmp/test_resume.pdf"
    
    # 创建PDF
    c = canvas.Canvas(pdf_path, pagesize=letter)
    width, height = letter
    
    # 添加内容
    c.setFont("Helvetica-Bold", 16)
    c.drawString(100, height - 100, "张三的简历")
    
    c.setFont("Helvetica", 12)
    c.drawString(100, height - 140, "个人信息：")
    c.drawString(120, height - 160, "姓名：张三")
    c.drawString(120, height - 180, "邮箱：zhangsan@example.com")
    c.drawString(120, height - 200, "电话：13800138000")
    
    c.drawString(100, height - 240, "工作经历：")
    c.drawString(120, height - 260, "2020-2025 ABC科技有限公司 高级软件工程师")
    c.drawString(140, height - 280, "- 负责后端系统开发和维护")
    c.drawString(140, height - 300, "- 使用Python和Django框架")
    c.drawString(140, height - 320, "- 参与系统架构设计")
    
    c.drawString(100, height - 360, "教育背景：")
    c.drawString(120, height - 380, "2016-2020 某某大学 计算机科学与技术学士")
    
    c.drawString(100, height - 420, "技能：")
    c.drawString(120, height - 440, "Python, Java, JavaScript, React, Vue, MySQL, Docker, Git")
    
    # 保存PDF
    c.save()
    
    print(f"✅ 测试PDF文件已创建: {pdf_path}")
    print(f"文件大小: {os.path.getsize(pdf_path)} 字节")
    
    return pdf_path

if __name__ == "__main__":
    create_test_pdf()
