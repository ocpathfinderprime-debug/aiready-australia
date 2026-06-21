import { describe, expect, it } from 'vitest';
import { scoreCitationPresence } from '../packages/core/src/citation';

describe('scoreCitationPresence', () => {
  it('calculates citation rate', () => {
    const result = scoreCitationPresence([{ promptId: 'p1', engine: 'bing', cited: true, competitors: [] }, { promptId: 'p2', engine: 'chatgpt', cited: false, competitors: ['Competitor'] }]);
    expect(result.citationRate).toBe(0.5);
  });
});
