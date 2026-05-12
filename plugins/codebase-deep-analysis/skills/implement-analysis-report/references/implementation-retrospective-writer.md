# Implementation retrospective writer (Step 5)

After Step 4 (or Step 3 if no showstoppers), iar writes an implementation retrospective bundle under:

`{report-dir}/retrospective/implementation/session-{NN}/`

The old single-file append model no longer exists.

## Session directory contract

Create exactly this tree:

```
retrospective/implementation/session-{NN}/
├── agents/
│   ├── runner.md
│   ├── cluster-{NN}-{slug}.md
│   └── ...
├── summary.md
└── suggestions.md
```

- `{NN}` is the zero-padded session number from preflight.
- Never overwrite an existing session directory.
- If the report came from an older cda run with no `retrospective/analysis/`, still create the implementation session directory normally.

## Writers

- `agents/runner.md` — written by the orchestrator from `PREFLIGHT_DECISIONS`, `PLAN`, `EXECUTION_LOG`, `SHOWSTOPPER_LIST`, `SHOWSTOPPER_ACTIONS`, and `IAR_REVISION`.
- One `agents/cluster-{cluster-number}-{slug}.md` file for every cluster subagent that actually ran, including runs that ended in defer or partial.
- `summary.md` — written by the orchestrator after all agent files exist.
- `suggestions.md` — written by the orchestrator after `summary.md`.

## Content source

Read `codebase-deep-analysis/references/retrospective-template.md` and follow the implementation-bundle sections verbatim for file shape and subsection names.

`summary.md` is the implementation-session synthesis prose. `suggestions.md` is the action list for v-next.

## Session numbering

`PREFLIGHT_DECISIONS.session_number` is computed by scanning:

`{report-dir}/retrospective/implementation/session-*`

Pick `max(existing) + 1`, or `01` when none exist. Also record:

`PREFLIGHT_DECISIONS.session_dir = retrospective/implementation/session-{NN}`

## Cross-cluster themes integration

Read `{report-dir}/.scratch/implement-themes.md` when present and include those themes in `summary.md` under `## Cross-cluster themes that emerged during fix work`.

## Suggestions contract

`suggestions.md` contains only concrete bullets:

- `**cda v-next:** ...`
- `**iar v-next:** ...`

Both audiences are mandatory to consider. Either side may legitimately end up with zero bullets, but the runner must make that explicit.

## Common mistakes

- Reconstructing the old single-file heading model inside `summary.md`.
- Writing only `summary.md` and skipping per-agent files.
- Reusing a prior `session-{NN}` directory.
- Mixing evidence and suggestions into one file instead of keeping `suggestions.md` action-only.
