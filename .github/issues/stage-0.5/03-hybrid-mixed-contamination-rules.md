## Goal
Implement deterministic rule framework for hybrid candidate, mixed profile, and contamination candidate outcomes.

## Why This Step
Complex biological profiles require explicit, auditable rule logic rather than one-off special cases.

## Scope
- In scope:
  - Add rule evaluation framework for multi-target combinations
  - Add contamination candidate detection hooks using QC flags
  - Add tests for representative rule scenarios
- Out of scope:
  - Probabilistic/Bayesian inference

## Current Behavior
Multi-target outcomes are not represented as robust explicit biological categories.

## Proposed Change
Extend deterministic rule engine and call taxonomy with evidence-backed hybrid/mixed/contamination states.

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
Compatibility wrappers may map complex states to legacy outputs while preserving detailed tables.

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
- tests/testthat/test-rule-engine-hybrid-mixed-contamination.R

## Documentation
- [x] Roxygen/help text updated if needed
- [x] README/vignette updates included if user-facing behavior changed
- [x] NEWS entry added if appropriate

## CI Status
- [ ] Local checks pass
- [ ] CI expected to pass

## Risk Assessment
Medium to high: rule interactions can be complex; precedence must be deterministic and documented.

## Definition of Done
- [x] Small, reviewable PR
- [x] Tests included
- [x] Return types explicit and stable
- [x] Compatibility impact documented
- [x] No unrelated refactors bundled

## Follow-up Items
- Feed these states into batch exports and review reports (stage 0.6).
