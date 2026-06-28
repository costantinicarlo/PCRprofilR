## Goal
Resolve package build/check hygiene issues discovered during the architecture audit without changing scientific behavior.

## Why This Step
Future agents need a clean baseline before making behavior changes. Packaging warnings and metadata drift make it harder to tell whether later failures come from new code or existing release hygiene.

## Scope
- In scope:
  - Update the declared R dependency to match native pipe usage (`R >= 4.1.0`)
  - Exclude repository-only metadata such as `.github` from source package builds
  - Decide and document whether generated vignette artifacts are source files, ignored artifacts, or built `inst/doc` outputs
  - Add or update focused tests/check notes only if needed for packaging assertions
- Out of scope:
  - Scientific calling behavior
  - Vignette content rewrite
  - Docker, Shiny, or Bayesian implementation

## Current Behavior
`R CMD build` automatically raises the package dependency to `R >= 4.1.0` because source files use the native pipe. `R CMD check` reports `.github` in the source bundle and warns about vignette artifacts without corresponding `inst/doc` outputs.

## Proposed Change
Make package metadata and build-ignore policy explicit so local and CI package checks start from a stable baseline.

Programmatic execution steps:
1. Inspect `DESCRIPTION`, `.Rbuildignore`, `.gitignore`, `vignettes/.gitignore`, and the current check log.
2. Apply only metadata/build-ignore changes required to remove known hygiene warnings.
3. Rebuild the source tarball.
4. Run targeted package checks with the same local constraints documented in the issue.
5. Update `NEWS.md` only if the user-visible supported R version changes.

Version-control plan:
- Commit type: `chore`
- Suggested commit: `chore(stage-0.7): clean package check metadata [#S07-01]`
- Commit only after package build succeeds and check output is documented.

## Affected Layers
- [ ] Import and normalization
- [ ] Assay specification
- [ ] Peak-level detection/evidence
- [ ] Sample-level interpretation
- [ ] QC flags/evaluation
- [x] Visualization/reporting
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
- [x] Migration note is included if needed

Details:
No scientific API behavior should change. If the minimum R version is updated, document it as a packaging/runtime support change.

## Validation and Error Handling
- [x] Inputs validated explicitly
- [x] Errors are clear and actionable
- [x] No hidden cwd/global-state dependencies introduced

## QC and Evidence Retention
- [x] Outputs remain machine-readable
- [x] Evidence is retained (size, concentration, thresholds, matched target, call, flags)
- [x] Ambiguous/weak cases are preserved and flagged, not forced binary

## Tests
- [ ] Existing behavior frozen where required
- [ ] New behavior covered with focused testthat tests
- [ ] Edge cases included (threshold boundaries, malformed input, multi-target/ambiguous cases)

Test files:
- Not expected unless a package-check scaffold test is updated.

## Documentation
- [ ] Roxygen/help text updated if needed
- [ ] README/vignette updates included if user-facing behavior changed
- [ ] NEWS entry added if appropriate

## CI Status
- [ ] Local checks pass
- [ ] CI expected to pass

## Risk Assessment
Low: metadata and build-ignore changes can affect package distribution but should not affect runtime behavior.

## Definition of Done
- [ ] Small, reviewable PR
- [ ] Tests included
- [ ] Return types explicit and stable
- [ ] Compatibility impact documented
- [ ] No unrelated refactors bundled

## Follow-up Items
- Use this clean packaging baseline before validator, QC, rule-engine, and plot refactors.
