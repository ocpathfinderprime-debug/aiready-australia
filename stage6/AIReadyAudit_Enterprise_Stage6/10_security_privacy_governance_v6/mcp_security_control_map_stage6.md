# MCP Security Control Map Stage 6

| Risk | Stage 6 control |
|---|---|
| Token exposure | no secrets in prompts/logs; short-lived scoped tokens |
| Scope creep | explicit read/draft/write/high-risk scopes |
| Tool poisoning | registry review and signed release process |
| Supply chain attacks | dependency scanning and lockfile review |
| Command injection | no shell execution from untrusted input |
| Intent flow subversion | external context treated as untrusted |
| Insufficient auth | OAuth protected-resource metadata and tenant checks |
| Lack of telemetry | tool invocation audit logs |
| Shadow MCP servers | app registry and deployment approval |
| Context over-sharing | memory boundary policy |
