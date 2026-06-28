## Goal
Add deterministic batch input/output helpers that wrap core functions without duplicating scientific logic.

## Why This Step
Programmatic and container workflows need file-based, reproducible entry points.

## Scope
- In scope:
  - Implement helpers to load input files, run core pipeline, and save outputs
  - Define explicit input/output contracts and directory layout
  - Add integration tests using fixture files
- Out of scope:
  - Full CLI binary packaging
  - Docker image build scripts

## Current Behavior
No standardized batch helper layer exists.

## Proposed Change
Add helper functions that orchestrate canonical pipeline objects and produce reproducible artifacts.

## Affected Layers
- [x] Import and normalization
- [x] Assay specification
- [x] Peak-level detection/evidence
- [x] Sample-level interpretation
- [x] QC flags/evaluation
- [ ] Visualization/reporting
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
New helpers should be additive and not alter existing wrappers.

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
- tests/testthat/test-batch-helpers.R

## Documentation
- [x] Roxygen/help text updated if needed
- [x] README/vignette updates included if user-facing behavior changed
- [x] NEWS entry added if appropriate

## CI Status
- [ ] Local checks pass
- [ ] CI expected to pass

## Risk Assessment
Medium: IO contract drift can break reproducibility if not versioned and tested.

## Definition of Done
- [x] Small, reviewable PR
- [x] Tests included
- [x] Return types explicit and stable
- [x] Compatibility impact documented
- [x] No unrelated refactors bundled

## Follow-up Items
- Reuse same helpers in Docker wrapper and future Shiny backend.
