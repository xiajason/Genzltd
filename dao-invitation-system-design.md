# DAO成员邀请系统设计方案

**创建时间**: 2025年1月28日  
**版本**: v1.0  
**基于**: Zervigo利益相关方管理体系 + DAO治理需求  
**目标**: 实现完整的成员邀请链接和邮件系统  

---

## 🎯 系统架构设计

### 核心组件
1. **邀请链接生成器** - 基于加密token的安全链接
2. **邮件通知系统** - 集成Zervigo邮件服务
3. **角色权限管理** - 基于Zervigo角色体系
4. **审核验证机制** - 多级审核和验证
5. **网络关系分析** - 基于利益相关方网络

### 数据库设计

```sql
-- 邀请记录表
CREATE TABLE dao_invitations (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    invitation_id VARCHAR(255) UNIQUE NOT NULL,
    dao_id BIGINT NOT NULL,
    inviter_id VARCHAR(255) NOT NULL,
    invitee_email VARCHAR(255) NOT NULL,
    invitee_name VARCHAR(255),
    role_type ENUM('member', 'moderator', 'admin') DEFAULT 'member',
    invitation_type ENUM('direct', 'referral', 'public') DEFAULT 'direct',
    status ENUM('pending', 'accepted', 'expired', 'revoked') DEFAULT 'pending',
    token VARCHAR(512) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    accepted_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_dao_id (dao_id),
    INDEX idx_inviter_id (inviter_id),
    INDEX idx_invitee_email (invitee_email),
    INDEX idx_token (token),
    INDEX idx_status (status),
    INDEX idx_expires_at (expires_at)
);

-- 邀请审核记录表
CREATE TABLE dao_invitation_reviews (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    invitation_id VARCHAR(255) NOT NULL,
    reviewer_id VARCHAR(255) NOT NULL,
    review_status ENUM('approved', 'rejected', 'pending') DEFAULT 'pending',
    review_comment TEXT,
    reviewed_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (invitation_id) REFERENCES dao_invitations(invitation_id),
    INDEX idx_invitation_id (invitation_id),
    INDEX idx_reviewer_id (reviewer_id)
);

-- 邀请统计表
CREATE TABLE dao_invitation_stats (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    dao_id BIGINT NOT NULL,
    total_invitations INT DEFAULT 0,
    accepted_invitations INT DEFAULT 0,
    pending_invitations INT DEFAULT 0,
    expired_invitations INT DEFAULT 0,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    UNIQUE KEY unique_dao_id (dao_id)
);
```

---

## 🔧 技术实现方案

### 1. 邀请链接生成器

```typescript
// 邀请链接生成服务
export class InvitationLinkGenerator {
    private readonly baseUrl: string;
    private readonly jwtSecret: string;
    
    constructor(baseUrl: string, jwtSecret: string) {
        this.baseUrl = baseUrl;
        this.jwtSecret = jwtSecret;
    }
    
    /**
     * 生成邀请链接
     */
    async generateInvitationLink(invitationData: InvitationData): Promise<InvitationLink> {
        // 生成安全token
        const token = await this.generateSecureToken(invitationData);
        
        // 构建邀请链接
        const invitationUrl = `${this.baseUrl}/dao/invite/${token}`;
        
        // 存储邀请记录
        await this.storeInvitationRecord(invitationData, token);
        
        return {
            invitationId: invitationData.invitationId,
            token,
            url: invitationUrl,
            expiresAt: invitationData.expiresAt,
            qrCode: await this.generateQRCode(invitationUrl)
        };
    }
    
    /**
     * 验证邀请链接
     */
    async validateInvitationLink(token: string): Promise<InvitationValidationResult> {
        try {
            // 解密token
            const payload = await this.decryptToken(token);
            
            // 检查邀请是否过期
            if (new Date() > new Date(payload.expiresAt)) {
                return { valid: false, error: 'INVITATION_EXPIRED' };
            }
            
            // 检查邀请状态
            const invitation = await this.getInvitationByToken(token);
            if (!invitation || invitation.status !== 'pending') {
                return { valid: false, error: 'INVITATION_INVALID' };
            }
            
            return {
                valid: true,
                invitation: invitation,
                payload: payload
            };
        } catch (error) {
            return { valid: false, error: 'TOKEN_INVALID' };
        }
    }
    
    /**
     * 生成安全token
     */
    private async generateSecureToken(data: InvitationData): Promise<string> {
        const payload = {
            invitationId: data.invitationId,
            daoId: data.daoId,
            inviterId: data.inviterId,
            inviteeEmail: data.inviteeEmail,
            roleType: data.roleType,
            expiresAt: data.expiresAt,
            timestamp: Date.now()
        };
        
        return jwt.sign(payload, this.jwtSecret, { 
            expiresIn: '7d',
            algorithm: 'HS256'
        });
    }
}
```

### 2. 邮件通知系统

```typescript
// 邮件通知服务
export class InvitationEmailService {
    private readonly emailClient: EmailClient;
    private readonly templateEngine: TemplateEngine;
    
    constructor(emailClient: EmailClient, templateEngine: TemplateEngine) {
        this.emailClient = emailClient;
        this.templateEngine = templateEngine;
    }
    
    /**
     * 发送邀请邮件
     */
    async sendInvitationEmail(invitation: InvitationData): Promise<void> {
        const template = await this.getEmailTemplate('dao-invitation');
        const htmlContent = await this.templateEngine.render(template, {
            inviterName: invitation.inviterName,
            daoName: invitation.daoName,
            daoDescription: invitation.daoDescription,
            invitationUrl: invitation.url,
            roleType: invitation.roleType,
            expiresAt: invitation.expiresAt,
            daoLogo: invitation.daoLogo
        });
        
        await this.emailClient.send({
            to: invitation.inviteeEmail,
            subject: `邀请您加入 ${invitation.daoName} DAO`,
            html: htmlContent,
            attachments: [
                {
                    filename: 'invitation-qr.png',
                    content: invitation.qrCode,
                    contentType: 'image/png'
                }
            ]
        });
    }
    
    /**
     * 发送提醒邮件
     */
    async sendReminderEmail(invitation: InvitationData): Promise<void> {
        const template = await this.getEmailTemplate('dao-invitation-reminder');
        const htmlContent = await this.templateEngine.render(template, {
            inviterName: invitation.inviterName,
            daoName: invitation.daoName,
            invitationUrl: invitation.url,
            daysRemaining: this.calculateDaysRemaining(invitation.expiresAt)
        });
        
        await this.emailClient.send({
            to: invitation.inviteeEmail,
            subject: `提醒：${invitation.daoName} DAO邀请即将过期`,
            html: htmlContent
        });
    }
}
```

### 3. tRPC API实现

```typescript
// 邀请系统API路由
export const invitationRouter = router({
    // 创建邀请
    createInvitation: procedure
        .input(z.object({
            daoId: z.string(),
            inviteeEmail: z.string().email(),
            inviteeName: z.string().optional(),
            roleType: z.enum(['member', 'moderator', 'admin']).default('member'),
            invitationType: z.enum(['direct', 'referral', 'public']).default('direct'),
            expiresInDays: z.number().min(1).max(30).default(7)
        }))
        .mutation(async ({ input, ctx }) => {
            const { user } = ctx;
            
            // 验证用户权限
            if (!await canInviteMembers(user.id, input.daoId)) {
                throw new TRPCError({
                    code: 'FORBIDDEN',
                    message: '您没有邀请成员的权限'
                });
            }
            
            // 生成邀请
            const invitation = await invitationService.createInvitation({
                daoId: input.daoId,
                inviterId: user.id,
                inviteeEmail: input.inviteeEmail,
                inviteeName: input.inviteeName,
                roleType: input.roleType,
                invitationType: input.invitationType,
                expiresInDays: input.expiresInDays
            });
            
            // 发送邮件
            await emailService.sendInvitationEmail(invitation);
            
            return {
                success: true,
                invitation: invitation,
                message: '邀请已发送'
            };
        }),
    
    // 验证邀请链接
    validateInvitation: procedure
        .input(z.object({
            token: z.string()
        }))
        .query(async ({ input }) => {
            const result = await invitationService.validateInvitationLink(input.token);
            
            if (!result.valid) {
                throw new TRPCError({
                    code: 'BAD_REQUEST',
                    message: result.error
                });
            }
            
            return {
                valid: true,
                invitation: result.invitation
            };
        }),
    
    // 接受邀请
    acceptInvitation: procedure
        .input(z.object({
            token: z.string(),
            userData: z.object({
                name: z.string(),
                avatar: z.string().optional()
            }).optional()
        }))
        .mutation(async ({ input, ctx }) => {
            const { user } = ctx;
            
            // 验证邀请
            const validation = await invitationService.validateInvitationLink(input.token);
            if (!validation.valid) {
                throw new TRPCError({
                    code: 'BAD_REQUEST',
                    message: '邀请链接无效或已过期'
                });
            }
            
            // 接受邀请
            const result = await invitationService.acceptInvitation({
                token: input.token,
                userId: user.id,
                userData: input.userData
            });
            
            return {
                success: true,
                daoId: validation.invitation.daoId,
                roleType: validation.invitation.roleType,
                message: '成功加入DAO'
            };
        }),
    
    // 获取邀请列表
    getInvitations: procedure
        .input(z.object({
            daoId: z.string(),
            status: z.enum(['pending', 'accepted', 'expired', 'revoked']).optional(),
            page: z.number().min(1).default(1),
            limit: z.number().min(1).max(100).default(20)
        }))
        .query(async ({ input, ctx }) => {
            const { user } = ctx;
            
            // 验证权限
            if (!await canManageInvitations(user.id, input.daoId)) {
                throw new TRPCError({
                    code: 'FORBIDDEN',
                    message: '您没有查看邀请列表的权限'
                });
            }
            
            const invitations = await invitationService.getInvitations({
                daoId: input.daoId,
                status: input.status,
                page: input.page,
                limit: input.limit
            });
            
            return invitations;
        })
});
```

---

## 🎨 前端界面设计

### 1. 邀请管理界面

```tsx
// 邀请管理组件
export const InvitationManagement: React.FC<{ daoId: string }> = ({ daoId }) => {
    const [invitations, setInvitations] = useState<Invitation[]>([]);
    const [showCreateForm, setShowCreateForm] = useState(false);
    
    const { data: daoData } = trpc.dao.getDAO.useQuery({ daoId });
    const { data: invitationList } = trpc.invitation.getInvitations.useQuery({
        daoId,
        page: 1,
        limit: 50
    });
    
    const createInvitationMutation = trpc.invitation.createInvitation.useMutation({
        onSuccess: () => {
            setShowCreateForm(false);
            // 刷新列表
        }
    });
    
    const handleCreateInvitation = async (data: CreateInvitationData) => {
        await createInvitationMutation.mutateAsync({
            daoId,
            ...data
        });
    };
    
    return (
        <div className="invitation-management">
            <div className="header">
                <h2>成员邀请管理</h2>
                <Button 
                    onClick={() => setShowCreateForm(true)}
                    variant="primary"
                >
                    邀请新成员
                </Button>
            </div>
            
            {/* 邀请统计 */}
            <InvitationStats daoId={daoId} />
            
            {/* 邀请列表 */}
            <InvitationList 
                invitations={invitationList?.invitations || []}
                onRefresh={() => {/* 刷新逻辑 */}}
            />
            
            {/* 创建邀请弹窗 */}
            {showCreateForm && (
                <CreateInvitationModal
                    daoData={daoData}
                    onSubmit={handleCreateInvitation}
                    onClose={() => setShowCreateForm(false)}
                />
            )}
        </div>
    );
};

// 创建邀请表单
export const CreateInvitationModal: React.FC<{
    daoData: DAOData;
    onSubmit: (data: CreateInvitationData) => void;
    onClose: () => void;
}> = ({ daoData, onSubmit, onClose }) => {
    const form = useForm<CreateInvitationData>({
        defaultValues: {
            inviteeEmail: '',
            inviteeName: '',
            roleType: 'member',
            invitationType: 'direct',
            expiresInDays: 7
        }
    });
    
    return (
        <Modal isOpen onClose={onClose}>
            <form onSubmit={form.handleSubmit(onSubmit)}>
                <h3>邀请新成员加入 {daoData.name}</h3>
                
                <FormField
                    label="邮箱地址"
                    error={form.formState.errors.inviteeEmail?.message}
                >
                    <Input
                        {...form.register('inviteeEmail', {
                            required: '请输入邮箱地址',
                            pattern: {
                                value: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
                                message: '请输入有效的邮箱地址'
                            }
                        })}
                        placeholder="example@email.com"
                    />
                </FormField>
                
                <FormField
                    label="姓名（可选）"
                    error={form.formState.errors.inviteeName?.message}
                >
                    <Input
                        {...form.register('inviteeName')}
                        placeholder="被邀请人姓名"
                    />
                </FormField>
                
                <FormField
                    label="角色类型"
                    error={form.formState.errors.roleType?.message}
                >
                    <Select {...form.register('roleType')}>
                        <option value="member">普通成员</option>
                        <option value="moderator">版主</option>
                        <option value="admin">管理员</option>
                    </Select>
                </FormField>
                
                <FormField
                    label="邀请类型"
                    error={form.formState.errors.invitationType?.message}
                >
                    <Select {...form.register('invitationType')}>
                        <option value="direct">直接邀请</option>
                        <option value="referral">推荐邀请</option>
                        <option value="public">公开邀请</option>
                    </Select>
                </FormField>
                
                <FormField
                    label="有效期（天）"
                    error={form.formState.errors.expiresInDays?.message}
                >
                    <Input
                        type="number"
                        {...form.register('expiresInDays', {
                            min: { value: 1, message: '最少1天' },
                            max: { value: 30, message: '最多30天' }
                        })}
                        min="1"
                        max="30"
                    />
                </FormField>
                
                <div className="actions">
                    <Button type="button" variant="secondary" onClick={onClose}>
                        取消
                    </Button>
                    <Button type="submit" variant="primary">
                        发送邀请
                    </Button>
                </div>
            </form>
        </Modal>
    );
};
```

### 2. 邀请接受页面

```tsx
// 邀请接受页面
export const InvitationAcceptPage: React.FC<{ token: string }> = ({ token }) => {
    const [invitation, setInvitation] = useState<Invitation | null>(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    
    const { data: validationResult } = trpc.invitation.validateInvitation.useQuery(
        { token },
        {
            onSuccess: (data) => {
                setInvitation(data.invitation);
                setLoading(false);
            },
            onError: (error) => {
                setError(error.message);
                setLoading(false);
            }
        }
    );
    
    const acceptInvitationMutation = trpc.invitation.acceptInvitation.useMutation({
        onSuccess: () => {
            // 跳转到DAO页面
            router.push(`/dao/${invitation?.daoId}`);
        }
    });
    
    if (loading) {
        return <LoadingSpinner />;
    }
    
    if (error || !invitation) {
        return (
            <div className="invitation-error">
                <h2>邀请无效</h2>
                <p>{error || '邀请链接无效或已过期'}</p>
                <Button onClick={() => router.push('/')}>
                    返回首页
                </Button>
            </div>
        );
    }
    
    return (
        <div className="invitation-accept">
            <div className="invitation-card">
                <div className="dao-info">
                    <img src={invitation.daoLogo} alt={invitation.daoName} />
                    <h2>{invitation.daoName}</h2>
                    <p>{invitation.daoDescription}</p>
                </div>
                
                <div className="invitation-details">
                    <h3>邀请详情</h3>
                    <p><strong>邀请人：</strong>{invitation.inviterName}</p>
                    <p><strong>角色：</strong>{getRoleDisplayName(invitation.roleType)}</p>
                    <p><strong>有效期至：</strong>{formatDate(invitation.expiresAt)}</p>
                </div>
                
                <div className="actions">
                    <Button 
                        onClick={() => acceptInvitationMutation.mutate({ token })}
                        loading={acceptInvitationMutation.isLoading}
                        variant="primary"
                    >
                        接受邀请
                    </Button>
                    <Button variant="secondary">
                        拒绝邀请
                    </Button>
                </div>
            </div>
        </div>
    );
};
```

---

## 🚀 实施计划

### 阶段一：基础功能开发（1周）
1. 数据库表创建和迁移
2. 邀请链接生成和验证API
3. 基础邮件发送功能
4. 简单的邀请管理界面

### 阶段二：高级功能开发（1周）
1. 邮件模板系统
2. 二维码生成功能
3. 邀请审核机制
4. 统计和分析功能

### 阶段三：用户体验优化（0.5周）
1. 响应式设计优化
2. 邮件模板美化
3. 错误处理完善
4. 性能优化

---

## 📊 预期效果

### 功能指标
- **邀请发送成功率**: >95%
- **邮件送达率**: >90%
- **邀请接受率**: >60%
- **系统响应时间**: <500ms

### 用户体验
- **邀请流程**: 3步完成邀请
- **邮件体验**: 美观的HTML邮件模板
- **移动端适配**: 100%响应式设计
- **错误处理**: 友好的错误提示

**基于Zervigo利益相关方设计经验，这个邀请系统将提供完整的成员管理解决方案！** 🎯
