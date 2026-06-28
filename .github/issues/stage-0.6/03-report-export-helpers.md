## Goal
Add report/export helpers for evidence tables, sample calls, and QC outputs with provenance.

## Why This Step
Operational use requires standardized artifacts for audit and review.

## Scope
- In scope:
  - Implement export helpers for CSV/TSV and optional summary reports
  - Include metadata/provenance fields (assay version, run ID, timestamp, package version)
  - Add tests for deterministic file outputs
- Out of scope:
  - Full HTML dashboard or Shiny implementation

## Current Behavior
Exports are ad hoc and not standardized for provenance.

## Proposed Change
Provide deterministic export helpers built strictly on core objects.

## Affected Layers
- [ ] Import and normalization
- [ ] Assay specification
- [ ] Peak-level detection/evidence
- [ ] Sample-level interpretation
- [x] QC flags/evaluation
- [x] Visualization/reporting
- [ ] Backward-compatibility wrappers

## Data Objects Impacted
- [ ] pcr_peaks
- [ ] pcr_assay
- [x] pcr_peak_calls
- [x] pcr_sample_calls
- [x] pcr_qc
- [ ] None

## Backward Compatibility
- [x] Existing user-facing functions remain usable (or changes are explicitly documented)
- [x] Behavior change is intentional and documented
- [x] Migration note is included if needed

Details:
Additive helper layer; existing APIs remain available.

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
- tests/testthat/test-export-helpers.R

## Documentation
- [x] Roxygen/help text updated if needed
- [x] README/vignette updates included if user-facing behavior changed
- [x] NEWS entry added if appropriate

## CI Status
- [ ] Local checks pass
- [ ] CI expected to pass

## Risk Assessment
Low to medium: file naming and metadata conventions must remain stable over time.

## Definition of Done
- [x] Small, reviewable PR
- [x] Tests included
- [x] Return types explicit and stable
- [x] Compatibility impact documented
- [x] No unrelated refactors bundled

## Follow-up Items
- Use these exports as primary artifacts for Docker and review UI workflows.
