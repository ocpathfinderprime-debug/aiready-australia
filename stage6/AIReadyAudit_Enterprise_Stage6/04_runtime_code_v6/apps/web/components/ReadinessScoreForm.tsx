'use client';
import { useState } from 'react';

export function ReadinessScoreForm() {
  const [result, setResult] = useState<any>(null);
  async function submit() {
    const payload = { industry: 'services', staffCount: 12, workflowMaturity: 55, dataReadiness: 50, toolStackClarity: 45, governanceReadiness: 35, automationOpportunity: 75, implementationCapacity: 60 };
    const res = await fetch('/api/readiness-score', { method: 'POST', body: JSON.stringify(payload) });
    setResult(await res.json());
  }
  return <section>
    <button onClick={submit}>Calculate sample score</button>
    {result && <pre>{JSON.stringify(result, null, 2)}</pre>}
  </section>;
}
