## Goal
Implement three-zone threshold interpretation (below analytical, analytical-to-confirmatory, above confirmatory).

## Why This Step
Single-threshold logic cannot represent weak or uncertain evidence.

## Scope
- In scope:
  - Add threshold-zone derivation in evidence and/or sample-call layers
  - Define deterministic precedence rules for zone-based status assignment
  - Add boundary tests for zone transitions
- Out of scope:
  - Hybrid/mixed biological interpretation

## Current Behavior
Thresholding is mostly binary.

## Proposed Change
Extend deterministic engine to zone-aware interpretation with explicit evidence fields.

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
Legacy wrappers may continue returning old simplified forms while internal statuses are richer.

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
- tests/testthat/test-three-zone-thresholds.R

## Documentation
- [x] Roxygen/help text updated if needed
- [x] README/vignette updates included if user-facing behavior changed
- [x] NEWS entry added if appropriate

## CI Status
- [ ] Local checks pass
- [ ] CI expected to pass

## Risk Assessment
Medium: boundary definition errors can alter classification near cutoffs.

## Definition of Done
- [x] Small, reviewable PR
- [x] Tests included
- [x] Return types explicit and stable
- [x] Compatibility impact documented
- [x] No unrelated refactors bundled

## Follow-up Items
- Implement explicit weak and indeterminate call categories.
