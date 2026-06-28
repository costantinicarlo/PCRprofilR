## Goal
Introduce pcr_peaks canonical object constructor and validator.

## Why This Step
A stable canonical peak table is the foundation for evidence, calling, QC, and deployment workflows.

## Scope
- In scope:
  - Define required columns and types for pcr_peaks
  - Implement constructor and validator
  - Add tests for valid/invalid schemas
- Out of scope:
  - Assay rules
  - Sample call logic

## Current Behavior
Functions operate directly on ad hoc raw data columns.

## Proposed Change
Create canonical pcr_peaks object API with explicit validation errors.

## Affected Layers
- [x] Import and normalization
- [ ] Assay specification
- [ ] Peak-level detection/evidence
- [ ] Sample-level interpretation
- [ ] QC flags/evaluation
- [ ] Visualization/reporting
- [x] Backward-compatibility wrappers

## Data Objects Impacted
- [x] pcr_peaks
- [ ] pcr_assay
- [ ] pcr_peak_calls
- [ ] pcr_sample_calls
- [ ] pcr_qc
- [ ] None

## Backward Compatibility
- [x] Existing user-facing functions remain usable (or changes are explicitly documented)
- [x] Behavior change is intentional and documented
- [ ] Migration note is included if needed

Details:
Legacy wrappers may continue accepting old column names but internally normalize to pcr_peaks.

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
- tests/testthat/test-pcr-peaks.R

## Documentation
- [x] Roxygen/help text updated if needed
- [x] README/vignette updates included if user-facing behavior changed
- [x] NEWS entry added if appropriate

## CI Status
- [ ] Local checks pass
- [ ] CI expected to pass

## Risk Assessment
Medium: schema strictness may surface latent data-quality problems.

## Definition of Done
- [x] Small, reviewable PR
- [x] Tests included
- [x] Return types explicit and stable
- [x] Compatibility impact documented
- [x] No unrelated refactors bundled

## Follow-up Items
- Implement import mapping helper in next issue.
