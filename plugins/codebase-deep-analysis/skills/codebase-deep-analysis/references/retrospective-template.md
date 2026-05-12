# Retrospective bundle template

**Purpose:** the retrospective bundle is the run-local critique of `codebase-deep-analysis` and `implement-analysis-report`, written from inside a real report lifecycle. It is the primary RED-phase input for the next skill versions.

The old single-file retrospective contract is replaced by a directory tree:

- Analysis run output: `retrospective/analysis/`
- Implementation run output: `retrospective/implementation/session-{NN}/`

Each bundle has the same top-level shape:

```
retrospective/{analysis | implementation/session-NN}/
├── agents/
│   ├── runner.md
│   ├── {agent-name}.md
│   └── ...
├── summary.md
└── suggestions.md
```

## Shared writing rules

- Write to the next skill author, not to the current report reader.
- Anonymize the analyzed project completely. Keep tier, stack family, rough size, counts, wall time, and calibration signal.
- Name skill files, prompts, scripts, and frontmatter fields precisely when critiquing them.
- Keep concrete evidence ahead of advice. "X was too vague" is weak; quote the line and name the workaround.
- Agent files are raw perspective dumps. `summary.md` synthesizes. `suggestions.md` is the action list.

## Analysis bundle

Path: `retrospective/analysis/`

Writers:

- `agents/runner.md` — written by the orchestrator after report render.
- `agents/structure-scout.md` — written by the Scout if it ran.
- One file for every dispatched analyst: `backend.md`, `frontend.md`, `database.md`, `tests.md`, `security.md`, `tooling.md`, `docs.md`, `coverage-profiling.md`, `styling.md`, `accessibility.md`, or the repo's actual agent roster names normalized to kebab-case.
- `summary.md` — written by the runner after all agent files exist.
- `suggestions.md` — written by the runner after `summary.md`.

### Analysis agent file template

Every file under `retrospective/analysis/agents/` uses this shape:

```markdown
# {Agent name} retrospective

## Run identity

- Skill revision: {sha:... | version:... | skill-md-hash:...}
- Project tier: {T1|T2|T3}
- Scope: {one line}
- Approx wall time: {value}
- Approx output tokens: {value or best estimate}

## What worked

- {2-8 bullets}

## What was friction

- {2-8 bullets}

## Blind spots or misses

- {0-N bullets}

## Suggestions for v-next

- **cda v-next:** {concrete change to a specific skill file}
```

The runner file may additionally record orchestration issues spanning multiple agents.

### `retrospective/analysis/summary.md`

The runner writes a short synthesis with these sections:

- Run identity
- What worked overall
- What was friction overall
- Tier and applicability calibration
- Coverage/profiling reality check when applicable
- Cluster-assembly reality check
- Noise, drops, and regrets

### `retrospective/analysis/suggestions.md`

The runner writes only concrete next-version items, one per bullet:

- `**cda v-next:** ...`

This file is allowed to be short. It is the distilled carry-forward list from the analysis run.

## Implementation bundle

Path: `retrospective/implementation/session-{NN}/`

Session numbering starts at `01` and increments by scanning existing `retrospective/implementation/session-*` directories and taking `max + 1`.

Writers:

- `agents/runner.md` — written by the implementation orchestrator.
- One file per cluster subagent that actually ran, named `cluster-{NN}-{slug}.md`.
- `summary.md` — written by the runner after all agent files exist.
- `suggestions.md` — written by the runner after `summary.md`.

### Implementation agent file template

Every file under `retrospective/implementation/session-{NN}/agents/` uses this shape:

```markdown
# {Agent name} retrospective

## Run identity

- IAR revision: {sha:... | version:... | skill-md-hash:...}
- Session: {NN}
- Cluster or role: {runner | cluster-XX-slug}
- Approx wall time: {value}

## What worked

- {2-8 bullets}

## What was friction

- {2-8 bullets}

## Misses in the report

- {0-N bullets}

## Suggestions for v-next

- **cda v-next:** {optional, report-generation issue}
- **iar v-next:** {optional, implementation-orchestration issue}
```

### `retrospective/implementation/session-{NN}/summary.md`

The runner writes a session synthesis with these sections:

- Run identity
- Cluster subset processed
- Did the TL;DR blocks tell the truth?
- Cluster sizing honesty
- Suggested-session-approach usefulness
- `Depends-on` edges in practice
- Scope-expansion events
- Deferred items
- Findings the report missed entirely
- Findings the report had that did not matter
- Tooling and gate reality
- Cross-cluster themes that emerged during fix work
- Cross-session observations when `NN > 01`

### `retrospective/implementation/session-{NN}/suggestions.md`

The runner writes concrete carry-forward items only:

- `**cda v-next:** ...`
- `**iar v-next:** ...`

Separate the two audiences cleanly. If one underlying issue produced both a report-generation problem and an implementation-orchestration problem, write two bullets.

## Common mistakes

- Do not collapse multiple runs back into one file.
- Do not overwrite a prior implementation session directory.
- Do not mix summary content into `suggestions.md`.
- Do not hide agent-specific friction by writing only the runner summary.
