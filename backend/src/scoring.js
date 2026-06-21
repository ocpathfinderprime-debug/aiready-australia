export function calculateReadinessScore(payload = {}) {
  const answers = payload.answers || payload;
  const numericSignals = [
    Number(answers.techComfort ?? answers.q8 ?? 0),
    Number(answers.dataQuality ?? answers.q17_quality ?? 0),
  ].filter((value) => Number.isFinite(value) && value > 0);

  let score = 42;
  if (numericSignals.length) {
    score += Math.round(numericSignals.reduce((sum, value) => sum + value, 0) / numericSignals.length * 3);
  }
  if (answers.currentAiUse || answers.q9) score += 8;
  if (answers.documentedProcesses || answers.q18) score += 6;
  if (answers.budget || answers.q19) score += 5;
  if (answers.implementationOwner || answers.q20) score += 5;
  if (answers.topBottlenecks || answers.q10) score += 4;

  score = Math.max(0, Math.min(100, score));

  const band = score >= 80 ? 'advanced' : score >= 62 ? 'ready' : score >= 45 ? 'emerging' : 'foundation';
  const nextAction = {
    advanced: 'Prioritise implementation portfolio and governance controls.',
    ready: 'Convert strongest workflow opportunities into a 90-day roadmap.',
    emerging: 'Clarify data, process, and ownership gaps before tooling decisions.',
    foundation: 'Start with workflow discovery and basic AI governance foundations.',
  }[band];

  return {
    score,
    band,
    nextAction,
    generatedAt: new Date().toISOString(),
  };
}
