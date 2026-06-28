## Goal
Document and enforce the boundary that Docker, Shiny, and Bayesian/probabilistic layers remain deferred consumers of the stable deterministic core.

## Why This Step
The project roadmap explicitly allows future batch/container workflows, Shiny review, and Bayesian evidence layers, but none should introduce separate scientific interpretation logic. A clear contract helps future agents avoid premature or duplicated implementations.

## Scope
- In scope:
  - Add or update roadmap documentation explaining which core objects future layers must consume
  - Record that Docker, Shiny, and Bayesian modeling are deferred until deterministic contracts are stable
  - Add lightweight tests or manifest checks only if useful for preventing accidental issue-stage drift
  - Update issue tracking/manifest references for next-stage planning
- Out of scope:
  - Implementing Docker/CLI wrappers
  - Implementing Shiny
  - Implementing Bayesian models
  - Changing scientific calling behavior

## Current Behavior
The Obsidian roadmap and `.github` instructions describe deferral, but the issue backlog currently ends at completed stage 0.6 and does not provide an auditable handoff contract for advanced layers.

## Proposed Change
Create a documented handoff point: deterministic core objects are the only supported input contract for future Docker, Shiny, and Bayesian work.

Programmatic execution steps:
1. Review current roadmap docs, issue manifest, and architecture audit.
2. Add a concise handoff document or update existing docs with core-object consumer contracts.
3. Mark advanced implementation work as deferred in the backlog rather than open implementation scope.
4. Run documentation-related checks and full tests if files under package docs are changed.
5. Commit only docs/manifest changes, with no code refactor mixed in.

Version-control plan:
- Commit type: `docs`
- Suggested commit: `docs(stage-0.7): record advanced layer deferral contract [#S07-07]`
- Commit after docs are internally consistent and no unrelated files changed.

## Affected Layers
- [ ] Import and normalization
- [ ] Assay specification
- [ ] Peak-level detection/evidence
- [ ] Sample-level interpretation
- [ ] QC flags/evaluation
- [x] Visualization/reporting
- [ ] Backward-compatibility wrappers

## Data Objects Impacted
- [x] pcr_peaks
- [x] pcr_assay
- [x] pcr_peak_calls
- [x] pcr_sample_calls
- [x] pcr_qc
- [ ] None

## Backward Compatibility
- [x] Existing user-facing functions remain usable (or changes are explicitly documented)
- [x] Behavior change is intentional and documented
- [x] Migration note is included if needed

Details:
No runtime behavior changes. This issue documents future development constraints and closes the hardening stage.

## Validation and Error Handling
- [x] Inputs validated explicitly
- [x] Errors are clear and actionable
- [x] No hidden cwd/global-state dependencies introduced

## QC and Evidence Retention
- [x] Outputs remain machine-readable
- [x] Evidence is retained (size, concentration, thresholds, matched target, call, flags)
- [x] Ambiguous/weak cases are preserved and flagged, not forced binary

## Tests
- [ ] Existing behavior frozen where required
- [ ] New behavior covered with focused testthat tests
- [ ] Edge cases included (threshold boundaries, malformed input, multi-target/ambiguous cases)

Test files:
- Not expected unless a manifest/readme consistency test is introduced.

## Documentation
- [x] Roxygen/help text updated if needed
- [x] README/vignette updates included if user-facing behavior changed
- [x] NEWS entry added if appropriate

## CI Status
- [ ] Local checks pass
- [ ] CI expected to pass

## Risk Assessment
Low: documentation-only issue, but important for preventing future architecture drift.

## Definition of Done
- [ ] Small, reviewable PR
- [ ] Tests included
- [ ] Return types explicit and stable
- [ ] Compatibility impact documented
- [ ] No unrelated refactors bundled

## Follow-up Items
- Open later stage issues for Docker, Shiny, or Bayesian work only after this contract is accepted.
