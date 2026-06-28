## Goal
Freeze current behavior of PCRexplorer and PCRpherogram plotting functions.

## Why This Step
Plotting refactor is planned later; current visual behavior and error handling must be captured now.

## Scope
- In scope:
  - Add baseline tests for object class and key plot attributes
  - Add tests for argument validation paths
  - Add tests for expected handling of control/join/xlimits options
- Out of scope:
  - Visual redesign
  - Logic extraction from plotting

## Current Behavior
Both functions compute plotting data directly from raw input; PCRpherogram includes direct classification outcome coloring.

## Proposed Change
Add deterministic tests to lock current outputs and validations.

## Affected Layers
- [ ] Import and normalization
- [ ] Assay specification
- [ ] Peak-level detection/evidence
- [ ] Sample-level interpretation
- [ ] QC flags/evaluation
- [x] Visualization/reporting
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
No behavior change expected in this issue.

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
- tests/testthat/test-PCRexplorer.R
- tests/testthat/test-PCRpherogram.R

## Documentation
- [ ] Roxygen/help text updated if needed
- [ ] README/vignette updates included if user-facing behavior changed
- [ ] NEWS entry added if appropriate

## CI Status
- [ ] Local checks pass
- [ ] CI expected to pass

## Risk Assessment
Low risk; plot snapshot brittleness may need stable theme/assertion strategy.

## Definition of Done
- [x] Small, reviewable PR
- [x] Tests included
- [x] Return types explicit and stable
- [x] Compatibility impact documented
- [x] No unrelated refactors bundled

## Follow-up Items
- Stage 0.4/0.5: refactor plotting to consume classified objects.
