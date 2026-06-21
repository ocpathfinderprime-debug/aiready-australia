export type ReadinessInput = {
  industry: string;
  staffCount: number;
  workflowMaturity: number;
  dataReadiness: number;
  toolStackClarity: number;
  governanceReadiness: number;
  automationOpportunity: number;
  implementationCapacity: number;
};

export type ReadinessScore = {
  total: number;
  band: 'early' | 'emerging' | 'ready' | 'advanced';
  recommendations: string[];
};

export type CitationObservation = {
  promptId: string;
  engine: string;
  cited: boolean;
  citedUrl?: string;
  competitors: string[];
  notes?: string;
};
