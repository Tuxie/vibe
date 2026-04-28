# Analyst roster

Each analyst is dispatched as an Explore subagent. Prune by the Scout's applicability flags — see SKILL.md Step 2. Security and Docs always run (the Step 2 exceptions); all others are pruned when their flag is `absent`.

Every analyst also filters its owned checklist items by the Scout's **project tier**: items with min-tier above the project tier are emitted as `[-] N/A — below profile threshold (project=T{N})` unless the analyst finds counter-evidence of explicit intent (see `checklist.md` "Tier interaction rule"). This is the single biggest lever for keeping the report right-sized.

Scope globs are advisory defaults; if the Scout's map reveals the project uses different conventions, adjust per-agent before dispatch and note the override in the report's Run metadata.

If the user explicitly overrides analyst model tiers for the run, apply that override and record `Analyst override: per user request, <scope of analysts> ran on <model/tier>` in Run metadata. The roster's default tiers still document the baseline and still inform any later "already senior vs. needs senior re-dispatch" decision.

| Agent | Default model tier | In-scope paths / patterns | Owned checklist IDs |
|-------|---------------|---------------------------|---------------------|
| **Backend Analyst** | Standard | `src/server/**`, `src/lib/server/**`, `server/**`, `api/**`, `app/**` server files, business-logic modules, CLI entry points | EFF-1..EFF-3, PERF-1, PERF-3, PERF-4, PERF-5, QUAL-1..QUAL-11 (incl. 5a/5b/5c), ERR-1..ERR-3, ERR-5, CONC-1..CONC-7, OBS-1..OBS-4, LOG-1..LOG-7, TYPE-1..TYPE-3, API-1..API-5, DEP-1..DEP-9, NAM-1..NAM-7, NAM-8 (log + CLI output), DEAD-1, DEAD-2, COM-1..COM-3, MONO-1, MONO-2 (if monorepo) |
| **Frontend Analyst** | Standard | `src/routes/**`, `src/components/**`, `src/lib/**` client files, `*.svelte`, `*.tsx`, `*.jsx`, `*.vue`, `*.html`, `*.css`, `*.scss`, `*.postcss`, `public/**`, CSS/Tailwind configs | EFF-1..EFF-3 (frontend-scoped), PERF-1, PERF-2 (joint with Styling), PERF-3, PERF-5, QUAL-1..QUAL-11 (frontend-scoped), ERR-4, ERR-5, CONC-1, CONC-2, CONC-4, CONC-6, CONC-7, OBS-4, TYPE-1..TYPE-3, I18N-1..I18N-3 (if `i18n-intent`), SEO-1..SEO-3 (if `web-facing-ui`), FE-1, FE-6, FE-7, FE-8, FE-21, FE-22, FE-23 (joint with Styling), FE-2..FE-5, FE-9..FE-20, UX-1 (joint with Styling), DEP-1..DEP-9 (frontend-scoped; prefer FE-9..FE-14 for frontend-specific overlap patterns), NAM-1..NAM-7 (frontend-scoped), NAM-8 (UI strings), DEAD-1, DEAD-2, COM-1..COM-3, MONO-1, MONO-2 (if monorepo) |
| **Styling Analyst** | Standard | `**/*.css`, `**/*.scss`, `**/*.sass`, `**/*.postcss`, `**/*.less`, `**/*.styl`, `**/*.module.{css,scss}`, `<style>` blocks in `*.svelte` / `*.vue` / `*.astro` / `*.tsx` / `*.jsx` / `*.html`, CSS-in-JS literals (`styled.X\`…\``, `css\`…\``, `sx={…}`, `style={{…}}`), utility-CSS configs (`tailwind.config.*`, `uno.config.*`, `panda.config.*`, `windi.config.*`, `unocss.config.*`), theme/token files (`**/theme.{ts,js,json,css}`, `**/tokens.{ts,js,json,css}`, `**/design-tokens/**`). Runs only when Scout emits `styling-surface: present`. | STYLE-1..STYLE-11 (sole owner); FE-1, FE-6, FE-7, FE-8, FE-21, FE-22, FE-23 (joint with Frontend); A11Y-3 (joint with Accessibility); UX-1 (joint with Frontend); PERF-2 (joint with Frontend, CSS-bundle slice only) |
| **Accessibility Analyst** | Standard | `src/routes/**`, `src/components/**`, `src/lib/**` client files, `*.svelte`, `*.tsx`, `*.jsx`, `*.vue`, `*.astro`, `*.html`, `*.css`, `*.scss`, `*.postcss` (for contrast cross-check), `*.module.{css,scss}`, theme/token files (`**/theme.{ts,js,json,css}`, `**/tokens.{ts,js,json,css}`, `**/design-tokens/**`). Runs only when Scout emits `web-facing-ui: present` (any sub-flag including `auth-gated`, `local-only`). | A11Y-1, A11Y-2, A11Y-4, A11Y-5 (sole — transferred from Frontend in v3.10); A11Y-6..A11Y-10 (sole — new in v3.10); UX-2 (sole — transferred from Frontend in v3.10); A11Y-3 (joint with Styling) |
| **Database Analyst** | Standard | `migrations/**`, `schema/**`, `*.sql`, ORM model files, query-builder usage sites | DB-1..DB-5, MIG-1..MIG-5 |
| **Test Analyst** | Standard | `tests/**`, `test/**`, `*_test.*`, `*.spec.*`, test config files (`vitest.config.*`, `playwright.config.*`, `bunfig.toml`, etc.) | TEST-1..TEST-12, DET-1..DET-4, FUZZ-1 (joint with Security) |
| **Security Analyst** | **Senior** | Entire repo — authn/z, input validation, secrets handling, subprocess, deserialization, crypto, file IO on user input, SSRF, ReDoS, OWASP top 10; also CI supply chain and container security cross-cuts | SEC-1, GIT-3, FUZZ-1 (joint with Test), CI-1..CI-5 (joint with Tooling, if `ci`), CONT-3 (joint with Tooling, if `container`), IAC-1..IAC-3 (joint with Tooling, if `iac`) |
| **Tooling Analyst** | Standard | `.github/**`, CI configs, `Dockerfile*`, `Makefile`, `justfile`, package manager configs (`package.json` scripts, `bunfig.toml`, etc.), deploy configs, lockfiles, toolchain pins | TOOL-1..TOOL-7, BUILD-1..BUILD-4, GIT-2, GIT-4, CI-1..CI-5 (if `ci`, joint with Security), CONT-1, CONT-2, CONT-4 (if `container`), IAC-1..IAC-3 (if `iac`, joint with Security) |
| **Docs Consistency Analyst** | Standard | `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `README.md`, `docs/**`, inline comments across whole repo | DOC-1..DOC-5, META-1, NAM-8 (user-visible text in docs), GIT-1, DEAD-3 |
| **Coverage & Profiling Analyst** | Standard | Test directories, coverage artifacts (`coverage/**`, `lcov.info`, `coverage-summary.json`), bench/profile artifacts (`bench/**`, `flamegraph.*`, `*.prof`), `package.json` scripts / `Makefile` / `justfile` / `Taskfile*` targets, instruction files (`AGENTS.md` / `CLAUDE.md` / `GEMINI.md` / `README.md`) for documented coverage thresholds | COV-1..COV-6, PROF-1..PROF-2 |

## `scripts/` directory ownership

The `scripts/` top-level directory (or any repo-convention equivalent: `bin/`, `tools/`, `dev/`) does **not** belong wholesale to Tooling. Each script is owned by whichever analyst owns its *target*, not its location:

- `scripts/bench-*`, `scripts/profile-*` → Coverage & Profiling.
- `scripts/bench-render-math.ts` (targets client code) → Frontend.
- `scripts/bench-api.ts` (targets server code) → Backend.
- `scripts/check-coverage.ts`, `scripts/coverage-report.ts` → Coverage & Profiling.
- `scripts/migrate-*`, `scripts/seed-*`, `scripts/db-*` → Database.
- `scripts/release.sh`, `scripts/ci-*`, `scripts/build-*`, `scripts/publish-*` → Tooling.
- `scripts/fuzz-*`, `scripts/sec-audit-*` → Security.
- Everything else (default) → Tooling.

If in doubt, ask: "If this script broke tomorrow, which analyst would notice first?" That is the owner. Record any non-obvious assignment in Run metadata under `Scope overrides`.

## Ownership collisions

Where the same checklist ID appears under two agents (e.g., `QUAL-1` for both Backend and Frontend), each agent keeps its own checklist line scoped to its paths — they do **not** fight for a single `[x]`. Synthesis merges overlapping *findings* by anchor but leaves both checklist lines in the report with subscope noted (see `synthesis.md` §4).

Joint items (e.g., `CI-1` owned by Tooling + Security, `FUZZ-1` by Test + Security): each owner examines from its own lens. Tooling looks at CI workflow ergonomics; Security looks at trust boundaries and secret exposure. Synthesis merges by anchor.

**Frontend + Styling joint ownership** on `FE-1`, `FE-6`, `FE-7`, `FE-8`, `FE-21`, `FE-22`, `FE-23`, `UX-1`, and the CSS-bundle slice of `PERF-2`. Frontend's lens is component-shape (this `<div style={{}}>` indicates a missing prop type); Styling's lens is system-shape (this inline style is one of 47 magic colors that should be a token). Synthesis dedup by `file:line` anchor handles the overlap. For `PERF-2`, Frontend keeps JS-bundle weight; Styling owns CSS-bundle weight (unused utility classes, duplicate keyframes, oversized stylesheet imports).

**Styling + Accessibility joint ownership** on `A11Y-3` (color-only signal / WCAG AA contrast). Styling's lens: is the token system internally coherent — does the palette have any combinations that would fail contrast at expected text sizes? Accessibility's lens: is this combination actually rendered against that background in the markup — find the JSX/template sites that combine the tokens problematically. Synthesis dedup by anchor handles the overlap. (Frontend was a third joint owner on A11Y-3 in v3.8–v3.9; v3.10 retired Frontend's role here as part of the broader A11Y-* sole transfer to Accessibility.)

**Accessibility owns sole** on `A11Y-1`, `A11Y-2`, `A11Y-4`, `A11Y-5`, `A11Y-6`, `A11Y-7`, `A11Y-8`, `A11Y-9`, `A11Y-10`, `UX-2`. Frontend does not own A11Y-* and does not own UX-2 — the dispatch wrapper passes Frontend's owned-IDs without these, so the analyst won't file A11Y or keyboard-shortcut findings. Cross-scope observations (the rare case where Frontend spots something Accessibility might miss) still go in `Notes` per the existing convention.

`NAM-8` (user-visible text — typos, grammar) is intentionally split:
- Frontend owns UI strings.
- Backend owns log messages and CLI output.
- Docs owns `*.md` files and inline comments.

## Coverage & Profiling Analyst execution exception

Coverage & Profiling is the only analyst that may execute project commands. It runs the auto-detected coverage command unattended in the regular Step 3 parallel fan-out — there is no consent gate at dispatch time. The Step 0 confirmation prompt (proceed / abort / instruct) is the single point at which the user can prevent the run. If the orchestrator's Step 0 detection found no coverage command, the analyst files COV-4 *Missing test coverage tracking system* with tier-graded severity and runs the static pass only.

See `coverage-profiling-prompt.md` for the analyst's prompt and the threshold-derivation rule; see SKILL.md Step 0 for the preflight protocol and Step 3 for the dispatch list.

## Escalation

There are three paths to a higher tier in v3.10+. They are not mutually exclusive — a single run can use any combination across analysts.

### Path A — gradient escalation (existing-style, after a first-pass run)

A dispatched analyst re-runs on a higher tier when **either** condition holds:

1. Its declared scope exceeds ~50k LOC (Scout's map numbers it). | Standard → Senior.
2. Its first-pass output contains >30 findings at Severity High or Critical. | Standard → Senior.

A Senior-tier analyst re-runs on Senior-1M when:

1. Its declared scope exceeds ~150k LOC, OR
2. Its first-pass output exceeds ~2,000 lines (signals genuine context pressure), OR
3. Synthesis input total exceeds an estimated 100k tokens (synthesis-pass-specific).

The second pass's output merges with the first pass during synthesis (same anchors → dedup per `synthesis.md` §2).

### Path B — Scout-direct dispatch at Senior-1M (new in v3.10)

The Scout, during Step 1's mapping pass, may emit a `Recommend senior-1m for: <analyst-list>` block (see `structure-scout-prompt.md`). The orchestrator dispatches the named analysts directly at Senior-1M in Step 3, bypassing both Standard and Senior. No prior pass is required. Path A's gradient does not apply to analysts that started at Senior-1M — they're already at the top.

The Scout's recommendation criteria are concrete and numeric: single-analyst scope >300k LOC, polyglot single-analyst scope ≥4 language families, mid-large monorepo cross-cutting Security on >1M LOC, or synthesis pre-prediction >100k tokens. Vibes-based recommendations are not allowed.

### Path C — user directive at Step 0

The Step 0 confirmation prompt accepts a free-text directive `use senior-1m on <analyst-name>` (additive to the existing `use senior on <analyst-name>` shape from v3.9). The orchestrator records the override in Run metadata and applies it at dispatch time, bypassing both Standard and Senior.

### Run metadata records, per analyst:

- `Tier: <tier>` — the tier the analyst actually ran on (`junior` | `standard` | `senior` | `senior-1m`).
- `Tier path: <path>` — `default` | `gradient: standard→senior` | `gradient: senior→senior-1m` | `scout-direct: senior-1m` | `user-directive`.

### Reasoning effort axis (orthogonal to tier)

Effort is a separate axis (`default` | `high` | `max`) that the skill recommends actively only on a closed list of triggers — see `SKILL.md` Model selection section. Most dispatches stay at `default`; bumps fire on synthesis-Senior-1M, Security at Senior-1M, and certain `iar` cluster shapes. Step 0 directive `use max-effort on <analyst-name>` is additive to model-tier directives.

### Resolution rule (load-bearing)

Never downgrade below the requested logical tier or effort level. When the harness exposes only one senior-class model (collapsed-senior topology common on Claude Pro/Max, ChatGPT Plus/Pro, etc.), every Senior dispatch and every Senior-1M dispatch goes to that same model. When the harness exposes only `default` effort, requested `high` or `max` is logged but cannot be honored. The skill never silently strips a tier or effort recommendation. See `SKILL.md` Model selection section for the full topology table and resolution semantics.
