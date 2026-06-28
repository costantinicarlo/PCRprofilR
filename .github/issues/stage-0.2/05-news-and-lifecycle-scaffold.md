## Goal
Introduce minimal release-note and lifecycle scaffolding for auditable staged evolution.

## Why This Step
Roadmap execution requires clear communication of behavior changes and stability levels.

## Scope
- In scope:
  - Add NEWS.md
  - Add lifecycle note in README and/or package docs
  - Document current status as pre-1.0 staged evolution
- Out of scope:
  - Full pkgdown website
  - Broad documentation rewrite

## Current Behavior
No dedicated NEWS or lifecycle scaffolding is present.

## Proposed Change
Add minimal documentation scaffolding that can be updated per stage merge.

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
Documentation-only changes.

## Validation and Error Handling
- [ ] Inputs validated explicitly
- [ ] Errors are clear and actionable
- [x] No hidden cwd/global-state dependencies introduced

## QC and Evidence Retention
- [x] Outputs remain machine-readable
- [ ] Evidence is retained (size, concentration, thresholds, matched target, call, flags)
- [ ] Ambiguous/weak cases are preserved and flagged, not forced binary

## Tests
- [ ] Existing behavior frozen where required
- [ ] New behavior covered with focused testthat tests
- [ ] Edge cases included (threshold boundaries, malformed input, multi-target/ambiguous cases)

Test files:
- none

## Documentation
- [x] Roxygen/help text updated if needed
- [x] README/vignette updates included if user-facing behavior changed
- [x] NEWS entry added if appropriate

## CI Status
- [ ] Local checks pass
- [ ] CI expected to pass

## Risk Assessment
Very low risk; improves release traceability.

## Definition of Done
- [x] Small, reviewable PR
- [ ] Tests included
- [x] Return types explicit and stable
- [x] Compatibility impact documented
- [x] No unrelated refactors bundled

## Follow-up Items
- Keep NEWS entries mandatory for all user-visible changes from stage 0.3 onward.
