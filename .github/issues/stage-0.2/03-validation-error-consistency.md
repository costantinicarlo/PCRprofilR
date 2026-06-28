## Goal
Standardize validation behavior and error messages across exported functions without changing scientific logic.

## Why This Step
Current validation mixes stopifnot patterns and inconsistent wording; cleaner errors are needed before architecture changes.

## Scope
- In scope:
  - Harmonize validators in validation helpers
  - Ensure consistent argument-name wording
  - Add tests for malformed input errors
- Out of scope:
  - New object model
  - Call-logic changes

## Current Behavior
Validation exists but is inconsistent in strictness and messaging between functions.

## Proposed Change
Refactor validation helpers and align callers to produce explicit, actionable errors.

## Affected Layers
- [x] Import and normalization
- [ ] Assay specification
- [ ] Peak-level detection/evidence
- [x] Sample-level interpretation
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
Error text may change; scientific outputs should remain unchanged.

## Validation and Error Handling
- [x] Inputs validated explicitly
- [x] Errors are clear and actionable
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
- tests/testthat/test-validation-errors.R

## Documentation
- [x] Roxygen/help text updated if needed
- [ ] README/vignette updates included if user-facing behavior changed
- [ ] NEWS entry added if appropriate

## CI Status
- [ ] Local checks pass
- [ ] CI expected to pass

## Risk Assessment
Low to medium: improved validation may expose previously silent misuse in downstream scripts.

## Definition of Done
- [x] Small, reviewable PR
- [x] Tests included
- [x] Return types explicit and stable
- [x] Compatibility impact documented
- [x] No unrelated refactors bundled

## Follow-up Items
- Reuse same validation style for pcr_peaks and pcr_assay constructors in stage 0.3.
