import { z } from "zod";
import { procedure, createTRPCRouter } from "@/server/api/trpc";
import { db } from "@/server/db";
import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";

const JWT_SECRET = process.env.JWT_SECRET || "dao-genie-secret-key-2024";

export const authRouter = createTRPCRouter({
  // 用户登录
  login: procedure
    .input(z.object({
      username: z.string(),
      password: z.string(),
    }))
    .mutation(async ({ input }) => {
      try {
        // 查找用户
        const member = await db.dAOMember.findFirst({
          where: { 
            username: input.username,
            status: "ACTIVE"
          },
        });

        if (!member || !member.password) {
          return { success: false, message: "用户不存在或密码不正确" };
        }

        // 验证密码
        const isValidPassword = await bcrypt.compare(input.password, member.password);
        if (!isValidPassword) {
          return { success: false, message: "用户不存在或密码不正确" };
        }

        // 生成JWT token
        const token = jwt.sign(
          { 
            userId: member.userId, 
            username: member.username,
            role: member.username === 'admin' ? 'admin' : 'member'
          },
          JWT_SECRET,
          { expiresIn: '24h' }
        );

        return {
          success: true,
          data: {
            token,
            user: {
              id: member.id,
              userId: member.userId,
              username: member.username,
              email: member.email,
              role: member.username === 'admin' ? 'admin' : 'member',
              reputationScore: member.reputationScore,
              contributionPoints: member.contributionPoints,
              votingPower: Math.floor((member.reputationScore * 0.6 + member.contributionPoints * 0.4) / 10),
              isAuthenticated: true
            }
          },
          message: "登录成功"
        };
      } catch (error: any) {
        return { success: false, message: "登录失败", error: error.message };
      }
    }),

  // 用户注册
  register: procedure
    .input(z.object({
      username: z.string(),
      email: z.string().email(),
      password: z.string(),
    }))
    .mutation(async ({ input }) => {
      try {
        // 检查用户是否已存在
        const existingMember = await db.dAOMember.findFirst({
          where: {
            OR: [
              { username: input.username },
              { email: input.email }
            ]
          },
        });

        if (existingMember) {
          return { success: false, message: "用户名或邮箱已存在" };
        }

        // 加密密码
        const hashedPassword = await bcrypt.hash(input.password, 10);

        // 创建新用户
        const newMember = await db.dAOMember.create({
          data: {
            userId: `user_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
            username: input.username,
            email: input.email,
            password: hashedPassword,
            joinDate: new Date(),
            status: "ACTIVE",
            reputationScore: 10, // 初始声誉积分
            contributionPoints: 0, // 初始贡献积分
          },
        });

        // 生成JWT token
        const token = jwt.sign(
          { 
            userId: newMember.userId, 
            username: newMember.username,
            role: 'member'
          },
          JWT_SECRET,
          { expiresIn: '24h' }
        );

        return {
          success: true,
          data: {
            token,
            user: {
              id: newMember.id,
              userId: newMember.userId,
              username: newMember.username,
              email: newMember.email,
              role: 'member',
              reputationScore: newMember.reputationScore,
              contributionPoints: newMember.contributionPoints,
              votingPower: Math.floor((newMember.reputationScore * 0.6 + newMember.contributionPoints * 0.4) / 10),
              isAuthenticated: true
            }
          },
          message: "注册成功"
        };
      } catch (error: any) {
        return { success: false, message: "注册失败", error: error.message };
      }
    }),

  // 获取当前用户信息
  getCurrentUser: procedure
    .input(z.object({
      token: z.string(),
    }))
    .mutation(async ({ input }) => {
      try {
        // 验证JWT token
        const decoded: any = jwt.verify(input.token, JWT_SECRET);
        
        // 查找用户信息
        const member = await db.dAOMember.findUnique({
          where: { userId: decoded.userId },
        });

        if (!member) {
          return { success: false, message: "用户未找到" };
        }

        return {
          success: true,
          data: {
            id: member.id,
            userId: member.userId,
            username: member.username,
            email: member.email,
            role: member.username === 'admin' ? 'admin' : 'member',
            reputationScore: member.reputationScore,
            contributionPoints: member.contributionPoints,
            votingPower: Math.floor((member.reputationScore * 0.6 + member.contributionPoints * 0.4) / 10),
            isAuthenticated: true
          },
          message: "获取用户信息成功"
        };
      } catch (error: any) {
        return { success: false, message: "获取用户信息失败", error: error.message };
      }
    }),

  // 验证token
  validateToken: procedure
    .input(z.object({
      token: z.string(),
    }))
    .mutation(async ({ input }) => {
      try {
        jwt.verify(input.token, JWT_SECRET);
        return { success: true, message: "Token有效" };
      } catch (error) {
        return { success: false, message: "Token无效或已过期" };
      }
    }),
});