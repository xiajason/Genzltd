-- 增强版职位匹配系统 - 向量数据库表结构
-- 创建时间: 2025-09-18
-- 用途: 存储简历和职位的向量化数据

-- 创建简历向量表
CREATE TABLE IF NOT EXISTS resume_vectors (
    id SERIAL PRIMARY KEY,
    resume_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    content_vector vector(384),           -- 简历内容向量 (sentence-transformers/all-MiniLM-L6-v2)
    skills_vector vector(384),            -- 技能向量
    experience_vector vector(384),        -- 经验向量
    education_vector vector(384),         -- 教育背景向量
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- 添加约束
    CONSTRAINT fk_resume_vectors_resume_id FOREIGN KEY (resume_id) REFERENCES resume_metadata(id) ON DELETE CASCADE,
    CONSTRAINT fk_resume_vectors_user_id FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    
    -- 添加唯一约束
    CONSTRAINT uk_resume_vectors_resume_id UNIQUE (resume_id)
);

-- 创建职位向量表
CREATE TABLE IF NOT EXISTS job_vectors (
    id SERIAL PRIMARY KEY,
    job_id INTEGER NOT NULL,
    company_id INTEGER NOT NULL,
    description_vector vector(384),       -- 职位描述向量
    requirements_vector vector(384),      -- 职位要求向量
    skills_vector vector(384),            -- 技能要求向量
    experience_vector vector(384),        -- 经验要求向量
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- 添加约束
    CONSTRAINT fk_job_vectors_job_id FOREIGN KEY (job_id) REFERENCES jobs(id) ON DELETE CASCADE,
    CONSTRAINT fk_job_vectors_company_id FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE,
    
    -- 添加唯一约束
    CONSTRAINT uk_job_vectors_job_id UNIQUE (job_id)
);

-- 创建匹配结果表
CREATE TABLE IF NOT EXISTS matching_results (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    resume_id INTEGER NOT NULL,
    job_id INTEGER NOT NULL,
    match_score FLOAT NOT NULL,           -- 总体匹配分数 (0-1)
    semantic_score FLOAT,                 -- 语义相似度分数
    skills_score FLOAT,                   -- 技能匹配分数
    experience_score FLOAT,               -- 经验匹配分数
    education_score FLOAT,                -- 教育匹配分数
    cultural_score FLOAT,                 -- 文化匹配分数
    breakdown JSONB,                      -- 详细匹配分析
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- 添加约束
    CONSTRAINT fk_matching_results_user_id FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_matching_results_resume_id FOREIGN KEY (resume_id) REFERENCES resume_metadata(id) ON DELETE CASCADE,
    CONSTRAINT fk_matching_results_job_id FOREIGN KEY (job_id) REFERENCES jobs(id) ON DELETE CASCADE,
    
    -- 添加唯一约束
    CONSTRAINT uk_matching_results_unique UNIQUE (user_id, resume_id, job_id)
);

-- 创建向量索引 (使用ivfflat算法)
-- 简历向量索引
CREATE INDEX IF NOT EXISTS idx_resume_content_vector 
ON resume_vectors USING ivfflat (content_vector vector_cosine_ops) WITH (lists = 100);

CREATE INDEX IF NOT EXISTS idx_resume_skills_vector 
ON resume_vectors USING ivfflat (skills_vector vector_cosine_ops) WITH (lists = 100);

CREATE INDEX IF NOT EXISTS idx_resume_experience_vector 
ON resume_vectors USING ivfflat (experience_vector vector_cosine_ops) WITH (lists = 100);

-- 职位向量索引
CREATE INDEX IF NOT EXISTS idx_job_description_vector 
ON job_vectors USING ivfflat (description_vector vector_cosine_ops) WITH (lists = 100);

CREATE INDEX IF NOT EXISTS idx_job_requirements_vector 
ON job_vectors USING ivfflat (requirements_vector vector_cosine_ops) WITH (lists = 100);

CREATE INDEX IF NOT EXISTS idx_job_skills_vector 
ON job_vectors USING ivfflat (skills_vector vector_cosine_ops) WITH (lists = 100);

-- 匹配结果索引
CREATE INDEX IF NOT EXISTS idx_matching_results_user_id ON matching_results(user_id);
CREATE INDEX IF NOT EXISTS idx_matching_results_resume_id ON matching_results(resume_id);
CREATE INDEX IF NOT EXISTS idx_matching_results_job_id ON matching_results(job_id);
CREATE INDEX IF NOT EXISTS idx_matching_results_score ON matching_results(match_score DESC);
CREATE INDEX IF NOT EXISTS idx_matching_results_created_at ON matching_results(created_at DESC);

-- 添加注释
COMMENT ON TABLE resume_vectors IS '简历向量化数据表，存储简历的向量表示';
COMMENT ON TABLE job_vectors IS '职位向量化数据表，存储职位的向量表示';
COMMENT ON TABLE matching_results IS '匹配结果表，存储简历与职位的匹配分析结果';

COMMENT ON COLUMN resume_vectors.content_vector IS '简历整体内容的向量表示';
COMMENT ON COLUMN resume_vectors.skills_vector IS '简历技能部分的向量表示';
COMMENT ON COLUMN resume_vectors.experience_vector IS '简历经验部分的向量表示';
COMMENT ON COLUMN resume_vectors.education_vector IS '简历教育背景的向量表示';

COMMENT ON COLUMN job_vectors.description_vector IS '职位描述的向量表示';
COMMENT ON COLUMN job_vectors.requirements_vector IS '职位要求的向量表示';
COMMENT ON COLUMN job_vectors.skills_vector IS '职位技能要求的向量表示';
COMMENT ON COLUMN job_vectors.experience_vector IS '职位经验要求的向量表示';

COMMENT ON COLUMN matching_results.match_score IS '总体匹配分数，范围0-1';
COMMENT ON COLUMN matching_results.breakdown IS '详细的匹配分析结果，JSON格式';
