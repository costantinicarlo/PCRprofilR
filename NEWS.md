# PCRprofilR News

## PCRprofilR 0.3.1 — development, unreleased

This is the post-implementation audit-hardening increment for the stage-0.8
profile-evidence/peak-balance layer recorded as PCRprofilR 0.3.0. **PCRprofilR
0.3.1 is untagged and unreleased.** Corrections from the independent
post-merge audit accumulate in this section as they are implemented.

## PCRprofilR 0.3.0 — unreleased development milestone

This section records the stage-0.8 pairwise profile-evidence and peak-balance
interpretation layer as it was merged in pull request #4
(`c0dbf232d4283ac4e764bbceebb13344f33df360`). **This version was neither
tagged nor formally released**; it exists only as an honest historical
boundary in `NEWS.md` and `DESCRIPTION` before the post-merge audit hardening
recorded under PCRprofilR 0.3.1.

- Added a canonical pairwise `pcr_profile_rules` object (`as_pcr_profile_rules()`, `validate_pcr_profile_rules()`) describing the expected quantitative relationship (hybrid, mixed, or forbidden) between two assay targets, with explicit calibration status and pair-specific balance tolerance.
- Added `evaluate_pcr_profiles()`, a deterministic profile-evidence layer that selects one representative peak per matched target and computes continuous peak-balance metrics (`observed_log2_ratio`, `raw_balance_ratio`, `fold_imbalance`, and, for validated rules, `abs_log2_deviation` and `balance_score`).
- **Breaking change:** `classify_pcr_samples()` no longer classifies every sample with two matched biological labels as `hybrid_candidate`. A `hybrid_candidate` call now requires an explicit, validated, pair-specific profile rule whose balance criterion passes. Dual-target samples otherwise resolve to `dual_target_unresolved_review`, `dual_target_weak_review`, `dual_target_imbalanced_review`, or `dual_target_balance_review`, while preserving `call == "positive"` for genuinely detected targets. This removes a permissive rule that produced an implausibly high rate of automatic hybrid calls on real data; see `.github/issues/stage-0.8/01-pairwise-profile-evidence-peak-balance.md`.
- `classify_pcr_samples()`, `run_pcr_batch()`, and `report_pcr_calls()` gained optional `profile_rules`/`profile_evidence` arguments so batch workflows and exports can supply and audit pairwise profile rules; `run_pcr_batch()` writes `profile_evidence.csv` alongside existing artifacts.
- Fixed `validate_pcr_profile_rules()` to apply the same optional-column defaults (`calibration_status`, `min_evidence_zone_a/b`, `rule_version`) internally that its documentation promised, so the exported validator accepts the documented minimal schema directly instead of erroring (pull-request review fix).
- Empirical calibration of `expected_log2_ratio` and `max_abs_log2_deviation` for any real target pair is deliberately out of scope for this release; `calibration_status = "pending"` is the correct state until pair-specific balance distributions are validated from confirmed reference samples.

## PCRprofilR 0.2.0 — unreleased development milestone

- Added baseline tests for `PCRoutcome()` behavior on package data and synthetic edge cases.
- Added baseline tests for `PCRexplorer()` and `PCRpherogram()` plotting behavior and argument validation.
- Standardized validation helper error behavior for clearer, consistent user-facing messages.
- Added GitHub Actions workflow for `R CMD check`.
- Added internal canonical `pcr_peaks` constructor and validation tests to start stage-0.3 object contracts.
- Added internal canonical `pcr_assay` constructor and validation tests for explicit assay specifications.
- Added `normalize_pcr_peaks()` with configurable source-column mapping into canonical `pcr_peaks` format.
- Added `pcr_peak_calls()` evidence-table generator linking canonical peaks to assay targets.
- Added `pcr_sample_calls()` deterministic sample-level aggregation from peak evidence.
- Added `pcr_qc()` machine-readable QC summary with initial run/sample/control flags.
- Routed legacy `PCRpositive()` internals through canonical peaks, assay, evidence, and sample-call layers while preserving output behavior.
- Added three-zone threshold evidence in canonical calls (`below_analytical`, `analytical_to_confirmatory`, `above_confirmatory`) with sample-level zone precedence summaries.
- Added explicit internal call states (`weak_positive`, `ambiguous_review`, `indeterminate_review`) and corresponding machine-readable QC review flags.
- Added deterministic `hybrid_candidate` and `mixed_profile_candidate` sample states and QC `contamination_candidate` hooks for positive controls and duplicate review patterns.
- Added `pcr_replicate_summary()` to deterministically aggregate replicate call-state/QC outcomes into concordant/discordant consensus summaries.
- Added `pcr_batch_run()` file-based orchestration helper to run normalization, canonical calls, and QC and write reproducible batch artifacts.
- Added `pcr_export_artifacts()` to export evidence/call/QC tables with provenance metadata and optional deterministic summary report.
- Curated a public 1.0-facing API surface by exporting stable aliases (`as_pcr_*`, `detect_pcr_peaks()`, `classify_pcr_samples()`, `qc_pcr_run()`, `summarize_pcr_replicates()`, `run_pcr_batch()`, `report_pcr_calls()`) and schema validators.
- Declared `R (>= 4.1.0)` to match native pipe usage in package source files and tightened source-build ignores for repository-only and generated vignette artifacts.
- Added explicit QC control-role semantics for positive controls, negative controls, no-template controls, and blanks while retaining legacy sample-name inference as a fallback.
- Added an explicit `allow_qc_issues` review path so missing or malformed well identifiers can be retained as machine-readable QC failures while strict canonical validation remains the default.
- Made `rule_group` operational through optional assay `target_role` values (`required`, `optional`, `forbidden`) and added rule-status evidence fields to sample calls; compatible multi-target same-label profiles now resolve as positives instead of ambiguous reviews.
- Added `plot_pcr_evidence()` as a classified-object plotting path that consumes peak evidence, sample calls, and QC objects without recomputing positivity rules.
- Reworked the package vignette as a first-class tutorial indexed as "PCRprofilR tutorial: from electrophoresis peaks to sample calls" and shipped installed vignette artifacts so `vignette("PCRprofilR")` can discover it when vignette building is skipped.
- Regenerated the installed vignette HTML from an installed package context so rendered output no longer shows YAML metadata or captured `library(PCRprofilR)` / `data(mosquito)` errors.
- Split the curated public workflow helpers into individual help topics so each function is visible as a first-class entry in the package help index.
- Fixed package metadata, README, and example-script drift found during the project hygiene audit.

