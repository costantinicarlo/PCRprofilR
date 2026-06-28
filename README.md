<p align="center">
  <img src="assets/PCRprofilR_logo_hex.png"
       alt="panpreposterous logo"
       width="420">
</p>

# PCRprofilR

PCRprofilR is an R package for deterministic, auditable interpretation of PCR fragment profiles from capillary electrophoresis outputs.

The current development version focuses on a stable interpretation core: raw fragment peaks are normalized, compared with an explicit assay specification, converted into peak-level evidence, summarized into sample calls, checked by QC rules, and exported with provenance.

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
- `validate_pcr_peaks()` and `validate_pcr_assay()`: check canonical object contracts.
- `detect_pcr_peaks()`: compare observed peaks with assay targets and create peak evidence.
- `classify_pcr_samples()`: summarize peak evidence into sample-level calls.
- `qc_pcr_run()`: create machine-readable QC flags.
- `plot_pcr_evidence()`: plot already-classified evidence without recomputing calls.
- `summarize_pcr_replicates()`: summarize repeated tests.
- `run_pcr_batch()`: run the deterministic workflow from input files.
- `report_pcr_calls()`: export evidence, calls, QC, summary files, and provenance.

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
sample_calls <- classify_pcr_samples(peak_calls)
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

For routine runs, write reproducible output files:

```r
report_pcr_calls(
  peak_calls = peak_calls,
  sample_calls = sample_calls,
  qc = qc,
  output_dir = "pcr-results",
  format = "csv",
  write_summary = TRUE
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
- `hybrid_candidate`
- `mixed_profile_candidate`

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

The current core is designed to be consumed by future operational layers. Docker/CLI wrappers, Shiny review interfaces, and Bayesian or probabilistic evidence layers are deliberately deferred and must consume the core objects rather than reimplementing scientific interpretation logic.

See:

- `NEWS.md` for user-visible changes.
- `vignettes/PCRprofilR.Rmd` for the source tutorial.
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
_R_CHECK_FORCE_SUGGESTS_=false R CMD check --no-manual --no-build-vignettes PCRprofilR_0.2.0.tar.gz
```

The normal CI workflow installs vignette dependencies and runs package checks through GitHub Actions.
