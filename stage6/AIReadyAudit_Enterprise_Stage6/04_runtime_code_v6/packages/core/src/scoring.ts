import type { ReadinessInput, ReadinessScore } from './types';

const clamp = (n: number) => Math.max(0, Math.min(100, Math.round(n)));

export function calculateReadinessScore(input: ReadinessInput): ReadinessScore {
  const total = clamp(
    input.workflowMaturity * 0.18 +
    input.dataReadiness * 0.18 +
    input.toolStackClarity * 0.14 +
    input.governanceReadiness * 0.18 +
    input.automationOpportunity * 0.17 +
    input.implementationCapacity * 0.15
  );

  const band = total < 35 ? 'early' : total < 60 ? 'emerging' : total < 80 ? 'ready' : 'advanced';
  const recommendations = [
    input.workflowMaturity < 60 ? 'Map the top 5 manual workflows before buying more AI tools.' : 'Use workflow evidence to prioritise implementation.',
    input.governanceReadiness < 60 ? 'Create an AI usage policy and data handling rules.' : 'Review governance quarterly as tool usage expands.',
    input.automationOpportunity > 70 ? 'Prioritise automation opportunities with high frequency and low risk.' : 'Start with assistive AI before complex automation.'
  ];

  return { total, band, recommendations };
}
