# DAO Genie 用户数据整合计划

## 🎯 整合目标
将zervigo项目中的5个测试用户数据整合到DAO系统中，丰富测试用户群体。

## 📊 当前状况
- **DAO项目**: 只有2个测试用户
- **Zervigo项目**: 有5个完整的测试用户（张三、李四、王五、赵六、钱七）
- **数据库**: 分别运行在不同端口（DAO: 9506, Zervigo: 3306）

## 🔄 整合方案

### 方案1：扩展DAO成员表结构（推荐）

#### 1. 修改Prisma Schema
```prisma
// 在 dao-frontend-genie/prisma/schema.prisma 中扩展 DAOMember 模型
model DAOMember {
  id                    BigInt    @id @default(autoincrement())
  userId                String    @unique @map("user_id")
  username              String?   // 新增：用户名
  email                 String?   // 新增：邮箱
  firstName             String?   @map("first_name") // 新增：名字
  lastName              String?   @map("last_name")  // 新增：姓氏
  avatarUrl             String?   @map("avatar_url") // 新增：头像URL
  phone                 String?   // 新增：电话
  bio                   String?   @db.Text // 新增：个人简介
  location              String?   // 新增：位置
  website               String?   // 新增：网站
  githubUrl             String?   @map("github_url") // 新增：GitHub链接
  linkedinUrl           String?   @map("linkedin_url") // 新增：LinkedIn链接
  skills                Json?     // 新增：技能列表
  interests             Json?     // 新增：兴趣列表
  languages             Json?     // 新增：语言列表
  
  // 原有字段保持不变
  walletAddress         String?   @map("wallet_address")
  reputationScore       Int       @default(0) @map("reputation_score")
  contributionPoints    Int       @default(0) @map("contribution_points")
  joinDate              DateTime  @default(now()) @map("join_date")
  status                DAOStatus @default(ACTIVE)
  createdAt             DateTime  @default(now()) @map("created_at")
  updatedAt             DateTime  @updatedAt @map("updated_at")
  
  // 关联关系保持不变
  proposals             DAOProposal[] @relation("Proposer")
  votes                 DAOVote[] @relation("Voter")
  rewards               DAOReward[] @relation("Recipient")
  activities            DAOActivity[] @relation("User")

  @@map("dao_members")
}
```

#### 2. 数据迁移脚本
```sql
-- 创建数据迁移脚本：dao-frontend-genie/scripts/migrate-users.sql
USE dao_governance;

-- 从zervigo数据库迁移用户数据
INSERT INTO dao_members (
    user_id, username, email, first_name, last_name, avatar_url, phone,
    bio, location, website, github_url, linkedin_url, skills, interests, languages,
    reputation_score, contribution_points, status, created_at
) 
SELECT 
    u.uuid as user_id,
    u.username,
    u.email,
    u.first_name,
    u.last_name,
    u.avatar_url,
    u.phone,
    up.bio,
    up.location,
    up.website,
    up.github_url,
    up.linkedin_url,
    up.skills,
    up.interests,
    up.languages,
    -- 根据技能和兴趣生成初始积分
    CASE 
        WHEN JSON_CONTAINS(up.skills, '"React"') THEN 80
        WHEN JSON_CONTAINS(up.skills, '"Go"') THEN 90
        WHEN JSON_CONTAINS(up.skills, '"Java"') THEN 85
        ELSE 50
    END as reputation_score,
    CASE 
        WHEN JSON_CONTAINS(up.interests, '"开源"') THEN 60
        WHEN JSON_CONTAINS(up.interests, '"技术分享"') THEN 55
        ELSE 40
    END as contribution_points,
    'ACTIVE' as status,
    u.created_at
FROM jobfirst_v3.users u
LEFT JOIN jobfirst_v3.user_profiles up ON u.id = up.user_id
WHERE u.status = 'active' AND u.deleted_at IS NULL;
```

#### 3. 更新API接口
```typescript
// 在 dao-frontend-genie/src/server/api/routers/dao.ts 中更新获取成员接口
export const getMembers = procedure
  .input(z.object({
    page: z.number().default(1),
    limit: z.number().default(10),
    status: z.string().optional(),
  }))
  .query(async ({ input }) => {
    try {
      const { page, limit, status } = input;
      const skip = (page - 1) * limit;

      const where = {
        ...(status && { status: status as any }),
      };

      const [members, total] = await Promise.all([
        db.dAOMember.findMany({
          where,
          skip,
          take: limit,
          orderBy: {
            reputationScore: "desc",
          },
        }),
        db.dAOMember.count({ where }),
      ]);

      // 计算投票权重
      const membersWithVotingPower = members.map(member => ({
        ...member,
        votingPower: Math.floor((member.reputationScore * 0.6 + member.contributionPoints * 0.4) / 10),
        // 格式化技能和兴趣数据
        skillsList: member.skills ? JSON.parse(member.skills as string) : [],
        interestsList: member.interests ? JSON.parse(member.interests as string) : [],
        languagesList: member.languages ? JSON.parse(member.languages as string) : [],
      }));

      return {
        success: true,
        data: membersWithVotingPower,
        pagination: {
          page,
          limit,
          total,
          totalPages: Math.ceil(total / limit),
        },
      };
    } catch (error) {
      console.error("获取成员列表失败:", error);
      throw new Error("获取成员列表失败");
    }
  });
```

## 🚀 实施步骤

### 第1步：数据库Schema更新
1. 修改 `prisma/schema.prisma` 文件
2. 运行 `npx prisma db push` 更新数据库结构
3. 运行 `npx prisma generate` 重新生成客户端

### 第2步：数据迁移
1. 创建数据迁移脚本
2. 连接到zervigo数据库导出用户数据
3. 导入到DAO数据库

### 第3步：API接口更新
1. 更新成员相关的API接口
2. 添加用户信息显示功能
3. 更新前端组件

### 第4步：前端界面优化
1. 更新成员列表显示，展示更多用户信息
2. 添加用户头像和技能标签
3. 优化用户资料页面

## 📈 预期效果

整合完成后，DAO系统将拥有：
- **7个测试用户** (原有2个 + 新增5个)
- **丰富的用户信息** (技能、兴趣、联系方式等)
- **更真实的测试环境** (不同背景的用户)
- **更好的演示效果** (完整的用户资料展示)

## ⚠️ 注意事项

1. **数据库连接**: 确保能同时访问两个数据库
2. **数据一致性**: 迁移后保持用户数据的完整性
3. **权限管理**: 新增用户需要设置适当的DAO权限
4. **测试验证**: 迁移后需要全面测试所有功能

## 🎯 时间安排

- **第1天**: 数据库Schema更新和数据迁移
- **第2天**: API接口更新和测试
- **第3天**: 前端界面优化和整体测试

总计：3天完成用户数据整合
