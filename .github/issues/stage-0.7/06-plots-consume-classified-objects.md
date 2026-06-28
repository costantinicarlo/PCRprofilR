## Goal
Refactor or add plotting workflows so modern visualizations consume `pcr_peak_calls`, `pcr_sample_calls`, and `pcr_qc` instead of independently recomputing positivity logic.

## Why This Step
The architecture requires visualization and reporting layers to display classified evidence, not duplicate scientific rules. This prevents plots, batch reports, and Shiny screens from disagreeing with the core interpreter.

## Scope
- In scope:
  - Identify plotting logic that recomputes threshold/window classification
  - Add modern plotting helper(s) or refactor existing plotting internals to accept classified core objects
  - Preserve `PCRexplorer()` and `PCRpherogram()` compatibility where feasible
  - Add tests confirming plots are driven by core call/evidence fields
- Out of scope:
  - Full Shiny interface
  - Full report dashboard
  - Changing deterministic call rules

## Current Behavior
Legacy plotting functions operate directly on raw-style input and apply plotting-specific threshold/window logic. They are useful for exploration but are not yet fully separated from scientific interpretation.

## Proposed Change
Introduce a core-object plotting path. Legacy functions may remain wrappers or exploratory helpers, but any new review/report plot must consume the canonical evidence and call objects.

Programmatic execution steps:
1. Add tests that establish existing legacy plot compatibility.
2. Add tests for a classified-object plot using synthetic `pcr_peak_calls` / `pcr_sample_calls` / `pcr_qc`.
3. Implement the smallest plotting helper or internal refactor.
4. Ensure visual tests check object structure, layers, data fields, and no warning debt rather than image snapshots.
5. Update vignette/README only for the new recommended plotting path.

Version-control plan:
- Commit type: `refactor` or `feat`
- Suggested commit: `refactor(stage-0.7): plot classified PCR evidence [#S07-06]`
- Commit after visual-function tests and full tests pass.

## Affected Layers
- [ ] Import and normalization
- [ ] Assay specification
- [x] Peak-level detection/evidence
- [x] Sample-level interpretation
- [x] QC flags/evaluation
- [x] Visualization/reporting
- [x] Backward-compatibility wrappers

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
Do not remove `PCRexplorer()` or `PCRpherogram()`. If behavior changes, document the compatibility impact and keep legacy examples working.

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
- tests/testthat/test-PCRexplorer.R
- tests/testthat/test-PCRpherogram.R
- Add a new focused plotting test if new exported helpers are introduced.

## Documentation
- [ ] Roxygen/help text updated if needed
- [ ] README/vignette updates included if user-facing behavior changed
- [ ] NEWS entry added if appropriate

## CI Status
- [ ] Local checks pass
- [ ] CI expected to pass

## Risk Assessment
Medium: plots are user-facing and support scientific review. Preserve old behavior while introducing the classified-object path incrementally.

## Definition of Done
- [ ] Small, reviewable PR
- [ ] Tests included
- [ ] Return types explicit and stable
- [ ] Compatibility impact documented
- [ ] No unrelated refactors bundled

## Follow-up Items
- Use the classified-object plotting path in future Shiny review screens and automated reports.
