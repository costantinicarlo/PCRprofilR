# PCRprofilR Project Hygiene Audit

Date: 2026-06-28
Scope: Repository consistency after stage 0.7 and the public API documentation split.

## Audit Coverage

This audit checked consistency across:

- package metadata (`DESCRIPTION`, `NAMESPACE`, package-level Rd);
- README, NEWS, vignette source, and installed vignette artifacts;
- exported public API and individual help topics;
- standalone examples and test coverage;
- staged issue manifest and advanced-layer deferral documentation;
- package build/check hygiene.

## Current Status

The repository is consistent with a completed stage-0.7 deterministic core:

- curated public helpers are exported and documented as individual help topics;
- the tutorial vignette is available through `vignette("PCRprofilR", package = "PCRprofilR")`;
- installed vignette HTML is rendered from a package-installed context and does not contain captured package-load or data-load errors;
- README, vignette, and example script now describe the same canonical workflow shape;
- advanced Docker/CLI, Shiny, and Bayesian layers remain deferred behind the stable core contract.

## Corrections Applied

- Corrected README logo alternate text from an unrelated project name to `PCRprofilR logo`.
- Corrected package metadata wording for the title and capillary electrophoresis description.
- Updated `examples/example-script.R` to include explicit `target_role`, replicate summary, and current sample/QC output columns.
- Added the missing `R CMD build --no-build-vignettes .` step before the README package-check command.

## Historical Documents

`docs/architecture-audit-2026-06-27.md` is retained as a historical stage-0.6 architecture audit. Current post-stage-0.7 handoff constraints are documented in `docs/advanced-layer-deferral-contract-2026-06-28.md`.

## Verification

Expected verification commands:

```sh
R CMD build --no-build-vignettes .
_R_CHECK_FORCE_SUGGESTS_=false R CMD check --no-manual --no-build-vignettes PCRprofilR_0.2.0.tar.gz
```

Expected R-level checks:

```r
pkgload::load_all()
testthat::test_dir("tests/testthat")
```
