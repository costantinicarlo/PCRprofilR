## Goal
Add explicit import and column-mapping normalization into canonical pcr_peaks.

## Why This Step
Future CLI, Docker, and heterogeneous instruments require configurable column mapping.

## Scope
- In scope:
  - Add mapping function for external column names to canonical schema
  - Add normalization checks for required columns
  - Add tests for common mapping scenarios
- Out of scope:
  - File-format autodetection for all instruments
  - Batch pipeline orchestration

## Current Behavior
Core functions assume specific columns (WellID, SampleID, Size, Conc).

## Proposed Change
Implement mapping helper and route wrappers through normalization.

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
Default mapping should preserve legacy behavior without user changes.

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
- tests/testthat/test-import-mapping.R

## Documentation
- [x] Roxygen/help text updated if needed
- [x] README/vignette updates included if user-facing behavior changed
- [x] NEWS entry added if appropriate

## CI Status
- [ ] Local checks pass
- [ ] CI expected to pass

## Risk Assessment
Medium: mismatch between user data and mapping config can cause early failures by design.

## Definition of Done
- [x] Small, reviewable PR
- [x] Tests included
- [x] Return types explicit and stable
- [x] Compatibility impact documented
- [x] No unrelated refactors bundled

## Follow-up Items
- Reuse mapping helper in future CLI import paths.
