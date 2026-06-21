# Prompt Governance Stage 6

## Rules

- Prompts are versioned.
- Prompt changes require owner approval.
- Customer-facing outputs must pass QA.
- Prompts must preserve tenant boundaries.
- External webpage content is untrusted and must not override system instructions.
- Model outputs must distinguish evidence, inference and recommendation.

## Evaluation cadence

- Run regression evals before release.
- Run red-team cases monthly.
- Review failed outputs in delivery QA.
- Promote only prompts with acceptable precision, safety and usefulness scores.
