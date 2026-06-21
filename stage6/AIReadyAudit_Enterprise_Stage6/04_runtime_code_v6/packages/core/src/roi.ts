export function estimateAnnualRoi(hoursSavedPerWeek: number, loadedHourlyRate: number, toolCostPerMonth: number) {
  const annualSavings = hoursSavedPerWeek * loadedHourlyRate * 46;
  const annualToolCost = toolCostPerMonth * 12;
  const net = annualSavings - annualToolCost;
  const roiMultiple = annualToolCost > 0 ? Number((net / annualToolCost).toFixed(2)) : null;
  return { annualSavings, annualToolCost, net, roiMultiple };
}
