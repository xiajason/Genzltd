# 简历文件上传架构解决方案

## 📋 问题分析

用户反馈："客户上传的文件是PDF、DOCX、DOC文件，没有可能不经过解析就生产出表单需要的数据，就是在MySQL存储也不可能实现啊"

这个反馈非常准确，指出了原有架构的根本问题：
1. **文件格式复杂**: PDF、DOCX、DOC是二进制格式，无法直接存储到关系型数据库
2. **缺少解析机制**: 没有文件解析和内容提取的功能
3. **数据流不完整**: 从文件上传到结构化数据存储的流程断裂

## 🏗️ 完整架构设计

### **1. 数据存储层**

#### **文件存储表 (resume_files)**
```sql
CREATE TABLE resume_files (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    original_filename VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,      -- 文件在服务器上的路径
    file_size BIGINT NOT NULL,
    file_type VARCHAR(50) NOT NULL,       -- pdf, docx, doc
    mime_type VARCHAR(100) NOT NULL,
    upload_status VARCHAR(20) DEFAULT 'uploaded',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

#### **简历数据表 (resumes)**
```sql
CREATE TABLE resumes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    file_id INT,                          -- 关联到原始文件
    title VARCHAR(200) NOT NULL,
    content TEXT,                         -- 解析后的文本内容
    creation_mode VARCHAR(20) DEFAULT 'markdown', -- markdown, upload
    status VARCHAR(20) DEFAULT 'draft',
    
    -- 解析后的结构化数据 (JSON格式)
    personal_info JSON,                   -- 个人信息
    work_experience JSON,                 -- 工作经历
    education JSON,                       -- 教育背景
    skills JSON,                          -- 技能列表
    projects JSON,                        -- 项目经历
    certifications JSON,                  -- 证书资质
    
    -- 解析状态管理
    parsing_status VARCHAR(20) DEFAULT 'pending', -- pending, processing, completed, failed
    parsing_error TEXT,                   -- 解析错误信息
    ai_analysis JSON,                     -- AI分析结果
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

#### **解析任务表 (resume_parsing_tasks)**
```sql
CREATE TABLE resume_parsing_tasks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    resume_id INT NOT NULL,
    file_id INT NOT NULL,
    task_type VARCHAR(50) NOT NULL,       -- file_parsing, ai_analysis
    status VARCHAR(20) DEFAULT 'pending', -- pending, processing, completed, failed
    progress INT DEFAULT 0,               -- 0-100
    error_message TEXT,
    result_data JSON,                     -- 解析结果数据
    started_at TIMESTAMP NULL,
    completed_at TIMESTAMP NULL
);
```

### **2. 文件解析层**

#### **解析器接口设计**
```go
type FileParser interface {
    ParseFile(filePath string) (*ParsedResumeData, error)
    GetSupportedTypes() []string
}

type ParsedResumeData struct {
    Title           string                 `json:"title"`
    Content         string                 `json:"content"`
    PersonalInfo    map[string]interface{} `json:"personal_info"`
    WorkExperience  []map[string]interface{} `json:"work_experience"`
    Education       []map[string]interface{} `json:"education"`
    Skills          []string               `json:"skills"`
    Projects        []map[string]interface{} `json:"projects"`
    Certifications  []map[string]interface{} `json:"certifications"`
    Keywords        []string               `json:"keywords"`
    Confidence      float64                `json:"confidence"`
}
```

#### **多格式解析器**
- **PDFParser**: 解析PDF文件，提取文本和结构化数据
- **DOCXParser**: 解析DOCX文件，保持格式信息
- **DOCParser**: 解析DOC文件（需要转换为其他格式）

### **3. 异步处理流程**

```
1. 文件上传
   ↓
2. 保存文件到服务器
   ↓
3. 创建数据库记录 (resume_files)
   ↓
4. 创建简历记录 (resumes, status=pending)
   ↓
5. 创建解析任务 (resume_parsing_tasks)
   ↓
6. 异步启动文件解析
   ↓
7. 更新解析状态 (processing)
   ↓
8. 调用对应解析器
   ↓
9. 提取结构化数据
   ↓
10. 保存解析结果到数据库
    ↓
11. 更新简历状态 (completed)
```

## 🔧 技术实现

### **1. 后端实现**

#### **文件上传处理**
```go
func handleFileUpload(c *gin.Context, core *jobfirst.Core) {
    // 1. 验证用户身份
    // 2. 验证文件类型 (PDF/DOCX/DOC)
    // 3. 保存文件到服务器
    // 4. 创建数据库记录
    // 5. 启动异步解析任务
}
```

#### **文件解析管理器**
```go
type FileParserManager struct {
    parsers map[string]FileParser
}

func (m *FileParserManager) ParseFile(filePath, fileType string) (*ParsedResumeData, error) {
    parser, exists := m.parsers[fileType]
    if !exists {
        return nil, fmt.Errorf("不支持的文件类型: %s", fileType)
    }
    return parser.ParseFile(filePath)
}
```

#### **异步解析处理**
```go
func startFileParsing(resumeID, fileID uint, filePath, fileType string, core *jobfirst.Core) {
    // 1. 更新任务状态为processing
    // 2. 调用解析器
    // 3. 提取结构化数据
    // 4. 保存到数据库
    // 5. 更新任务状态为completed
}
```

### **2. 前端实现**

#### **文件上传组件**
```typescript
// 支持拖拽上传、文件类型验证、进度显示
const handleFileUpload = async (files: any[]) => {
    const response = await resumeService.createFromFile(file, title);
    if (response.code === 200) {
        // 显示解析进度
        // 轮询解析状态
    }
};
```

#### **解析状态监控**
```typescript
// 轮询解析状态，显示进度
const pollParsingStatus = async (resumeId: string) => {
    const status = await resumeService.getParsingStatus(resumeId);
    if (status === 'completed') {
        // 跳转到简历详情页面
    } else if (status === 'failed') {
        // 显示错误信息
    }
};
```

## 📊 数据流转示例

### **PDF文件上传流程**

1. **用户上传**: `resume.pdf` (2MB)
2. **文件存储**: `/uploads/resumes/4_1757691577_resume.pdf`
3. **数据库记录**:
   ```json
   // resume_files表
   {
     "id": 1,
     "user_id": 4,
     "original_filename": "resume.pdf",
     "file_path": "/uploads/resumes/4_1757691577_resume.pdf",
     "file_size": 2097152,
     "file_type": "pdf",
     "mime_type": "application/pdf",
     "upload_status": "uploaded"
   }
   
   // resumes表
   {
     "id": 1,
     "user_id": 4,
     "file_id": 1,
     "title": "resume",
     "creation_mode": "upload",
     "parsing_status": "processing"
   }
   ```

4. **解析结果**:
   ```json
   // 解析后的结构化数据
   {
     "personal_info": {
       "name": "张三",
       "phone": "138-0000-0000",
       "email": "zhangsan@example.com"
     },
     "work_experience": [
       {
         "company": "某科技公司",
         "position": "软件工程师",
         "start_date": "2020-01",
         "end_date": "2023-12"
       }
     ],
     "skills": ["Go", "微服务", "数据库"],
     "confidence": 0.85
   }
   ```

## 🚀 优势特点

### **1. 完整的文件处理流程**
- ✅ **文件存储**: 原始文件安全保存
- ✅ **格式支持**: PDF、DOCX、DOC全覆盖
- ✅ **异步处理**: 不阻塞用户体验
- ✅ **状态跟踪**: 实时显示解析进度

### **2. 结构化数据提取**
- ✅ **智能解析**: 自动提取个人信息、工作经历等
- ✅ **数据验证**: 解析结果置信度评估
- ✅ **错误处理**: 完善的错误恢复机制
- ✅ **AI增强**: 可集成AI服务进行内容分析

### **3. 用户体验优化**
- ✅ **实时反馈**: 上传进度和解析状态显示
- ✅ **错误提示**: 清晰的错误信息和解决建议
- ✅ **平台适配**: H5和小程序端不同处理策略
- ✅ **数据预览**: 解析完成后可预览和编辑

## 📝 实施步骤

### **阶段1: 数据库准备**
1. 执行 `create_resume_tables.sql` 创建表结构
2. 配置文件上传目录权限
3. 测试数据库连接和表创建

### **阶段2: 后端开发**
1. 实现文件上传API (`/api/v1/resume/resumes/upload`)
2. 开发文件解析器 (PDF、DOCX、DOC)
3. 实现异步解析任务处理
4. 添加解析状态查询API

### **阶段3: 前端集成**
1. 更新简历创建页面支持文件上传
2. 实现文件上传组件和进度显示
3. 添加解析状态监控和轮询
4. 优化错误处理和用户提示

### **阶段4: 测试验证**
1. 测试不同格式文件上传
2. 验证解析结果准确性
3. 测试错误处理机制
4. 性能测试和优化

## 🎯 总结

通过这个完整的架构设计，我们解决了用户提出的核心问题：

1. **✅ 文件存储**: 原始PDF/DOCX/DOC文件安全存储
2. **✅ 内容解析**: 智能提取结构化数据
3. **✅ 数据存储**: 解析结果存储到MySQL数据库
4. **✅ 用户体验**: 异步处理，实时状态反馈

这个方案不仅解决了当前的文件上传问题，还为未来的AI增强、批量处理等功能奠定了坚实的基础。
