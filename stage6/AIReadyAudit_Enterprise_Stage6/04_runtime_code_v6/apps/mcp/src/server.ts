import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { z } from 'zod';
import { calculateReadinessScore, scoreCitationPresence } from '../../../packages/core/src/index';

const server = new McpServer({ name: 'aiready-audit-stage6', version: '6.0.0' });

server.tool('calculate_readiness_score', {
  industry: z.string(), staffCount: z.number(), workflowMaturity: z.number(), dataReadiness: z.number(), toolStackClarity: z.number(), governanceReadiness: z.number(), automationOpportunity: z.number(), implementationCapacity: z.number()
}, async (input) => ({ content: [{ type: 'text', text: JSON.stringify(calculateReadinessScore(input), null, 2) }] }));

server.tool('score_ai_citation_presence', { observations: z.array(z.any()) }, async (input) => ({ content: [{ type: 'text', text: JSON.stringify(scoreCitationPresence(input.observations as any), null, 2) }] }));

export { server };
