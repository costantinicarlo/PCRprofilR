## Goal
Add explicit control-role metadata and QC semantics so positive controls, negative controls, no-template controls, blanks, and ordinary samples are not conflated.

## Why This Step
Current QC infers controls from sample names such as `CTR`, `CONTROL`, or `NTC`. This is fragile and scientifically ambiguous because positive controls and no-template controls have opposite expected outcomes.

## Scope
- In scope:
  - Add optional control-role fields to assay or metadata contracts using conservative defaults
  - Define deterministic expected behavior for positive control, negative control, no-template control, blank, and unknown/ordinary sample roles
  - Update `pcr_qc()` to preserve machine-readable role-specific flags
  - Add focused tests for control pass/review/fail cases
- Out of scope:
  - Full plate-map import
  - Interactive QC review UI
  - Bayesian control modeling

## Current Behavior
`pcr_qc()` sets `control_sample` by regex on `sample_id` and treats control positivity in a generic contamination expression.

## Proposed Change
Introduce explicit control-role semantics without breaking existing name-based heuristics. Existing heuristics may remain as a fallback but should be documented as fallback behavior, not the preferred contract.

Programmatic execution steps:
1. Add tests that demonstrate the current ambiguity between positive controls and no-template controls.
2. Define minimal control-role column names and allowed values.
3. Update QC output with role-specific flags while retaining existing columns where feasible.
4. Verify existing tests for `pcr_qc()` and hybrid/mixed contamination still pass or are intentionally updated.
5. Document compatibility behavior and fallback name inference.

Version-control plan:
- Commit type: `feat`
- Suggested commit: `feat(stage-0.7): add explicit control role QC semantics [#S07-03]`
- Commit after focused QC tests and full tests pass.

## Affected Layers
- [ ] Import and normalization
- [x] Assay specification
- [ ] Peak-level detection/evidence
- [ ] Sample-level interpretation
- [x] QC flags/evaluation
- [ ] Visualization/reporting
- [ ] Backward-compatibility wrappers

## Data Objects Impacted
- [ ] pcr_peaks
- [x] pcr_assay
- [ ] pcr_peak_calls
- [ ] pcr_sample_calls
- [x] pcr_qc
- [ ] None

## Backward Compatibility
- [x] Existing user-facing functions remain usable (or changes are explicitly documented)
- [x] Behavior change is intentional and documented
- [x] Migration note is included if needed

Details:
Preserve current QC columns where possible. Additive role-specific fields are preferred over replacing existing fields in one step.

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
- tests/testthat/test-pcr-qc.R
- tests/testthat/test-rule-engine-hybrid-mixed-contamination.R
- tests/testthat/test-pcr-assay.R

## Documentation
- [ ] Roxygen/help text updated if needed
- [ ] README/vignette updates included if user-facing behavior changed
- [ ] NEWS entry added if appropriate

## CI Status
- [ ] Local checks pass
- [ ] CI expected to pass

## Risk Assessment
Medium: control semantics are scientifically important and can change QC interpretation. Add fields conservatively and document any changed status mapping.

## Definition of Done
- [ ] Small, reviewable PR
- [ ] Tests included
- [ ] Return types explicit and stable
- [ ] Compatibility impact documented
- [ ] No unrelated refactors bundled

## Follow-up Items
- Use explicit control roles in rule-group evaluation and future plate-map support.
