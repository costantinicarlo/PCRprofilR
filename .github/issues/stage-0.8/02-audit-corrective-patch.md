---
name: Refactor Step
description: Plan and track one small, reviewable PCRprofilR refactor increment
title: "[Refactor] Stage 0.8 audit corrective patch: assay safety, fail-closed hybrid gating, provenance"
labels: ["refactor", "architecture", "stage-0.8", "audit"]
assignees: []
---

## Goal
Address the release-blocking and important correctness findings from the post-stage-0.8 audit (`PCRprofilR audit post stage 0.8.md`) so the pairwise profile-evidence/peak-balance layer merged in PR #4 (`c0dbf232d4283ac4e764bbceebb13344f33df360`) is assay-safe, fails closed on ambiguous or forged evidence, and is fully auditable from exported artifacts before stage 0.8 is marked complete or any tag/release is cut.

## Why This Step
An independent post-merge audit found the profile-balance feature is conceptually sound and CI is green, but flagged **four release-blocking issues** plus several correctness/consistency, documentation, and security-hardening items that must be resolved before `master` is releasable:

1. `pcr_peak_calls()`/`pcr_profile_evidence()`/`pcr_sample_calls()` never carry `assay_id` through target- and sample-level grouping or through the profile-evidence join, so a multi-`assay_id` `pcr_assay` table can silently combine or collapse targets across assays and produce duplicated sample-call rows.
2. `classify_pcr_samples()` accepts an externally supplied `profile_evidence` object without validating its schema, status enums, or internal consistency. The `hybrid_candidate` gate checks `profile_rule_status == "calibration_validated" & balance_status == "pass"` but does **not** require `strength_status == "pass"`, so a stale/forged/partially reconstructed evidence object with `strength_status = NA` can still reach `hybrid_candidate` — a fail-open violation of the intended fail-closed design.
3. Exported `profile_evidence.csv` omits the actual rule parameters used (`max_abs_log2_deviation`, `min_evidence_zone_a`, `min_evidence_zone_b`), and batch mode never exports the canonical `pcr_profile_rules` table itself, so a reviewer cannot reconstruct why a `balance_status`/`strength_status` was assigned from batch output alone. Batch mode also writes CSVs directly with `write.csv()`, bypassing the provenance helper used by `report_pcr_calls()`.
4. The package version (`0.2.0`) does not distinguish outputs produced by the old permissive "two labels -> hybrid" algorithm from the new calibrated profile-balance algorithm; there is no `interpretation_model_version` field.

Additional correctness/consistency issues (5-9 in the audit) cover: profile evidence being computed for "two labels" while sample calls require "two matched targets" (producing contradictory exported evidence vs. final call for >2-matched-target/2-label samples); accepted but semantically invalid `profile_type`/`calibration_status` combinations; `as.numeric()` silently mis-converting factor-valued rule columns; arbitrary dominant-target assignment on exact concentration ties; and ambiguous precedence between the duplicate-physical-peak guard and `rule_missing`.

The audit also found documentation drift (stale installed vignette, incomplete README, obsolete advanced-layer-deferral contract, stage-0.8 manifest left `open`), one pre-existing compatibility gap (undeclared `dplyr` version requirement for the `relationship` argument), and three security-hardening items (CSV formula-injection exposure for a future Shiny layer, unpinned/under-permissioned GitHub Actions, unprotected `master`).

## Scope
- In scope:
  - Require and validate a single `assay_id` per `detect_pcr_peaks()` invocation (or otherwise thread `assay_id` correctly) and carry `assay_id` through target-level grouping, sample-level grouping, `pcr_sample_calls` output, and the profile-evidence join key.
  - Add `validate_pcr_profile_evidence()` (canonical columns/types, one row per `(run_id, plate_id, well_id, sample_id, assay_id)`, valid enumerated status combinations, target-pair agreement with `peak_calls`) and require `strength_status == "pass"` (in addition to `profile_rule_status == "calibration_validated"` and `balance_status == "pass"`) before assigning `hybrid_candidate`. Assert join-key uniqueness before joining profile evidence into sample calls.
  - Carry `max_abs_log2_deviation`, `min_evidence_zone_a`, and `min_evidence_zone_b` into every profile-evidence row; export the canonical `pcr_profile_rules` table (`profile_rules.csv`) from both `run_pcr_batch()` and `report_pcr_calls()`, routed through the shared provenance-writing helper instead of a second `write.csv()` path.
  - Add an explicit `interpretation_model_version` provenance field, distinct from `rule_version` and the installed package version, and advance the development package version.
  - Restrict evaluable pairwise profile evidence to exactly two matched targets and exactly two biological labels (matching `pcr_sample_calls()`'s existing gate); emit an explicit `multi_target_profile_review`-style state instead of silently reducing >2 matched targets to one target per label.
  - Tighten `pcr_profile_rules` validation to an explicit `profile_type` x `calibration_status` compatibility matrix, require explicit (non-defaulted) `min_evidence_zone_a/b` and `rule_version` for validated hybrid rules, and reject/warn on rule target or assay identifiers unmatched in the supplied assay/peak_calls.
  - Fix factor-unsafe numeric coercion for `expected_log2_ratio`/`max_abs_log2_deviation` (reject factors or convert via `as.character()` with an explicit non-conversion check).
  - Resolve the equal-concentration dominant-target tie (explicit `dominance_status = "equal"` / both `dominant_target`/`minor_target` set to `NA`, or explicit co-dominance labeling) and clarify duplicate-physical-peak vs. `rule_missing` precedence (prioritize `rule_missing` while retaining `duplicate_physical_peak = TRUE`, or introduce `dual_target_overlap_review`).
  - Declare `dplyr (>= 1.1.1)` in `DESCRIPTION` for the `relationship` argument used in `pcr_peak_calls()`.
  - Regenerate installed vignette artifacts (`inst/doc/PCRprofilR.Rmd/.R/.html`) from the updated source vignette; finish the README update (worked example with profile rules/evidence, complete `call_state` list, stage list through 0.8); update the advanced-layer-deferral contract to include `pcr_profile_rules`/`pcr_profile_evidence` in the stable consumer contract.
  - Add the regression tests enumerated in the audit's "Missing regression tests" section (multi-`assay_id`, duplicated `(assay_id, target_id)`, malformed/forged supplied evidence, `strength_status = NA` cannot yield hybrid, 3-matched-targets/2-labels, factor-valued rule columns, invalid type/status combinations, unmatched rule identifiers, tie dominance, batch with a real `profile_rules_path`, rule-table export/reconstruction, `report_pcr_calls()` with/without profile evidence, installed-vignette consistency, minimum-supported-`dplyr` execution).
  - Harden the GitHub Actions workflow (explicit `permissions: contents: read`, SHA-pinned actions with version comments, remove the redundant live `install.packages()`), and document/apply branch protection on `master` (PR required, required status check, review required, force-push/deletion blocked).
- Out of scope:
  - Any further scientific/calibration work (`expected_log2_ratio`/`max_abs_log2_deviation` empirical values for real target pairs remain deliberately uncalibrated).
  - Multi-assay support as a first-class feature (this step only fails closed/validates against it; a later redesign may add assay identity to the peak schema itself).
  - Docker, Shiny, or Bayesian layer implementation.
  - CI matrix expansion beyond documenting the current gap (adding R 4.1/release/devel and macOS/Windows jobs can be a separate follow-up).
  - Tagging or releasing the package.

## Current Behavior
`pcr_peak_calls()`, `.pcr_representative_target_peaks()`, and `pcr_sample_calls()` group by `run_id`/`plate_id`/`well_id`/`sample_id`/`target_id` only, omitting `assay_id`, even though `pcr_assay` permits multiple `assay_id` values. `classify_pcr_samples()`/`pcr_sample_calls()` join externally supplied `profile_evidence` after only an `inherits()` check and derive `hybrid_candidate` from `profile_rule_status`/`balance_status` without requiring `strength_status == "pass"`. `pcr_profile_evidence()` selects evaluable pairs by biological-label count (`== 2`) independent of matched-target count, while `pcr_sample_calls()` gates the pairwise pathway on `matched_target_count == 2 & matched_label_count == 2`, so the two objects can disagree for >2-matched-target samples. Batch/export helpers write `profile_evidence.csv` without rule parameters or a `profile_rules.csv`, and `pcr_batch_run()` writes files directly with `write.csv()` rather than through `.with_provenance()`/`report_pcr_calls()`. `pcr_profile_rules()` accepts `as.numeric()` on rule columns (unsafe for factors) and permits scientifically inconsistent `profile_type`/`calibration_status` combinations. `DESCRIPTION` declares an unversioned `dplyr` dependency despite using the `relationship` argument (dplyr >= 1.1.1). The installed vignette, README, and advanced-layer-deferral contract were not updated to reflect the new dual-target states/objects.

## Proposed Change
Thread `assay_id` explicitly through the profile-evidence and sample-call pipeline and validate single-assay input at the `detect_pcr_peaks()` boundary. Add `validate_pcr_profile_evidence()` and make it a required, fail-closed gate for both internally computed and externally supplied profile evidence, requiring `strength_status == "pass"` for any `hybrid_candidate` call. Enrich profile-evidence rows and batch/report exports with the full rule provenance needed to reconstruct a decision (`profile_rules.csv`, rule thresholds embedded per row, `interpretation_model_version`). Align the "evaluable pair" definition between `pcr_profile_evidence()` and `pcr_sample_calls()`. Tighten `pcr_profile_rules` validation (compatibility matrix, explicit required fields for validated hybrid rules, safe numeric coercion) and resolve the two identified semantic ambiguities (tie dominance, duplicate-peak vs. rule-missing precedence). Declare the correct `dplyr` version floor. Regenerate/complete documentation artifacts. Add the audit's enumerated regression tests. Harden CI workflow permissions/pinning and document required branch protection for `master`.

## Affected Layers
Check all that apply:
- [x] Import and normalization
- [x] Assay specification
- [x] Peak-level detection/evidence
- [x] Sample-level interpretation
- [ ] QC flags/evaluation
- [x] Visualization/reporting
- [ ] Backward-compatibility wrappers

## Data Objects Impacted
Check all that apply:
- [x] pcr_peaks
- [x] pcr_assay
- [x] pcr_peak_calls
- [x] pcr_sample_calls
- [ ] pcr_qc
- [ ] None

Also impacts the stage-0.8 objects `pcr_profile_rules` and `pcr_profile_evidence` (adds `validate_pcr_profile_evidence()`).

## Backward Compatibility
- [x] Existing user-facing functions remain usable (or changes are explicitly documented)
- [x] Behavior change is intentional and documented
- [x] Migration note is included if needed

Details:
Requiring a single `assay_id` per `detect_pcr_peaks()` call and requiring `strength_status == "pass"` for `hybrid_candidate` are both intentional, documented tightenings that can change output for inputs that previously worked "by accident" (multi-assay tables, hand-built/forged `profile_evidence` objects). Any caller relying on either prior behavior must be called out in `NEWS.md` as a follow-up breaking change to the stage-0.8 feature, consistent with PCRprofilR's fail-closed design principle.

## Validation and Error Handling
- [x] Inputs validated explicitly
- [x] Errors are clear and actionable
- [x] No hidden cwd/global-state dependencies introduced

Multi-`assay_id` input, unmatched rule target/assay identifiers, invalid `profile_type`/`calibration_status` combinations, and malformed/inconsistent supplied `profile_evidence` must all fail with clear, actionable errors (or an explicit review state) rather than silently degrading or producing an incorrect classification.

## QC and Evidence Retention
- [x] Outputs remain machine-readable
- [x] Evidence is retained (size, concentration, thresholds, matched target, call, flags)
- [x] Ambiguous/weak cases are preserved and flagged, not forced binary

Profile evidence must retain the actual rule thresholds used (not just derived pass/fail statuses) so a decision is reconstructible from exported artifacts alone.

## Tests
- [x] Existing behavior frozen where required
- [x] New behavior covered with focused testthat tests
- [x] Edge cases included (threshold boundaries, malformed input, multi-target/ambiguous cases)

Test files:
- New/updated tests covering: multiple `assay_id` values and duplicated `(assay_id, target_id)`; supplied `profile_evidence` with missing/invalid/duplicated statuses; evidence with mismatched sample/assay/target-pair context; `calibration_validated + balance pass + strength_status = NA` cannot yield `hybrid_candidate`; three matched targets representing two labels; factor-valued numeric rule columns; invalid `profile_type`/`calibration_status` combinations; unmatched rule target/assay identifiers; equal-concentration dominance; `pcr_batch_run()` with a real `profile_rules_path`; rule-table export and decision reconstruction from exported files; `report_pcr_calls()` with empty and non-empty profile evidence; installed-vignette consistency check; execution against the minimum supported `dplyr` version.

## Documentation
- [x] Roxygen/help text updated if needed
- [x] README/vignette updates included if user-facing behavior changed
- [x] NEWS entry added if appropriate

Details:
Regenerate `inst/doc/PCRprofilR.Rmd/.R/.html` from the updated source vignette; complete the README's worked example (profile rules/evidence construction), full `call_state` enumeration, and stage list; update the advanced-layer-deferral contract to include `pcr_profile_rules`/`pcr_profile_evidence`; add a `NEWS.md` entry for every behavior change in this issue, including the new `interpretation_model_version` field and any further breaking tightenings.

## CI Status
- [ ] Local checks pass
- [ ] CI expected to pass

## Risk Assessment
Medium-high: several of these are correctness fixes that change classification behavior for previously mishandled inputs (multi-assay tables, forged/partial evidence objects), which is the intended, safety-improving outcome, but downstream consumers relying on the current permissive behavior must be notified via `NEWS.md`. The provenance/export and documentation items are low risk (additive). The CI/branch-protection hardening items are governance changes outside the R package code and should be applied by a maintainer with repository admin access.

## Definition of Done
- [ ] Small, reviewable PR
- [ ] Tests included
- [ ] Return types explicit and stable
- [ ] Compatibility impact documented
- [ ] No unrelated refactors bundled

## Follow-up Items
- Empirical calibration of `expected_log2_ratio`/`max_abs_log2_deviation` for real target pairs (unchanged from stage-0.8, still deferred).
- First-class multi-assay support with assay identity carried in the peak schema itself, if a real workflow requires evaluating more than one assay per invocation.
- CI matrix expansion (R 4.1, release, devel; macOS/Windows jobs) and Dependabot configuration for pinned GitHub Actions.
- CSV formula-injection mitigation (spreadsheet-safe export mode or identifier sanitization) before any future Shiny/upload-facing layer is built.
- Mark stage-0.8 (`S08-01`) and this corrective issue as `closed` in `.github/issues/manifest.yaml` only once this patch and its tests are merged, then re-evaluate readiness to tag/release.
