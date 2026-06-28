## Goal
Add explicit weak, ambiguous, and indeterminate sample call categories.

## Why This Step
Non-binary call categories are central to scientific validity and review workflows.

## Scope
- In scope:
  - Add call-state taxonomy for weak/ambiguous/indeterminate
  - Define precedence and tie-breaking rules
  - Add tests for representative ambiguous scenarios
- Out of scope:
  - Hybrid/mixed inference rules that depend on assay combinations

## Current Behavior
Ambiguous scenarios are not consistently represented as first-class call states.

## Proposed Change
Extend pcr_sample_calls and pcr_qc with explicit review-oriented statuses.

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
Expose richer statuses internally and provide compatibility mapping for legacy outputs.

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
- tests/testthat/test-call-states-weak-ambiguous-indeterminate.R

## Documentation
- [x] Roxygen/help text updated if needed
- [x] README/vignette updates included if user-facing behavior changed
- [x] NEWS entry added if appropriate

## CI Status
- [ ] Local checks pass
- [ ] CI expected to pass

## Risk Assessment
Medium: introducing new states requires strict compatibility documentation.

## Definition of Done
- [x] Small, reviewable PR
- [x] Tests included
- [x] Return types explicit and stable
- [x] Compatibility impact documented
- [x] No unrelated refactors bundled

## Follow-up Items
- Integrate with hybrid/mixed/contamination rules.
