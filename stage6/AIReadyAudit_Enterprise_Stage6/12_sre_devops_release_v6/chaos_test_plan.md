# Chaos Test Plan

## Tests

- API container restart during score submissions.
- Worker queue failure during citation scan.
- OC Prime endpoint unavailable.
- Database read replica unavailable.
- MCP auth service returns insufficient scope.

## Pass criteria

- graceful degradation
- retries with backoff
- no data loss
- clear alert
- runbook followed
