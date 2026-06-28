## Goal
Implement pcr_peak_calls evidence table linking observed peaks to assay targets.

## Why This Step
Evidence-first design is required before robust sample-level calling.

## Scope
- In scope:
  - Match pcr_peaks against pcr_assay windows and thresholds
  - Store match evidence fields (observed size, expected size, delta, concentration, zone)
  - Add tests for match/no-match boundaries
- Out of scope:
  - Final biological decision logic
  - QC aggregation

## Current Behavior
Matching logic is implicit inside wrapper-level functions.

## Proposed Change
Centralize matching into pcr_peak_calls as a stable intermediate object.

## Affected Layers
- [ ] Import and normalization
- [x] Assay specification
- [x] Peak-level detection/evidence
- [ ] Sample-level interpretation
- [ ] QC flags/evaluation
- [ ] Visualization/reporting
- [x] Backward-compatibility wrappers

## Data Objects Impacted
- [ ] pcr_peaks
- [ ] pcr_assay
- [x] pcr_peak_calls
- [ ] pcr_sample_calls
- [ ] pcr_qc
- [ ] None

## Backward Compatibility
- [x] Existing user-facing functions remain usable (or changes are explicitly documented)
- [x] Behavior change is intentional and documented
- [ ] Migration note is included if needed

Details:
Wrappers should still return current outputs until stage 0.4 routing issue is complete.

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
- tests/testthat/test-pcr-peak-calls.R

## Documentation
- [x] Roxygen/help text updated if needed
- [x] README/vignette updates included if user-facing behavior changed
- [x] NEWS entry added if appropriate

## CI Status
- [ ] Local checks pass
- [ ] CI expected to pass

## Risk Assessment
Medium: boundary conditions must match historical behavior where expected.

## Definition of Done
- [x] Small, reviewable PR
- [x] Tests included
- [x] Return types explicit and stable
- [x] Compatibility impact documented
- [x] No unrelated refactors bundled

## Follow-up Items
- Feed pcr_peak_calls into sample-level deterministic engine.
