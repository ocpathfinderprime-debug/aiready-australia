import http from 'k6/http';
import { check } from 'k6';
export const options = { vus: 20, duration: '1m' };
export default function () {
  const res = http.post('https://api.aireadyaudit.com.au/v6/readiness-score', JSON.stringify({ workflowMaturity: 50, dataReadiness: 50, toolStackClarity: 50, governanceReadiness: 50, automationOpportunity: 50, implementationCapacity: 50 }), { headers: { 'Content-Type': 'application/json' } });
  check(res, { 'status is 200': r => r.status === 200 });
}
