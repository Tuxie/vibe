# `analysis-analysis.md` template

**Purpose:** this file is the retrospective on the `codebase-deep-analysis` skill itself, written from the inside of a real run. It is the **primary input to the next version of the skill**. The v-next author (Claude, reading this file cold) will use it the way the v2 author used `tips-from-runner.md`: as the RED-phase documentation of what failed, what surprised, and what to change.

Two authors write two parts:

- **Part A — Runner retrospective.** Written by the orchestrator at the end of Step 5, before handing the report to the user. The runner has just driven every step of the skill and knows exactly where friction lived, which references got consulted vs. ignored, and where the template underdetermined or overdetermined the work.
- **Part B — Fix coordinator retrospective.** Appended by whoever drives the fix sessions that consume the cluster files — usually days or weeks later. The fix coordinator knows whether cluster sizing was honest, whether the `Suggested session approach` block matched reality, whether `Depends-on` edges held up, whether deferred items stayed deferred for the right reasons.

Both parts are **addressed to a specific reader**: the person or agent authoring `codebase-deep-analysis` v-next. Write to them, not to the user of the current report. Do not rewrite content that already lives in the frozen report — this file exists to critique the skill, not to summarize findings.

**The v-next reader has no access to the analyzed codebase** and usually no prior context about it — different user, different repo, possibly private. Write the retrospective so it stands alone for someone who will never see the project:

- **Anonymize project specifics.** Do not name the repo, company, product, internal services, real file paths, real module names, real identifiers, real URLs, real stack names that would pinpoint the project, or distinctive domain vocabulary. Replace with generic stand-ins (`the repo`, `a payments-adjacent service`, `module-A`, `src/foo/bar.ts`, `an internal auth lib`) and keep the stand-in consistent within a bullet so structure stays readable.
- **Strip secrets and sensitive findings.** No credentials, tokens, hostnames, IPs, customer names, real CVE write-ups tied to this code, or any vulnerability detail specific enough to exploit. If a security finding is the reason a retrospective bullet exists, describe the *class* of finding and the skill's behavior around it (`the security analyst missed an authz-bypass class that presented as {generic shape}`), not the exploit.
- **Keep calibration signal intact.** Tier, stack family (e.g., "Python web backend + TypeScript SPA"), rough size (`~30k LOC`, `~180 analyst findings`), analyst token counts, wall time, and retention of which references/steps misfired are all safe and load-bearing. Do not anonymize them away.
- **When in doubt, generalize.** A v-next change grounded in "on a T2 polyglot repo with an ORM-heavy data layer, the DB analyst's schema-drift checklist overfired on generated migrations" is just as actionable as the named version and carries no leakage risk.

---

## Writing rules (for both parts)

- **Be specific with anchors.** "The scout prompt was too long" is not actionable. "The scout prompt's Tech-stack section ran 140 lines on a polyglot repo and blew the 500-line total budget" is actionable.
- **Quote prompt/template text when critiquing it.** `references/foo.md` + the exact line that misfired > vague recollection.
- **Name what worked, too.** Only saving corrections is how a skill drifts toward risk-aversion. If the tier filter, analyst parallelism, or cluster-hint vocabulary held up under pressure, say so — the v-next author will otherwise assume nothing is stable.
- **Token costs: real numbers or the best estimate.** "Burned a lot of tokens" is useless; "Security analyst on Opus produced 47k output tokens; other analysts averaged 12k each" is useful calibration.
- **One-paragraph ceiling per bullet.** If a point needs more, it probably has ≥2 distinct points inside it — split.
- **Suggest concrete v-next changes where you can.** Not every critique has an obvious fix; say so when that's the case.
- **Do not duplicate `tips-from-runner.md`-style general advice.** That file is project-agnostic. This file is run-specific: what this codebase, this tier, this stack surfaced about the skill.

---

## Part A — Runner retrospective

Fill this section at the end of Step 5, immediately after the report renders and before the token-saving context decay. You have the freshest memory of the run here — do not put it off.

### Run identity

```
Repo: {generic descriptor — e.g., "T2 Python+TS web app, ~40k LOC, ORM-heavy"; do NOT name the project}
Stack family: {e.g., "Django + React SPA + Postgres"}
Project tier called by Scout: {T1|T2|T3}
Skill revision: {identifier for the skill version that produced this run, captured via the SKILL.md Step 6 fallback chain. Format: `<source>:<value>`. Sources: `sha:<short-sha>` (when `.git/` present), `version:<VERSION-file-contents>` (plugin cache), or `skill-md-hash:<8-char-sha256>` (last resort). Example: `version:3.0.0`.}
Skill source: {repo slug or URL the skill was loaded from, e.g., "tuxie/vibe @ plugins/codebase-deep-analysis"}
Report directory: docs/code-analysis/{stem}/   (path-shape only; no project-specific segments)
Analysts dispatched: {list}
Analysts skipped: {list with reason}
Step 3.5 consent: {granted | declined | static-only | skipped}
Total wall time, approximate: {N minutes}
Total output tokens, approximate: {sum across analysts}
```

The **Skill revision** line is mandatory. V-next needs to diff the behavior described here against the exact code of the skill that produced it; without the identifier every critique is guesswork. Capture it at the *start* of the run (Step 0) and paste it here — not at the end, by which time the working tree may have drifted. Use the fallback chain in SKILL.md Step 6: prefer `sha:` (git), fall back to `version:` (VERSION file), last-resort `skill-md-hash:` (sha256 of SKILL.md). A plain short-SHA without a prefix is accepted for backwards compatibility with v2 reports but disfavored — prefix it.

### What worked

Three to eight bullets. Focus on the parts of the skill that performed as designed or better. Be specific about which step/reference did the work.

- Example shape: "The right-sizing filter caught {N} findings that would have been noise on a T{N} repo — without it, the report would have been {N} findings longer and {unhelpful in what way}."
- Example shape: "Cluster-hint vocabulary stayed to {N} distinct slugs across {M} analysts; clustering assembled cleanly with zero manual reshaping."

### What was friction

Three to eight bullets. Each bullet names the step or reference file at fault, the symptom, and whichever rationalization you used to work around it.

- Example shape: "`references/X.md` section Y said {quote}; I read it as {interpretation A} but the intent was clearly {interpretation B}. I resolved by {workaround}. V-next: rewrite the section to make B unambiguous."
- Example shape: "Step N's instruction to {do thing} assumed {assumption} which didn't hold because {repo reality}. I improvised by {what I did}. V-next: either weaken the assumption or describe the fallback explicitly."

### Under-sized guidance

Where did the skill tell you **too little** and you had to invent? Name the decision you had to make without instruction support. These are the most valuable notes for v-next — they are genuine gaps, not preference differences.

### Over-sized guidance

Where did the skill tell you **too much** and the extra instruction pushed you toward worse output? Common failure modes: over-specified templates that don't fit this stack, mandatory sections that rendered empty, rigid ordering that fought the natural shape of the findings.

### Token and cost reality

- Which analyst was the largest single cost? Was it expected?
- Did any analyst under-run its budget so far that its output was suspiciously thin? (A Security analyst that returns two findings on a T2 repo usually means something went wrong with dispatch.)
- Did re-dispatch (synthesis §10) fire? If so, what triggered it, and was the re-dispatch productive?
- If you had to re-run one analyst with different instructions, which one and why?

### Tier calibration

- Did the Scout's tier call match what the rest of the run discovered? If an analyst's evidence contradicted the tier, was the contradiction surfaced and resolved?
- Were the min-tier tags on checklist items pitched correctly for this stack? Stacks often imply tier-specific expectations (e.g., Rust repos without `clippy` at T2 is a bigger smell than Node without `eslint` at T2).
- Did "tier as a confidence boost" (agent-prompt-template: autofix-ready rather than needs-decision on T2+ with explicit intent) fire where expected? If not, was the intent evidence too subtle for the analyst to pick up?

### Applicability-flag calibration

For each applicability flag the Scout set (`backend`, `frontend`, `database`, `tests`, `security-surface`, `tooling`, `docs`, `container`, `ci`, `iac`, `monorepo`, `web-facing-ui`, `i18n-intent`), was the flag **correct in hindsight**, and if not, what evidence should have flipped it? Collecting these per-run builds a calibration corpus for v-next.

### Docs-drift flag accuracy

- Did the Scout's `Docs drift: likely-drifted` calls match what the Docs analyst actually found?
- Were there drift cases the Scout missed?
- Was the 30d/90d threshold in `structure-scout-prompt.md` "Load-bearing instruction-file drift" correct for this repo's commit rhythm? Say so explicitly — the threshold is a guess that needs calibration evidence.

### Pre-release surface accuracy

If the Scout recommended a pre-release checklist, was the recommendation correct? If the Scout did not recommend one, should it have?

### Step 3.5 reality check

(Skip this subsection if Step 3.5 was declined or skipped — note "not run" and move on.)

- Did the detected coverage/bench commands match the right targets?
- Did the dynamic pass produce findings the static pass missed? If not, the gate paid no dividend this run and the v-next author should think about whether to keep the dynamic pass at all.
- Did anything the dynamic pass ran mutate state despite the "read-only" intent? (e.g., a coverage target that generated a new file in the repo, or a bench target that wrote to a cache dir.)

### Cluster-assembly reality check

- Number of clusters produced: {N}
- Cluster size distribution: {min/median/max findings}
- How many clusters exceeded the soft cap of 10 findings? Were they actually split per synthesis §6, or did the cap get stretched?
- Were any `misc-{severity}.md` fallback clusters produced? (If yes, the cluster-hint vocabulary was too sparse — note for v-next.)
- Any clusters that should have been merged but the hybrid procedure kept separate?

### Noise, drops, and regrets

- Was there a finding the skill's filter dropped that you (or the user) later wished had been kept? Name it, locate it if you can, and explain which filter rule dropped it.
- Was there a finding the skill's filter kept that was clearly inactionable noise? Name it and say which filter rule should have caught it.

### Instructions to the v-next author

Close Part A with a short list — 3 to 10 bullets — each starting `**V-next:**` followed by a concrete change to a specific file in the skill. Example:

- **V-next:** `references/synthesis.md` §6 step 3 says "split at >12"; make it ">10 with at least one Critical/High; >12 otherwise" — on this run the single-tier-T3 cluster at 11 findings should have split but didn't.
- **V-next:** `references/agent-prompt-template.md` "Autonomy guide" needs an example of the tier-as-confidence-boost rule firing correctly; the current paragraph is ambiguous enough that I applied it inconsistently across analysts.

---

## Part B — Fix coordinator retrospective

Fill this section after the last cluster from this report has been resolved, deferred, or is stuck behind something outside the fix coordinator's control. If the report is still live at the next invocation of the skill, write what you have and flag the rest as open.

### Run identity (carry from Part A)

Re-state the Part A identity block (same anonymization rules) plus the fields below. If fix work spanned a skill upgrade, record the **fix-time skill revision** in addition to the run-time one — a divergence between the two is itself useful signal for v-next.

```
Skill revision at report time: {short SHA, copied from Part A}
Skill revision at fix time: {short SHA of skill HEAD when fix work concluded, if known}
Report directory: docs/code-analysis/{stem}/
Clusters at start: {N}
Clusters closed: {N}
Clusters in-progress: {N}
Clusters deferred: {N} (see not-in-scope.md "Deferred this run")
Clusters resolved-by-dep: {N}
Span of fix work: {first commit date} → {last commit date}
```

### Did the TL;DR block tell the truth?

For each closed cluster, did the TL;DR `Impact:` line predict the actual effect of landing the fix? Undersold impact is fine; oversold impact is a skill failure (the summary is supposed to help users pick the right cluster to work on).

### Cluster sizing honesty

- For each closed cluster, record the actual session size vs. the estimated size (Small/Medium/Large).
- If actuals consistently landed one bucket higher than estimates, the skill's estimation heuristic is under-calibrated — call it out.

### Was the `Suggested session approach` useful?

- Which cluster's approach block got followed closely and worked?
- Which cluster's approach block got ignored — and was that the right call?
- Any cluster where the approach block misled the fix session in a costly way?

### `Depends-on` edges in practice

- Did any cluster close and incidentally resolve a `Depends-on:` finding in a downstream cluster? (The `Status: resolved-by-dep` path from synthesis §11.)
- Did any `Depends-on:` edge turn out to be wrong — the downstream finding survived its upstream cluster's merge when the edge implied it shouldn't?
- Were there implicit dependencies the analyst missed — two clusters that should have named each other?

### Scope-expansion events

For each cluster where fix work touched code outside the cluster's listed files:

```
- Cluster {NN}: touched {N} extra files under {path} to unblock {gate}.
  Legitimate per synthesis §12? {yes | no | debatable — explain}
  Commit used an `Incidental fixes` heading? {yes | no}
```

If scope expansion fired and the commit message didn't use the `Incidental fixes` convention, that's a skill-readability failure even if the expansion itself was right — flag for v-next.

### Deferred items

For each `[~] deferred` item, record what the tracking location now says:

- Still deferred on purpose (good outcome) — {N}
- Forgotten / untracked (bad outcome — the tracking location went stale) — {N}
- Resolved anyway — {N}
- Turned out to be a mis-classified `[?]` that needed analysis, not a decision — {N}

The last bucket is the important one for v-next: if deferrals keep turning out to be inconclusive analyses in disguise, the `[?]` vs `[~]` boundary in synthesis §8 needs sharper language.

### Findings the report missed entirely

The most valuable note in Part B. During fix work, did you hit bugs, smells, or antipatterns that should have been in the report and weren't? For each:

- Name the finding.
- Identify which analyst's scope it fell under.
- Propose what checklist item or prompt change would have caught it.

A pattern of misses in one analyst's scope is a v-next priority. A pattern of misses that span analysts suggests a missing analyst or a missing checklist category.

### Findings the report had that didn't matter

Mirror of the previous section: which findings, once looked at with fix-work context, were real but too low-impact to be worth the cluster cost? These are candidates for tightening the right-sizing filter in synthesis §3.

### Tooling reality

- Did `scripts/render-status.sh` work on the first try? Any manual edits you ended up making to the README index anyway?
- Did any cluster-file frontmatter fail to parse? (If yes, name the file and the fix.)
- Any other infra friction the skill's scripting/templating introduced.

### Instructions to the v-next author

Close Part B with a short list — 3 to 10 bullets — each starting `**V-next:**` followed by a concrete change. Prefer changes grounded in the gap-between-report-and-reality findings above; those are the highest-signal. Example:

- **V-next:** Add an `API-5` checklist item for "Handler returns a 200 with error payload in the body" — the fix work on this run surfaced 4 instances, none of which the existing API-1..API-4 captured.
- **V-next:** `references/report-template.md` cluster template's `## Commit-message guidance` currently says "name the cluster slug and date on the first line"; on this run that format collided with our Conventional Commits setup. Either document a fallback for CC repos or loosen the requirement.

---

## Rendering and storage

- File path: `docs/code-analysis/{stem}/analysis-analysis.md` — alongside README.md, not buried under `.scratch/`.
- The orchestrator creates the file with Part A filled in and Part B left as the empty template above.
- After fix work, whoever coordinated the fix sessions appends Part B in place, commits, and optionally copies the file to the skill repo (where the v-next author will read it).
- The file is not auto-regenerated by any script. It is hand-written on purpose — the v-next author needs honest prose, not derived metrics.
