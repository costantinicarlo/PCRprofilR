# PCRprofilR Architecture Audit and Staged Plan

Date: 2026-06-27

## 1. Current package structure

- Public functions are implemented in `R/` with one function per file.
- Current exports: `PCRpositive()`, `PCRoutcome()`, `PCRexplorer()`, `PCRpherogram()`.
- Internal helper: `inside.range()`.
- Single bundled dataset: `mosquito`.
- No test suite currently present.
- No CI workflows currently present.

## 2. Current exported functions

- `PCRpositive(dat, target_size, tolerance, threshold)`
  - Detects samples with at least one fragment in size window and above concentration threshold.
  - Returns sorted unique character vector of `SampleID` or `NULL` when none.
- `PCRoutcome(dat, targets, tolerance, threshold)`
  - Applies `PCRpositive()` over named targets and joins back to unique `WellID`/`SampleID` rows.
  - Returns data frame with one row per sample and optional `Outcome` label.
- `PCRexplorer(...)`
  - Plots size/concentration scatter with optional target windows and guides.
- `PCRpherogram(...)`
  - Plots per-well bar-style fragment profiles and highlights current positive logic.

## 3. Current assumptions

- Required input columns are hard-coded (`WellID`, `SampleID`, `Size`, `Conc`).
- Input validation uses `stopifnot()` checks directly in each function.
- Classification is threshold-window based with no weak zone and no explicit QC layer.
- Multi-target interpretation in `PCRoutcome()` is only label assignment by target hits.
- Plot functions depend on input schema and may include implicit interpretation logic.

## 4. Risks in present implementation

- Return type instability: `PCRpositive()` returns character vector or `NULL`.
- Validation logic is duplicated and uneven across functions.
- No formal object model for peak evidence, sample calls, or QC flags.
- No machine-readable QC outputs (controls, contamination, invalid runs/samples).
- No tests to freeze behavior before refactoring.
- No CI safety net for incremental architecture changes.
- Future deployment paths (CLI/Docker/Shiny) would currently duplicate logic unless core is modularized.

## 5. Proposed internal object model

Introduce stable tibble-first objects (light S3 optional):

- `pcr_peaks`: canonical normalized peak table.
- `pcr_assay`: validated assay specification.
- `pcr_peak_calls`: evidence-level target matching.
- `pcr_sample_calls`: sample-level interpreted calls.
- `pcr_qc`: run/plate/sample QC flags and statuses.

Core deterministic pipeline:

raw input -> pcr_peaks -> pcr_assay -> pcr_peak_calls -> pcr_sample_calls -> pcr_qc -> reporting/plots

## 6. Proposed public API for 1.0.0

Core API candidates:

- `as_pcr_peaks()` / `validate_pcr_peaks()`
- `as_pcr_assay()` / `validate_pcr_assay()`
- `detect_pcr_peaks()`
- `classify_pcr_samples()`
- `qc_pcr_run()`
- `report_pcr_calls()`

Compatibility wrappers retained:

- `PCRpositive()`
- `PCRoutcome()`
- `PCRexplorer()`
- `PCRpherogram()`

Wrappers should call core pipeline internals and preserve documented behavior where possible.

## 7. Deterministic algorithm and limitations

Current deterministic rule:

- positive if `Conc >= threshold` and `Size` in `[target - left_tol, target + right_tol]`.

Known limitations:

- no weak/indeterminate zone;
- no explicit ambiguity classes;
- no formal hybrid/mixed profile logic;
- no control-aware invalid run/sample states;
- no replicate-aware consolidation.

## 8. Bayesian extension fit

Bayesian layer should be optional and consume core structured outputs:

- inputs: `pcr_peaks`, `pcr_assay`, `pcr_peak_calls`, `pcr_sample_calls`, `pcr_qc`, replicate metadata.
- outputs: posterior probabilities for biological states and uncertainty decomposition.

Precondition: deterministic evidence/QC objects must be stable first.

## 9. Deployment architecture fit (batch/container/shiny)

- CLI/Docker and Shiny should call exactly the same core API.
- No scientific interpretation logic should live in deployment/UI code.
- Core functions should be deterministic, explicit-input/explicit-output, and side-effect minimal.

## 10. Staged issue/PR plan

### PR 1 (current): stabilization baseline

- Add architecture audit document.
- Add `testthat` infrastructure.
- Add tests that freeze current `PCRpositive()` behavior.

### PR 2: validation consolidation

- Add shared internal validators for input schema and numeric argument checks.
- Replace duplicated `stopifnot()` blocks with consistent error messages.

### PR 3: canonical object foundations

- Add `as_pcr_peaks()` and `as_pcr_assay()` constructors/validators.
- Add unit tests for schema mapping and validation failures.

### PR 4: evidence and calls

- Add `detect_pcr_peaks()` and `classify_pcr_samples()` returning stable tibbles.
- Introduce weak/indeterminate/positive deterministic zones.

### PR 5: QC framework

- Add `qc_pcr_run()` with machine-readable flags.
- Add controls and invalid-state handling.

### PR 6: wrapper migration and plotting alignment

- Route legacy wrappers through new core functions.
- Ensure plotting consumes classified/evidence objects and does not recompute scientific logic.

### PR 7+: deployment and optional Bayesian roadmap

- Batch export/report helpers.
- CLI/Docker wrapper over core API.
- Shiny review prototype over core API.
- Optional Bayesian module after deterministic objects and QC are stable.
