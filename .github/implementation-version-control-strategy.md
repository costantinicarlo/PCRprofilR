# PCRprofilR Implementation Version-Control Strategy

## Purpose
Define how implementation work is versioned and committed across roadmap stages so progress is auditable, reversible, and reproducible.

This strategy is aligned with:
- roadmap milestones in the project prompt
- the issue workflow in .github/ISSUE_TEMPLATE/refactor-step.md

## Operating Model
- Work in small stage-scoped branches.
- Open one issue per refactor increment using the refactor-step template.
- Link every commit to one issue and one roadmap stage.
- Commit only when stage gates are satisfied.
- Avoid mixing unrelated layers in a single commit.

## Roadmap to Branch and Commit Mapping
- Stage 0.2.x (stabilization): tests, validation cleanup, CI, no behavior drift unless documented.
- Stage 0.3.x (objects): canonical peak table + assay specification internals.
- Stage 0.4.x (evidence/calls): peak evidence tables, sample calls, QC object.
- Stage 0.5.x (rules): weak/ambiguous/hybrid/mixed/invalid deterministic logic.
- Stage 0.6.x (operations): replicate summaries, batch/report helpers.
- Stage 0.7.x+ (deployment): container and optional Bayesian design work only after deterministic core is stable.

Branch naming:
- feat/stage-0.2-<short-scope>
- feat/stage-0.3-<short-scope>
- feat/stage-0.4-<short-scope>
- fix/stage-0.2-<bug-scope>
- chore/stage-0.2-<infra-scope>

## Commit Policy
### Allowed commit scope
One commit should include only one logical increment:
- one function family OR
- one object contract OR
- one test bundle for a single behavior OR
- one CI/config increment.

### Commit message format
Use conventional style with stage and issue linkage:

<type>(stage-<x.y>): <short imperative summary> [#<issue-id>]

Examples:
- test(stage-0.2): freeze PCRoutcome baseline behavior [#21]
- feat(stage-0.3): add pcr_peaks validator and constructor [#34]
- refactor(stage-0.4): route PCRpositive through peak evidence layer [#42]

Allowed types:
- feat
- fix
- refactor
- test
- docs
- chore

### Atomicity rules
- No unrelated formatting-only changes mixed with behavior changes.
- No cross-stage mixing in one commit.
- Keep generated files in separate commits when possible.

## Commit Gates (Definition of Commit-Ready)
A commit is allowed only if all checks below pass for that increment:
1. Issue scope is explicit (Goal, Scope, Proposed Change filled in template).
2. Tests added or updated for changed behavior.
3. Existing affected tests pass locally.
4. Return objects remain explicit and documented.
5. Backward compatibility impact is documented.
6. No unrelated files changed.

## Stage Completion Gates (Definition of Stage-Ready)
A stage branch is ready to merge only when:
1. All stage issues are closed or deferred with rationale.
2. CI is green for the branch.
3. CHANGELOG/NEWS notes are updated for user-visible behavior.
4. Public API changes are documented.
5. Risks and follow-up items are logged.

## Tagging and Release Cadence
- Tag only at stage milestone boundaries.
- Use semantic prerelease tags before 1.0.0:
  - v0.2.0, v0.3.0, v0.4.0, etc.
  - optional rc tags for stabilization: v0.5.0-rc1
- Keep patch releases for bugfix-only backports:
  - v0.4.1, v0.4.2

## Merge Policy
- Prefer squash merge for single-increment issues.
- Prefer rebase merge for clean multi-commit, single-stage history.
- Do not merge with failing CI except for docs-only changes.

## Rollback and Recovery
- Every stage branch must be independently revertible.
- If a regression appears, revert the smallest faulty commit first.
- Add regression test before re-introducing fixed behavior.

## Evidence and Traceability Requirements
Each PR must include:
- linked issue ID
- roadmap stage label
- test evidence summary
- compatibility note
- concise risk note

## Agent Execution Guardrails
During automated development:
- do not auto-commit after exploratory edits
- do not auto-commit when tests fail
- do not auto-commit mixed concerns
- do commit immediately after a commit-ready increment passes gates
- stop and open/update issue if scope expands
