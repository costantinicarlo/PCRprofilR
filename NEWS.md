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
