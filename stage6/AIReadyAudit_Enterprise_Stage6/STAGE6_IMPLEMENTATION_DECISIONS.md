# Stage 6 Implementation Decisions

## Architecture decisions

1. **Event-first integration with OC Prime**  
   AIReady emits structured events and OC Prime routes those events to dashboards, queues and approval workflows. Direct cross-app writes are avoided unless the request is approved and auditable.

2. **MCP tools are separated by risk class**  
   Read tools expose non-sensitive state, draft tools generate recommendations, write tools create records, and high-risk write tools require approval tokens.

3. **AI-search work is measured through citations and retrieval signals**  
   Search Console, Bing Webmaster Tools, manual AI prompt panels and server logs are combined into one citation operating loop.

4. **Website pages must be commercially useful and AI-readable**  
   Every core page needs a plain-language entity summary, evidence, methodology, FAQs, internal links and structured data.

5. **Benchmark data is anonymised by design**  
   Benchmark outputs must not disclose identifiable customer, staff, pricing or workflow details without consent.

6. **Partner scale requires quality gates**  
   Partners cannot deliver unsupervised reports until they pass certification, QA sampling and customer-feedback thresholds.
