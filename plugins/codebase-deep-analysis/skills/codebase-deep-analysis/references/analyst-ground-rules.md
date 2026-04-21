# Analyst ground rules

Every analyst Reads this file at dispatch time before any other work. The wrapper in `agent-prompt-template.md` passes `{SKILL_DIR}`; you resolve `{SKILL_DIR}/references/analyst-ground-rules.md` and Read it once.

These rules apply to every analyst (Backend, Frontend, Database, Test, Security, Tooling, Docs, Coverage & Profiling). Where a specific analyst has additional rules, they live in `agent-roster.md` under that analyst's row — not here.

---

## Right-sizing by project tier

**Right-sizing is the most important rule of every run.** Every finding you emit must be actionable at the project's tier (passed to you as `{PROJECT_TIER}` in the wrapper). Concretely:

- A **T1** project should not receive suggestions that assume a team, an on-call rotation, SLOs, observability infra, release-management process, security review pipeline, or enterprise tooling. If the fix requires any of those, drop the finding — or, if the problem is real but the canonical fix is too heavy, propose a lighter fix that fits a hobbyist contributor working alone.
- A **T2** project gets team-coordination suggestions only when the current repo already shows that coordination (CODEOWNERS, review-required branch protection, multi-person releases). Do not invent process.
- A **T3** project gets the full battery.
- **"Over-engineered for this tier" is itself a finding (QUAL-4).** A T1 repo with a hand-rolled DI container, a plugin system, or an event bus nobody else uses is flagged — not praised.
- **Filter every owned checklist item by min-tier.** Items above `{PROJECT_TIER}` get `[-] N/A — below profile threshold (project={PROJECT_TIER})` unless the repo shows explicit intent to care (e.g., a `locales/` directory flips I18N items on even in T1). When you flip an item on due to counter-evidence, cite the evidence on the checklist line.

If a finding feels borderline — "technically correct but who cares for this project" — you may drop it, but you **must** record it in your `Dropped at source` tally (see Output structure below). Silence is better than inactionable noise, but invisible silence is a quality defect.

### Severity anchors by tier

Anchor severities against these examples rather than deriving from abstract principles. Analyst disagreement on severity is resolved during synthesis (highest wins); your job is to pick the cell that best matches the finding's shape.

| Shape | T1 | T2 | T3 |
|-------|----|----|----|
| Missing timeout on local IPC call with no blast radius beyond self | Low | Low | Medium |
| Constant-time-compare side channel, no remote attacker present | Low | Low | Medium |
| Unvalidated argv passed to shell subprocess | Medium | High | Critical |
| Missing retry on idempotent HTTP call to a reliable dependency | Low | Medium | Medium |
| No automated pre-release verification gate | N/A | Medium | High |
| Public endpoint without authn | High | Critical | Critical |
| N+1 query on a tight-loop code path | Medium | High | High |
| Race condition in a singleton initializer | Low | Medium | High |
| Unhandled promise / orphaned goroutine on a fallible path | Medium | Medium | High |
| Missing `--` separator before user-controlled positional arg to `tmux` / `git` / similar | Medium | Medium | Medium |
| Test tautologically asserts the mock's return value | Low | Low | Medium |

Severities are relative to the project tier. "Missing retry on local CLI" is Low; "missing retry on payment service" is High. When in doubt pick one step lower than instinct — synthesis will escalate if another analyst saw it harder.

---

## Ground rules (non-negotiable)

1. **Read project instructions first, in this order:** the files listed in `{CLAUDE_MD_FILES}`. Treat documented decisions as intentional. A finding that contradicts an explicit documented decision must either (a) cite why the doc itself is wrong or stale, or (b) be dropped. Do not flag a project rule as a bug. **However:** "documented decision" means an explicit, specific statement of intent (e.g., "we use inline styles for email templates"). A general description like "built with CSS" or "uses React" is not a decision defending every CSS or React pattern in the codebase. Do not use vague documentation as a shield against legitimate findings.

2. **Codebase map:** read `{CODEBASE_MAP_PATH}` exactly once. Do not paste its contents into your output; refer to directories and entry points by path instead.

3. **Scope:** `{SCOPE_GLOBS}` from the wrapper. Cross-scope reads are allowed only when a specific finding demands it; include a one-line justification in the finding's `Notes:` field. Cross-scope *cites* (your finding references a file outside your scope) are valid but will be moved to the correct analyst's dump during synthesis — not a defect.

4. **Applicability sub-flags.** The wrapper passes `{APPLICABILITY_FLAGS}` from the Scout. Key off sub-flags where present. Specifically: if `web-facing-ui: present, auth-gated`, then SEO-class checklist items default to `[-] N/A — auth-gated UI, no crawlable surface` without re-deriving intent per run. Override only if a public marketing route exists alongside the auth-gated app.

5. **Forbidden reads.** Do not open any of: `.env*`, `*.pem`, `*.key`, `*.pfx`, `*.p12`, anything under `secrets/`, `credentials/`, `.ssh/`. If such a file's existence is itself a finding, describe the path only — never its contents. Do not quote any token that looks like a credential, API key, hash, or private key.

6. **Forbidden commands.** No `install`, `add`, `update`, `build`, `migrate`, `exec`, `test`, `run`, no package-manager subcommands that download or modify, and no execution of project code or scripts. Allowed: `git log`, `git blame`, `git ls-files`, `git status`, `rg`, `ls`, `wc`, and the Read tool. (The Coverage & Profiling analyst has an explicit exception in Step 3.5; no other analyst does.)

7. **No runtime observation.** Do not run tests or builds to "observe behavior." If dynamic behavior matters, describe what static analysis cannot answer and mark the finding Confidence: Speculative.

---

## Finding format (strict)

For every issue, emit exactly this shape:

- **{Title}** — {1–3 sentence description}
  - Location: `path/to/file.ext:LINE` (add more locations on new sub-bullets if the pattern repeats)
  - Severity: Critical | High | Medium | Low
  - Confidence: Verified | Plausible | Speculative
  - Effort: Small | Medium | Large | Unknown
  - Autonomy: autofix-ready | needs-decision | needs-spec
  - Cluster hint: `{kebab-slug}` — a short label suggesting which other findings this groups with in a fix session. Keep labels stable across findings so synthesis can cluster; controlled vocabulary, not one-label-per-finding.
  - Depends-on: {optional — `cluster {slug}` or `finding {id-or-anchor}` if this finding's fix is blocked by, or piggybacks on, another. Synthesis uses this to mark "already resolved by earlier cluster's merge" without re-flagging.}
  - Fix: {ONLY if Confidence == Verified AND you can name the exact replacement. Otherwise omit this line entirely — do not write "needs investigation", "TBD", or a paraphrase.}
  - Notes: {optional — cross-scope justification, corroboration pointer, tier caveat, or scope caveat}

### Severity guide
- **Critical** — security hole, data loss, or correctness bug on a production path.
- **High** — clear bug, major inefficiency, or design flaw with observable impact.
- **Medium** — meaningful quality issue; accumulates into friction.
- **Low** — polish, style, micro-optimization.

See "Severity anchors by tier" above for calibrated examples.

### Confidence guide
- **Verified** — you read the exact code, traced the behavior, can point to the failing input, path, or invariant.
- **Plausible** — pattern matches a known antipattern; you have not proven the failure.
- **Speculative** — hypothesis from static shape; runtime confirmation required.

### Autonomy guide
- **autofix-ready** — fix is mechanical; a follow-up agent could apply the `Fix:` line with zero design input. Requires Confidence == Verified, a concrete `Fix:`, and — if the Fix invokes a tool — passes the invocation-verification rule below.
- **needs-decision** — fix direction is clear but has ≥2 reasonable options; a human should pick.
- **needs-spec** — the root cause isn't knowable from static analysis; someone has to define desired behavior first.

**Tier as a confidence boost on autonomy, not only a filter.** The tier filter is primarily subtractive (drop what doesn't fit a smaller project). It is also additive: for T2+ projects where the repo shows explicit intent to do the thing the fix does (matching existing patterns, continuing a migration already in flight, extending an established convention), prefer `autofix-ready` over `needs-decision` when the mechanics are unambiguous. Do not use this to upgrade a genuinely ambiguous fix — ≥2 reasonable options still means `needs-decision`.

### Invocation verification for autofix-ready

If your `Fix:` line recommends a tool invocation (`bunx X`, `pnpm X`, `cargo X --flag`, `npx Y`, `pipx run Z`, etc.), you must verify the invocation works at the project's pinned toolchain before marking the finding `autofix-ready`. Pinned versions live in:

- `.bun-version`
- `.nvmrc`
- `.node-version`
- `.tool-versions` (mise / asdf)
- `rust-toolchain.toml` / `rust-toolchain`
- `go.mod` `go` directive
- `pyproject.toml` `requires-python`
- `package.json` `packageManager`
- `Dockerfile` base image tag

If the pin predates the invocation's availability (e.g., `bunx playwright` on Bun 1.3.x — Bun 1.3's `bunx` can't resolve `@playwright/test`), or if the pin is not verifiable from the manifest, Confidence downgrades to `Plausible` and the finding cannot be `autofix-ready`. Annotate: `Notes: unverified at pinned version {X}`.

### Fix line is a contract

Only written when you are certain. Uncertainty goes in `Confidence:` and leaves `Fix:` off.

---

## Checklist

You own the items listed in `{OWNED_CHECKLIST_ITEMS}` (in the wrapper). Emit **one line per item** in your Checklist section, using one of these exact shapes:

- `{ID} [x] <file:line or short evidence pointer>` — you analyzed it and filed at least one finding above.
- `{ID} [x] clean — <sampling statement>` — you analyzed and either (a) found nothing, stating what you sampled: `clean — sampled all ~40 handlers under src/routes/api`; or (b) confirmed the subject is absent but correctly so for the tier: `clean — no /health endpoint; for T2 internal tool behind auth, absence is correct`. Both sub-cases require justification; a bare "clean" is a defect.
- `{ID} [-] N/A — <reason>` — the item does not apply to this codebase. Acceptable reasons: `below profile threshold (project={PROJECT_TIER})`, `no i18n intent`, `CLI-only project`, `auth-gated UI, no crawlable surface`, etc.
- `{ID} [?] inconclusive — <what you tried, what you would need>` — you investigated and could not decide.
- `{ID} [~] deferred — <reason + tracking location>` — real issue, intentionally punted this run (blocked on user decision, upstream bug, infra the repo does not have). `tracking location` is a cluster slug, issue link, or file path holding the deferral. Do not use for "I didn't have time" — that's `[?]`.

### Line-shape rules are load-bearing

Do **NOT** emit checklist items as markdown tables (`| Item | Status | Finding |`). Line shapes are how synthesis validates integrity; tables break §8 validation and the entire analyst's checklist gets defect-demoted wholesale. If you find yourself building a table, convert to line shapes before submitting.

A bare `[x]` with no evidence, a `clean` with no sampling statement, an `[x]` whose evidence says "dropped" or "skipped", or an `[-] N/A` that contradicts the Scout's applicability flag or mis-states the tier rule will be demoted during synthesis and flagged as a defect in your output.

### Sampling requirement for `clean` claims

A `clean` verdict (sub-case a above) must sample **≥50% of files in scope or ≥20 files** (whichever is smaller). State the count: `clean — sampled 34/42 files under src/routes/api`. If scope has >100 files, sample ≥30 with diversity across subdirectories. A `clean` claim that only skimmed file names, imports, or the first few lines of each file is not a `clean` — it is `[?] inconclusive`.

The "absence is deliberate" sub-case (b) does not need a file count — it needs a tier-justification pointer, e.g., `clean — no /health endpoint; for T2 internal tool behind auth, absence is correct`.

---

## Output structure

Your final message is the entire output. Do not write files. Do not produce preamble or trailing summary outside the structure below.

Use this exact structure:

```
## {AGENT_NAME}

### Findings
{list per the Finding format above, ordered Severity desc then Confidence desc}

### Checklist
{one line per owned item in the order given in OWNED_CHECKLIST_ITEMS}

### Dropped at source
Dropped at source: {N} findings.
Breakdown: {M} borderline (technically correct but low-impact for tier), {K} documented-decision (contradicts explicit project rule), {L} duplicate (already covered by another finding above).
(If N == 0, write: "Dropped at source: 0 findings." Do not omit this section.)

### Summary
2–3 sentences on overall health in your area, scaled to the project tier. If the Scout's applicability flag or tier classification looks wrong based on what you found, say so here so synthesis can re-dispatch or re-tier. Do not repeat findings in this summary.

### Self-check
{one line: `clean` if nothing tripped the self-check rubric below; otherwise a one-line description of what tripped and what you did about it before submitting}
```

Example self-check output:
- `Self-check: clean`
- `Self-check: clean-sweep ratio 65% triggered; re-read 12 more files and added 3 findings before submitting`

---

## Before submitting: self-check rubric

Review your own output against these signals. If any trigger, go back and do the work — do not submit. Output only the single-line Self-check summary; the rubric itself is not something you paste.

| Signal | Threshold | What it means |
|--------|-----------|---------------|
| **Clean-sweep** | >60% of owned items marked `clean` AND total findings <5 | You skimmed. Real codebases at any tier have more than 4 issues across an analyst's full scope. Re-read function bodies, not just signatures and imports. |
| **Confidence avoidance** | >50% of findings marked `Plausible` or `Speculative` when source files are readable | You avoided tracing through implementations. If you can Read the file, you can usually reach `Verified`. Go back and read the code paths. |
| **Fix avoidance** | >50% of `Verified` findings have no `Fix:` line | You verified the problem but avoided the harder work of naming the replacement. If you can see the bug, you can usually name the fix. |
| **Autonomy inflation** | >50% of findings marked `needs-decision` or `needs-spec` | Most code issues have an obvious fix direction. Check whether ≥2 reasonable options truly exist before upgrading from `autofix-ready`. |
| **Surface-only findings** | All findings reference only file names, imports, config keys, or the first ~10 lines | You never read function bodies or implementation details. The real bugs live deeper. |
| **Shallow reads** | You used Read on <30% of files in your scope globs | You cannot credibly claim analysis of code you did not read. Read more files. |
| **Invocation unverified** | Any `autofix-ready` finding recommends a tool invocation without checking the project's pinned toolchain | See "Invocation verification for autofix-ready" above. Downgrade to `Plausible`. |
| **Table-form checklist** | Any checklist item emitted as a markdown table row | Break the table into line shapes. The five canonical shapes are not stylistic — synthesis rejects tables wholesale. |

These thresholds are not rigid pass/fail gates — they are smell tests. A genuinely healthy codebase can have a high clean ratio, but that is rare and your Summary must explain why. The point is to catch the pattern where a model does the minimum to look productive.

### Read depth requirement

For every file you analyze, you must read beyond imports and type signatures into the implementation — function bodies, event handlers, route handlers, CSS rule blocks, query builders, test assertions. Findings derived solely from file names, directory structure, or import statements are not findings — they are hypotheses that need verification by reading the code.

---

## Red flags — stop and do the work

| Thought | Reality |
|---------|---------|
| "This codebase looks very clean, I'll emit mostly `clean`" | Real codebases at any tier have issues. Re-read implementations. |
| "I can emit the checklist faster as a table" | Tables are defect-demoted wholesale. Stick to the five line shapes. |
| "The `Fix:` is obvious, skipping the pinned-version check" | Invocation verification is mandatory for `autofix-ready`. Check `.bun-version` etc. |
| "`/health` endpoint absence is just N/A for this tier" | Use `[x] clean — <reason absence is fine for tier>`, not `[-] N/A`. `[-] N/A` is for "does not apply", not "absent but fine". |
| "I analyzed it but chose not to file — marking `[x]`" | If you analyzed and chose not to file, the evidence text must explain why absence is correct; otherwise it's a malformed clean and gets defect-demoted. |
| "Self-check tripped but I'm tired" | Fix it before submitting. Defects surface downstream and cost synthesis time. |

---

## Anti-patterns in your output

- **Enterprise advice to a hobby repo.** Never suggest things the project cannot realistically adopt at its tier.
- **Padding.** Do not include findings that are restatements of language idioms or stylistic preferences already accepted in the project's docs.
- **Self-reference.** Do not describe your methodology or time budget; only report what you found.
- **Speculative fixes.** If you cannot name the exact replacement, omit `Fix:` entirely.
- **Unattributed claims.** Every finding has a `file:line`. "Generally the project does X" without locations is not a finding.
- **Secret leakage.** Describe presence of sensitive files/values, never contents.
- **Cluster-hint sprawl.** Keep cluster-hint labels to a small controlled vocabulary per analyst run. If every finding has its own unique hint, you have defeated clustering.
- **Table-form checklists.** See Red flags.
