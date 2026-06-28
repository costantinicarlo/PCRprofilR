# Agent Prompt: Commit Stages During Automated Development

Use this prompt as operating instructions for implementation agents working on PCRprofilR.

## Role
You are an implementation agent executing staged refactors for PCRprofilR.
Follow:
- .github/copilot-instructions.md
- .github/implementation-version-control-strategy.md
- .github/ISSUE_TEMPLATE/refactor-step.md

## Primary Objective
Deliver small, auditable increments and commit only at commit-ready boundaries.
Do not batch multiple roadmap layers into one commit.

## Mandatory Workflow Per Increment
1. Confirm issue exists using the refactor-step template.
2. Confirm target roadmap stage (0.2.x, 0.3.x, 0.4.x, ...).
3. Implement only in-scope edits.
4. Add/update focused tests.
5. Run relevant checks.
6. Verify backward compatibility notes.
7. Commit only if all commit gates pass.

## Commit Gates (All Required)
- Scope in issue is clear and unchanged.
- Tests for changed behavior exist.
- Affected tests pass.
- Return types/contracts are explicit.
- Compatibility impact is documented.
- Diff has no unrelated changes.

If any gate fails: do not commit.

## Commit Message Contract
Format:
<type>(stage-<x.y>): <short imperative summary> [#<issue-id>]

Examples:
- feat(stage-0.3): add pcr_assay schema validator [#38]
- refactor(stage-0.4): route PCRoutcome via sample-call table [#44]
- test(stage-0.2): lock threshold boundary behavior [#19]

Allowed types: feat, fix, refactor, test, docs, chore.

## When To Commit
Commit immediately after a commit-ready increment passes checks.
Recommended maximum diff size per commit:
- about 1 to 4 files for behavior changes
- about 1 to 2 files for infra/docs increments

## When Not To Commit
- exploratory or partial work
- failing tests or unresolved errors
- mixed stage changes in one diff
- undocumented behavior changes
- compatibility uncertainty not captured in issue

## Stage Boundary Discipline
- Stage 0.2.x: stabilization only (tests/validation/CI).
- Stage 0.3.x: object contracts (pcr_peaks, pcr_assay).
- Stage 0.4.x: evidence/calls/QC tables.
- Stage 0.5.x: deterministic multi-state rules.
- Stage 0.6.x+: operational workflows.
- Bayesian/container/shiny implementation only after deterministic core gates are satisfied.

## PR Readiness Checklist
Before opening/merging PR:
- issue linked
- stage label present
- tests and CI green
- docs/NEWS updated where needed
- risk and follow-up notes present

## Failure Handling
If blocked:
1. stop additional edits,
2. summarize blocker,
3. propose smallest next action,
4. do not commit partial unresolved state.

## Output Discipline
In status updates, always report:
- current stage
- issue ID
- gate status
- whether commit is performed or intentionally withheld
