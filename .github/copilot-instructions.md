# PCRprofilR Operational Implementation Instructions

## Mission
Evolve PCRprofilR incrementally from its current deterministic threshold/window implementation to a robust, auditable interpretation engine for PCR fragment profiles, targeting a stable 1.0.0 API.

Work in small, reviewable changes. Do not do large rewrites.

## First Rule: Audit Before Refactor
Before major implementation:
1. Inspect current structure and exported API.
2. Identify assumptions and failure risks.
3. Propose a staged plan.
4. Start with minimal changes that preserve behavior.

## Core Architecture Target
Build and use explicit layers:
1. Import and normalization.
2. Assay specification.
3. Peak-level detection and evidence.
4. Sample-level interpretation.
5. QC evaluation.
6. Visualization/reporting consuming classified outputs.

Target data flow:
raw peaks -> canonical peaks -> assay spec -> peak evidence -> sample calls -> QC flags -> reports/plots

## Canonical Internal Objects
Prefer stable tibble-like outputs (optionally light S3):
- pcr_peaks
- pcr_assay
- pcr_peak_calls
- pcr_sample_calls
- pcr_qc

Use stable return types. Avoid NULL/character special cases when tables can represent empty results.

## Scientific Calling Principles
Do not keep a binary-only mindset.
Design for:
- negative
- positive
- weak positive
- indeterminate/review
- invalid sample
- invalid run
- contamination candidate
- mixed profile
- hybrid candidate

Support threshold zones:
- below analytical threshold
- analytical-to-confirmatory zone
- above confirmatory threshold

Every final call must remain evidence-backed and auditable.

## QC Is Mandatory
QC must be machine-readable and explicit, not console-only warnings.
Include run/sample/control validity and ambiguity-related flags.

## Backward Compatibility
Keep existing user-facing functions working where feasible:
- PCRpositive()
- PCRoutcome()
- PCRexplorer()
- PCRpherogram()

Refactor internals first, route wrappers to new internals gradually, and document behavior changes.

## Implementation Priorities
1. Freeze existing behavior with tests.
2. Improve validation and error messages.
3. Introduce canonical peak object.
4. Introduce validated assay specification.
5. Add peak-level evidence outputs.
6. Add sample-level calls + QC flags.
7. Expand rule engine for weak/ambiguous/hybrid/mixed logic.
8. Refactor plotting to consume classified objects (no duplicate scientific logic).

## Testing and CI Expectations
- Add focused testthat cases for current and new behavior.
- Cover threshold boundaries, malformed inputs, multiple targets, and ambiguous scenarios.
- Keep tests readable and deterministic.
- Keep CI green; avoid merging behavior changes without tests.

## Scope Guardrails
Do:
- preserve scientific meaning
- preserve information and flag uncertainty
- use explicit structures and clear terminology

Do not:
- force ambiguous samples into binary calls
- hard-code assay-specific biology into core architecture
- hide logic in plotting/UI code
- introduce hidden global state or cwd-dependent behavior

## Deployment and UI Strategy
Design now for future use by:
- standard R scripts
- batch/CLI workflows
- Docker wrappers
- Shiny review tools

But do not implement Docker/Shiny/Bayesian first.
Core deterministic evidence architecture comes first.

## Bayesian Layer Policy
Bayesian/probabilistic modeling is optional and later.
Only begin after deterministic objects, QC, and evidence tables are stable.
Treat Bayesian outputs as complementary evidence, not a replacement for deterministic baseline calls.

## Definition of Done for Each PR
A change is done when:
1. Scope is small and reviewable.
2. Tests cover the changed behavior.
3. Return objects and errors are explicit.
4. Backward compatibility impact is documented.
5. No unrelated refactors are bundled.
