# Stage 0.8.x Tracking: Pairwise Profile Evidence and Peak-Balance Interpretation

Goal: replace the unconditional "two matched biological labels -> `hybrid_candidate`" rule with a deterministic, auditable, calibratable pairwise profile-evidence layer, so dual-target calls (hybrid, mixed, forbidden) are backed by explicit rules and continuous peak-balance evidence rather than label counting alone.

Checklist:
- [x] 01-pairwise-profile-evidence-peak-balance.md
- [x] 02-audit-corrective-patch.md (implemented on `fix/stage-0.8-audit-v0.3.1`, pending review/merge)

Stage completion gates:
- [x] `pcr_profile_rules` canonical object exists with constructor/validator and rejects invalid/duplicate/unordered rule definitions
- [x] `pcr_profile_evidence` canonical object exists via `evaluate_pcr_profiles()`, consuming `pcr_peak_calls` + `pcr_profile_rules`
- [x] Representative-peak selection is deterministic and independent of the eventual balance outcome
- [x] Same physical peak cannot be double-counted as two distinct target matches without being flagged non-evaluable
- [x] Sample-level dual-target states (`hybrid_candidate`, `dual_target_unresolved_review`, `dual_target_weak_review`, `dual_target_imbalanced_review`, `dual_target_balance_review`, `mixed_profile_candidate`, `ambiguous_review`) are implemented and tested
- [x] `call` vs `call_state` distinction preserved for dual-target review states
- [x] QC (`pcr_qc()`/`qc_pcr_run()`) unchanged in scientific logic; only consumes resulting `call_state`
- [x] Replicate layer updated to include new review states in `review_replicates`
- [x] Backward-compatible wrappers (`PCRpositive()`, `PCRoutcome()`, `PCRexplorer()`, `PCRpherogram()`) remain usable
- [x] NEWS entry documents the removal of the unconditional two-label hybrid rule
- [ ] Post-merge audit corrective patch (assay-safety, fail-closed hybrid gating, provenance completeness, documentation/security hardening) merged and tested; see `02-audit-corrective-patch.md` (implemented and locally tested on `fix/stage-0.8-audit-v0.3.1`; awaiting review and merge before this gate and the stage are marked complete)
