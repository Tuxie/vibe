# Part B writer (Step 5)

After Step 4 (or Step 3 if no showstoppers), iar writes Part B of `analysis-analysis.md` — the fix coordinator's retrospective. Same "write while memory is live" principle as cda's Part A: never defer.

## Audience and contract

The audience is **the author of the next version of iar** — a future Claude instance with no access to this report, this project, or this run's transcripts. Write directly to them.

Anonymization contract matches cda's Part A (see `codebase-deep-analysis/references/analysis-analysis-template.md` "Writing rules"):

- Name files *in the iar skill* (`SKILL.md` sections, reference filenames, cluster frontmatter fields) and quote template text verbatim.
- **Anonymize everything about the analyzed project.** No repo name, no real paths, no internal service names, no secrets. Replace with generic stand-ins that preserve shape (`module-A`, `the ORM layer`, `a T2 Python+TS web app`).
- Keep tier, stack family, rough size, counts, wall time — calibration signal, not identification.
- General advice ("be more specific") is useless. Anonymized-but-specific observations drive real improvements.

## Data iar has at write time

The orchestrator's working memory at Step 5 contains:

- `PREFLIGHT_DECISIONS` — every answer the user gave at Step 0.
- `PLAN` — cluster order, gate set, per-cluster gate overrides.
- `EXECUTION_LOG` — per-cluster: pre-SHA, outcome (closed/partial/deferred/showstopper/resolved-by-dep), wall time, gates run and their results, incidental files, subagent prompt + reply excerpts.
- `SHOWSTOPPER_LIST` and `SHOWSTOPPER_ACTIONS` — every deferred cluster and the user's Step 3 answer.
- `PARTB_START_SHA` and `PARTB_END_SHA` — first and last commit produced by the run (computed from the first cluster's pre-SHA and `git rev-parse HEAD` at Step 5).
- iar's own VERSION (`0.1.0`).
- cda's report version (from the report's metadata).

## Template to fill

Read `codebase-deep-analysis/references/analysis-analysis-template.md` and locate the Part B section. Fill it subsection by subsection. Do NOT skip subsections — a truthful "nothing notable here" is acceptable for a given subsection, but the heading must appear.

Subsections to fill (names verbatim from the template):

- Run identity (carry from Part A; add iar-specific rows: iar version, primary-pass wall time, second-pass wall time, gates run)
- Did the TL;DR block tell the truth? (evidence from EXECUTION_LOG)
- Cluster sizing honesty (compare Est. session size to actual wall time)
- Was the Suggested session approach useful?
- `Depends-on` edges in practice (did they hold? were any informally-unblocks edges load-bearing after all?)
- Scope-expansion events (every incidental-fix entry from EXECUTION_LOG)
- Deferred items (every showstopper that ended as `defer` or `partial`)
- Findings the report missed entirely (clusters whose fix surfaced bugs the analyst didn't flag)
- Findings the report had that didn't matter (e.g., an already-fixed flagged issue)
- Tooling reality (how gates behaved; any pinned-version surprises)
- Instructions to the v-next author (3–10 concrete items for the next iar version)

## Output location

Append to `{report-dir}/analysis-analysis.md`. The cda Step 6 template left a Part B section with placeholders; iar fills those placeholders in place. If no Part B section exists (older report), append a new `## Part B — Fix coordinator retrospective` section at the end of the file with a leading note that Part A was missing.

Part B is NOT under `.scratch/`. It sits next to Part A so anyone reviewing the report finds both retrospectives together.

## Common mistakes

- **Postponing.** By the time the next invocation rolls around, the details are gone. Write Part B immediately after the last cluster hits a terminal state.
- **Copying Part A's shape into Part B.** Part A is the runner retrospective (does synthesis over-filter?). Part B is the fix coordinator retrospective (did the cluster files tell the truth once we tried to implement them?). Different audiences, different questions.
- **Leaking project identity.** Even a throwaway code snippet can de-anonymize. When in doubt, replace with `<generic-shape>`.
- **Writing advice instead of evidence.** "Be more careful with autonomy flags" is useless. "Cluster 03 was marked autofix-ready but the third finding required deciding between two valid approaches; the subagent correctly returned shape B; v-next iar should prefer shape B more aggressively when the Fix: line uses hedging language" is useful.
