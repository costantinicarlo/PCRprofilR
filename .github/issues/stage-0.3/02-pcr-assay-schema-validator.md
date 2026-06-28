## Goal
Introduce pcr_assay object constructor and validator for explicit assay specification.

## Why This Step
Named target vectors are insufficient for weak/confirmatory thresholds and rule groups.

## Scope
- In scope:
  - Define assay schema columns
  - Implement constructor and validator
  - Add deterministic tests for required/optional fields
- Out of scope:
  - Rule engine execution
  - Bayesian modeling

## Current Behavior
Assay input is mostly a named numeric vector.

## Proposed Change
Add pcr_assay schema with explicit biological and threshold metadata.

## Affected Layers
- [ ] Import and normalization
- [x] Assay specification
- [ ] Peak-level detection/evidence
- [ ] Sample-level interpretation
- [ ] QC flags/evaluation
- [ ] Visualization/reporting
- [x] Backward-compatibility wrappers

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
- [ ] Migration note is included if needed

Details:
Wrap named vectors into minimal pcr_assay internally during transition.

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

## Documentation
- [x] Roxygen/help text updated if needed
- [x] README/vignette updates included if user-facing behavior changed
- [x] NEWS entry added if appropriate

## CI Status
- [ ] Local checks pass
- [ ] CI expected to pass

## Risk Assessment
Medium: may require transitional helpers for legacy inputs.

## Definition of Done
- [x] Small, reviewable PR
- [x] Tests included
- [x] Return types explicit and stable
- [x] Compatibility impact documented
- [x] No unrelated refactors bundled

## Follow-up Items
- Use pcr_assay in peak evidence generation (stage 0.4).
