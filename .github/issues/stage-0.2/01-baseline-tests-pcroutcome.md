## Goal
Freeze current behavior of PCRoutcome with explicit baseline tests.

## Why This Step
PCRoutcome is a core wrapper currently using legacy deterministic logic. Behavior must be locked before internal refactor.

## Scope
- In scope:
  - Add testthat coverage for nominal outcome assignment
  - Add tests for multiple target matches and NA outcomes
  - Add threshold and tolerance boundary tests for PCRoutcome
- Out of scope:
  - Changes to classification logic
  - New object model introduction

## Current Behavior
PCRoutcome classifies sample IDs by applying PCRpositive per target and left-joining by SampleID.

## Proposed Change
Add focused tests that capture current behavior exactly, including edge-case outputs.

## Affected Layers
- [ ] Import and normalization
- [ ] Assay specification
- [ ] Peak-level detection/evidence
- [x] Sample-level interpretation
- [ ] QC flags/evaluation
- [ ] Visualization/reporting
- [x] Backward-compatibility wrappers

## Data Objects Impacted
- [ ] pcr_peaks
- [ ] pcr_assay
- [ ] pcr_peak_calls
- [ ] pcr_sample_calls
- [ ] pcr_qc
- [x] None

## Backward Compatibility
- [x] Existing user-facing functions remain usable (or changes are explicitly documented)
- [x] Behavior change is intentional and documented
- [ ] Migration note is included if needed

Details:
No behavior change expected; this is baseline freezing.

## Validation and Error Handling
- [ ] Inputs validated explicitly
- [ ] Errors are clear and actionable
- [x] No hidden cwd/global-state dependencies introduced

## QC and Evidence Retention
- [x] Outputs remain machine-readable
- [ ] Evidence is retained (size, concentration, thresholds, matched target, call, flags)
- [ ] Ambiguous/weak cases are preserved and flagged, not forced binary

## Tests
- [x] Existing behavior frozen where required
- [x] New behavior covered with focused testthat tests
- [x] Edge cases included (threshold boundaries, malformed input, multi-target/ambiguous cases)

Test files:
- tests/testthat/test-PCRoutcome.R

## Documentation
- [ ] Roxygen/help text updated if needed
- [ ] README/vignette updates included if user-facing behavior changed
- [ ] NEWS entry added if appropriate

## CI Status
- [ ] Local checks pass
- [ ] CI expected to pass

## Risk Assessment
Risk is low; tests may reveal undocumented legacy behavior requiring explicit acceptance.

## Definition of Done
- [x] Small, reviewable PR
- [x] Tests included
- [x] Return types explicit and stable
- [x] Compatibility impact documented
- [x] No unrelated refactors bundled

## Follow-up Items
- Route PCRoutcome through pcr_sample_calls when stage 0.4 begins.
