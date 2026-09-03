# Stage 0.8.x Tracking: Pairwise Profile Evidence and Peak-Balance Interpretation

Goal: replace the unconditional "two matched biological labels -> `hybrid_candidate`" rule with a deterministic, auditable, calibratable pairwise profile-evidence layer, so dual-target calls (hybrid, mixed, forbidden) are backed by explicit rules and continuous peak-balance evidence rather than label counting alone.

Checklist:
- [ ] 01-pairwise-profile-evidence-peak-balance.md

Stage completion gates:
- [ ] `pcr_profile_rules` canonical object exists with constructor/validator and rejects invalid/duplicate/unordered rule definitions
- [ ] `pcr_profile_evidence` canonical object exists via `evaluate_pcr_profiles()`, consuming `pcr_peak_calls` + `pcr_profile_rules`
- [ ] Representative-peak selection is deterministic and independent of the eventual balance outcome
- [ ] Same physical peak cannot be double-counted as two distinct target matches without being flagged non-evaluable
- [ ] Sample-level dual-target states (`hybrid_candidate`, `dual_target_unresolved_review`, `dual_target_weak_review`, `dual_target_imbalanced_review`, `dual_target_balance_review`, `mixed_profile_candidate`, `ambiguous_review`) are implemented and tested
- [ ] `call` vs `call_state` distinction preserved for dual-target review states
- [ ] QC (`pcr_qc()`/`qc_pcr_run()`) unchanged in scientific logic; only consumes resulting `call_state`
- [ ] Replicate layer updated to include new review states in `review_replicates`
- [ ] Backward-compatible wrappers (`PCRpositive()`, `PCRoutcome()`, `PCRexplorer()`, `PCRpherogram()`) remain usable
- [ ] NEWS entry documents the removal of the unconditional two-label hybrid rule
