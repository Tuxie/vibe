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
| Extracting an ID/status from message text when a structured field exists | Medium | Medium | High |
| Returning prose-only data that downstream code must parse for machine values | Medium | Medium | High |
| Missing retry on idempotent HTTP call to a reliable dependency | Low | Medium | Medium |
| No automated pre-release verification gate | N/A | Medium | High |
| Public endpoint without authn | High | Critical | Critical |
| N+1 query on a tight-loop code path | Medium | High | High |
| Race condition in a singleton initializer | Low | Medium | High |
| Unhandled promise / orphaned goroutine on a fallible path | Medium | Medium | High |
| Sleep/poll loop used where an event/completion signal exists | Low | Medium | High |
| CI tests source code but releases an untested packaged artifact | Medium | High | Critical |
| Missing `--` separator before user-controlled positional arg to `tmux` / `git` / similar | Medium | Medium | Medium |
| Test tautologically asserts the mock's return value | Low | Low | Medium |

Severities are relative to the project tier. "Missing retry on local CLI" is Low; "missing retry on payment service" is High. When in doubt pick one step lower than instinct — synthesis will escalate if another analyst saw it harder.

### Local-first calibration

If the Scout's applicability flags include `web-facing-ui: present, local-only` (desktop app, localhost-only dev server, LAN-only tool), apply these anchors **instead of** the generic public-surface ones for any network-boundary finding. Local-first tools have a different attacker model: the attacker is either on the same host (very limited attack value) or on the same LAN (intentional for some use cases, accidental for others).

| Shape | T1 local-first | T2 local-first | T3 local-first |
|-------|----|----|----|
| HTTP API bound to `0.0.0.0` by default (unintentional LAN exposure) | Medium | High | High |
| HTTP API bound to `127.0.0.1` by default, `--host` flag available for explicit opt-in | Low | Low | Medium |
| Endpoint accepts user argv → subprocess on localhost | Medium | High | Critical |
| Path traversal in user-uploaded filename (local-only server) | Medium | High | High |
| Missing authn on endpoint reachable only via loopback | Low | Low | Medium |
| Missing authn on endpoint reachable via LAN binding | Medium | High | High |
| CORS misconfigured (e.g., `*` origin) on local-only API | Low | Medium | Medium |

Reasoning: a local-first tool that unintentionally binds `0.0.0.0` elevates attack surface from "code running as the user on their own box" (near-zero marginal risk) to "anyone on the LAN can hit the API" (real risk on shared networks — coffee shops, offices, dorms). But an intentional loopback binding with opt-in `--host` is a user-controlled choice, not a vulnerability.

When both tables apply (mixed surface: local-first admin UI + public telemetry endpoint), use the generic anchors for the public surface and local-first anchors for the local one; note the split in `Notes:`.

---

## Ground rules (non-negotiable)

1. **Read project instructions first, in this order:** the files listed in `{INSTRUCTION_FILES}`. Treat documented decisions as intentional. A finding that contradicts an explicit documented decision must either (a) cite why the doc itself is wrong or stale, or (b) be dropped. Do not flag a project rule as a bug. **However:** "documented decision" means an explicit, specific statement of intent (e.g., "we use inline styles for email templates"). A general description like "built with CSS" or "uses React" is not a decision defending every CSS or React pattern in the codebase. Do not use vague documentation as a shield against legitimate findings.

2. **Codebase map:** read `{CODEBASE_MAP_PATH}` exactly once. Do not paste its contents into your output; refer to directories and entry points by path instead.

3. **Scope:** `{SCOPE_GLOBS}` from the wrapper. Cross-scope reads are allowed only when a specific finding demands it; include a one-line justification in the finding's `Notes:` field. Cross-scope *cites* (your finding references a file outside your scope) are valid but will be moved to the correct analyst's dump during synthesis — not a defect.

4. **Applicability sub-flags and uncertain resolutions.** The wrapper passes `{APPLICABILITY_FLAGS}` from the Scout. Apply both tables below mechanically — do not re-interpret per-finding, do not ask the orchestrator to clarify.

   **Sub-flag resolutions:**
   - `web-facing-ui: present, auth-gated` → SEO-class checklist items default to `[-] N/A — auth-gated UI, no crawlable surface`. Override only if a public marketing route exists alongside the auth-gated app.
   - `web-facing-ui: present, local-only` → apply the "Local-first calibration" severity anchors (later in this file) instead of the generic public-surface anchors for network-boundary findings. SEO-class items default to `[-] N/A — local-only tool, not indexed`.

   **Uncertain-flag resolutions:**

   | Flag = `uncertain` | Treat as `present` for | Treat as `absent` for |
   |---|---|---|
   | `web-facing-ui` | Security checklist items, A11Y-1..A11Y-10 | SEO-1..SEO-3 |
   | `database` | Security checklist items (data handling paths) | DB-1..DB-5, MIG-1..MIG-5 |
   | `i18n-intent` | — | I18N-1..I18N-3 (N/A with reason "no i18n intent") |
   | `security-surface` | all Security checklist items | — (security defaults to present on uncertainty) |
   | `container` | — | CONT-1..CONT-4 |
   | `ci` | — | CI-1..CI-4 |
   | `iac` | — | IAC-1..IAC-3 |
   | `monorepo` | — | MONO-1..MONO-2 |

   If your analyst's scope depends on a flag with `uncertain` and the table has no row for it, treat as `present` for safety-sensitive checks (`security-surface`, `tests`) and `absent` for optional-feature checks (`i18n-intent`, `monorepo`); note the assumption in `Notes:` on any affected finding.

5. **Forbidden reads.** Do not open any of: `.env*`, `*.pem`, `*.key`, `*.pfx`, `*.p12`, anything under `secrets/`, `credentials/`, `.ssh/`. If such a file's existence is itself a finding, describe the path only — never its contents. Do not quote any token that looks like a credential, API key, hash, or private key.

6. **Forbidden commands.** No `install`, `add`, `update`, `build`, `migrate`, `exec`, `test`, `run`, no package-manager subcommands that modify the project's state (lockfile, node_modules, virtualenvs, etc.), and no execution of project code or scripts. Allowed: `git log`, `git blame`, `git ls-files`, `git status`, `rg`, `ls`, `wc`, and the Read tool. (The Coverage & Profiling analyst has an explicit exception described in its own prompt — it may invoke a single auto-detected coverage command unattended; no other analyst may execute anything.)

   **Dependency-freshness allowlist (read-only registry queries).** For DEP-1, DEP-6, TOOL-3 and related dependency-version checks, analysts MAY run the native "what's newer than what I have" command for the project's package manager. These commands read the registry but do not modify the lockfile, `node_modules`, or any project file:

   - `bun outdated` (Bun)
   - `npm outdated` (npm)
   - `pnpm outdated` (pnpm)
   - `yarn outdated` (Yarn classic; Yarn Berry uses `yarn upgrade-interactive --latest` dry-run)
   - `cargo outdated` (Rust; 3rd-party subcommand — only if already installed; otherwise skip)
   - `pip list --outdated` (pip)
   - `uv pip list --outdated` (uv)
   - `gem outdated` (Ruby)
   - `go list -m -u all` (Go)
   - `mix hex.outdated` (Elixir)
   - `composer outdated` (PHP)

   If the native command is not available for the project's ecosystem, or the analyst cannot determine the correct invocation from a single probe (`bun --version` etc.), web-search for the package's latest stable version instead (see "Dependency freshness checks" below). Commands that write state (`install`, `add`, `update`, `upgrade`) remain forbidden.

   (The Coverage & Profiling analyst has a separate, broader exception described in its own prompt; the allowlist above is for all analysts, not just Coverage.)

7. **No runtime observation.** Do not run tests or builds to "observe behavior." If dynamic behavior matters, describe what static analysis cannot answer and mark the finding Confidence: Speculative.

---

## Required bug-pattern passes

These passes are mandatory where their surfaces exist. They are not style preferences; they catch correctness bugs that often slip through broad review.

### Structured data beats text parsing

Search for code that parses human-oriented strings to recover values: `split`, `match`, regex capture groups, substring slicing, `includes`, `indexOf`, shell-text parsing, XML/HTML text scraping, log scraping, or error-message parsing. For each hit, ask whether the value already exists in a structured source nearby:

- Database/ORM column or query result field.
- JSON/XML field, HTTP header, status code, trailer, structured response body, or typed SDK property.
- Structured error/code/cause/details object.
- Event payload field, queue message field, CLI option parser result, or generated artifact metadata.

If the structured value exists, file `QUAL-10` (or `API-5` when the bad shape is an API response). If downstream callers are forced to parse returned prose because the producer omits separate fields, file `QUAL-11` / `API-5` against the producer, not just the consumer. A good fix exposes the machine value as a field and leaves prose as display-only.

Do not over-flag parsers whose actual job is parsing a protocol or user-authored language (CSV parser, XML parser, compiler, router, date parser, log importer). The smell is parsing display/error/prose text when a structured source of truth is available.

### Async completion must be explicit

Search for racy async shapes: floating promises/coroutines/tasks/goroutines, callbacks that set state after the caller returns, event handlers registered after the event may already fire, stream/process/worker operations without close/exit/join awaits, queue sends without delivery confirmation when required, and tests that start async work without joining it. File `CONC-6` or `TEST-12` when correctness depends on scheduler timing.

Search separately for polling/sleep synchronization: `sleep`, `setTimeout`, `setInterval`, `waitForTimeout`, retry loops around readiness checks, busy waits, arbitrary timeouts in tests, and loops polling files/ports/flags. If a real completion signal exists (event emitter, promise, channel, condition variable, observer, stream `finish`/`close`, process `exit`, worker message, fake timer advancement, framework lifecycle hook), file `CONC-7` or `TEST-11`. Polling can be acceptable for external systems that expose no event source; in that case mark clean with the sampled scope and why no event path exists.

### CI must test the artifact users receive

For Tooling/Security, inspect CI build/test order and release packaging. If the workflow builds an executable, Docker image, browser bundle, generated client, compiled package, or single-file binary, verify that at least a smoke/contract test runs against that artifact after packaging. Running unit tests against source before packaging is useful but does not prove the packaged artifact works. File `CI-5` and/or `BUILD-4` when CI can pass while the release artifact is broken, missing assets, missing native dependencies, using different entry points, or bundling different code than tests exercised.

Common examples: Bun/SEA/pkg/Nuitka/PyInstaller binaries, Docker images, compiled TS output, minified frontend bundles, generated API clients, CLI tarballs, wheels/gems/npm packages, and Electron/Tauri apps. The fix should be tier-sized: T1 may only need a one-command artifact smoke test; T3 may need full post-package contract checks.

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

### Enshrined-test check for autofix-ready

Before marking a finding `Autonomy: autofix-ready`, grep the project's test directories for references to the code the fix replaces. If any test asserts the pre-fix behavior, the fix must expand scope to also update or delete those tests.

The check: find test literals (not comments) that the fix would make impossible. Examples of the pattern:

- Fix changes a regex so `'cap-a'` is no longer a valid capture ID → search `tests/**` for the literal `'cap-a'`; any match is an enshrined test.
- Fix rewrites an error message from `"not found"` to `"capture does not exist"` → search tests for the old message literal.
- Fix changes an HTTP status from `200` to `404` on a specific error path → search tests calling that endpoint for `.status(200)` / `statusCode: 200` assertions.

Action:

- **Zero enshrined tests found:** `autofix-ready` stands.
- **1–2 enshrined tests found, same file:** keep `autofix-ready` BUT list the enshrined-test file paths in `Notes:` so the fix subagent expands scope by design, not surprise. Example: `Notes: expanded scope — fix makes tests/api/captures-paste-route.test.ts:43 ('cap-a') and tests/api/admin-jobs-id-route.test.ts:71 ('abc-123') enshrine an impossible input; both must be updated to use real UUIDs.`
- **3+ enshrined tests OR tests span multiple files/modules:** downgrade Autonomy to `needs-decision` with `Notes: fix breaks {N} enshrined tests across {M} files; subagent must decide whether to update the tests in place, delete them, or replace with an equivalent assertion against the new behavior`.

Bare test-function-name matches (not `// comment` matches) count. A test literal that the fix will make impossible is the signal. Do not count implementation-file literal matches — those are the target of the fix, not enshrined tests.

### Dependency freshness checks — no training-data guessing

**Never use your own memory as the source of truth for "what's the latest version of X".** LLM training data is months-to-years stale; claiming `react@18.2.0` is current when the registry has `react@19.x` turns every DEP-1 / DEP-6 / TOOL-3 finding into noise and misleads fix sessions.

When you need to assess dependency freshness (DEP-1 outdated versions, DEP-6 deprecated/abandoned, TOOL-3 outdated tooling, or any `Fix:` line that names a version number), use at least one of these three sources — in preference order:

1. **Run the project's native outdated command** from the allowlist above (`bun outdated`, `npm outdated`, `pnpm outdated`, etc.). Single source of truth, matches the project's registry configuration (public npm, private registry, vendored mirror), and produces a machine-readable diff between pinned and latest.
2. **Web-search for "latest stable version of X" at analysis time** (or equivalent query naming the package). Use your harness's web-search tool if available. Name the source URL in the finding's `Notes:` line.
3. **Fetch the registry's version metadata directly** if your harness supports it (e.g., `https://registry.npmjs.org/<pkg>/latest`, `https://pypi.org/pypi/<pkg>/json`). Cite the URL + access date in `Notes:`.

If none of the three is available in your harness, mark the finding Confidence: `Plausible` (not `Verified`) and annotate `Notes: version freshness not verified at analysis time — subagent must re-check before applying the fix`. The finding is still useful as a signal but cannot be `autofix-ready`.

**Output contract for version findings.** Every `DEP-1`, `DEP-6`, `TOOL-3` finding (or any finding whose `Fix:` specifies a version bump) must include in its body:

- **Current pinned version** — what the project uses now, cited from `package.json` / `Cargo.toml` / `pyproject.toml` / `go.mod` / etc.
- **Latest stable version** — what the registry says as of this run, with source: `(source: bun outdated)` / `(source: npmjs.com/package/foo 2026-04-22)` / `(source: web search "latest stable version of foo" 2026-04-22)`.
- **Gap** — e.g., *"pinned 1.2.3, latest 4.5.6 — two major versions behind"*.

Findings lacking the source citation are demoted during synthesis §8 as malformed-version-finding.

**Handling abandoned packages.** DEP-6 requires more than "outdated" — it requires evidence of abandonment. Signals: last-release date >18 months ago, repo archived on GitHub, README deprecation notice, official successor package named. Web-search is often required; `<pm> outdated` does not surface abandonment. Cite at least one specific signal in the finding body: *"last release 2024-02 (18 months before this run), repo archived 2024-06 per github.com/foo/bar"*.

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

### Gate-widening findings must ballpark the surfaced-error count

If a finding's `Fix:` is "widen this gate's scope" — extending a `tsconfig.check.json` `include` pattern, adding a directory to a linter config, turning on a previously-off eslint/biome/ruff rule, raising a coverage threshold, adding a new required CI job — run the widened check mentally (or via `rg` / dry-run where allowed) and count the resulting errors **before** marking the finding `autofix-ready`.

Include in the finding body under a `Surfaced-errors:` line:

- `Surfaced-errors: N — first 5: {path:line, path:line, path:line, path:line, path:line}` when N ≤ 20.
- `Surfaced-errors: ~N — sample: {5 paths}` when N > 20; approximate is fine, order of magnitude matters.
- `Surfaced-errors: 0` when the widened check genuinely passes as-is (rare; common case is >0).

If running the widened check is outside the analyst's read-only scope (the check is dynamic, `bun tsc` is forbidden, etc.), mark Confidence: `Plausible` with `Notes: widened-check not run; error count unknown at report time — fix coordinator must ballpark before proceeding`.

**Effort reclassification:** if `Surfaced-errors` > 20, `Effort` must be `Large` regardless of how trivial the gate-widening one-liner itself is. The session size is bounded by the cleanup cost, not the config edit.

**Autonomy reclassification:** if `Surfaced-errors` > 20, `Autonomy` cannot be `autofix-ready`. The cleanup decisions (fix in place vs. suppress vs. defer) are per-error, not mechanical.

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
| **Unsourced version claims** | Any DEP-1 / DEP-6 / TOOL-3 finding cites a "latest version" without a source line (native command, web search, or registry URL) | LLM memory is not a valid source. Run the allowlisted outdated command or web-search before citing versions. See "Dependency freshness checks". |
| **Text-parsing pass skipped** | Scope contains string parsing around errors, API responses, logs, CLI output, database rows, or event payloads, but QUAL-10/QUAL-11/API-5 checklist lines are all `clean` without sampling concrete parser sites | Re-read the parser sites and prove the parsed values do not exist as structured fields before claiming clean. |
| **Async-event pass skipped** | Scope contains sleeps, polling loops, timers, event emitters, streams, subprocesses, workers, or async tests, but CONC-6/CONC-7/TEST-11/TEST-12 are all `clean` without naming sampled wait/completion sites | Re-read the async control flow; identify the actual completion signal or file a finding. |
| **Artifact verification pass skipped** | CI/build config creates a packaged artifact, but CI-5/BUILD-4 are `clean` without naming the post-package command that exercises that exact artifact | Re-read the workflow and release scripts; source-level tests alone are not artifact verification. |

These thresholds are not rigid pass/fail gates — they are smell tests. A genuinely healthy codebase can have a high clean ratio, but that is rare and your Summary must explain why. The point is to catch the pattern where a model does the minimum to look productive.

### Read depth requirement

For every file you analyze, you must read beyond imports and type signatures into the implementation — function bodies, event handlers, route handlers, CSS rule blocks, ARIA attribute semantics on interactive elements, query builders, test assertions. Findings derived solely from file names, directory structure, or import statements are not findings — they are hypotheses that need verification by reading the code.

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
| "I know the latest version of React is 18" | Your training data is months-to-years stale. Run `<pm> outdated` or web-search for the current version before citing one. |
| "The docs say package X supports Y; good enough" | Docs rot. For DEP-1 / DEP-6 / TOOL-3 cite a live source (native command or registry query), not documentation you recall. |

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
