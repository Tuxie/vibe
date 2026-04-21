# Preflight prompt (Step 0)

The whole interaction with the user lives in this single step. One `AskUserQuestion` with every decision the run needs. At most one follow-up if the user picks `edit detected commands / gates first`. After that, Steps 1–5 proceed unattended.

## Data the orchestrator must collect before issuing the prompt

Gather these before the user sees anything — the prompt itself shows summarized values, not interactive detection.

1. **Report directory.** Either passed as the skill's argument or defaulted to the newest `docs/code-analysis/*/` directory. Verify it exists and contains a recognizable layout (`README.md` + `clusters/` dir, `REPORT.md` with `<!-- cluster:NN:start -->` markers, or `README.md` + no clusters — fail cleanly if none).
2. **cda version compatibility.** Read `{report-dir}/.scratch/codebase-map.md` first line or look for the v3+ frontmatter fields in any cluster (`Autonomy:`, `informally-unblocks:`). Abort with a clear message if the report predates v3.0.
3. **Dependencies installed.** Probe the harness for `superpowers:subagent-driven-development`. If not discoverable, abort before any user interaction.
4. **Cluster enumeration.** Walk every cluster (full-multi-file: `clusters/*.md`; compact-multi-file: same; single-file: parse `<!-- cluster:NN:start -->` / `<!-- cluster:NN:end -->` blocks from `REPORT.md`). For each cluster collect: slug, goal, Autonomy, Depends-on, informally-unblocks, Pre-conditions, per-cluster `gate:` override (if any), needs-decision question (from Suggested session approach block).
5. **Gate detection.** Read `package.json` scripts, top-level `Makefile`, `justfile`, `Taskfile*`, `pyproject.toml` `[tool.*.scripts]`. Build the baseline set per `gate-detection.md` rules.
6. **Current branch and working-tree state.** `git rev-parse --abbrev-ref HEAD`, `git status --porcelain`. Needed to surface warnings in the prompt (uncommitted changes + non-current-branch strategy = warning; uncommitted changes + current-branch strategy = warning; clean tree = no warning).

## Prompt structure

Issue exactly one `AskUserQuestion` with these sections:

```
Implement Analysis Report

Report: {report-dir}  (cda v{version}, {N} clusters)

== CLUSTER SUBSET ==
All clusters (default)
  [will process all {N} clusters in topological Depends-on order]
Only specific clusters
  [user lists slugs; the rest stay open]
All except specific clusters
  [user lists slugs to skip; the rest proceed]

== DECISIONS (needs-decision clusters in subset) ==
For each needs-decision cluster in the subset, show a question derived
from its Suggested session approach block, accept free-text answer:

  Cluster 04-auth-rewrite — [question from cluster body]
    Your answer: _____________
  Cluster 11-slider-refactor — [question from cluster body]
    Your answer: _____________
  ...

== NEEDS-SPEC HANDLING ==
For each needs-spec cluster in the subset:

  Cluster 02-webgl-harness — [default: auto-defer to docs/ideas/02-webgl-harness.md]
    Alternative: answer now with a free-text spec

== BRANCH STRATEGY ==
( ) New branch `fix/deep-analysis-{YYYY-MM-DD}`  (default)
( ) Current branch `{current-branch}`
( ) Git worktree (isolated; requires superpowers:using-git-worktrees)

== VERIFICATION GATES (auto-detected) ==
test:     `{detected-test-cmd}`    [edit] [remove]
typecheck: `{detected-tc-cmd}`     [edit] [remove]
lint:     `{detected-lint-cmd}`    [edit] [remove]
build:    `{detected-build-cmd}`   [edit] [remove]
[add custom gate]

== DRY RUN ==
( ) Off (default; commits land)
( ) On (validate flow; no commits, no frontmatter changes, log only)

== PROCEED ==
After answering, the run proceeds unattended through Steps 1–5.
The next user interaction is at Step 3 (showstoppers) if any arise.

( ) Proceed
( ) Edit detected commands / gates first
( ) Abort
```

## Handling `Edit detected commands / gates first`

Issue **one** follow-up `AskUserQuestion` with free-text slots for each editable gate command. Re-issue the primary prompt with the edited values so the user confirms the whole set with the corrections in view. Maximum two round-trips total. Never loop.

## Output capture

After the user's final answer, record a `PREFLIGHT_DECISIONS` object in working memory:

```
PREFLIGHT_DECISIONS = {
  "cluster_subset": "all" | "only: [slug, slug]" | "all-except: [slug, slug]",
  "decisions": {
    "04-auth-rewrite": "answer text",
    ...
  },
  "needs_spec_handling": {
    "02-webgl-harness": "auto-defer" | "spec: <free text>",
    ...
  },
  "branch_strategy": "new-branch" | "current-branch" | "worktree",
  "branch_name": "fix/deep-analysis-2026-04-21",  # derived when relevant
  "gates": {
    "test": "bun test",
    "typecheck": "tsc --noEmit",
    ...
  },
  "gate_timeouts": {
    "test": 600,    # seconds; default 600 (10 min) per gate
    "build": 1800,  # 30 min override
    ...
  },
  "dry_run": false
}
```

Steps 1–5 read from this object exclusively. No re-detection. No re-parsing.

## Timeouts

If the user does not respond to the primary prompt, exit cleanly with a message: *"No preflight response; exiting without changes."* Do not proceed with defaults — unlike cda Step 3.5's "default to static-only", here the user has not even authorized the run.

## Common mistakes

- **Asking anything before detecting everything.** Do all detection first; the prompt shows a summary, not live questions.
- **Re-asking a decision mid-run.** Every `needs-decision` cluster's question lives here or nowhere.
- **Silently defaulting a branch on a dirty tree.** If the tree has uncommitted changes AND the user picks `current-branch`, show a warning line in the prompt and require explicit confirmation. Do not auto-stash.
