// MongoDB初始化脚本
// 创建应用数据库和用户

// 切换到应用数据库
db = db.getSiblingDB('looma_independent');

// 创建应用用户
db.createUser({
  user: 'looma_user',
  pwd: 'looma_password',
  roles: [
    {
      role: 'readWrite',
      db: 'looma_independent'
    }
  ]
});

// 创建基础集合
db.createCollection('users');
db.createCollection('resumes');
db.createCollection('companies');
db.createCollection('jobs');
db.createCollection('projects');
db.createCollection('skills');

// 创建索引
db.users.createIndex({ "email": 1 }, { unique: true });
db.users.createIndex({ "username": 1 }, { unique: true });
db.resumes.createIndex({ "user_id": 1 });
db.resumes.createIndex({ "created_at": -1 });
db.companies.createIndex({ "name": 1 });
db.jobs.createIndex({ "company_id": 1 });
db.jobs.createIndex({ "created_at": -1 });

print('MongoDB数据库初始化完成');
