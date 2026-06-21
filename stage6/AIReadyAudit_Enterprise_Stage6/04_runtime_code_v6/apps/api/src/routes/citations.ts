import { scoreCitationPresence } from '../../../../packages/core/src/citation';
export async function handleCitationScore(payload: any) {
  return scoreCitationPresence(payload.observations ?? []);
}
