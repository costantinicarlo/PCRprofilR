## Goal
Implement pcr_sample_calls deterministic engine from pcr_peak_calls + pcr_assay.

## Why This Step
Sample-level interpretation must be explicit, auditable, and decoupled from plotting and wrappers.

## Scope
- In scope:
  - Build deterministic sample call aggregation from evidence table
  - Support current positive/negative behavior initially
  - Add tests preserving baseline while enabling richer statuses later
- Out of scope:
  - Full weak/hybrid/mixed rule expansion (stage 0.5)

## Current Behavior
Sample calls are produced indirectly via wrapper logic.

## Proposed Change
Create pcr_sample_calls with explicit call columns and confidence metadata placeholders.

## Affected Layers
- [ ] Import and normalization
- [x] Assay specification
- [x] Peak-level detection/evidence
- [x] Sample-level interpretation
- [ ] QC flags/evaluation
- [ ] Visualization/reporting
- [x] Backward-compatibility wrappers

## Data Objects Impacted
- [ ] pcr_peaks
- [ ] pcr_assay
- [ ] pcr_peak_calls
- [x] pcr_sample_calls
- [ ] pcr_qc
- [ ] None

## Backward Compatibility
- [x] Existing user-facing functions remain usable (or changes are explicitly documented)
- [x] Behavior change is intentional and documented
- [ ] Migration note is included if needed

Details:
Wrappers may map richer internal calls back to legacy outputs during transition.

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

## Documentation
- [x] Roxygen/help text updated if needed
- [x] README/vignette updates included if user-facing behavior changed
- [x] NEWS entry added if appropriate

## CI Status
- [ ] Local checks pass
- [ ] CI expected to pass

## Risk Assessment
Medium: call precedence and tie handling must be deterministic.

## Definition of Done
- [x] Small, reviewable PR
- [x] Tests included
- [x] Return types explicit and stable
- [x] Compatibility impact documented
- [x] No unrelated refactors bundled

## Follow-up Items
- Add weak/indeterminate statuses in stage 0.5.
