## Goal
Route legacy wrappers to new internal deterministic objects while preserving legacy outputs.

## Why This Step
Transition architecture without breaking public API.

## Scope
- In scope:
  - Route PCRpositive/PCRoutcome internals through new layers
  - Preserve current return types externally for compatibility
  - Add regression tests for wrapper outputs
- Out of scope:
  - Public API redesign
  - Plotting refactor completion

## Current Behavior
Wrappers currently implement classification logic directly.

## Proposed Change
Use pcr_peaks, pcr_assay, pcr_peak_calls, pcr_sample_calls, and pcr_qc internally.

## Affected Layers
- [x] Import and normalization
- [x] Assay specification
- [x] Peak-level detection/evidence
- [x] Sample-level interpretation
- [x] QC flags/evaluation
- [ ] Visualization/reporting
- [x] Backward-compatibility wrappers

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
Any deviations must be explicitly recorded and justified in NEWS.

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
- tests/testthat/test-wrapper-compatibility.R

## Documentation
- [x] Roxygen/help text updated if needed
- [x] README/vignette updates included if user-facing behavior changed
- [x] NEWS entry added if appropriate

## CI Status
- [ ] Local checks pass
- [ ] CI expected to pass

## Risk Assessment
Medium to high: this is the key integration point and must be tightly regression-tested.

## Definition of Done
- [x] Small, reviewable PR
- [x] Tests included
- [x] Return types explicit and stable
- [x] Compatibility impact documented
- [x] No unrelated refactors bundled

## Follow-up Items
- Begin stage 0.5 call-state expansion after integration is stable.
