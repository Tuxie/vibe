---
name: codebase-deep-analysis
description: Use when asked to perform an exhaustive deep analysis of an entire codebase to identify issues, antipatterns, and improvements — results are written as a directory of markdown files under docs/code-analysis/{date}/ (indexed README, per-cluster fix plans, by-analyst dumps, checklist, META rules) sized to the project's scale tier so a T1 hobby tool doesn't get T3 enterprise advice
---

# Codebase Deep Analysis

## Overview

Dispatch parallel Explore subagents to analyze every **applicable** layer of the codebase — backend, frontend, tests, tooling, database, documentation, security — then synthesize findings into a **directory** of markdown files that a brainstorming session can consume one cluster at a time.

**The only writes permitted are to `docs/code-analysis/`** (the report directory and a scratch subdirectory). No code modifications. Read-only shell commands only, with **one carefully-bounded exception**: Step 3.5 may invoke the project's own existing coverage and bench commands if — and only if — the user grants a second explicit consent specifically for that step. Never run builds, migrations, installs, or any other subcommand that mutates state.

**Two core principles, equally important:**

1. **Analyze everything, fix nothing.** Only suggest a fix when you can name the file, the line, and the replacement text.
2. **Right-size to the project.** A hobby tool does not get enterprise advice. Every analyst filters by the project's tier (T1 hobby / T2 serious-OSS / T3 prod-team); synthesis drops or rewrites findings whose canonical fix assumes infra, team, or process the project lacks. Inactionable noise is worse than a shorter report.

## References (load as needed)

| File | Purpose |
|------|---------|
| `references/structure-scout-prompt.md` | Prompt for the mapping pass, including **project tier**, docs-drift flag, and pre-release-surface detection |
| `references/agent-roster.md` | Which analysts exist, what they own, when they run (including the gated Coverage & Profiling analyst) |
| `references/agent-prompt-template.md` | Template filled in per analyst; enforces ground rules + tier-sensitive finding format (adds `Autonomy:`, `Cluster hint:`, and `Depends-on:` fields) |
| `references/checklist.md` | Stable checklist IDs with min-tier tags, agent ownership, and the full set of checklist-line shapes including `[~] deferred` |
| `references/synthesis.md` | Dedup, right-sizing filter, hybrid clustering, severity resolution, Executive Summary, Depends-on handling, scope-expansion rules |
| `references/report-template.md` | Multi-file directory skeleton with cluster `Status:` / `Resolved-in:` frontmatter, TL;DR block, Pre-release checklist, Deferred section |
| `references/coverage-profiling-prompt.md` | Prompt for the Step 3.5 gated analyst; static-only pass is default, dynamic execution requires second user consent |
| `references/analysis-analysis-template.md` | Two-part retrospective template (runner + fix coordinator) written **to the next skill version's author** — primary RED-phase input for v-next |
| `scripts/render-status.sh` | Rebuilds the README cluster-index block from each cluster file's `Status:` field — prevents README drift |

## Execution flow

```dot
digraph analysis_flow {
    "Start" [shape=doublecircle];
    "Step 0 — Preflight" [shape=box];
    "Step 1 — Structure Scout (maps + tiers + drift)" [shape=box];
    "Step 2 — Scope resolution (prune by applicability + tier)" [shape=box];
    "Step 3 — Dispatch analysts (parallel, read-only)" [shape=box];
    "Step 3.5 — Coverage & Profiling (gated)" [shape=box];
    "Step 4 — Synthesis: dedup + right-size + cluster" [shape=box];
    "Step 5 — Render report directory" [shape=box];
    "Step 6 — Retrospective (analysis-analysis.md, Part A)" [shape=box];
    "Done" [shape=doublecircle];

    "Start" -> "Step 0 — Preflight";
    "Step 0 — Preflight" -> "Step 1 — Structure Scout (maps + tiers + drift)";
    "Step 1 — Structure Scout (maps + tiers + drift)" -> "Step 2 — Scope resolution (prune by applicability + tier)";
    "Step 2 — Scope resolution (prune by applicability + tier)" -> "Step 3 — Dispatch analysts (parallel, read-only)";
    "Step 3 — Dispatch analysts (parallel, read-only)" -> "Step 3.5 — Coverage & Profiling (gated)";
    "Step 3.5 — Coverage & Profiling (gated)" -> "Step 4 — Synthesis: dedup + right-size + cluster";
    "Step 4 — Synthesis: dedup + right-size + cluster" -> "Step 5 — Render report directory";
    "Step 5 — Render report directory" -> "Step 6 — Retrospective (analysis-analysis.md, Part A)";
    "Step 6 — Retrospective (analysis-analysis.md, Part A)" -> "Done";
}
```

## Step 0 — Preflight

1. **Token warning with a single ask.** Tell the user: *"This run dispatches several analyst subagents in parallel and will consume a large number of tokens. It is best run when weekly quota has spare headroom. Proceed?"* Use `AskUserQuestion` (or equivalent single prompt). If the user does not answer within a reasonable window, or answers no, abort with a short status message. Never block indefinitely.
2. **Check git state, but do not gate on it.** Run `git status --porcelain`. If output is non-empty, warn the user that any `file:line` references in the resulting report may shift if they later commit or revert. Do **not** abort — this skill is read-only and a dirty tree is not a safety issue.
3. **Pick a non-clobbering report directory.** Default: `docs/code-analysis/YYYY-MM-DD/`. If that directory already exists, use `YYYY-MM-DD-HHMMSS/` instead. Never overwrite a prior report directory.
4. **Create the directory skeleton,** empty — `clusters/`, `by-analyst/`, `.scratch/` — so later steps append into place.

## Step 1 — Structure Scout

Dispatch **one** Explore subagent with the prompt in `references/structure-scout-prompt.md`. Haiku is preferred for this pass; fall back to the default model if Haiku is unavailable.

The Scout's job is four things: (a) map the codebase; (b) **classify the project tier (T1 / T2 / T3)** with cited evidence; (c) flag **load-bearing instruction-file drift** (CLAUDE.md / AGENTS.md / GEMINI.md / README.md that have fallen behind the code they reference); (d) detect the **pre-release verification surface** (CI config + local CI-equivalent runner). The tier is the single biggest right-sizing lever — it drives which analysts run, which checklist items are owned, and which findings survive synthesis. The drift flag tells the Docs analyst where to look hardest. The pre-release surface controls whether the final README emits a release checklist.

Explore subagents cannot write files. When the Scout returns, **you** (the orchestrator) write its full output to `docs/code-analysis/{stem}/.scratch/codebase-map.md`. Analysts will Read that path; they will never receive the map pasted into their prompt.

If the repo has no `.git/`, the scout falls back to `rg --files --hidden --no-ignore-vcs` — specified inside the scout prompt file.

## Step 2 — Scope resolution

Read the scout's **Applicability flags** block and **Project tier** block.

- **Applicability pruning.** Drop analysts whose scope is absent: no web UI → skip Frontend; no DB → skip Database; no CI config → Tooling still runs (it owns BUILD/GIT even without CI) but its CI-specific items become `[-] N/A`.
- **Tier pruning.** Do not skip analysts based on tier — tier filtering happens per checklist-item inside each analyst, not at the roster level.

Record every skipped analyst and the reason — the final `README.md` must state this under Run metadata.

Exceptions that always run:

- **Security Analyst always runs.** Even a "pure backend library" can ship a subprocess call or deserialization surface.
- **Docs Analyst always runs** if any of `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `README.md`, or `docs/**` exists.
- **Tooling Analyst always runs** unless the repo has literally no manifest/build config at all (rare; essentially `.txt` files only).

## Step 3 — Dispatch analysts (parallel)

Launch all remaining analysts **in a single message** using multiple `Agent` tool calls so they run concurrently. Each agent is an Explore subagent. Each prompt is assembled from `references/agent-prompt-template.md` with these substitutions:

- `{AGENT_NAME}`, `{SCOPE_GLOBS}` — from `references/agent-roster.md`
- `{CODEBASE_MAP_PATH}` — the scratch file you wrote in Step 1
- `{PROJECT_TIER}`, `{TIER_RATIONALE}` — copied from the Scout's Project-tier block
- `{OWNED_CHECKLIST_ITEMS}` — the subset of `references/checklist.md` this agent owns, with min-tier tags copied inline (the agent should not need to read the full checklist file)
- `{CLAUDE_MD_FILES}` — list of actual top-level instruction/doc files that exist (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `README.md`, `docs/*.md`)

Hard rules the template enforces (read it before editing):

- Every agent reads `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` / top-level `docs/*.md` before reading any source file. Documented decisions are intentional unless the agent can show the doc itself is wrong.
- Every agent receives the **project tier** at the top of its prompt and must filter every owned checklist item and every finding against it. Inactionable-for-this-tier findings are dropped at source; the synthesis right-sizing filter is a second line of defense, not the primary one.
- Forbidden reads: `.env*`, `*.pem`, `*.key`, `*.pfx`, `*.p12`, anything under `secrets/`, `credentials/`, `.ssh/`. Describe existence, never contents. Do not quote any token that looks like a credential.
- Forbidden commands: `install`, `add`, `build`, `migrate`, `exec`, `test`, `run`, any package-manager subcommand that downloads or modifies, and any execution of project code. Allowed: `git log`, `git blame`, `git ls-files`, `rg`, `ls`, `wc`, and the Read tool.
- Every finding carries: `file:line`, Severity (Critical/High/Medium/Low), Confidence (Verified / Plausible / Speculative), Effort (Small/Medium/Large/Unknown), **Autonomy** (autofix-ready / needs-decision / needs-spec), **Cluster hint** (kebab slug). The `Fix:` line is written only when Confidence = Verified **and** the agent can name the exact replacement — otherwise the line is omitted.
- Every owned checklist item gets one of: `[x] <evidence pointer>`, `[x] clean — <what was sampled>`, `[-] N/A — <reason>`, `[?] inconclusive — <what was tried>`. Bare `[x]` is a defect.

## Step 3.5 — Coverage & Profiling (gated, optional)

This is the **only** step in the skill that may invoke project commands. It runs only when the user grants a second, explicit consent — do not roll it into Step 0's blanket approval.

1. **Detect candidates without running anything.** Read `package.json` scripts, top-level `Makefile`, `justfile`, `Taskfile*`, `pyproject.toml`'s `[tool.*.scripts]` equivalents. Identify the coverage command (names containing `cov`, `coverage`, or a test runner flag like `--coverage`) and the bench/profile command (names containing `bench`, `benchmark`, `profile`). There may be zero, one, or both.
2. **Ask once.** Use `AskUserQuestion` with the detected commands laid out plainly. Example: *"Step 3.5 can run the project's own coverage (`{cmd}`) and benchmarks (`{cmd}`) and fold the results into the report. This executes project code — unlike every other step in this skill. Proceed? [Run both / Run coverage only / Run bench only / Static-only / Skip]."* Do not block indefinitely; default to **Static-only** if the user does not answer in a reasonable window.
3. **Dispatch the Coverage & Profiling analyst** with the prompt in `references/coverage-profiling-prompt.md`. Pass `{EXECUTION_CONSENT}` = `granted` or `declined` plus the detected commands (or "none detected"). The analyst is the single choke point for runtime invocation: the orchestrator does not run anything itself.
4. **Merge output into synthesis.** The analyst's findings and checklist lines flow through Step 4 the same way as every other analyst — the only novelty is the optional dynamic-pass Confidence upgrade from Plausible to Verified on covered items.

If the user chose **Skip**, omit the analyst entirely and record `Coverage & Profiling: skipped (user declined)` in Run metadata. The analyst is not silent on decline — static-only is its default mode.

## Step 4 — Synthesis

See `references/synthesis.md`. Summary of what happens here:

1. **Collect & dedup** by anchor; merge entries across agents.
2. **Right-sizing filter** (§3 — the most important step). Drop or rewrite findings whose canonical fix assumes infrastructure/team/process absent at the project's tier. Stylistic and rule-restatement findings also drop here. The filter activity is tallied and surfaced under Run metadata so under/over-filtering is visible.
3. **Resolve ownership collisions** for multi-owner checklist items.
4. **Promote cross-cutting themes** (≥3 files across ≥2 agents after right-sizing).
5. **Hybrid clustering** (§6). Seed clusters from analyst `Cluster hint:` labels, reshape to share files/subsystems, apply the soft cap of 5–10 findings per cluster (split at >12). Each cluster is a self-contained fix session.
6. **Executive Summary** selects up to 5 clusters by severity + confidence + spread/sensitivity.
7. **Validate checklist integrity**; defect-demote bare `[x]` and contradictory `[-] N/A`.
8. **Draft META-1 entries** — CLAUDE.md rules that would have prevented recurring finding shapes.
9. **Optional single targeted re-dispatch** if Executive Summary is thin or defects demand it.
10. **Freeze.** No further changes during rendering.

## Step 5 — Render report directory

Fill in the directory layout from `references/report-template.md`:

```
docs/code-analysis/{stem}/
├── README.md                    # index, metadata, token warning, tier
├── executive-summary.md         # top clusters
├── themes.md
├── clusters/{NN-slug}.md        # one file per cluster
├── by-analyst/{agent}.md        # analyst-native dumps
├── checklist.md                 # full checklist with defects
├── meta.md                      # META-1 drafts
├── not-in-scope.md              # filtered-out tally + structural exclusions
└── .scratch/codebase-map.md
```

Rendering is a pure pass from the frozen synthesized set. The only place rendering adds anything is the 2–3-sentence `Suggested session approach` block per cluster file and, conditionally, the `## Pre-release verification checklist` block in the README when the Scout's `Pre-release surface` section recommended it.

At the top of `README.md`, repeat the Step 0 token-warning sentence verbatim so any follow-up brainstorming session re-confirms before burning more tokens.

Cluster files render with frontmatter containing `Status: open` and an empty `Resolved-in:`. The README's cluster-index block is bracketed by `<!-- cluster-index:start -->` / `<!-- cluster-index:end -->` markers so `scripts/render-status.sh` can regenerate it later without disturbing the rest of the README.

## Bookkeeping after the report lands

The report is a living artifact. The only file-format fields the user is expected to edit by hand after rendering are inside cluster frontmatter:

- Flip `Status:` when work begins (`in-progress`), merges (`closed`), is punted (`deferred`), or is resolved incidentally by another cluster (`resolved-by-dep`).
- Fill `Resolved-in:` with the commit SHA or release tag that actually resolved the cluster.
- After any edit, run `scripts/render-status.sh <report-dir>` to rebuild the README index block. **Do not hand-edit the index**; it will drift from the cluster files immediately.
- When the last cluster closes, defers, or stalls, append **Part B** of `analysis-analysis.md` per the template at `references/analysis-analysis-template.md`. Part B is the fix coordinator's retrospective; it is the second half of the input the v-next author needs, and nobody else is positioned to write it. If fix work is ongoing at the next invocation of the skill on this repo, write what you have so far and mark the rest open.

See `references/report-template.md` "Cluster `Status` lifecycle" for the full state table. See `references/synthesis.md` §11 (Depends-on resolution) and §12 (scope expansion) for the two follow-on patterns that govern what fix sessions are allowed to do after the report is frozen.

## Step 6 — Retrospective: write `analysis-analysis.md` (Part A)

**The skill is self-evolving. This step is how.**

`tips-from-runner.md` in the skill repo was the RED-phase input for the v2 rewrite. The v3 author needs the same kind of input, but collected in-flight rather than reconstructed from memory. Step 6 produces that input every run.

Immediately after Step 5 renders — **before the token-saving context decay makes details fuzzy** — write `docs/code-analysis/{stem}/analysis-analysis.md` from the template at `references/analysis-analysis-template.md`. The file has two parts:

- **Part A — Runner retrospective.** You (the orchestrator) fill this in now. You have just driven every step of the skill; you know where the references over-specified, where they under-specified, where the filter dropped something it shouldn't have, and what token/time cost each analyst actually incurred. Write while that memory is live. The template lists every subsection — do not skip subsections, but a truthful "nothing notable here" is an acceptable body for one.
- **Part B — Fix coordinator retrospective.** Leave as the empty template. The person (or agent) who later coordinates fix sessions on this report appends Part B when the last cluster closes, defers, or stalls.

The audience is **the author of the next version of this skill** — a future Claude instance reading this file with no context from this run **and no access to the analyzed codebase**. Write to them directly. Name files *in the skill* (references, scripts, SKILL.md sections) and quote template text verbatim; give token counts when you have them. But **anonymize everything about the analyzed project** — no repo name, no real paths, no internal service names, no secrets, no exploit-grade security detail. Replace with generic stand-ins that preserve shape (`module-A`, `the ORM layer`, `a T2 Python+TS web app`). Keep tier, stack family, rough size, analyst token counts, wall time — those are calibration signal, not identification. General advice ("be more specific") is useless; anonymized-but-specific observations ("on a T3 polyglot repo with 14 analysts the scout's 500-line budget was 2x too small") are what drives real improvements.

**Capture the skill's own git revision at the start of the run** (`git -C <skill-repo> rev-parse --short HEAD`) and paste it into the `Skill revision:` field of the template's Run identity block. Without that SHA the v-next author cannot diff the critiqued behavior against the exact code that produced it, and every note in the retrospective becomes guesswork. See `references/analysis-analysis-template.md` "Writing rules" for the full anonymization contract.

Do not skip this step. A v-next author with zero retrospectives is flying blind and will regress parts of the skill that already work. A v-next author with even one honest retrospective can focus changes on the parts that actually failed.

The scratch codebase map is retained. `analysis-analysis.md` is **not** under `.scratch/` — it sits next to the report's `README.md` so the user finds it when reviewing the run, and so it is trivial to copy into the skill repo for v-next planning.

## Model selection

Default every analyst to **Sonnet**. Escalations:

- **Security Analyst → Opus** by default (cross-cutting; high cost of missing a finding).
- **Any analyst whose declared scope exceeds ~50k LOC, or which returns >30 High/Critical findings in the first pass → re-dispatch that agent on Opus** for a second, deeper pass and merge outputs during synthesis.
- **Haiku** only for Structure Scout (and any pure enumeration helper you add later).

There is **no** "when unsure, pick the more powerful tier" override. Unsure stays Sonnet; synthesis escalates surgically rather than broadly.

## Common mistakes

- **Enterprise advice to a hobby repo.** The single biggest quality failure. If the project is T1, drop anything that assumes SLOs, observability infra, team process, security review pipelines, or release management. The right-sizing filter at §3 of synthesis is the backstop — but analysts should drop at source.
- **Modifying code.** Never. The only writes are the report directory and its scratch subdir.
- **Pasting the codebase map into every prompt.** Write it to scratch once, reference by path. Pasting multiplies token cost by N agents.
- **Re-reading the whole repo per agent.** Each agent stays inside its scope filter; cross-scope reads require a one-line justification on the finding that needed them.
- **Self-certifying a fix suggestion.** If you cannot name the file, line, and exact replacement text, the `Fix:` line is omitted — not paraphrased.
- **Ticking a checklist item with no evidence.** `[x]` without a file:line or an explicit "clean — <what was sampled>" / `[-] N/A — <reason>` is a defect; synthesis demotes it.
- **Confusing `[?]` with `[~]`.** `[?]` means analysis was blocked; `[~] deferred` means analysis succeeded and action is intentionally punted. The two have different downstream behavior — see `synthesis.md` §8.
- **Hand-editing the README cluster index.** It is generated from cluster-file `Status:` fields. Edit the cluster file, re-run `scripts/render-status.sh`.
- **Skipping Step 6.** The retrospective is how the skill evolves. An empty or boilerplate `analysis-analysis.md` is worse than none — it misleads the v-next author. Write specifics while they are fresh, or say "nothing notable" honestly.
- **Postponing Part A.** If the orchestrator defers Part A to "write it later", the useful details are already gone. Part A is a Step 6 deliverable, not a follow-up.
- **Trusting Scout's applicability or tier flags blindly.** If an analyst finds evidence that an applicability flag was wrong or the tier classification mismatches reality, it says so in its Summary; synthesis re-dispatches or re-tiers.
- **Cluster-hint sprawl.** If every finding has its own unique cluster hint, clustering collapses into one-finding-per-file and the multi-file report is useless. Keep hints to a small controlled vocabulary per run.
- **Rolling Step 3.5 consent into the Step 0 token warning.** They are different approvals — Step 3.5 runs project code. Ask separately or skip the dynamic pass.
- **Auto-resolving `Depends-on:` findings when the upstream cluster merges.** The edge is a prompt to check, not a conclusion. See `synthesis.md` §11.
- **Silent scope expansion during fix work.** When a cluster's fix must touch adjacent files to pass a verification gate, document every extra file under an `Incidental fixes` section in the commit message. See `synthesis.md` §12.
- **Quoting secrets.** Describe presence, never contents.
- **Running anything outside Step 3.5.** No `bun test`, no `npm run build`, no migrations, no scripts in any other step. Static reading only.
