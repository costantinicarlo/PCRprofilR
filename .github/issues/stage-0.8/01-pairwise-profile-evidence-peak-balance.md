---
name: Refactor Step
description: Plan and track one small, reviewable PCRprofilR refactor increment
title: "[Refactor] Pairwise profile evidence and peak-balance interpretation"
labels: ["refactor", "architecture", "stage-0.8"]
assignees: []
---

## Goal
Introduce a deterministic **profile-level interpretation layer** (`pcr_profile_rules` / `pcr_profile_evidence`) that sits between peak-level evidence and sample-level calls, so that dual-target profiles (in particular putative hybrids) are classified using pairwise, target-specific, calibratable peak-balance evidence instead of the current "two matched labels -> `hybrid_candidate`" shortcut.

## Why This Step
Field application of PCRprofilR produced an implausibly high rate of `hybrid_candidate` calls. Root-cause analysis (see `PCRprofilR hybrid candidate review.md`) identified that:
- `matched` at peak level only requires the analytical threshold, not the confirmatory threshold;
- sample-level hybrid logic only checks `Nmatched == 2 && Nlabels == 2`, with no comparison between the two concentrations;
- the target summarization collapses each target to `target_matched`/`target_best_zone` and discards the representative peak concentration needed for any pairwise comparison.

As a result, a sample with concentrations 8.0 and 0.08 is currently indistinguishable from one with 4.0 and 3.5. A scale-free, pair-specific, empirically calibrated balance criterion is required, but it must not be a hard-coded universal fold-change cutoff, and it must not be folded into `pcr_qc()` (balance is profile-level scientific evidence, not run/control QC).

This step is the next architectural increment after stage-0.7 hardened the deterministic core (control roles, QC contracts, rule-group engine, plotting) and explicitly deferred advanced layers behind stable core contracts.

## Scope
- In scope:
  - New canonical pairwise rule object `pcr_profile_rules` with constructor/validator (`as_pcr_profile_rules()`, `validate_pcr_profile_rules()`), scoped per `assay_id`/`profile_id`/ordered `target_a`,`target_b` pair.
  - New canonical `pcr_profile_evidence` object and public `evaluate_pcr_profiles()`, consuming `pcr_peak_calls` + `pcr_profile_rules`.
  - Deterministic representative-peak selection per matched target (smallest size deviation -> highest concentration -> `peak_id` tie-break), without discarding original peak-level evidence.
  - Continuous balance metrics: `observed_log2_ratio`, `raw_balance_ratio`, `fold_imbalance`, and (when a validated rule exists) `expected_log2_ratio`, `abs_log2_deviation`, `balance_score`, `balance_status`.
  - Guard against the same physical `peak_id` becoming the representative peak for two different targets (flag as non-evaluable, not as a genuine dual-band profile).
  - Revised sample-level dual-target states: `hybrid_candidate`, `dual_target_unresolved_review`, `dual_target_weak_review`, `dual_target_imbalanced_review`, `dual_target_balance_review`, `mixed_profile_candidate`, `ambiguous_review`, replacing the current unconditional `two labels -> hybrid_candidate` rule.
  - Preserving the existing `call` vs `call_state` distinction so imbalanced/pending dual-target profiles remain `call = positive` rather than collapsing to `negative`.
  - Minimal replicate-layer updates so new review states are correctly included in `review_replicates` and are not treated as concordant positives.
  - testthat coverage for boundary, overlapping-window, non-evaluable, and calibration-status scenarios.
- Out of scope:
  - Any Bayesian/probabilistic modeling of profile evidence.
  - Empirical calibration of real `expected_log2_ratio` / `max_abs_log2_deviation` values for any specific target pair (this issue ships the mechanism and rule schema only; calibration is a separate, data-driven follow-up).
  - Docker, Shiny, or CLI/batch UI work.
  - Rewriting `pcr_qc()` to consume or recompute balance evidence.
  - Any change to `master` outside a dedicated feature branch; no tagging or release.

## Current Behavior
- `pcr_peak_calls` marks a target `matched` once size falls within the assay window and concentration exceeds only the analytical threshold; the confirmatory threshold only affects `evidence_zone`.
- `pcr_sample_calls` reduces target-level evidence with `any(matched)`-style logic, calls `hybrid_candidate` whenever exactly two matched targets belong to two distinct biological labels, and does not retain or compare representative peak concentrations.
- `pcr_qc()` runs after sample calls and does not revise `call_state`; peak-balance is not evaluated anywhere in the pipeline.

## Proposed Change
Extend the deterministic flow from:
```text
raw peaks -> pcr_peaks -> pcr_assay -> pcr_peak_calls -> pcr_sample_calls -> pcr_qc -> replicate/export layers
```
to:
```text
raw peaks -> pcr_peaks -> pcr_assay -> pcr_peak_calls -> pcr_profile_evidence -> pcr_sample_calls -> pcr_qc -> replicate/export layers
```
with `pcr_profile_rules` as a new versioned, assay-scoped pairwise specification consumed by `pcr_profile_evidence`. Sample-level interpretation consumes profile evidence instead of re-deriving hybrid logic from raw label counts. QC continues to consume the resulting `call_state` without redefining it.

## Affected Layers
Check all that apply:
- [ ] Import and normalization
- [ ] Assay specification
- [x] Peak-level detection/evidence
- [x] Sample-level interpretation
- [ ] QC flags/evaluation
- [ ] Visualization/reporting
- [ ] Backward-compatibility wrappers

## Data Objects Impacted
Check all that apply:
- [x] pcr_peaks
- [x] pcr_assay
- [x] pcr_peak_calls
- [x] pcr_sample_calls
- [ ] pcr_qc
- [ ] None

New objects introduced: `pcr_profile_rules`, `pcr_profile_evidence`.

## Backward Compatibility
- [x] Existing user-facing functions remain usable (or changes are explicitly documented)
- [x] Behavior change is intentional and documented
- [x] Migration note is included if needed

Details:
`PCRpositive()`, `PCRoutcome()`, `PCRexplorer()`, `PCRpherogram()` must continue to work. Any assay without an explicit `pcr_profile_rules` entry for a detected target pair must resolve to `dual_target_unresolved_review`, not silently fall back to the old unconditional `hybrid_candidate` behavior. This is an intentional, documented behavior change from the current permissive hybrid rule and must be called out in `NEWS.md`.

## Validation and Error Handling
- [x] Inputs validated explicitly
- [x] Errors are clear and actionable
- [x] No hidden cwd/global-state dependencies introduced

`pcr_profile_rules` validation must reject early and clearly: `target_a == target_b`; validated rules missing `expected_log2_ratio` or `max_abs_log2_deviation`; negative `max_abs_log2_deviation`; unknown evidence-zone values; duplicate rules for the same unordered target pair within an assay/profile context.

## QC and Evidence Retention
- [x] Outputs remain machine-readable
- [x] Evidence is retained (size, concentration, thresholds, matched target, call, flags)
- [x] Ambiguous/weak cases are preserved and flagged, not forced binary

All continuous balance metrics (log2 ratio, deviation, balance score, fold imbalance) must be exported even when the deterministic outcome collapses to a status enum, to support future recalibration and the planned Bayesian evidence layer.

## Tests
- [x] Existing behavior frozen where required
- [x] New behavior covered with focused testthat tests
- [x] Edge cases included (threshold boundaries, malformed input, multi-target/ambiguous cases)

Test files:
- New `tests/testthat/test-pcr-profile-rules.R` (constructor/validator contract, duplicate/invalid rule rejection)
- New `tests/testthat/test-pcr-profile-evidence.R` (representative peak selection, balance metrics, overlapping-window guard, non-evaluable concentrations)
- Updated sample-calls tests covering `hybrid_candidate`, `dual_target_unresolved_review`, `dual_target_weak_review`, `dual_target_imbalanced_review`, `dual_target_balance_review`, `mixed_profile_candidate`, `ambiguous_review`

## Documentation
- [x] Roxygen/help text updated if needed
- [x] README/vignette updates included if user-facing behavior changed
- [x] NEWS entry added if appropriate

Details:
Add `man/as_pcr_profile_rules.Rd`, `man/validate_pcr_profile_rules.Rd`, `man/evaluate_pcr_profiles.Rd`. Document the removal of the unconditional two-label hybrid rule in `NEWS.md` and, if applicable, the vignette.

## CI Status
- [ ] Local checks pass
- [ ] CI expected to pass

## Risk Assessment
Medium: this changes real-world sample classification outcomes for dual-target profiles (previously called `hybrid_candidate`, many will now resolve to `dual_target_unresolved_review` or `dual_target_imbalanced_review` pending calibrated rules). Mitigated by keeping `call = positive` for these review states, retaining full continuous evidence, and requiring an explicit, versioned `pcr_profile_rules` entry before any `hybrid_candidate` can be produced again.

## Definition of Done
- [ ] Small, reviewable PR
- [ ] Tests included
- [ ] Return types explicit and stable
- [ ] Compatibility impact documented
- [ ] No unrelated refactors bundled

## Follow-up Items
- Empirical calibration of `expected_log2_ratio` / `max_abs_log2_deviation` per validated target pair, from retrospective and confirmed-hybrid data (stage-0.9+).
- Replicate-aware profile-balance concordance summaries beyond the minimal review-state bookkeeping added here.
- Optional Bayesian evidence layer consuming the continuous balance metrics preserved in `pcr_profile_evidence`.
