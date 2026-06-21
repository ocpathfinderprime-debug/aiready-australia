import { describe, expect, it } from 'vitest';
import { calculateReadinessScore } from '../packages/core/src/scoring';

describe('calculateReadinessScore', () => {
  it('returns a bounded score', () => {
    const result = calculateReadinessScore({ industry: 'services', staffCount: 10, workflowMaturity: 50, dataReadiness: 50, toolStackClarity: 50, governanceReadiness: 50, automationOpportunity: 50, implementationCapacity: 50 });
    expect(result.total).toBeGreaterThanOrEqual(0);
    expect(result.total).toBeLessThanOrEqual(100);
  });
});
