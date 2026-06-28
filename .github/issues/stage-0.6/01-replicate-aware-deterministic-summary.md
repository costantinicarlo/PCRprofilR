## Goal
Add replicate-aware deterministic summary functions using core call/evidence objects.

## Why This Step
Repeated tests are common and require structured deterministic aggregation before Bayesian work.

## Scope
- In scope:
  - Define replicate grouping metadata requirements
  - Implement deterministic summary across replicate runs
  - Add tests for concordant/discordant replicate scenarios
- Out of scope:
  - Bayesian pooling

## Current Behavior
Replicate handling is ad hoc or absent.

## Proposed Change
Provide explicit replicate summary helpers tied to pcr_sample_calls and pcr_qc.

## Affected Layers
- [ ] Import and normalization
- [ ] Assay specification
- [x] Peak-level detection/evidence
- [x] Sample-level interpretation
- [x] QC flags/evaluation
- [ ] Visualization/reporting
- [x] Backward-compatibility wrappers

## Data Objects Impacted
- [ ] pcr_peaks
- [ ] pcr_assay
- [ ] pcr_peak_calls
- [x] pcr_sample_calls
- [x] pcr_qc
- [ ] None

## Backward Compatibility
- [x] Existing user-facing functions remain usable (or changes are explicitly documented)
- [x] Behavior change is intentional and documented
- [x] Migration note is included if needed

Details:
This adds new helpers; existing wrappers remain intact.

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
- tests/testthat/test-replicate-summary.R

## Documentation
- [x] Roxygen/help text updated if needed
- [x] README/vignette updates included if user-facing behavior changed
- [x] NEWS entry added if appropriate

## CI Status
- [ ] Local checks pass
- [ ] CI expected to pass

## Risk Assessment
Medium: replicate IDs and metadata integrity can vary across labs.

## Definition of Done
- [x] Small, reviewable PR
- [x] Tests included
- [x] Return types explicit and stable
- [x] Compatibility impact documented
- [x] No unrelated refactors bundled

## Follow-up Items
- Provide replicate summary export formats for batch usage.
