"use client";

import { IntegralDAOMain } from "./integral-dao-main";

interface ShowDaoProps {
  daoId: number;
}

export function ShowDao({ daoId }: ShowDaoProps) {
  return <IntegralDAOMain daoId={daoId} />;
}
