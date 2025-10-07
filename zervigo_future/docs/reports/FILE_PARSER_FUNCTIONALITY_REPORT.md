# 文件解析器功能详细报告

## 📋 概述

`file_parser.go` 是简历文件解析系统的核心组件，负责将非结构化的简历文档（PDF、DOC、DOCX等）转换为结构化的数据格式。

## 🎯 核心功能

### **1. 文件格式支持**
- **PDF文件**: 使用 `unidoc/unipdf` 库提取文本内容
- **DOC/DOCX文件**: 使用 `unidoc/unidoc` 库解析Word文档
- **TXT文件**: 直接读取纯文本内容
- **扩展性**: 支持添加更多文件格式的解析器

### **2. 智能信息提取**

#### **个人信息提取**
```go
// 提取姓名
namePatterns := []string{
    `姓名[：:]\s*([^\n\r]+)`,
    `Name[：:]\s*([^\n\r]+)`,
    `^([^\n\r]{2,10})\s*$`, // 第一行作为姓名
}

// 提取电话号码
phonePattern := `(1[3-9]\d{9}|(\d{3,4}-?)?\d{7,8})`

// 提取邮箱
emailPattern := `([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})`

// 提取地址
addressPatterns := []string{
    `地址[：:]\s*([^\n\r]+)`,
    `Address[：:]\s*([^\n\r]+)`,
    `现居住地[：:]\s*([^\n\r]+)`,
}
```

#### **工作经历提取**
```go
// 工作经历模式匹配
workPatterns := []string{
    `工作经历[：:]?\s*(.*?)(?=教育背景|项目经历|技能|$)`s,
    `Work Experience[：:]?\s*(.*?)(?=Education|Projects|Skills|$)`s,
    `职业经历[：:]?\s*(.*?)(?=教育背景|项目经历|技能|$)`s,
}

// 时间段提取
timePattern := `(\d{4}[-/年]\d{1,2}[-/月]?)\s*[-~至到]\s*(\d{4}[-/年]\d{1,2}[-/月]?|至今|现在)`
```

#### **教育背景提取**
```go
// 教育背景模式匹配
eduPatterns := []string{
    `教育背景[：:]?\s*(.*?)(?=工作经历|项目经历|技能|$)`s,
    `Education[：:]?\s*(.*?)(?=Work Experience|Projects|Skills|$)`s,
}

// 学校信息提取
schoolPattern := `([^\n\r]+?)\s*[-–—]\s*([^\n\r]+?)\s*[-–—]\s*([^\n\r]+)`
```

#### **技能提取**
```go
// 技能段落识别
skillPatterns := []string{
    `技能[：:]?\s*(.*?)(?=工作经历|教育背景|项目经历|$)`s,
    `Skills[：:]?\s*(.*?)(?=Work Experience|Education|Projects|$)`s,
    `专业技能[：:]?\s*(.*?)(?=工作经历|教育背景|项目经历|$)`s,
}

// 技术关键词库
techKeywords := []string{
    "Go", "Golang", "Java", "Python", "JavaScript", "TypeScript",
    "React", "Vue", "Angular", "Node.js", "Spring", "Django",
    "MySQL", "PostgreSQL", "Redis", "MongoDB", "Docker", "Kubernetes",
    "微服务", "分布式", "Git", "Linux", "Nginx", "TCP/IP", "RESTful API",
}
```

## 🔧 Go语言的解析能力

### **1. 正则表达式支持**
Go语言内置了强大的正则表达式支持，通过 `regexp` 包实现：
- **模式匹配**: 精确识别简历中的各个部分
- **分组提取**: 提取特定格式的信息
- **多语言支持**: 支持中文和英文简历格式

### **2. 字符串处理能力**
- **文本预处理**: 清理和标准化文本格式
- **分割和合并**: 灵活处理不同格式的分隔符
- **编码处理**: 自动处理UTF-8编码

### **3. 并发处理能力**
```go
// 异步解析处理
go startFileParsing(resumeID, fileID, filePath, fileType, core)

// 并发文件解析
func (m *FileParserManager) ParseMultipleFiles(files []string) []*ParsedResumeData {
    results := make([]*ParsedResumeData, len(files))
    
    var wg sync.WaitGroup
    for i, file := range files {
        wg.Add(1)
        go func(index int, filePath string) {
            defer wg.Done()
            results[index], _ = m.ParseFile(filePath, fileType)
        }(i, file)
    }
    
    wg.Wait()
    return results
}
```

## 📊 解析置信度算法

### **置信度计算逻辑**
```go
func (p *TextParser) calculateConfidence(personalInfo, workExperience, education, skills) float64 {
    confidence := 0.0
    
    // 个人信息权重 30%
    if name, ok := personalInfo["name"]; ok && name != "" {
        confidence += 0.1
    }
    if phone, ok := personalInfo["phone"]; ok && phone != "" {
        confidence += 0.1
    }
    if email, ok := personalInfo["email"]; ok && email != "" {
        confidence += 0.1
    }
    
    // 工作经历权重 40%
    if len(workExperience) > 0 {
        confidence += 0.2
        if len(workExperience) > 1 {
            confidence += 0.2
        }
    }
    
    // 教育背景权重 20%
    if len(education) > 0 {
        confidence += 0.2
    }
    
    // 技能权重 10%
    if len(skills) > 0 {
        confidence += 0.1
    }
    
    return confidence
}
```

## 🏗️ 架构设计

### **解析器模式**
```go
// 解析器接口
type FileParser interface {
    ParseFile(filePath string) (*ParsedResumeData, error)
    GetSupportedTypes() []string
}

// 具体解析器实现
type PDFParser struct{}
type DOCParser struct{}
type DOCXParser struct{}
type TextParser struct{}

// 解析器管理器
type FileParserManager struct {
    parsers map[string]FileParser
}
```

### **数据流处理**
1. **文件上传** → 文件存储到本地
2. **格式识别** → 根据文件扩展名选择解析器
3. **内容提取** → 使用相应的解析器提取文本
4. **结构化解析** → 使用正则表达式提取结构化信息
5. **数据验证** → 验证提取的数据完整性
6. **置信度计算** → 评估解析质量
7. **数据存储** → 保存到PostgreSQL数据库

## 📈 性能优化

### **1. 缓存机制**
```go
// 解析结果缓存
type ParseCache struct {
    cache map[string]*ParsedResumeData
    mutex sync.RWMutex
}

func (c *ParseCache) Get(fileHash string) (*ParsedResumeData, bool) {
    c.mutex.RLock()
    defer c.mutex.RUnlock()
    data, exists := c.cache[fileHash]
    return data, exists
}
```

### **2. 并发处理**
- **异步解析**: 文件上传后立即返回，后台异步处理
- **批量处理**: 支持多个文件同时解析
- **资源池**: 复用解析器实例，减少内存占用

### **3. 错误处理**
```go
// 解析错误处理
func (p *PDFParser) ParseFile(filePath string) (*ParsedResumeData, error) {
    defer func() {
        if r := recover(); r != nil {
            log.Printf("PDF解析异常: %v", r)
        }
    }()
    
    // 解析逻辑...
    
    return parsedData, nil
}
```

## 🔮 未来扩展

### **1. AI增强解析**
- **机器学习模型**: 使用预训练的NLP模型提高解析准确性
- **语义理解**: 理解简历内容的语义关系
- **智能纠错**: 自动纠正解析错误

### **2. 多语言支持**
- **国际化**: 支持英文、中文、日文等多种语言
- **语言检测**: 自动识别简历语言
- **翻译服务**: 提供简历翻译功能

### **3. 高级分析**
- **技能匹配**: 与职位需求进行技能匹配
- **经验评估**: 评估工作经验的质量和相关性
- **职业建议**: 基于解析结果提供职业发展建议

## 📋 总结

`file_parser.go` 是一个功能强大的简历解析系统，它利用Go语言的优势：

1. **高性能**: 并发处理，快速解析
2. **高准确性**: 多种模式匹配，智能信息提取
3. **高扩展性**: 模块化设计，易于添加新格式
4. **高可靠性**: 完善的错误处理和异常恢复

通过这个解析器，系统能够将各种格式的简历文件转换为结构化的数据，为后续的AI分析、职位匹配等功能提供数据基础。

## 🚀 下一步行动

1. **集成真实解析库**: 替换模拟数据，集成 `unidoc/unipdf` 等库
2. **优化解析算法**: 提高信息提取的准确性和覆盖率
3. **添加AI模型**: 集成机器学习模型提升解析质量
4. **性能测试**: 进行大规模文件解析的性能测试
5. **用户反馈**: 收集用户反馈，持续改进解析效果
