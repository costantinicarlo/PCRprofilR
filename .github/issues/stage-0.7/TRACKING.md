# Stage 0.7.x Tracking: Deterministic Core Hardening Before Deployment Layers

Goal: harden the completed deterministic core so it is ready to support future Docker, Shiny, and optional Bayesian layers without moving scientific logic out of the package.

Checklist:
- [x] 01-packaging-check-hygiene.md
- [x] 02-align-assay-validator-constructor.md
- [x] 03-explicit-control-roles-qc.md
- [x] 04-qc-able-malformed-input-contract.md
- [x] 05-operational-rule-group-engine.md
- [x] 06-plots-consume-classified-objects.md
- [x] 07-defer-advanced-layers-contract.md

Stage completion gates:
- [x] Package build/check hygiene issues are resolved or intentionally documented
- [x] Exported validators and constructors expose consistent contracts
- [x] Control roles and QC expectations are explicit and tested
- [x] Malformed input handling distinguishes strict object validation from QC-able review data
- [x] `rule_group` has documented deterministic semantics
- [x] Plotting workflows consume core evidence/call/QC objects where new behavior is introduced
- [x] Docker, Shiny, and Bayesian work remain deferred behind stable core contracts
