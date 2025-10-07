import assert from "assert";

/**
 * 积分制DAO工具函数
 */

/**
 * 解析提案ID（用于积分制DAO）
 */
export function parseProposalId(proposalId: string) {
  // 积分制DAO的提案ID格式：prop_timestamp_random
  const parts = proposalId.split('_');
  if (parts.length !== 3 || parts[0] !== 'prop') {
    throw new Error("Invalid proposal ID format");
  }
  return {
    type: parts[0]!,
    timestamp: parseInt(parts[1]!),
    random: parts[2]!
  };
}

/**
 * 生成提案ID（用于积分制DAO）
 */
export function generateProposalId() {
  const timestamp = Date.now();
  const random = Math.random().toString(36).substr(2, 9);
  return `prop_${timestamp}_${random}`;
}

/**
 * 计算投票权重（基于声誉积分和贡献积分）
 */
export function calculateVotingPower(reputationScore: number, contributionPoints: number) {
  // 权重计算：声誉积分60% + 贡献积分40%
  return Math.floor((reputationScore * 0.6 + contributionPoints * 0.4) / 10);
}

/**
 * 格式化积分显示
 */
export function formatPoints(points: number): string {
  if (points >= 1000) {
    return `${(points / 1000).toFixed(1)}K`;
  }
  return points.toString();
}

/**
 * 检查提案状态是否可投票
 */
export function canVote(proposalStatus: string, currentTime: Date, endTime?: Date): boolean {
  if (proposalStatus !== 'active') {
    return false;
  }
  if (endTime && currentTime > endTime) {
    return false;
  }
  return true;
}

/**
 * 计算提案通过率
 */
export function calculatePassRate(votesFor: number, votesAgainst: number): number {
  const totalVotes = votesFor + votesAgainst;
  if (totalVotes === 0) return 0;
  return votesFor / totalVotes;
}

/**
 * intended to replicate ES2024 Promise.withResolvers:
 * https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/withResolvers
 */
export function promiseWithResolvers<T>() {
  // hacky solution to: https://github.com/microsoft/TypeScript/issues/45658
  //   (aka https://github.com/microsoft/TypeScript/issues/9998)
  let resolve = undefined as ((value: T | PromiseLike<T>) => void) | undefined;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  let reject = undefined as ((reason?: any) => void) | undefined;
  const promise = new Promise<T>((innerResolve, innerReject) => {
    resolve = innerResolve;
    reject = innerReject;
  });
  assert(resolve !== undefined, "resolve must be defined");
  assert(reject !== undefined, "reject must be defined");
  return { promise, resolve, reject };
}
