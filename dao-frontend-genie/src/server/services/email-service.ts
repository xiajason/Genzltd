import nodemailer from 'nodemailer';
import { QRCodeSVG } from 'qrcode.react';

// 邮件配置接口
interface EmailConfig {
  host: string;
  port: number;
  secure: boolean;
  auth: {
    user: string;
    pass: string;
  };
}

// 邀请邮件数据接口
interface InvitationEmailData {
  invitationId: string;
  daoId: string;
  daoName: string;
  daoDescription?: string;
  daoLogo?: string;
  inviterName: string;
  inviterAvatar?: string;
  inviteeEmail: string;
  inviteeName?: string;
  roleType: 'member' | 'moderator' | 'admin';
  invitationUrl: string;
  expiresAt: Date;
}

// 邮件模板接口
interface EmailTemplate {
  subject: string;
  html: string;
  text?: string;
}

export class EmailService {
  private transporter: nodemailer.Transporter;
  private baseUrl: string;

  constructor(config: EmailConfig, baseUrl: string) {
    this.baseUrl = baseUrl;
    this.transporter = nodemailer.createTransporter({
      host: config.host,
      port: config.port,
      secure: config.secure,
      auth: config.auth,
    });
  }

  /**
   * 发送邀请邮件
   */
  async sendInvitationEmail(data: InvitationEmailData): Promise<void> {
    try {
      const template = this.generateInvitationEmailTemplate(data);
      
      // 生成二维码
      const qrCodeDataUrl = await this.generateQRCode(data.invitationUrl);
      
      const mailOptions = {
        from: `"${data.daoName} DAO" <noreply@dao-genie.com>`,
        to: data.inviteeEmail,
        subject: template.subject,
        html: template.html,
        text: template.text,
        attachments: [
          {
            filename: 'invitation-qr.png',
            content: qrCodeDataUrl.split(',')[1],
            encoding: 'base64',
            contentType: 'image/png'
          }
        ]
      };

      await this.transporter.sendMail(mailOptions);
      console.log(`邀请邮件已发送到: ${data.inviteeEmail}`);
    } catch (error) {
      console.error('发送邀请邮件失败:', error);
      throw new Error(`发送邀请邮件失败: ${error}`);
    }
  }

  /**
   * 发送邀请提醒邮件
   */
  async sendInvitationReminder(data: InvitationEmailData): Promise<void> {
    try {
      const template = this.generateReminderEmailTemplate(data);
      
      const mailOptions = {
        from: `"${data.daoName} DAO" <noreply@dao-genie.com>`,
        to: data.inviteeEmail,
        subject: template.subject,
        html: template.html,
        text: template.text
      };

      await this.transporter.sendMail(mailOptions);
      console.log(`邀请提醒邮件已发送到: ${data.inviteeEmail}`);
    } catch (error) {
      console.error('发送邀请提醒邮件失败:', error);
      throw new Error(`发送邀请提醒邮件失败: ${error}`);
    }
  }

  /**
   * 发送邀请接受确认邮件
   */
  async sendInvitationAcceptedEmail(data: InvitationEmailData): Promise<void> {
    try {
      const template = this.generateAcceptedEmailTemplate(data);
      
      const mailOptions = {
        from: `"${data.daoName} DAO" <noreply@dao-genie.com>`,
        to: data.inviteeEmail,
        subject: template.subject,
        html: template.html,
        text: template.text
      };

      await this.transporter.sendMail(mailOptions);
      console.log(`邀请接受确认邮件已发送到: ${data.inviteeEmail}`);
    } catch (error) {
      console.error('发送邀请接受确认邮件失败:', error);
      throw new Error(`发送邀请接受确认邮件失败: ${error}`);
    }
  }

  /**
   * 生成邀请邮件模板
   */
  private generateInvitationEmailTemplate(data: InvitationEmailData): EmailTemplate {
    const roleDisplayName = this.getRoleDisplayName(data.roleType);
    const expiresDate = this.formatDate(data.expiresAt);
    
    const subject = `邀请您加入 ${data.daoName} DAO`;
    
    const html = `
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DAO邀请</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f8fafc;
        }
        .container {
            background: white;
            border-radius: 12px;
            padding: 40px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
        }
        .logo {
            width: 80px;
            height: 80px;
            border-radius: 12px;
            margin: 0 auto 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 24px;
            font-weight: bold;
        }
        .title {
            font-size: 28px;
            font-weight: 700;
            color: #1a202c;
            margin-bottom: 10px;
        }
        .subtitle {
            font-size: 16px;
            color: #718096;
        }
        .content {
            margin: 30px 0;
        }
        .invitation-details {
            background: #f7fafc;
            border-radius: 8px;
            padding: 20px;
            margin: 20px 0;
        }
        .detail-item {
            display: flex;
            justify-content: space-between;
            margin-bottom: 10px;
            padding: 8px 0;
            border-bottom: 1px solid #e2e8f0;
        }
        .detail-item:last-child {
            border-bottom: none;
        }
        .detail-label {
            font-weight: 600;
            color: #4a5568;
        }
        .detail-value {
            color: #2d3748;
        }
        .cta-button {
            display: inline-block;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            text-decoration: none;
            padding: 16px 32px;
            border-radius: 8px;
            font-weight: 600;
            font-size: 16px;
            text-align: center;
            margin: 20px 0;
            transition: transform 0.2s;
        }
        .cta-button:hover {
            transform: translateY(-2px);
        }
        .qr-code {
            text-align: center;
            margin: 20px 0;
        }
        .qr-code img {
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }
        .footer {
            margin-top: 40px;
            padding-top: 20px;
            border-top: 1px solid #e2e8f0;
            text-align: center;
            color: #718096;
            font-size: 14px;
        }
        .warning {
            background: #fff5f5;
            border: 1px solid #fed7d7;
            border-radius: 8px;
            padding: 16px;
            margin: 20px 0;
            color: #c53030;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="logo">DAO</div>
            <h1 class="title">您收到了一个DAO邀请</h1>
            <p class="subtitle">来自 ${data.inviterName} 的邀请</p>
        </div>
        
        <div class="content">
            <p>您好 ${data.inviteeName || '朋友'}，</p>
            
            <p>我们很高兴地通知您，<strong>${data.inviterName}</strong> 邀请您加入 <strong>${data.daoName}</strong> DAO。</p>
            
            ${data.daoDescription ? `<p>${data.daoDescription}</p>` : ''}
            
            <div class="invitation-details">
                <div class="detail-item">
                    <span class="detail-label">DAO名称：</span>
                    <span class="detail-value">${data.daoName}</span>
                </div>
                <div class="detail-item">
                    <span class="detail-label">邀请人：</span>
                    <span class="detail-value">${data.inviterName}</span>
                </div>
                <div class="detail-item">
                    <span class="detail-label">邀请角色：</span>
                    <span class="detail-value">${roleDisplayName}</span>
                </div>
                <div class="detail-item">
                    <span class="detail-label">有效期至：</span>
                    <span class="detail-value">${expiresDate}</span>
                </div>
            </div>
            
            <div style="text-align: center;">
                <a href="${data.invitationUrl}" class="cta-button">
                    接受邀请并加入DAO
                </a>
            </div>
            
            <div class="qr-code">
                <p>或扫描二维码直接访问：</p>
                <img src="cid:invitation-qr.png" alt="邀请二维码" style="width: 200px; height: 200px;">
            </div>
            
            <div class="warning">
                <strong>注意：</strong>此邀请链接将在 ${expiresDate} 过期，请及时处理。
            </div>
            
            <p>如果您有任何问题，请随时联系我们。</p>
            
            <p>祝好，<br>${data.daoName} DAO 团队</p>
        </div>
        
        <div class="footer">
            <p>此邮件由 DAO Genie 系统自动发送，请勿回复。</p>
            <p>如果您没有请求此邀请，请忽略此邮件。</p>
        </div>
    </div>
</body>
</html>`;

    const text = `
您收到了一个DAO邀请

您好 ${data.inviteeName || '朋友'}，

${data.inviterName} 邀请您加入 ${data.daoName} DAO。

邀请详情：
- DAO名称：${data.daoName}
- 邀请人：${data.inviterName}
- 邀请角色：${roleDisplayName}
- 有效期至：${expiresDate}

请点击以下链接接受邀请：
${data.invitationUrl}

此邀请链接将在 ${expiresDate} 过期，请及时处理。

如果您有任何问题，请随时联系我们。

祝好，
${data.daoName} DAO 团队
`;

    return { subject, html, text };
  }

  /**
   * 生成提醒邮件模板
   */
  private generateReminderEmailTemplate(data: InvitationEmailData): EmailTemplate {
    const daysRemaining = this.calculateDaysRemaining(data.expiresAt);
    
    const subject = `提醒：${data.daoName} DAO邀请即将过期`;
    
    const html = `
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DAO邀请提醒</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f8fafc;
        }
        .container {
            background: white;
            border-radius: 12px;
            padding: 40px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        .warning {
            background: #fff5f5;
            border: 1px solid #fed7d7;
            border-radius: 8px;
            padding: 20px;
            margin: 20px 0;
            color: #c53030;
            text-align: center;
        }
        .cta-button {
            display: inline-block;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            text-decoration: none;
            padding: 16px 32px;
            border-radius: 8px;
            font-weight: 600;
            font-size: 16px;
            text-align: center;
            margin: 20px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="warning">
            <h2>⏰ 邀请即将过期</h2>
            <p>您的DAO邀请还有 <strong>${daysRemaining}</strong> 天过期</p>
        </div>
        
        <p>您好 ${data.inviteeName || '朋友'}，</p>
        
        <p>我们想提醒您，<strong>${data.inviterName}</strong> 邀请您加入 <strong>${data.daoName}</strong> DAO 的邀请还有 <strong>${daysRemaining}</strong> 天就要过期了。</p>
        
        <div style="text-align: center;">
            <a href="${data.invitationUrl}" class="cta-button">
                立即接受邀请
            </a>
        </div>
        
        <p>请尽快处理此邀请，过期后将无法使用此链接。</p>
        
        <p>祝好，<br>${data.daoName} DAO 团队</p>
    </div>
</body>
</html>`;

    const text = `
DAO邀请提醒

您好 ${data.inviteeName || '朋友'}，

您的DAO邀请还有 ${daysRemaining} 天过期。

${data.inviterName} 邀请您加入 ${data.daoName} DAO。

请点击以下链接接受邀请：
${data.invitationUrl}

请尽快处理此邀请，过期后将无法使用此链接。

祝好，
${data.daoName} DAO 团队
`;

    return { subject, html, text };
  }

  /**
   * 生成接受确认邮件模板
   */
  private generateAcceptedEmailTemplate(data: InvitationEmailData): EmailTemplate {
    const subject = `欢迎加入 ${data.daoName} DAO`;
    
    const html = `
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>欢迎加入DAO</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f8fafc;
        }
        .container {
            background: white;
            border-radius: 12px;
            padding: 40px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        .success {
            background: #f0fff4;
            border: 1px solid #9ae6b4;
            border-radius: 8px;
            padding: 20px;
            margin: 20px 0;
            color: #22543d;
            text-align: center;
        }
        .cta-button {
            display: inline-block;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            text-decoration: none;
            padding: 16px 32px;
            border-radius: 8px;
            font-weight: 600;
            font-size: 16px;
            text-align: center;
            margin: 20px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="success">
            <h2>🎉 欢迎加入DAO</h2>
            <p>您已成功加入 ${data.daoName} DAO</p>
        </div>
        
        <p>您好 ${data.inviteeName || '朋友'}，</p>
        
        <p>恭喜您！您已成功接受邀请并加入 <strong>${data.daoName}</strong> DAO。</p>
        
        <p>作为DAO成员，您现在可以：</p>
        <ul>
            <li>参与治理投票</li>
            <li>创建和讨论提案</li>
            <li>获得积分奖励</li>
            <li>参与社区活动</li>
        </ul>
        
        <div style="text-align: center;">
            <a href="${this.baseUrl}/dao/${data.daoId}" class="cta-button">
                进入DAO
            </a>
        </div>
        
        <p>祝您在DAO中度过愉快的时光！</p>
        
        <p>祝好，<br>${data.daoName} DAO 团队</p>
    </div>
</body>
</html>`;

    const text = `
欢迎加入DAO

您好 ${data.inviteeName || '朋友'}，

恭喜您！您已成功接受邀请并加入 ${data.daoName} DAO。

作为DAO成员，您现在可以：
- 参与治理投票
- 创建和讨论提案
- 获得积分奖励
- 参与社区活动

访问DAO：${this.baseUrl}/dao/${data.daoId}

祝您在DAO中度过愉快的时光！

祝好，
${data.daoName} DAO 团队
`;

    return { subject, html, text };
  }

  /**
   * 生成二维码
   */
  private async generateQRCode(url: string): Promise<string> {
    // 这里使用简化的方法，实际项目中可以使用qrcode库
    const qrCodeData = `data:image/svg+xml;base64,${Buffer.from(`
      <svg width="200" height="200" xmlns="http://www.w3.org/2000/svg">
        <rect width="200" height="200" fill="white"/>
        <text x="100" y="100" text-anchor="middle" font-family="Arial" font-size="12">
          QR Code
        </text>
        <text x="100" y="120" text-anchor="middle" font-family="Arial" font-size="10">
          ${url.substring(0, 30)}...
        </text>
      </svg>
    `).toString('base64')}`;
    
    return qrCodeData;
  }

  /**
   * 获取角色显示名称
   */
  private getRoleDisplayName(roleType: string): string {
    const roleNames = {
      member: '普通成员',
      moderator: '版主',
      admin: '管理员'
    };
    return roleNames[roleType as keyof typeof roleNames] || roleType;
  }

  /**
   * 格式化日期
   */
  private formatDate(date: Date): string {
    return new Intl.DateTimeFormat('zh-CN', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    }).format(date);
  }

  /**
   * 计算剩余天数
   */
  private calculateDaysRemaining(expiresAt: Date): number {
    const now = new Date();
    const diffTime = expiresAt.getTime() - now.getTime();
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    return Math.max(0, diffDays);
  }
}

// 创建邮件服务实例
export const emailService = new EmailService(
  {
    host: process.env.SMTP_HOST || 'smtp.gmail.com',
    port: parseInt(process.env.SMTP_PORT || '587'),
    secure: process.env.SMTP_SECURE === 'true',
    auth: {
      user: process.env.SMTP_USER || '',
      pass: process.env.SMTP_PASS || ''
    }
  },
  process.env.NEXT_PUBLIC_BASE_URL || 'http://localhost:3000'
);
