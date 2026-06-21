# MCP/App Security Review Checklist

- Tool schemas are explicit and validated.
- Tool descriptions do not hide instructions or privileged behaviour.
- High-risk actions require approval token.
- Tokens are short-lived and scoped.
- Tool calls are audit logged.
- Customer data is tenant-isolated.
- Prompt injection from external content is treated as untrusted.
- Dependency versions are monitored.
- Widgets do not expose secrets.
