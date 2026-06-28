## Goal
Separate strict canonical object validation from QC-able malformed input handling so selected issues, such as missing or malformed wells, can become machine-readable QC flags instead of pre-QC hard failures.

## Why This Step
The current `pcr_peaks` validator rejects missing or empty `well_id`, while `pcr_qc()` also contains `has_missing_well_id`. This means the QC flag is unreachable for canonical objects, weakening the audit trail for imperfect instrument exports.

## Scope
- In scope:
  - Decide which malformed fields must remain fatal and which can be represented as QC flags
  - Add a narrow normalization/review pathway for QC-able issues such as missing or malformed wells
  - Keep strict constructors available for guaranteed-valid canonical objects
  - Add tests proving missing/malformed well handling reaches `pcr_qc()` when using the review pathway
- Out of scope:
  - Permitting invalid sizes or negative concentrations as canonical evidence
  - Broad fuzzy import/parsing
  - Plate-map validation beyond minimal well syntax checks

## Current Behavior
`pcr_peaks()` requires all ID columns to be non-missing, non-empty character values. `pcr_qc()` computes `has_missing_well_id`, but that condition is not reachable after strict object construction.

## Proposed Change
Introduce an explicit contract for strict versus reviewable data. The implementation may use a separate helper, an optional normalization mode, or a documented pre-QC path, but it must avoid silently weakening strict canonical validation.

Programmatic execution steps:
1. Add tests that show missing `well_id` currently fails before QC.
2. Define the minimal set of QC-able malformed conditions.
3. Implement the smallest explicit review path without changing strict `pcr_peaks()` unexpectedly.
4. Verify downstream calls preserve evidence and QC flags.
5. Update documentation to explain strict objects versus reviewable imports.

Version-control plan:
- Commit type: `feat` or `refactor`
- Suggested commit: `feat(stage-0.7): add qc-able malformed input path [#S07-04]`
- Commit only after strict validation and review-path tests both pass.

## Affected Layers
- [x] Import and normalization
- [ ] Assay specification
- [ ] Peak-level detection/evidence
- [ ] Sample-level interpretation
- [x] QC flags/evaluation
- [ ] Visualization/reporting
- [ ] Backward-compatibility wrappers

## Data Objects Impacted
- [x] pcr_peaks
- [ ] pcr_assay
- [ ] pcr_peak_calls
- [ ] pcr_sample_calls
- [x] pcr_qc
- [ ] None

## Backward Compatibility
- [x] Existing user-facing functions remain usable (or changes are explicitly documented)
- [x] Behavior change is intentional and documented
- [x] Migration note is included if needed

Details:
Strict validation should remain available. Any relaxed pathway must be explicit and documented so existing users do not unknowingly accept malformed inputs.

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
- tests/testthat/test-import-mapping.R
- tests/testthat/test-pcr-qc.R

## Documentation
- [ ] Roxygen/help text updated if needed
- [ ] README/vignette updates included if user-facing behavior changed
- [ ] NEWS entry added if appropriate

## CI Status
- [ ] Local checks pass
- [ ] CI expected to pass

## Risk Assessment
Medium: relaxing validation incorrectly could allow bad evidence into calls. Keep strict and reviewable pathways distinct.

## Definition of Done
- [ ] Small, reviewable PR
- [ ] Tests included
- [ ] Return types explicit and stable
- [ ] Compatibility impact documented
- [ ] No unrelated refactors bundled

## Follow-up Items
- Feed malformed-input QC flags into reporting and future Shiny review screens.
