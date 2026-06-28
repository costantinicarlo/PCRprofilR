# PCRprofilR Programmatic Issue Backlog

This folder contains a staged, agent-executable issue set aligned with the roadmap and commit-gate policy.

Machine-readable orchestration file:
- .github/issues/manifest.yaml

How to use:
1. Open one issue file at a time.
2. Copy contents into a GitHub issue using the refactor-step template.
3. Label with stage and layer.
4. Implement only in-scope work.
5. Commit only when commit gates pass.

Programmatic execution:
1. Parse .github/issues/manifest.yaml.
2. Select the first `open` issue whose dependencies are all `closed`.
3. If no issue is available, evaluate stage completion gates and advance to the next stage.
4. Update issue `status` and stage `status` in the manifest as work progresses.

Execution order:
1. stage-0.2/TRACKING.md
2. stage-0.3/TRACKING.md
3. stage-0.4/TRACKING.md
4. stage-0.5/TRACKING.md
5. stage-0.6/TRACKING.md

Core policy references:
- .github/copilot-instructions.md
- .github/implementation-version-control-strategy.md
- .github/agent-commit-stage-prompt.md
- .github/ISSUE_TEMPLATE/refactor-step.md
