# PCRprofilR Architecture Audit

Date: 2026-06-28
Scope: Post-implementation audit after completion through stage-0.6.

## 1. Executive status

The architecture plan is implemented through stage-0.6, with deterministic core layers, machine-readable QC, wrapper routing, replicate summaries, batch orchestration helpers, and export/provenance helpers all present and tested.

Stage status summary (from manifest):

- stage-0.2: completed
- stage-0.3: completed
- stage-0.4: completed
- stage-0.5: completed
- stage-0.6: completed

## 2. Current implemented architecture

Implemented deterministic pipeline:

raw input -> normalize_pcr_peaks() -> pcr_peaks() -> pcr_assay() -> pcr_peak_calls() -> pcr_sample_calls() -> pcr_qc() -> pcr_replicate_summary() / pcr_batch_run() / pcr_export_artifacts()

Canonical object/functions currently present:

- pcr_peaks / validate_pcr_peaks
- pcr_assay / validate_pcr_assay
- normalize_pcr_peaks
- pcr_peak_calls
- pcr_sample_calls
- pcr_qc
- pcr_replicate_summary
- pcr_batch_run
- pcr_export_artifacts

Legacy compatibility wrappers retained and usable:

- PCRpositive
- PCRoutcome
- PCRexplorer
- PCRpherogram

## 3. What changed versus the prior audit

Previously identified gaps that are now closed:

- test suite absent -> comprehensive testthat suite now present
- CI absent -> GitHub Actions R CMD check workflow present
- duplicated/uneven validation -> shared validation helpers in place
- no canonical object model -> implemented
- no peak/sample/QC evidence tables -> implemented
- binary-only classification -> three-zone evidence and richer review states implemented
- no replicate-aware consolidation -> implemented
- no batch/export layer -> implemented with deterministic file contracts and provenance

## 4. Deterministic interpretation model (current)

Evidence zones:

- below_analytical
- analytical_to_confirmatory
- above_confirmatory

Sample call-state taxonomy now includes:

- positive
- negative
- weak_positive
- indeterminate_review
- ambiguous_review
- hybrid_candidate
- mixed_profile_candidate

QC state flags now include (non-exhaustive):

- has_missing_well_id
- duplicate_sample_id_in_run
- control_sample
- weak_positive_state
- ambiguous_call_state
- indeterminate_call_state
- contamination_candidate

## 5. Wrapper compatibility status

Compatibility wrappers are still the exported surface and continue to return legacy-style outputs.

Notable behavior-preserving design detail:

- PCRpositive now routes through canonical internals but pre-filters invalid legacy rows (for example, non-positive or missing Size/Conc) to avoid breaking existing usage patterns.

## 6. Quality gates and verification status

Implemented quality infrastructure:

- broad testthat coverage across legacy wrappers and new internals/helpers
- CI workflow for package checks
- stage manifest and tracking files enforcing sequential completion and gate discipline

Current known warning debt (non-blocking):

- ggplot2 aes_string deprecation warnings in PCRexplorer/PCRpherogram tests

No architecture blockers were identified for completion through stage-0.6.

## 7. Architecture fitness assessment

Assessment: fit-for-purpose for deterministic, auditable PCR interpretation workflows.

Strengths:

- clear layered separation from normalization to evidence, calls, QC, and operational outputs
- machine-readable outputs enabling auditability and downstream automation
- additive helper layer for batch and exports without duplicating scientific rules
- retained backward compatibility at wrapper level

Residual risks:

- plotting layer still carries deprecated ggplot idioms
- internal function naming diverges from earlier 1.0.0 candidate names (for example, pcr_peaks vs as_pcr_peaks); API curation still needed before 1.0.0 freeze
- contamination/hybrid/mixed logic is deterministic and rule-based; domain calibration/validation may still evolve

## 8. Recommended next architecture work (post-0.6)

Priority 1:

- plot layer modernization: replace aes_string usage and remove warning debt

Priority 2:

- public API curation: decide which canonical functions become exported and stabilize naming/contracts for 1.0.0

Priority 3:

- operational packaging: optional CLI/Docker wrapper standardization on pcr_batch_run/pcr_export_artifacts contracts

Priority 4 (optional, later):

- Bayesian extension as complementary evidence layer consuming stable deterministic objects

## 9. Audit conclusion

The staged architecture plan is implemented through stage-0.6 and materially achieves the original deterministic evidence/QC objectives.

The project has transitioned from a wrapper-centric binary classifier to a layered, test-backed, auditable interpretation engine with reusable operational helpers, while preserving backward-compatible user-facing wrappers.
