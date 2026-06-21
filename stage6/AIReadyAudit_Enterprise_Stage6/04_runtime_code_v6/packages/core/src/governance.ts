export function classifyAiGovernanceRisk(input: { personalData: boolean; customerImpact: boolean; regulatedIndustry: boolean; automatedDecisioning: boolean }) {
  let score = 0;
  if (input.personalData) score += 25;
  if (input.customerImpact) score += 25;
  if (input.regulatedIndustry) score += 25;
  if (input.automatedDecisioning) score += 25;
  return score >= 75 ? 'high' : score >= 40 ? 'medium' : 'low';
}
