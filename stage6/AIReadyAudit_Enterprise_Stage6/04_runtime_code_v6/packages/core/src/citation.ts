import type { CitationObservation } from './types';

export function scoreCitationPresence(observations: CitationObservation[]) {
  if (observations.length === 0) return { prompts: 0, cited: 0, citationRate: 0, competitorMentions: {} as Record<string, number> };
  const cited = observations.filter(o => o.cited).length;
  const competitorMentions: Record<string, number> = {};
  for (const obs of observations) {
    for (const c of obs.competitors) competitorMentions[c] = (competitorMentions[c] ?? 0) + 1;
  }
  return { prompts: observations.length, cited, citationRate: Number((cited / observations.length).toFixed(3)), competitorMentions };
}
