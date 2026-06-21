export function buildReportOutline(packageType: string) {
  return [
    'Executive summary',
    'Business context',
    'Current workflow and tool stack',
    'Readiness score',
    'Opportunity register',
    'Recommended tools',
    'Risk and governance notes',
    'ROI estimates',
    '90-day roadmap',
    `Package-specific appendix: ${packageType}`
  ];
}
