## Goal
Align `validate_pcr_assay()` with `pcr_assay()` / `as_pcr_assay()` so exported validation accepts the same minimally valid assay contract as the constructor.

## Why This Step
The constructor currently fills missing `confirm_concentration` from `min_concentration`, but the exported validator treats `confirm_concentration` as required during numeric validation. That mismatch makes the public API harder to trust and blocks clean downstream assay-specification workflows.

## Scope
- In scope:
  - Define whether `confirm_concentration` is optional or required in the public assay contract
  - Make `validate_pcr_assay()`, `pcr_assay()`, and `as_pcr_assay()` consistent with that decision
  - Add tests for direct validator use on assays with and without `confirm_concentration`
  - Update documentation if the public contract changes or is clarified
- Out of scope:
  - Adding control roles
  - Changing threshold-zone semantics
  - Implementing a full rule engine

## Current Behavior
`pcr_assay()` adds `confirm_concentration <- min_concentration` when the column is absent. `validate_pcr_assay()` includes `confirm_concentration` in numeric columns before ensuring that default exists.

## Proposed Change
Make direct validation and constructor validation share the same schema-normalization path or clearly split `normalize` from `validate` so users get one coherent assay contract.

Programmatic execution steps:
1. Add failing tests that call `validate_pcr_assay()` directly on a minimally valid assay without `confirm_concentration`.
2. Implement the smallest normalization or validation change.
3. Add boundary tests for `confirm_concentration < min_concentration`.
4. Run `test-pcr-assay.R` and `test-public-api-curation.R`.
5. Run the full test suite before commit.

Version-control plan:
- Commit type: `fix`
- Suggested commit: `fix(stage-0.7): align assay validator contract [#S07-02]`
- Commit after focused tests and full package tests pass.

## Affected Layers
- [ ] Import and normalization
- [x] Assay specification
- [ ] Peak-level detection/evidence
- [ ] Sample-level interpretation
- [ ] QC flags/evaluation
- [ ] Visualization/reporting
- [ ] Backward-compatibility wrappers

## Data Objects Impacted
- [ ] pcr_peaks
- [x] pcr_assay
- [ ] pcr_peak_calls
- [ ] pcr_sample_calls
- [ ] pcr_qc
- [ ] None

## Backward Compatibility
- [x] Existing user-facing functions remain usable (or changes are explicitly documented)
- [x] Behavior change is intentional and documented
- [x] Migration note is included if needed

Details:
This should be a compatibility improvement for the curated public validator. Existing constructor behavior should remain stable unless explicitly documented.

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
- tests/testthat/test-pcr-assay.R
- tests/testthat/test-public-api-curation.R

## Documentation
- [ ] Roxygen/help text updated if needed
- [ ] README/vignette updates included if user-facing behavior changed
- [ ] NEWS entry added if appropriate

## CI Status
- [ ] Local checks pass
- [ ] CI expected to pass

## Risk Assessment
Low to medium: assay validation is foundational, so keep the diff narrow and test constructor, validator, and public alias behavior together.

## Definition of Done
- [ ] Small, reviewable PR
- [ ] Tests included
- [ ] Return types explicit and stable
- [ ] Compatibility impact documented
- [ ] No unrelated refactors bundled

## Follow-up Items
- Add explicit control-role assay fields after validator semantics are stable.
