import { calculateReadinessScore } from '../../../../packages/core/src/scoring';
export async function handleReadinessScore(payload: unknown) {
  return calculateReadinessScore(payload as any);
}
