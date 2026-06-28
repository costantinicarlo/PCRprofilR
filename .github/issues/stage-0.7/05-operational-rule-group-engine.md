## Goal
Make `rule_group` operational by introducing documented deterministic rule semantics for target combinations, required/optional/forbidden markers, hybrid candidates, mixed profiles, and ambiguous profiles.

## Why This Step
`rule_group` is present in assay specifications, but current sample-level interpretation mostly uses generic matched-target counts and distinct biological labels. A mature assay interpreter needs explicit rule semantics rather than implicit heuristics.

## Scope
- In scope:
  - Define the minimal rule fields needed for deterministic interpretation
  - Implement rule evaluation inside the existing sample-call pipeline or as a small internal helper consumed by it
  - Preserve current call states unless an intentional, tested rule-specific change is documented
  - Add tests for single-target positive, multi-target positive, required/forbidden conflicts, hybrid candidate, mixed profile, and ambiguous review
- Out of scope:
  - Probabilistic/Bayesian rule weighting
  - Assay-specific mosquito hard-coding
  - Full external rule language or YAML parser

## Current Behavior
`pcr_sample_calls()` assigns complex states using deterministic count-based precedence. This is transparent but does not yet use `rule_group` as a real assay rule contract.

## Proposed Change
Introduce a small, auditable rule layer that remains table-driven and deterministic. Rules should consume `pcr_assay` and `pcr_peak_calls` evidence and produce the same stable `pcr_sample_calls` object class.

Programmatic execution steps:
1. Add tests that freeze current count-based behavior.
2. Add tests for desired `rule_group` behavior using synthetic assay tables.
3. Implement rule evaluation in one narrow helper or one constrained section of `pcr_sample_calls()`.
4. Verify legacy wrappers still return compatible outputs.
5. Update README/vignette only if user-facing assay-specification guidance changes.

Version-control plan:
- Commit type: `feat`
- Suggested commit: `feat(stage-0.7): operationalize deterministic rule groups [#S07-05]`
- Commit after affected rule, wrapper, and public API tests pass.

## Affected Layers
- [ ] Import and normalization
- [x] Assay specification
- [x] Peak-level detection/evidence
- [x] Sample-level interpretation
- [x] QC flags/evaluation
- [ ] Visualization/reporting
- [x] Backward-compatibility wrappers

## Data Objects Impacted
- [ ] pcr_peaks
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
Legacy wrappers may continue mapping detailed states to legacy binary/NA outputs, but detailed core tables must retain rule evidence and review flags.

## Validation and Error Handling
- [x] Inputs validated explicitly
- [x] Errors are clear and actionable
- [x] No hidden cwd/global-state dependencies introduced

## QC and Evidence Retention
- [x] Outputs remain machine-readable
- [x] Evidence is retained (size, concentration, thresholds, matched target, call, flags)
- [x] Ambiguous/weak cases are preserved and flagged, not forced binary

## Tests
- [x] Existing behavior frozen where required
- [x] New behavior covered with focused testthat tests
- [x] Edge cases included (threshold boundaries, malformed input, multi-target/ambiguous cases)

Test files:
- tests/testthat/test-pcr-sample-calls.R
- tests/testthat/test-rule-engine-hybrid-mixed-contamination.R
- tests/testthat/test-wrapper-compatibility.R
- tests/testthat/test-public-api-curation.R

## Documentation
- [ ] Roxygen/help text updated if needed
- [ ] README/vignette updates included if user-facing behavior changed
- [ ] NEWS entry added if appropriate

## CI Status
- [ ] Local checks pass
- [ ] CI expected to pass

## Risk Assessment
High: rule precedence defines scientific interpretation. Keep the initial rule contract minimal, deterministic, and heavily tested.

## Definition of Done
- [ ] Small, reviewable PR
- [ ] Tests included
- [ ] Return types explicit and stable
- [ ] Compatibility impact documented
- [ ] No unrelated refactors bundled

## Follow-up Items
- Use the rule layer as the only scientific interpretation source for future reports, Docker, Shiny, and Bayesian evidence consumers.
