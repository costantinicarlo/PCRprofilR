---
name: Refactor Step
description: Plan and track one small, reviewable PCRprofilR refactor increment
title: "[Refactor] "
labels: ["refactor", "architecture"]
assignees: []
---

## Goal
Describe one small, reviewable change.

## Why This Step
Explain why this step is needed now and what it unlocks next.

## Scope
- In scope:
- Out of scope:

## Current Behavior
Describe current behavior and assumptions in affected functions.

## Proposed Change
Describe the intended internal change.

## Affected Layers
Check all that apply:
- [ ] Import and normalization
- [ ] Assay specification
- [ ] Peak-level detection/evidence
- [ ] Sample-level interpretation
- [ ] QC flags/evaluation
- [ ] Visualization/reporting
- [ ] Backward-compatibility wrappers

## Data Objects Impacted
Check all that apply:
- [ ] pcr_peaks
- [ ] pcr_assay
- [ ] pcr_peak_calls
- [ ] pcr_sample_calls
- [ ] pcr_qc
- [ ] None

## Backward Compatibility
- [ ] Existing user-facing functions remain usable (or changes are explicitly documented)
- [ ] Behavior change is intentional and documented
- [ ] Migration note is included if needed

Details:

## Validation and Error Handling
- [ ] Inputs validated explicitly
- [ ] Errors are clear and actionable
- [ ] No hidden cwd/global-state dependencies introduced

## QC and Evidence Retention
- [ ] Outputs remain machine-readable
- [ ] Evidence is retained (size, concentration, thresholds, matched target, call, flags)
- [ ] Ambiguous/weak cases are preserved and flagged, not forced binary

## Tests
- [ ] Existing behavior frozen where required
- [ ] New behavior covered with focused testthat tests
- [ ] Edge cases included (threshold boundaries, malformed input, multi-target/ambiguous cases)

Test files:

## Documentation
- [ ] Roxygen/help text updated if needed
- [ ] README/vignette updates included if user-facing behavior changed
- [ ] NEWS entry added if appropriate

## CI Status
- [ ] Local checks pass
- [ ] CI expected to pass

## Risk Assessment
What could break and how risk is mitigated.

## Definition of Done
- [ ] Small, reviewable PR
- [ ] Tests included
- [ ] Return types explicit and stable
- [ ] Compatibility impact documented
- [ ] No unrelated refactors bundled

## Follow-up Items
List next small increments enabled by this step.
