# PCRprofilR Advanced Layer Deferral Contract

Date: 2026-06-28
Scope: Stage 0.7 deterministic-core hardening handoff.

## Purpose

PCRprofilR now has a deterministic, auditable core composed of canonical peak objects, assay specifications, peak evidence, sample calls, QC outputs, replicate summaries, exports, and classified-object plotting.

Future Docker, Shiny, and Bayesian/probabilistic work must consume these core package objects. They must not introduce separate scientific interpretation logic.

## Stable Core Consumer Contract

Future layers may consume these objects:

- `pcr_peaks`: canonical peak table, including explicit review-mode handling for QC-able well issues when requested.
- `pcr_assay`: assay target specification, including optional `target_role` values: `required`, `optional`, and `forbidden`.
- `pcr_peak_calls`: peak-level evidence table containing size deltas, target-window evidence, threshold-zone evidence, and target matches.
- `pcr_sample_calls`: sample-level deterministic calls, call states, rule status, matched targets, and review flags.
- `pcr_qc`: machine-readable QC flags, control-role outcomes, malformed-well flags, contamination candidates, and pass/review/fail status.
- `pcr_replicate_calls`: deterministic replicate summaries.
- `pcr_export_artifacts`: reproducible output artifacts with provenance.

Any future operational layer should call the same public helpers used by ordinary R workflows:

```r
peaks <- as_pcr_peaks(raw_peaks)
assay <- as_pcr_assay(raw_assay)
peak_calls <- detect_pcr_peaks(peaks, assay)
sample_calls <- classify_pcr_samples(peak_calls)
qc <- qc_pcr_run(peaks, sample_calls)
replicates <- summarize_pcr_replicates(sample_calls, qc = qc)
exports <- report_pcr_calls(peak_calls, sample_calls, qc, output_dir = "results")
```

## Deferred Layers

### Docker / CLI

Deferred status: not implemented in stage 0.7.

Future command-line or container workflows may wrap `run_pcr_batch()` or the public core helpers. They must not parse, classify, or QC PCR profiles with separate rules outside the package.

Required behavior before implementation:

- explicit input files;
- explicit output directory;
- no hidden current-working-directory assumptions;
- all scientific decisions traceable to core package outputs;
- exported evidence, calls, QC, and provenance retained.

### Shiny Review Interface

Deferred status: not implemented in stage 0.7.

Future Shiny work may provide upload, review, plotting, correction, and export workflows. It must display and annotate core objects rather than recomputing positivity, control validity, hybrid/mixed states, or QC outcomes.

Required behavior before implementation:

- all displayed calls originate from `pcr_sample_calls`;
- all QC badges originate from `pcr_qc`;
- all evidence plots consume `pcr_peak_calls` / `pcr_sample_calls` / `pcr_qc`;
- any human review override must be stored separately from deterministic core calls.

### Bayesian / Probabilistic Evidence

Deferred status: not implemented in stage 0.7.

Future probabilistic models may estimate posterior evidence for biological states, technical uncertainty, dropout/drop-in, run effects, or replicate uncertainty. They must consume deterministic evidence objects and calibration data; they must not parse raw files directly.

Required behavior before implementation:

- deterministic core remains the auditable baseline;
- probabilistic outputs are complementary evidence, not silent replacements;
- posterior decisions retain links to observed peaks, assay targets, deterministic calls, QC flags, and replicate metadata;
- biological-state pooling must be explicit and must not erase rare states such as hybrids by accident.

## Stage 0.7 Handoff

Stage 0.7 closes with the advanced layers deferred behind these contracts.

The next agent should open new stage issues only after deciding which layer is being pursued:

- Docker/CLI operational wrapper;
- Shiny review prototype;
- Bayesian design/calibration plan;
- workflow/vignette documentation pass.

Each future issue must state which core objects it consumes and must include tests proving that scientific interpretation remains delegated to the package core.
