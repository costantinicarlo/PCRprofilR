## Goal
Add CI workflow that runs R CMD check and testthat on push/PR.

## Why This Step
Automated commit gating needs CI feedback before stage-level merges.

## Scope
- In scope:
  - Add GitHub Actions workflow for package checks
  - Include dependency install caching where practical
  - Fail build on test/check failures
- Out of scope:
  - Full release automation
  - Coverage upload and pkgdown deploy

## Current Behavior
No workflow automation exists for package checks.

## Proposed Change
Create minimal robust CI workflow with documented expected runtime and failure handling.

## Affected Layers
- [ ] Import and normalization
- [ ] Assay specification
- [ ] Peak-level detection/evidence
- [ ] Sample-level interpretation
- [ ] QC flags/evaluation
- [ ] Visualization/reporting
- [ ] Backward-compatibility wrappers

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
No runtime API change; infrastructure-only.

## Validation and Error Handling
- [ ] Inputs validated explicitly
- [x] Errors are clear and actionable
- [x] No hidden cwd/global-state dependencies introduced

## QC and Evidence Retention
- [x] Outputs remain machine-readable
- [ ] Evidence is retained (size, concentration, thresholds, matched target, call, flags)
- [ ] Ambiguous/weak cases are preserved and flagged, not forced binary

## Tests
- [x] Existing behavior frozen where required
- [x] New behavior covered with focused testthat tests
- [ ] Edge cases included (threshold boundaries, malformed input, multi-target/ambiguous cases)

Test files:
- .github/workflows/r-cmd-check.yml

## Documentation
- [ ] Roxygen/help text updated if needed
- [ ] README/vignette updates included if user-facing behavior changed
- [x] NEWS entry added if appropriate

## CI Status
- [ ] Local checks pass
- [x] CI expected to pass

## Risk Assessment
Low risk; occasional failures may come from dependency resolution differences.

## Definition of Done
- [x] Small, reviewable PR
- [x] Tests included
- [x] Return types explicit and stable
- [x] Compatibility impact documented
- [x] No unrelated refactors bundled

## Follow-up Items
- Add optional lintr and coverage workflows in separate issues.
