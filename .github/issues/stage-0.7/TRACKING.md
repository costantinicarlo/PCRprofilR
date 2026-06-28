# Stage 0.7.x Tracking: Deterministic Core Hardening Before Deployment Layers

Goal: harden the completed deterministic core so it is ready to support future Docker, Shiny, and optional Bayesian layers without moving scientific logic out of the package.

Checklist:
- [ ] 01-packaging-check-hygiene.md
- [ ] 02-align-assay-validator-constructor.md
- [ ] 03-explicit-control-roles-qc.md
- [ ] 04-qc-able-malformed-input-contract.md
- [ ] 05-operational-rule-group-engine.md
- [ ] 06-plots-consume-classified-objects.md
- [ ] 07-defer-advanced-layers-contract.md

Stage completion gates:
- [ ] Package build/check hygiene issues are resolved or intentionally documented
- [ ] Exported validators and constructors expose consistent contracts
- [ ] Control roles and QC expectations are explicit and tested
- [ ] Malformed input handling distinguishes strict object validation from QC-able review data
- [ ] `rule_group` has documented deterministic semantics
- [ ] Plotting workflows consume core evidence/call/QC objects where new behavior is introduced
- [ ] Docker, Shiny, and Bayesian work remain deferred behind stable core contracts
