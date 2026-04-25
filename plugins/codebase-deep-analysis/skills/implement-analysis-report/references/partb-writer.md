# Part B writer (Step 5)

After Step 4 (or Step 3 if no showstoppers), iar writes Part B of `analysis-analysis.md` — the fix coordinator's retrospective. Same "write while memory is live" principle as cda's Part A: never defer.

**One Part B section per session.** Every invocation of iar that touches the report appends its own Part B section, identified by session number, date, and the exact iar revision that ran. Prior sessions are never overwritten. Over time a report's `analysis-analysis.md` accumulates `Part B (session 1)`, `Part B (session 2)`, … — a time-ordered log of fix-work across however many resumption runs were needed.

## Audience and contract

Part B has **two v-next audiences** and the retrospective must serve both:

1. **The author of the next codebase-deep-analysis version (cda v-next).** Needs evidence about whether the *report* was faithful — did clusters match implementation reality, were findings correctly attributed, did the synthesis right-sizing filter draw the right line. Read cda's `analysis-analysis-template.md` "Writing rules" for the anonymization contract.
2. **The author of the next implement-analysis-report version (iar v-next).** Needs evidence about whether the *fix-coordinator* was adequate — did the preflight capture the right decisions, did gate detection cover the project's toolchain, did showstopper handling resolve cleanly, did the subagent wrapper output contract work as specified.

Both audiences are future capable agents with no access to this report, this project, or this run's transcripts. Write directly to them. A single Part B section serves both — separate suggestions are emitted in the dedicated `cda v-next` and `iar v-next` subsections near the end.

Anonymization contract matches cda's Part A (see `codebase-deep-analysis/references/analysis-analysis-template.md` "Writing rules"):

- Name files *in the iar skill* (`SKILL.md` sections, reference filenames, cluster frontmatter fields) and quote template text verbatim.
- **Anonymize everything about the analyzed project.** No repo name, no real paths, no internal service names, no secrets. Replace with generic stand-ins that preserve shape (`module-A`, `the ORM layer`, `a T2 Python+TS web app`).
- Keep tier, stack family, rough size, counts, wall time — calibration signal, not identification.
- General advice ("be more specific") is useless. Anonymized-but-specific observations drive real improvements.

## Data iar has at write time

The orchestrator's working memory at Step 5 contains:

- `PREFLIGHT_DECISIONS` — every answer the user gave at Step 0, including `session_number` and `include_terminal`.
- `PLAN` — cluster order, gate set, per-cluster gate overrides.
- `EXECUTION_LOG` — per-cluster: pre-SHA, outcome (closed/partial/deferred/showstopper/resolved-by-dep), wall time, gates run and their results, incidental files, subagent prompt + reply excerpts.
- `SHOWSTOPPER_LIST` and `SHOWSTOPPER_ACTIONS` — every deferred cluster and the user's Step 3 answer.
- `PARTB_START_SHA` and `PARTB_END_SHA` — first and last commit produced by the run (computed from the first cluster's pre-SHA and `git rev-parse HEAD` at Step 5).
- `IAR_REVISION` — iar's own revision, captured at Step 0 via the same fallback chain cda uses (Step 6 of `codebase-deep-analysis/SKILL.md`):
  1. `git -C <iar-skill-repo> rev-parse --short HEAD` → `sha:<short-sha>` when the iar skill repo has `.git/`.
  2. Otherwise `cat <iar-skill-repo>/VERSION` → `version:<content>` when loaded from a plugin cache.
  3. Last resort `sha256sum <iar-skill-repo>/SKILL.md | cut -c1-8` → `skill-md-hash:<hash>`.
  Format: `<source>:<value>` (e.g., `version:0.2.0` or `sha:a1b2c3d`). This field is **mandatory** — Part B cannot be written without it, because future-iar's RED-phase needs to diff its critiqued behavior against the exact code that produced the session.
- cda's report version (from the report's metadata).

## Session heading

Append a fresh Part B section to `analysis-analysis.md` with exact heading:

```
## Part B — Fix coordinator retrospective (session {N}, {YYYY-MM-DD}, iar {IAR_REVISION})
```

Example: `## Part B — Fix coordinator retrospective (session 2, 2026-04-22, iar version:0.2.0)`

`{N}` is `PREFLIGHT_DECISIONS.session_number` (computed at preflight by scanning for prior Part B headings). `{YYYY-MM-DD}` is the date the run completed. `{IAR_REVISION}` is the mandatory `<source>:<value>` identifier described above.

Never edit a prior session's heading or body. If the template-left Part B placeholder from cda Step 6 exists and is empty (no prior session has written), treat it as an unused template: replace it with this session's heading. If it already contains content, add this session as a new heading below.

## Template to fill

Read `codebase-deep-analysis/references/analysis-analysis-template.md` and locate the Part B section. Fill it subsection by subsection under the session heading above. Do NOT skip subsections — a truthful "nothing notable here" is acceptable for a given subsection, but the heading must appear.

Subsections to fill (names verbatim from the template):

- Run identity (carry from Part A; add iar-specific rows: **iar revision** (from `IAR_REVISION`), session number, cluster subset processed, `include_terminal` flag value, primary-pass wall time, second-pass wall time, gates run)
- Did the TL;DR block tell the truth? (evidence from EXECUTION_LOG)
- Cluster sizing honesty (compare Est. session size to actual wall time)
- Was the Suggested session approach useful?
- `Depends-on` edges in practice (did they hold? were any informally-unblocks edges load-bearing after all?)
- Scope-expansion events (every incidental-fix entry from EXECUTION_LOG)
- Deferred items (every showstopper that ended as `defer` or `partial`)
- Findings the report missed entirely (clusters whose fix surfaced bugs the analyst didn't flag)
- Findings the report had that didn't matter (e.g., an already-fixed flagged issue)
- Tooling reality (how gates behaved; any pinned-version surprises)
- **Cross-cluster themes that emerged during fix work.** Read `{report-dir}/.scratch/implement-themes.md` (written by Step 2's theme detector). Reproduce each detected theme verbatim as a nested block. If the file is empty or does not exist, write `_none detected this session_` — mandatory subsection, but `none` is acceptable. Detected themes feed both v-next audiences; the `Surface:` field on each theme points at whether cda synthesis, iar preflight, or project docs should absorb the change, and the subsequent `cda v-next:` / `iar v-next:` bullets may reference themes by tag for traceability.
- Cross-session observations (when `session_number > 1`): what did this session learn that the earlier session(s) already covered or contradicted? Name the prior session explicitly by its heading. If this is session 1, omit this subsection.
- **Suggestions for codebase-deep-analysis v-next** (0–10 concrete items). Each item starts with `**cda v-next:**` and names a change the *report-producer* skill should make — e.g., a missing checklist category surfaced by the fix work, a cluster-frontmatter field that was ambiguous, a synthesis rule that over- or under-filtered. `0 items` is acceptable when this session's evidence is entirely about iar, not cda.
- **Suggestions for implement-analysis-report v-next** (3–10 concrete items, MANDATORY). Each item starts with `**iar v-next:**` and names a change the *fix-coordinator* skill should make. This subsection is mandatory — every run surfaces at least three frictions (if only papercut-level). If you cannot find three, re-read the EXECUTION_LOG; something is always suboptimal. Examples of iar v-next items:
  - **iar v-next:** preflight did not detect `bun test --coverage` because the package.json script was named `coverage:run` not `test:coverage`; `references/gate-detection.md` "typecheck" section's key-matching logic needs a corresponding broader pattern.
  - **iar v-next:** cluster 03 was `Autonomy: autofix-ready` but the subagent hit shape B on finding 2 because the `Fix:` line referenced a variable that had been renamed since the report was generated; iar could pre-flight-check for drift by running `rg` on the `Fix:` targets before dispatching.
  - **iar v-next:** `PREFLIGHT_DECISIONS.session_number` scan was slow (~3s) on a report with 14 prior Part B sections because the regex walked every line; cache the max session-number in `.scratch/implement-run.log` header.

## Output location

Append to `{report-dir}/analysis-analysis.md`. Behavior depends on the file's current state:

- **Cda Step 6 placeholder present, no prior session.** Replace the empty Part B placeholder with this session's filled section (heading + body per the template).
- **Prior session(s) exist.** Append this session as a new `## Part B — Fix coordinator retrospective (session N, ...)` section after the last existing Part B section, separated by a blank line. Never edit a prior session.
- **No Part B section exists (older cda report without Step 6).** Append a new section at the end of the file with this session's heading, prefixed by a one-line note: *"Note: Part A missing from this report (older cda version). Runner context unknown."*

Part B sections live next to Part A, not under `.scratch/`, so anyone reviewing the report finds every retrospective together.

## Common mistakes

- **Postponing.** By the time the next invocation rolls around, the details are gone. Write Part B immediately after the last cluster hits a terminal state.
- **Copying Part A's shape into Part B.** Part A is the runner retrospective (does synthesis over-filter?). Part B is the fix coordinator retrospective (did the cluster files tell the truth once we tried to implement them?). Different audiences, different questions.
- **Overwriting a prior session's Part B.** Every iar run writes its own Part B section. Prior sessions are immutable. A resumption run that overwrites an earlier session's retrospective destroys RED-phase evidence the next iar version needs.
- **Skipping the iar revision.** `IAR_REVISION` is mandatory in the session heading. Without it, the v-next author cannot diff the critiqued behavior against the exact code. Write `version:unknown` only if every fallback chain step genuinely failed, and explain in Run identity why.
- **Mixing data across sessions.** A single Part B section reflects only that session's work. If session 2 discovers that session 1's closed cluster is actually broken (drift re-check via `include-terminal: true`), it's session 2's observation — not a retroactive edit of session 1's section.
- **Leaking project identity.** Even a throwaway code snippet can de-anonymize. When in doubt, replace with `<generic-shape>`.
- **Writing advice instead of evidence.** "Be more careful with autonomy flags" is useless. "Cluster 03 was marked autofix-ready but the third finding required deciding between two valid approaches; the subagent correctly returned shape B; v-next iar should prefer shape B more aggressively when the Fix: line uses hedging language" is useful.
- **Skipping the iar v-next subsection because "nothing went wrong".** Every run surfaces frictions, even on perfect paths. If you genuinely cannot find three iar-specific items after a clean run, the bar is "what would have gone subtly better, or what would shorten next time's runtime, or what rough edge is one papercut away from being a problem". Mandatory means mandatory.
- **Mixing audiences in one bullet.** Keep `cda v-next:` and `iar v-next:` bullets strictly separated. A finding about a cluster's Fix: line drift is cda's problem (reports drift with code); a finding about iar not detecting the drift before dispatch is iar's problem. Often the same underlying issue has one bullet for each audience — that's fine, write both.
