import { createCallerFactory, createTRPCRouter } from "@/server/api/trpc";
import { daoRouter } from "@/server/api/routers/dao";
import { authRouter } from "@/server/api/routers/auth";
import { pointsRouter } from "@/server/api/routers/points";
import { invitationRouter } from "@/server/api/routers/invitation";
import { daoConfigRouter } from "@/server/api/routers/dao-config";
import { permissionRouter } from "@/server/api/routers/permission";
import { auditRouter } from "@/server/api/routers/audit";
import { i18nRouter } from "@/server/api/routers/i18n";
import { smartGovernanceRouter } from "@/server/api/routers/smart-governance";

/**
 * This is the primary router for your server.
 *
 * Procedures from api/procedures should be added here.
 */
export const appRouter = createTRPCRouter({
  dao: daoRouter,
  auth: authRouter,
  points: pointsRouter,
  invitation: invitationRouter,
  daoConfig: daoConfigRouter,
  permission: permissionRouter,
  audit: auditRouter,
  i18n: i18nRouter,
  smartGovernance: smartGovernanceRouter,
});

// export type definition of API
export type AppRouter = typeof appRouter;

/**
 * Create a server-side caller for the tRPC API.
 * @example
 * const trpc = createCaller(createContext);
 * const res = await trpc.post.all();
 *       ^? Post[]
 */
export const createCaller = createCallerFactory(appRouter);
