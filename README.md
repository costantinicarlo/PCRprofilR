<p align="center">
  <img src="assets/PCRprofilR_logo_hex.png"
       alt="PCRprofilR logo"
       width="420">
</p>

# PCRprofilR

PCRprofilR is an R package for deterministic, auditable interpretation of PCR fragment profiles from capillary electrophoresis outputs.

The current development version is **0.3.1**, an untagged, unreleased post-audit hardening increment over the 0.3.0 stage-0.8 milestone. Neither 0.3.0 nor 0.3.1 has been tagged or released; see `NEWS.md` for the version history and rationale. PCRprofilR distinguishes three separate identifiers in exported provenance:

- `package_version`: the installed PCRprofilR version (`0.3.1`).
- `interpretation_model_version`: identifies the scientific interpretation algorithm itself (currently `"pairwise-profile-balance-v1"`), independent of package version.
- `rule_version`: identifies a specific target-pair calibration rule inside a `pcr_profile_rules` table.

The interpretation core: raw fragment peaks are normalized, compared with an explicit, single-assay specification, converted into peak-level evidence, evaluated for pairwise profile balance where two targets are detected, summarized into sample calls, checked by QC rules, and exported with full provenance.

The package is still pre-1.0. The legacy plotting and calling helpers remain available, but new work should use the curated public workflow described below.

## Start Here

After installation, open the tutorial vignette:

```r
vignette("PCRprofilR", package = "PCRprofilR")
```

The vignette is the first teaching resource for the package. It walks through the included `mosquito` data set from instrument-like peak rows to evidence, sample calls, QC flags, plots, replicate summaries, and exports.

If RStudio does not show the vignette immediately after installation, restart the R session and run the command above again. The repository now ships installed vignette artifacts in `inst/doc/`, so normal package installs can index the tutorial even when vignette rebuilding is skipped.

## Installation

PCRprofilR is currently distributed from GitHub:

```r
install.packages("devtools")
devtools::install_github("costantinicarlo/PCRprofilR")
```

The package depends on R 4.1.0 or later.

## Current Public API

Use these functions for new deterministic workflows:

- `as_pcr_peaks()`: normalize raw peak tables into the canonical peak schema.
- `as_pcr_assay()`: normalize assay target specifications.
- `as_pcr_profile_rules()`: normalize pairwise target-relationship rules (hybrid, mixed, forbidden) used to gate `hybrid_candidate` calls.
- `validate_pcr_peaks()`, `validate_pcr_assay()`, and `validate_pcr_profile_rules()`: check canonical object contracts.
- `detect_pcr_peaks()`: compare observed peaks with assay targets and create peak evidence.
- `evaluate_pcr_profiles()`: compute deterministic representative-peak selection and peak-balance evidence for dual-target samples.
- `classify_pcr_samples()`: summarize peak evidence (and, where supplied, profile evidence) into sample-level calls.
- `qc_pcr_run()`: create machine-readable QC flags.
- `plot_pcr_evidence()`: plot already-classified evidence without recomputing calls.
- `summarize_pcr_replicates()`: summarize repeated tests.
- `run_pcr_batch()`: run the deterministic workflow from input files.
- `report_pcr_calls()`: export evidence, calls, QC, summary files, and provenance.

> **Note:** detecting two matched biological targets is no longer sufficient for a `hybrid_candidate` call. A `hybrid_candidate` requires an explicit, validated, pair-specific `pcr_profile_rules` entry where both the absolute signal-strength requirement (`strength_status == "pass"`) and the pair-specific balance tolerance (`balance_status == "pass"`) are satisfied; otherwise the sample resolves to a `dual_target_*_review` state. `classify_pcr_samples()`, `evaluate_pcr_profiles()`, and any externally supplied `profile_evidence` are always validated with `validate_pcr_profile_evidence()`, so malformed or forged evidence can never "fail open" into `hybrid_candidate`. See `NEWS.md` for details.
>
> **One assay per invocation:** a canonical `pcr_assay` object passed to `detect_pcr_peaks()` must represent exactly one `assay_id` with unique `target_id` values. Multi-assay tables are rejected rather than silently combined, because the peak schema has no assay identity of its own to disambiguate them.

Legacy compatibility wrappers are still exported:

- `PCRpositive()`
- `PCRoutcome()`
- `PCRexplorer()`
- `PCRpherogram()`

Use `PCRexplorer()` and `PCRpherogram()` mainly for exploratory visualization of older workflows. Use the curated API above for auditable interpretation.

## Core Workflow

This minimal example uses the included `mosquito` data. The tutorial vignette explains each step in plain language.

```r
library(PCRprofilR)

data(mosquito)

peaks_input <- transform(
  mosquito,
  RunID = "run-1",
  PlateID = "plate-1",
  PeakID = paste0("peak-", seq_len(nrow(mosquito))),
  RawFile = "mosquito.csv",
  Instrument = "labchip"
)

usable_peak_rows <- with(
  peaks_input,
  !is.na(Size) &
    is.finite(Size) &
    Size > 0 &
    !is.na(Conc) &
    is.finite(Conc) &
    Conc >= 0 &
    !is.na(WellID) &
    nzchar(as.character(WellID)) &
    !is.na(SampleID) &
    nzchar(as.character(SampleID))
)

peaks <- as_pcr_peaks(peaks_input[usable_peak_rows, ])

assay <- as_pcr_assay(data.frame(
  assay_id = c("species-assay", "species-assay", "species-assay"),
  target_id = c("arabiensis", "gambiae", "melas"),
  expected_size_bp = c(315, 390, 464),
  lower_size_bp = c(315, 390, 464),
  upper_size_bp = c(325, 400, 474),
  min_concentration = c(0.05, 0.05, 0.05),
  confirm_concentration = c(0.2, 0.2, 0.2),
  biological_label = c("arabiensis", "gambiae", "melas"),
  rule_group = c("species", "species", "species"),
  target_role = c("optional", "optional", "optional"),
  stringsAsFactors = FALSE
))

peak_calls <- detect_pcr_peaks(peaks, assay)

# Profile rules describe which target pairs are recognized hybrid, mixed, or
# forbidden combinations. These calibration values are illustrative synthetic
# examples only, not empirically validated thresholds for any real assay.
profile_rules <- as_pcr_profile_rules(data.frame(
  assay_id = "species-assay",
  profile_id = "gambiae_arabiensis_hybrid",
  target_a = "gambiae",
  target_b = "arabiensis",
  profile_type = "hybrid",
  calibration_status = "pending", # keep "pending" until pair-specific balance is empirically calibrated
  stringsAsFactors = FALSE
))

profile_evidence <- evaluate_pcr_profiles(peak_calls, profile_rules)
sample_calls <- classify_pcr_samples(peak_calls, profile_evidence = profile_evidence)
qc <- qc_pcr_run(peaks, sample_calls)
replicate_summary <- summarize_pcr_replicates(sample_calls, qc = qc)

head(sample_calls[, c(
  "sample_id",
  "call",
  "call_state",
  "matched_targets",
  "rule_status",
  "review_required"
)])

head(qc[, c("sample_id", "control_role", "qc_status")])
```

For routine runs, write reproducible output files, including profile evidence and the canonical profile rules actually used:

```r
report_pcr_calls(
  peak_calls = peak_calls,
  sample_calls = sample_calls,
  qc = qc,
  output_dir = "pcr-results",
  format = "csv",
  write_summary = TRUE,
  profile_evidence = profile_evidence,
  profile_rules = profile_rules
)
```

## Interpretation Model

PCRprofilR does not force all results into positive or negative calls. The deterministic core keeps review states visible.

Current sample-level `call_state` values include:

- `positive`
- `negative`
- `weak_positive`
- `indeterminate_review`
- `ambiguous_review`
- `mixed_profile_candidate`
- `dual_target_unresolved_review`: two biological labels detected, but no pairwise profile rule exists for that target pair.
- `dual_target_balance_review`: a recognized hybrid rule exists but calibration is still `pending`, or peak balance cannot be evaluated (for example, a duplicated physical peak).
- `dual_target_weak_review`: a validated hybrid rule applies, but one or both targets do not meet its minimum evidence-zone requirement.
- `dual_target_imbalanced_review`: a validated hybrid rule applies and both targets are strong enough, but the observed peak-concentration balance fails the rule's tolerance.
- `hybrid_candidate`: a validated, pair-specific rule applies, both targets are sufficiently strong, and the observed balance is compatible with the calibrated expectation.

Multiple detected targets is **not** the same thing as a supported hybrid profile: `hybrid_candidate` requires an explicit, calibrated `pcr_profile_rules` entry, never label counting alone.

Peak evidence records whether a fragment is inside the target size window and whether concentration is below the analytical threshold, between analytical and confirmatory thresholds, or above the confirmatory threshold.

Assay rule groups now support explicit `target_role` values:

- `required`: the target is required for the rule group to pass.
- `optional`: the target may support a label when detected.
- `forbidden`: the target conflicts with the rule group when detected.

QC outputs include explicit control-role semantics for positive controls, negative controls, no-template controls, blanks, malformed well identifiers in the review pathway, duplicate sample identifiers, and contamination candidates.

## Strict Validation and Reviewable QC Issues

By default, canonical peak validation is strict. For example, peak size must be numeric, finite, non-missing, and strictly positive.

Some malformed inputs are better represented as QC review records rather than discarded before interpretation. For those cases, selected helpers accept `allow_qc_issues = TRUE`; currently this review pathway is intended for missing or malformed well identifiers. Numeric peak measurements such as `size_bp` and `concentration` still need valid values for strict peak interpretation.

The vignette shows how to filter ladder, calibration, blank, or non-peak instrument rows before calling `as_pcr_peaks()`.

## Project Status

Completed development stages:

- 0.2: baseline tests, validation cleanup, and R CMD check workflow.
- 0.3: canonical peak and assay object contracts.
- 0.4: peak evidence, sample calls, QC objects, and wrapper routing.
- 0.5: threshold zones, weak/ambiguous/indeterminate states, hybrid and mixed-profile candidates.
- 0.6: replicate summaries, batch helpers, exports, and provenance.
- 0.7: package check hygiene, aligned validators, explicit control roles, QC-able malformed input contract, operational rule groups, classified-object plotting, and advanced-layer deferral contract.

Stage 0.8 (pairwise profile-evidence and peak-balance interpretation) is implemented and under post-implementation audit hardening; it is recorded as completed only once all corrective gates in `.github/issues/stage-0.8/` pass. See `.github/issues/stage-0.8/02-audit-corrective-patch.md` for the current corrective work.

The current core is designed to be consumed by future operational layers. Docker/CLI wrappers, Shiny review interfaces, and Bayesian or probabilistic evidence layers are deliberately deferred and must consume the core objects, including `pcr_profile_rules` and `pcr_profile_evidence`, rather than reimplementing scientific interpretation logic.

See:

- `NEWS.md` for user-visible changes and the 0.2.0/0.3.0/0.3.1 version history.
- `vignettes/PCRprofilR.Rmd` for the source tutorial.
- `docs/project-hygiene-audit-2026-06-28.md` for the repository consistency audit.
- `docs/advanced-layer-deferral-contract-2026-06-28.md` for the handoff contract for future layers.
- `.github/issues/manifest.yaml` for the auditable staged development manifest.

## Development

Useful local checks:

```r
pkgload::load_all()
testthat::test_dir("tests/testthat")
```

For package checks in environments without `rmarkdown` or network access to install suggests, use:

```sh
R CMD build --no-build-vignettes .
_R_CHECK_FORCE_SUGGESTS_=false R CMD check --no-manual --no-build-vignettes PCRprofilR_0.3.1.tar.gz
```

The normal CI workflow installs vignette dependencies and runs package checks through GitHub Actions against R 4.1 and the current R release.
