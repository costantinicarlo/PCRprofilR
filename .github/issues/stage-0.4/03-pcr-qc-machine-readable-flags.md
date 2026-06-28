## Goal
Implement pcr_qc object with machine-readable run, sample, and control flags.

## Why This Step
QC is mandatory for auditable calls and for future Bayesian or operational workflows.

## Scope
- In scope:
  - Define pcr_qc schema and flag taxonomy
  - Implement initial checks (missing wells, duplicated sample IDs, control validity placeholders)
  - Add tests for flagged scenarios
- Out of scope:
  - Full contamination/hybrid inference (stage 0.5)

## Current Behavior
QC is implicit or absent in machine-readable outputs.

## Proposed Change
Add pcr_qc generation and attach references to sample calls.

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
- [ ] pcr_sample_calls
- [x] pcr_qc
- [ ] None

## Backward Compatibility
- [x] Existing user-facing functions remain usable (or changes are explicitly documented)
- [x] Behavior change is intentional and documented
- [ ] Migration note is included if needed

Details:
Legacy wrappers may expose limited QC at first while preserving existing outputs.

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
- tests/testthat/test-pcr-qc.R

## Documentation
- [x] Roxygen/help text updated if needed
- [x] README/vignette updates included if user-facing behavior changed
- [x] NEWS entry added if appropriate

## CI Status
- [ ] Local checks pass
- [ ] CI expected to pass

## Risk Assessment
Medium: QC strictness can surface latent run-quality issues.

## Definition of Done
- [x] Small, reviewable PR
- [x] Tests included
- [x] Return types explicit and stable
- [x] Compatibility impact documented
- [x] No unrelated refactors bundled

## Follow-up Items
- Expand QC taxonomy for weak/contamination/hybrid in stage 0.5.
