# Analyst roster

Each analyst is dispatched as an Explore subagent. Prune by the Scout's applicability flags — see SKILL.md Step 2. Security and Docs always run (the Step 2 exceptions); all others are pruned when their flag is `absent`.

Every analyst also filters its owned checklist items by the Scout's **project tier**: items with min-tier above the project tier are emitted as `[-] N/A — below profile threshold (project=T{N})` unless the analyst finds counter-evidence of explicit intent (see `checklist.md` "Tier interaction rule"). This is the single biggest lever for keeping the report right-sized.

Scope globs are advisory defaults; if the Scout's map reveals the project uses different conventions, adjust per-agent before dispatch and note the override in the report's Run metadata.

| Agent | Default model | In-scope paths / patterns | Owned checklist IDs |
|-------|---------------|---------------------------|---------------------|
| **Backend Analyst** | Sonnet | `src/server/**`, `src/lib/server/**`, `server/**`, `api/**`, `app/**` server files, business-logic modules, CLI entry points | EFF-1..EFF-3, PERF-1, PERF-3, PERF-4, PERF-5, QUAL-1..QUAL-9 (incl. 5a/5b/5c), ERR-1..ERR-3, ERR-5, CONC-1..CONC-5, OBS-1..OBS-4, LOG-1..LOG-7, TYPE-1..TYPE-3, API-1..API-4, DEP-1..DEP-8, NAM-1..NAM-7, NAM-8 (log + CLI output), DEAD-1, DEAD-2, COM-1..COM-3, MONO-1, MONO-2 (if monorepo) |
| **Frontend Analyst** | Sonnet | `src/routes/**`, `src/components/**`, `src/lib/**` client files, `*.svelte`, `*.tsx`, `*.jsx`, `*.vue`, `*.html`, `*.css`, `*.scss`, `*.postcss`, `public/**`, CSS/Tailwind configs | EFF-1..EFF-3 (frontend-scoped), PERF-1..PERF-3, PERF-5, QUAL-1..QUAL-9 (frontend-scoped), ERR-4, ERR-5, CONC-1, CONC-2, CONC-4, OBS-4, TYPE-1..TYPE-3, A11Y-1..A11Y-5, I18N-1..I18N-3 (if `i18n-intent`), SEO-1..SEO-3 (if `web-facing-ui`), FE-1..FE-23, UX-1, UX-2, DEP-1..DEP-8 (frontend-scoped; prefer FE-9..FE-14 for frontend-specific overlap patterns), NAM-1..NAM-7 (frontend-scoped), NAM-8 (UI strings), DEAD-1, DEAD-2, COM-1..COM-3, MONO-1, MONO-2 (if monorepo) |
| **Database Analyst** | Sonnet | `migrations/**`, `schema/**`, `*.sql`, ORM model files, query-builder usage sites | DB-1..DB-5, MIG-1..MIG-5 |
| **Test Analyst** | Sonnet | `tests/**`, `test/**`, `*_test.*`, `*.spec.*`, test config files (`vitest.config.*`, `playwright.config.*`, `bunfig.toml`, etc.) | TEST-1..TEST-10, DET-1..DET-4, FUZZ-1 (joint with Security) |
| **Security Analyst** | **Opus** | Entire repo — authn/z, input validation, secrets handling, subprocess, deserialization, crypto, file IO on user input, SSRF, ReDoS, OWASP top 10; also CI supply chain and container security cross-cuts | SEC-1, GIT-3, FUZZ-1 (joint with Test), CI-1..CI-4 (joint with Tooling, if `ci`), CONT-3 (joint with Tooling, if `container`), IAC-1..IAC-3 (joint with Tooling, if `iac`) |
| **Tooling Analyst** | Sonnet | `.github/**`, CI configs, `Dockerfile*`, `Makefile`, `justfile`, package manager configs (`package.json` scripts, `bunfig.toml`, etc.), deploy configs, lockfiles, toolchain pins | TOOL-1..TOOL-7, BUILD-1..BUILD-3, GIT-2, GIT-4, CI-1..CI-4 (if `ci`, joint with Security), CONT-1, CONT-2, CONT-4 (if `container`), IAC-1..IAC-3 (if `iac`, joint with Security) |
| **Docs Consistency Analyst** | Sonnet | `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `README.md`, `docs/**`, inline comments across whole repo | DOC-1..DOC-5, META-1, NAM-8 (user-visible text in docs), GIT-1, DEAD-3 |
| **Coverage & Profiling Analyst** | Sonnet | Test directories, coverage artifacts (`coverage/**`, `lcov.info`, `coverage-summary.json`), bench/profile artifacts (`bench/**`, `flamegraph.*`, `*.prof`), `package.json` scripts / `Makefile` / `justfile` / `Taskfile*` targets | COV-1..COV-3, PROF-1..PROF-2 (new IDs — see coverage-profiling-prompt.md for definitions) |

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

`NAM-8` (user-visible text — typos, grammar) is intentionally split:
- Frontend owns UI strings.
- Backend owns log messages and CLI output.
- Docs owns `*.md` files and inline comments.

## Gated analyst: Coverage & Profiling

Unlike every other analyst, Coverage & Profiling may **run** project commands (coverage target, bench target). That breaks the read-only invariant of the rest of the skill, so it is gated behind the execution authorization captured at Step 0's single consolidated consent prompt — it does **not** dispatch in the Step 3 parallel fan-out. It is also static-capable: if the user chose `static-only` at Step 0, the analyst still produces a static gap-analysis pass (source→test mapping, missing-test inference, bench-target presence check) without running anything. Step 3.5 itself is non-interactive in v3.1+.

See `coverage-profiling-prompt.md` for the analyst's prompt; see SKILL.md Step 0 (preflight capture) and Step 3.5 (non-interactive dispatch) for the execution protocol.

## Escalation

A dispatched analyst re-runs on Opus when **either** condition holds:

1. Its declared scope exceeds ~50k LOC (Scout's map numbers it).
2. Its first-pass output contains >30 findings at Severity High or Critical.

The second pass's output merges with the first pass during synthesis (same anchors → dedup per `synthesis.md` §2).
