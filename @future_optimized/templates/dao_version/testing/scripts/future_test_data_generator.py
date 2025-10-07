#!/usr/bin/env python3
"""
Future版测试数据生成器
为腾讯云服务Future版各类型数据库生成测试数据
"""

import json
import random
import uuid
from datetime import datetime, timedelta
from typing import List, Dict, Any

class FutureTestDataGenerator:
    """Future版测试数据生成器"""
    
    def __init__(self):
        self.users = []
        self.skills = []
        self.companies = []
        self.positions = []
        self.resumes = []
        self.work_experiences = []
        self.projects = []
        self.educations = []
        self.certifications = []
        self.comments = []
        self.likes = []
        self.shares = []
        self.points = []
        self.point_history = []
        
    def generate_users(self, count: int = 50) -> List[Dict[str, Any]]:
        """生成用户测试数据"""
        users = []
        
        # 管理员用户
        users.append({
            'uuid': str(uuid.uuid4()),
            'username': 'admin',
            'email': 'admin@jobfirst.com',
            'password_hash': 'hashed_admin_password',
            'first_name': 'Admin',
            'last_name': 'User',
            'role': 'admin',
            'status': 'active',
            'email_verified': True,
            'phone_verified': True,
            'created_at': datetime.now() - timedelta(days=365)
        })
        
        # 普通用户
        first_names = ['John', 'Jane', 'Bob', 'Alice', 'Charlie', 'Diana', 'Eve', 'Frank', 'Grace', 'Henry']
        last_names = ['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis', 'Rodriguez', 'Martinez']
        
        for i in range(count):
            first_name = random.choice(first_names)
            last_name = random.choice(last_names)
            username = f"{first_name.lower()}_{last_name.lower()}_{i+1}"
            email = f"{username}@example.com"
            
            users.append({
                'uuid': str(uuid.uuid4()),
                'username': username,
                'email': email,
                'password_hash': f'hashed_password_{i+1}',
                'first_name': first_name,
                'last_name': last_name,
                'role': 'user',
                'status': random.choice(['active', 'active', 'active', 'inactive']),
                'email_verified': random.choice([True, True, False]),
                'phone_verified': random.choice([True, False]),
                'created_at': datetime.now() - timedelta(days=random.randint(1, 365))
            })
        
        self.users = users
        return users
    
    def generate_skills(self) -> List[Dict[str, Any]]:
        """生成技能测试数据"""
        skills_data = [
            # 编程语言
            {'name': 'Python', 'category': 'Programming', 'description': 'Python programming language', 'skill_level': 'advanced'},
            {'name': 'JavaScript', 'category': 'Programming', 'description': 'JavaScript programming language', 'skill_level': 'intermediate'},
            {'name': 'Java', 'category': 'Programming', 'description': 'Java programming language', 'skill_level': 'advanced'},
            {'name': 'C++', 'category': 'Programming', 'description': 'C++ programming language', 'skill_level': 'intermediate'},
            {'name': 'Go', 'category': 'Programming', 'description': 'Go programming language', 'skill_level': 'beginner'},
            
            # 前端框架
            {'name': 'React', 'category': 'Frontend', 'description': 'React.js frontend framework', 'skill_level': 'advanced'},
            {'name': 'Vue.js', 'category': 'Frontend', 'description': 'Vue.js frontend framework', 'skill_level': 'intermediate'},
            {'name': 'Angular', 'category': 'Frontend', 'description': 'Angular frontend framework', 'skill_level': 'intermediate'},
            
            # 后端框架
            {'name': 'Node.js', 'category': 'Backend', 'description': 'Node.js backend framework', 'skill_level': 'advanced'},
            {'name': 'Django', 'category': 'Backend', 'description': 'Django Python framework', 'skill_level': 'intermediate'},
            {'name': 'Spring Boot', 'category': 'Backend', 'description': 'Spring Boot Java framework', 'skill_level': 'advanced'},
            
            # 数据库
            {'name': 'MySQL', 'category': 'Database', 'description': 'MySQL database management', 'skill_level': 'advanced'},
            {'name': 'PostgreSQL', 'category': 'Database', 'description': 'PostgreSQL database management', 'skill_level': 'intermediate'},
            {'name': 'MongoDB', 'category': 'Database', 'description': 'MongoDB NoSQL database', 'skill_level': 'intermediate'},
            {'name': 'Redis', 'category': 'Database', 'description': 'Redis in-memory database', 'skill_level': 'intermediate'},
            
            # DevOps
            {'name': 'Docker', 'category': 'DevOps', 'description': 'Docker containerization', 'skill_level': 'advanced'},
            {'name': 'Kubernetes', 'category': 'DevOps', 'description': 'Kubernetes orchestration', 'skill_level': 'intermediate'},
            {'name': 'AWS', 'category': 'DevOps', 'description': 'Amazon Web Services', 'skill_level': 'intermediate'},
            {'name': 'Azure', 'category': 'DevOps', 'description': 'Microsoft Azure cloud', 'skill_level': 'beginner'},
            
            # 软技能
            {'name': 'Leadership', 'category': 'Soft Skills', 'description': 'Team leadership and management', 'skill_level': 'advanced'},
            {'name': 'Communication', 'category': 'Soft Skills', 'description': 'Effective communication skills', 'skill_level': 'advanced'},
            {'name': 'Problem Solving', 'category': 'Soft Skills', 'description': 'Analytical problem solving', 'skill_level': 'advanced'},
            {'name': 'Project Management', 'category': 'Soft Skills', 'description': 'Project planning and execution', 'skill_level': 'intermediate'},
        ]
        
        self.skills = skills_data
        return skills_data
    
    def generate_companies(self) -> List[Dict[str, Any]]:
        """生成公司测试数据"""
        companies_data = [
            {
                'name': 'TechCorp Inc',
                'industry': 'Technology',
                'size': 'large',
                'location': 'San Francisco, CA',
                'website': 'https://techcorp.com',
                'description': 'Leading technology company specializing in AI and machine learning'
            },
            {
                'name': 'StartupXYZ',
                'industry': 'Technology',
                'size': 'startup',
                'location': 'Austin, TX',
                'website': 'https://startupxyz.com',
                'description': 'Innovative startup company focused on blockchain technology'
            },
            {
                'name': 'FinanceFirst',
                'industry': 'Finance',
                'size': 'medium',
                'location': 'New York, NY',
                'website': 'https://financefirst.com',
                'description': 'Financial services company providing investment solutions'
            },
            {
                'name': 'HealthTech',
                'industry': 'Healthcare',
                'size': 'medium',
                'location': 'Boston, MA',
                'website': 'https://healthtech.com',
                'description': 'Healthcare technology company developing medical software'
            },
            {
                'name': 'EduTech Solutions',
                'industry': 'Education',
                'size': 'small',
                'location': 'Seattle, WA',
                'website': 'https://edutech.com',
                'description': 'Educational technology company creating learning platforms'
            },
            {
                'name': 'GreenEnergy Corp',
                'industry': 'Energy',
                'size': 'large',
                'location': 'Denver, CO',
                'website': 'https://greenenergy.com',
                'description': 'Renewable energy company developing sustainable solutions'
            }
        ]
        
        self.companies = companies_data
        return companies_data
    
    def generate_positions(self) -> List[Dict[str, Any]]:
        """生成职位测试数据"""
        positions_data = [
            {'name': 'Software Engineer', 'category': 'Engineering', 'description': 'Full-stack software development'},
            {'name': 'Senior Software Engineer', 'category': 'Engineering', 'description': 'Senior-level software development'},
            {'name': 'Product Manager', 'category': 'Management', 'description': 'Product strategy and management'},
            {'name': 'Data Scientist', 'category': 'Analytics', 'description': 'Data analysis and machine learning'},
            {'name': 'UX Designer', 'category': 'Design', 'description': 'User experience design'},
            {'name': 'UI Designer', 'category': 'Design', 'description': 'User interface design'},
            {'name': 'DevOps Engineer', 'category': 'Engineering', 'description': 'Infrastructure and deployment'},
            {'name': 'Marketing Manager', 'category': 'Marketing', 'description': 'Digital marketing and growth'},
            {'name': 'Sales Manager', 'category': 'Sales', 'description': 'Sales strategy and management'},
            {'name': 'HR Manager', 'category': 'Human Resources', 'description': 'Human resources management'},
            {'name': 'Business Analyst', 'category': 'Analytics', 'description': 'Business analysis and strategy'},
            {'name': 'Project Manager', 'category': 'Management', 'description': 'Project planning and execution'}
        ]
        
        self.positions = positions_data
        return positions_data
    
    def generate_resumes(self, user_count: int = 50) -> List[Dict[str, Any]]:
        """生成简历测试数据"""
        resumes = []
        
        for i in range(user_count):
            resume = {
                'user_id': i + 1,
                'title': f'Resume {i + 1}',
                'file_path': f'/resumes/resume_{i + 1}.pdf',
                'file_size': random.randint(100000, 2000000),
                'parsing_status': random.choice(['completed', 'completed', 'completed', 'pending']),
                'is_public': random.choice([True, False]),
                'view_count': random.randint(0, 100),
                'creation_mode': random.choice(['manual', 'upload', 'ai_generated']),
                'created_at': datetime.now() - timedelta(days=random.randint(1, 365))
            }
            resumes.append(resume)
        
        self.resumes = resumes
        return resumes
    
    def generate_work_experiences(self, resume_count: int = 50) -> List[Dict[str, Any]]:
        """生成工作经历测试数据"""
        work_experiences = []
        
        for i in range(resume_count):
            # 每个简历1-3个工作经历
            exp_count = random.randint(1, 3)
            for j in range(exp_count):
                start_date = datetime.now() - timedelta(days=random.randint(30, 2000))
                end_date = start_date + timedelta(days=random.randint(180, 1000))
                
                work_exp = {
                    'resume_metadata_id': i + 1,
                    'company_name': random.choice(self.companies)['name'],
                    'position': random.choice(self.positions)['name'],
                    'start_date': start_date.date(),
                    'end_date': end_date.date() if random.choice([True, False]) else None,
                    'is_current': random.choice([True, False]),
                    'description': f'Worked as {random.choice(self.positions)["name"]} at {random.choice(self.companies)["name"]}',
                    'achievements': f'Led multiple successful projects and improved team productivity by {random.randint(10, 50)}%',
                    'location': random.choice(['San Francisco, CA', 'New York, NY', 'Austin, TX', 'Boston, MA', 'Seattle, WA'])
                }
                work_experiences.append(work_exp)
        
        self.work_experiences = work_experiences
        return work_experiences
    
    def generate_projects(self, resume_count: int = 50) -> List[Dict[str, Any]]:
        """生成项目经验测试数据"""
        projects = []
        
        for i in range(resume_count):
            # 每个简历0-2个项目
            proj_count = random.randint(0, 2)
            for j in range(proj_count):
                start_date = datetime.now() - timedelta(days=random.randint(30, 1000))
                end_date = start_date + timedelta(days=random.randint(30, 300))
                
                project = {
                    'resume_metadata_id': i + 1,
                    'name': f'Project {j + 1}',
                    'description': f'Developed a {random.choice(["web application", "mobile app", "API", "database system"])} using {random.choice(["Python", "JavaScript", "Java", "Go"])}',
                    'start_date': start_date.date(),
                    'end_date': end_date.date(),
                    'technologies': ', '.join(random.sample([skill['name'] for skill in self.skills[:10]], random.randint(2, 5))),
                    'project_url': f'https://github.com/user/project_{j + 1}',
                    'github_url': f'https://github.com/user/project_{j + 1}'
                }
                projects.append(project)
        
        self.projects = projects
        return projects
    
    def generate_educations(self, resume_count: int = 50) -> List[Dict[str, Any]]:
        """生成教育背景测试数据"""
        educations = []
        
        institutions = [
            'Stanford University', 'MIT', 'Harvard University', 'UC Berkeley',
            'Carnegie Mellon University', 'Georgia Tech', 'University of Washington',
            'University of Texas', 'University of Michigan', 'Cornell University'
        ]
        
        degrees = ['Bachelor of Science', 'Master of Science', 'PhD', 'Bachelor of Arts', 'Master of Business Administration']
        fields = ['Computer Science', 'Software Engineering', 'Data Science', 'Information Technology', 'Business Administration']
        
        for i in range(resume_count):
            # 每个简历1-2个教育背景
            edu_count = random.randint(1, 2)
            for j in range(edu_count):
                start_date = datetime.now() - timedelta(days=random.randint(1000, 3000))
                end_date = start_date + timedelta(days=random.randint(1000, 1500))
                
                education = {
                    'resume_metadata_id': i + 1,
                    'institution': random.choice(institutions),
                    'degree': random.choice(degrees),
                    'field_of_study': random.choice(fields),
                    'start_date': start_date.date(),
                    'end_date': end_date.date(),
                    'gpa': round(random.uniform(3.0, 4.0), 2),
                    'description': f'Studied {random.choice(fields)} with focus on {random.choice(["software development", "data analysis", "machine learning", "business management"])}'
                }
                educations.append(education)
        
        self.educations = educations
        return educations
    
    def generate_certifications(self, resume_count: int = 50) -> List[Dict[str, Any]]:
        """生成证书认证测试数据"""
        certifications = []
        
        cert_names = [
            'AWS Certified Solutions Architect',
            'Google Cloud Professional',
            'Microsoft Azure Fundamentals',
            'Certified Kubernetes Administrator',
            'PMP Certification',
            'Scrum Master Certification',
            'Data Science Professional',
            'Machine Learning Engineer'
        ]
        
        organizations = [
            'Amazon Web Services', 'Google Cloud', 'Microsoft', 'Linux Foundation',
            'Project Management Institute', 'Scrum Alliance', 'Coursera', 'Udacity'
        ]
        
        for i in range(resume_count):
            # 每个简历0-3个证书
            cert_count = random.randint(0, 3)
            for j in range(cert_count):
                issue_date = datetime.now() - timedelta(days=random.randint(30, 1000))
                expiry_date = issue_date + timedelta(days=365 * random.randint(1, 3))
                
                certification = {
                    'resume_metadata_id': i + 1,
                    'name': random.choice(cert_names),
                    'issuing_organization': random.choice(organizations),
                    'issue_date': issue_date.date(),
                    'expiry_date': expiry_date.date(),
                    'credential_id': f'CERT-{random.randint(100000, 999999)}',
                    'credential_url': f'https://certificates.org/verify/{random.randint(100000, 999999)}'
                }
                certifications.append(certification)
        
        self.certifications = certifications
        return certifications
    
    def generate_points_data(self, user_count: int = 50) -> List[Dict[str, Any]]:
        """生成积分系统测试数据"""
        points = []
        point_history = []
        
        for i in range(user_count):
            total_points = random.randint(100, 2000)
            used_points = random.randint(0, total_points // 2)
            available_points = total_points - used_points
            
            points.append({
                'user_id': i + 1,
                'total_points': total_points,
                'available_points': available_points,
                'used_points': used_points
            })
            
            # 生成积分历史
            actions = ['earn', 'spend', 'expire', 'bonus']
            descriptions = [
                '注册奖励', '完善资料奖励', '首次登录奖励', '每日签到奖励',
                '简历创建奖励', '技能认证奖励', '推荐好友奖励', '活动参与奖励'
            ]
            
            history_count = random.randint(3, 10)
            for j in range(history_count):
                action = random.choice(actions)
                points_change = random.randint(10, 100) if action == 'earn' else -random.randint(5, 50)
                
                point_history.append({
                    'user_id': i + 1,
                    'points_change': points_change,
                    'action_type': action,
                    'description': random.choice(descriptions),
                    'reference_type': random.choice(['registration', 'profile_completion', 'first_login', 'daily_checkin']),
                    'reference_id': random.randint(1, 100),
                    'created_at': datetime.now() - timedelta(days=random.randint(1, 365))
                })
        
        self.points = points
        self.point_history = point_history
        return points, point_history
    
    def generate_social_data(self, resume_count: int = 50, user_count: int = 50) -> List[Dict[str, Any]]:
        """生成社交互动测试数据"""
        comments = []
        likes = []
        shares = []
        
        # 生成评论
        for i in range(resume_count):
            comment_count = random.randint(0, 5)
            for j in range(comment_count):
                comment = {
                    'resume_metadata_id': i + 1,
                    'user_id': random.randint(1, user_count),
                    'comment': random.choice([
                        'Great resume! Very impressive experience.',
                        'Nice work on the project descriptions.',
                        'Good skills listed, well organized.',
                        'Could use more detail in the experience section.',
                        'Excellent formatting and structure.'
                    ]),
                    'is_public': random.choice([True, False]),
                    'created_at': datetime.now() - timedelta(days=random.randint(1, 365))
                }
                comments.append(comment)
        
        # 生成点赞
        for i in range(resume_count):
            like_count = random.randint(0, 10)
            liked_users = random.sample(range(1, user_count + 1), min(like_count, user_count))
            for user_id in liked_users:
                like = {
                    'resume_metadata_id': i + 1,
                    'user_id': user_id,
                    'created_at': datetime.now() - timedelta(days=random.randint(1, 365))
                }
                likes.append(like)
        
        # 生成分享
        for i in range(resume_count):
            share_count = random.randint(0, 3)
            for j in range(share_count):
                share = {
                    'resume_metadata_id': i + 1,
                    'user_id': random.randint(1, user_count),
                    'share_type': random.choice(['public', 'private', 'link']),
                    'share_url': f'https://jobfirst.com/resume/{i + 1}/share/{random.randint(100000, 999999)}',
                    'expires_at': datetime.now() + timedelta(days=random.randint(1, 30)) if random.choice([True, False]) else None,
                    'created_at': datetime.now() - timedelta(days=random.randint(1, 365))
                }
                shares.append(share)
        
        self.comments = comments
        self.likes = likes
        self.shares = shares
        return comments, likes, shares
    
    def generate_all_data(self, user_count: int = 50) -> Dict[str, Any]:
        """生成所有测试数据"""
        print("🚀 开始生成Future版测试数据...")
        
        # 生成基础数据
        users = self.generate_users(user_count)
        skills = self.generate_skills()
        companies = self.generate_companies()
        positions = self.generate_positions()
        
        # 生成业务数据
        resumes = self.generate_resumes(user_count)
        work_experiences = self.generate_work_experiences(user_count)
        projects = self.generate_projects(user_count)
        educations = self.generate_educations(user_count)
        certifications = self.generate_certifications(user_count)
        
        # 生成积分数据
        points, point_history = self.generate_points_data(user_count)
        
        # 生成社交数据
        comments, likes, shares = self.generate_social_data(user_count, user_count)
        
        # 汇总所有数据
        all_data = {
            'users': users,
            'skills': skills,
            'companies': companies,
            'positions': positions,
            'resumes': resumes,
            'work_experiences': work_experiences,
            'projects': projects,
            'educations': educations,
            'certifications': certifications,
            'points': points,
            'point_history': point_history,
            'comments': comments,
            'likes': likes,
            'shares': shares,
            'generated_at': datetime.now().isoformat(),
            'total_records': len(users) + len(skills) + len(companies) + len(positions) + 
                           len(resumes) + len(work_experiences) + len(projects) + 
                           len(educations) + len(certifications) + len(points) + 
                           len(point_history) + len(comments) + len(likes) + len(shares)
        }
        
        print(f"✅ 测试数据生成完成！")
        print(f"📊 数据统计:")
        print(f"   • 用户: {len(users)} 个")
        print(f"   • 技能: {len(skills)} 个")
        print(f"   • 公司: {len(companies)} 个")
        print(f"   • 职位: {len(positions)} 个")
        print(f"   • 简历: {len(resumes)} 个")
        print(f"   • 工作经历: {len(work_experiences)} 个")
        print(f"   • 项目: {len(projects)} 个")
        print(f"   • 教育背景: {len(educations)} 个")
        print(f"   • 证书: {len(certifications)} 个")
        print(f"   • 积分记录: {len(point_history)} 个")
        print(f"   • 评论: {len(comments)} 个")
        print(f"   • 点赞: {len(likes)} 个")
        print(f"   • 分享: {len(shares)} 个")
        print(f"   • 总记录数: {all_data['total_records']} 个")
        
        return all_data
    
    def save_to_json(self, data: Dict[str, Any], filename: str = 'future_test_data.json'):
        """保存数据到JSON文件"""
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False, default=str)
        print(f"💾 数据已保存到: {filename}")
    
    def generate_sql_scripts(self, data: Dict[str, Any]):
        """生成SQL插入脚本"""
        sql_scripts = []
        
        # 用户数据SQL
        users_sql = "INSERT INTO users (uuid, username, email, password_hash, first_name, last_name, role, status, email_verified, phone_verified, created_at) VALUES\n"
        for user in data['users']:
            users_sql += f"('{user['uuid']}', '{user['username']}', '{user['email']}', '{user['password_hash']}', '{user['first_name']}', '{user['last_name']}', '{user['role']}', '{user['status']}', {user['email_verified']}, {user['phone_verified']}, '{user['created_at']}'),\n"
        users_sql = users_sql.rstrip(',\n') + ';\n'
        sql_scripts.append(users_sql)
        
        # 技能数据SQL
        skills_sql = "INSERT INTO skills (name, category, description, skill_level) VALUES\n"
        for skill in data['skills']:
            skills_sql += f"('{skill['name']}', '{skill['category']}', '{skill['description']}', '{skill['skill_level']}'),\n"
        skills_sql = skills_sql.rstrip(',\n') + ';\n'
        sql_scripts.append(skills_sql)
        
        # 保存SQL脚本
        with open('future_test_data.sql', 'w', encoding='utf-8') as f:
            f.write('-- Future版测试数据SQL脚本\n')
            f.write('-- 生成时间: ' + datetime.now().isoformat() + '\n\n')
            for script in sql_scripts:
                f.write(script + '\n')
        
        print("💾 SQL脚本已保存到: future_test_data.sql")

def main():
    """主函数"""
    generator = FutureTestDataGenerator()
    
    # 生成测试数据
    data = generator.generate_all_data(user_count=50)
    
    # 保存到JSON文件
    generator.save_to_json(data, 'future_test_data.json')
    
    # 生成SQL脚本
    generator.generate_sql_scripts(data)
    
    print("\n🎉 Future版测试数据生成完成！")
    print("📁 生成的文件:")
    print("   • future_test_data.json - JSON格式数据")
    print("   • future_test_data.sql - SQL插入脚本")

if __name__ == '__main__':
    main()
