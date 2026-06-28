# PCRprofilR

## Introduction

PCRprofilR provides deterministic and auditable interpretation of PCR fragment profiles from capillary electrophoresis outputs.

The package now includes:

- legacy wrapper functions for established workflows
- canonical internal objects for peaks, assay specs, evidence, sample calls, and QC
- multi-state deterministic interpretation (not only binary positive/negative)
- replicate summaries
- batch and export helpers with provenance fields

## Installation

PCRprofilR is currently distributed from GitHub.

```r
install.packages("devtools")
devtools::install_github("costantinicarlo/PCRprofilR")
```

## Public API (current)

Legacy compatibility wrappers remain available:

- PCRpositive
- PCRoutcome
- PCRexplorer
- PCRpherogram

Curated 1.0-facing API:

- as_pcr_peaks
- as_pcr_assay
- validate_pcr_peaks
- validate_pcr_assay
- detect_pcr_peaks
- classify_pcr_samples
- qc_pcr_run
- summarize_pcr_replicates
- run_pcr_batch
- report_pcr_calls

## Deterministic Core Workflow

```r
library(PCRprofilR)

data(mosquito)

# Build canonical-like input from legacy columns for a reproducible example.
peaks_input <- transform(
	mosquito,
	RunID = "run-1",
	PlateID = "plate-1",
	PeakID = paste0("peak-", seq_len(nrow(mosquito))),
	RawFile = "mosquito.csv",
	Instrument = "labchip"
)

peaks <- as_pcr_peaks(peaks_input)

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
	stringsAsFactors = FALSE
))

peak_calls <- detect_pcr_peaks(peaks, assay)
sample_calls <- classify_pcr_samples(peak_calls)
qc <- qc_pcr_run(peaks, sample_calls)

head(sample_calls[, c("sample_id", "call", "call_state", "threshold_status")])
head(qc[, c("sample_id", "qc_status", "contamination_candidate")])
```

## Multi-State Calls

Current sample-level call_state values include:

- positive
- negative
- weak_positive
- indeterminate_review
- ambiguous_review
- hybrid_candidate
- mixed_profile_candidate

This keeps uncertain profiles explicit and reviewable instead of forcing binary outcomes.

## Batch and Export Helpers

Use run_pcr_batch for file-driven orchestration and report_pcr_calls for reproducible exports with provenance metadata.

```r
# batch_out <- run_pcr_batch("peaks.csv", "assay.csv", "out/")
# report_out <- report_pcr_calls(
#   batch_out$peak_calls,
#   batch_out$sample_calls,
#   batch_out$qc,
#   output_dir = "out/reports",
#   format = "csv"
# )
```

## Lifecycle

PCRprofilR is pre-1.0 and developed in staged increments.

Stages completed so far:

- 0.2: baseline tests, validation cleanup, CI stabilization
- 0.3: canonical peak and assay object contracts
- 0.4: evidence tables, sample calls, QC objects
- 0.5: deterministic multi-state interpretation rules
- 0.6: replicate summaries and batch/export helper layer

See NEWS.md for user-visible changes and docs/architecture-audit-2026-06-27.md for architecture status.
