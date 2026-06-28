# PCRprofilR News

## 0.2.0 (development)

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
