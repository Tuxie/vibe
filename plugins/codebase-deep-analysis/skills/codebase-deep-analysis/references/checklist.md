# Checklist

Stable IDs, orthogonal categories. Each item carries a **Min tier** so analysts automatically skip items below the project's profile. Ownership column names the responsible analyst (see `agent-roster.md`). Multi-owner rows keep one checklist line per owning scope during synthesis.

## Tiers

The Structure Scout assigns the repo one tier, with evidence. Analysts filter owned items by tier:

- **T1 — Hobby / solo / experimental.** Any project. Single or few contributors, may lack CI/LICENSE/releases, may not be deployed anywhere.
- **T2 — Serious OSS / small team.** Multi-contributor, CI present, releases or changelog, LICENSE, optional deploy config. Internal-only business apps usually land here.
- **T3 — Production / team / enterprise.** Prod deploy artifacts (k8s / terraform / docker-compose-prod), security policy or issue templates, multiple recurring contributors, SLO-relevant traffic.

**Tier interaction rule for every checklist item:**

- Item min-tier ≤ project tier → analyst must address it.
- Item min-tier > project tier → analyst emits `[-] N/A — below profile threshold (project=T{N})` **unless** the repo shows explicit intent to do the thing anyway (e.g., an `i18n/` dir in a T1 repo flips I18N items back on). Counter-evidence gets cited on the checklist line.

**Checklist line shapes (the full set):**

- `[x] <evidence pointer>` — analyzed and filed ≥1 finding.
- `[x] clean — <what was sampled>` — analyzed, nothing to file; scope of "clean" must be concrete.
- `[-] N/A — <reason>` — does not apply (wrong tier, wrong stack, no surface).
- `[?] inconclusive — <what was tried>` — investigated, could not decide.
- `[~] deferred — <reason + tracking location>` — real finding, intentionally not addressed this run (infra blocker, awaiting upstream, awaiting user decision the skill is not empowered to make). `tracking location` is a file path, issue link, or cluster slug holding the deferral.

`[~] deferred` is a **terminal** state, not a placeholder for `[?]`. Use `[?]` when analysis itself was blocked; use `[~]` when analysis succeeded but action is deliberately punted. Synthesis treats the two differently: `[?]` flags weak coverage; `[~]` is accepted as-is and surfaced in the Executive Summary only if the deferred item is Critical/High.

**Over-engineering is a first-class finding.** If a T1 repo uses T3-scale patterns (full DI container, hexagonal architecture, metrics pipeline no one reads), that is a `QUAL-4` finding against the project — not praise.

---

## EFF — Efficiency (algorithmic, non-DB, non-PERF)

| ID | Item | Min tier | Owner |
|----|------|----------|-------|
| EFF-1 | Inefficient algorithms (asymptotic or large constant factors) | T1 | Backend, Frontend |
| EFF-2 | Inefficient I/O patterns — sync where async/parallel helps; polling where events exist | T1 | Backend, Frontend |
| EFF-3 | Dead or unused code (unreachable, unexported with no refs, unused exports) | T1 | Backend, Frontend |

## PERF — Performance beyond algorithm

| ID | Item | Min tier | Owner |
|----|------|----------|-------|
| PERF-1 | Missing caching / memoization where recomputation is the bottleneck | T2 | Backend, Frontend |
| PERF-2 | Bundle size / cold start — large imports, no code-splitting, duplicate deps in bundle. Joint ownership: Styling co-owns the CSS-bundle slice (unused utility classes shipping, duplicate keyframes, oversized stylesheet imports); Frontend keeps the JS-bundle slice. | T2 | Frontend, Styling |
| PERF-3 | Memory leaks / unbounded collections (uncleaned listeners, caches without eviction, goroutine/worker leaks, stale refs) | T1 | Backend, Frontend |
| PERF-4 | Missing timeouts on network / subprocess / external I/O | T1 | Backend |
| PERF-5 | Missing cancellation / AbortSignal / context propagation through long-running work | T2 | Backend, Frontend |

## QUAL — Code quality

| ID | Item | Min tier | Owner |
|----|------|----------|-------|
| QUAL-1 | Duplicated code that should share a helper | T1 | Backend, Frontend |
| QUAL-2 | Messy structure / unclear module boundaries | T1 | Backend, Frontend |
| QUAL-3 | Inconsistent style within a file or module (not cross-project; defer to `.editorconfig` / formatter config) | T1 | Backend, Frontend |
| QUAL-4 | **Over-engineered for the project's tier** — premature abstraction, enterprise patterns in a T1/T2 project, unnecessary indirection, speculative generality | T1 | Backend, Frontend |
| QUAL-5a | Missing input validation where input crosses a trust boundary (HTTP body/query, CLI arg, file contents, IPC) | T1 | Backend, Frontend |
| QUAL-5b | Missing error handling on an external call (network, disk, subprocess, DB) — error swallowed, or unwrap/panic on fallible path | T1 | Backend, Frontend |
| QUAL-5c | Missing resource cleanup (file handle, connection, subscription, timer) on normal OR error paths | T1 | Backend, Frontend |
| QUAL-6 | Non-idiomatic for the language / framework in use | T1 | Backend, Frontend |
| QUAL-7 | Reimplementation of stdlib / in-use framework functionality | T1 | Backend, Frontend |
| QUAL-8 | Workaround where a root-cause fix is available | T1 | Backend, Frontend |
| QUAL-9 | Cross-boundary code duplication in same-language stacks — logic reimplemented across server/client/middleware/API-layer boundaries instead of extracted to a shared module. Common in full-stack JS/TS (Node, Bun, Deno), but applies to any stack where layers share a runtime: validation, formatting, constants, type definitions, business rules, data transformation. Each analyst checks the codebase map for same-language counterparts and spot-reads for equivalent logic in the other boundary's paths | T1 | Backend, Frontend |
| QUAL-10 | Text parsing used where structured data is already available — extracting IDs, statuses, dates, or types from error strings, log text, labels, rendered markup, filenames, or human messages when the value exists in a database column, JSON/XML field, HTTP header, typed object, enum, structured error property, or API response field | T1 | Backend, Frontend |
| QUAL-11 | Machine consumers forced to parse prose — a function/API/event/test helper returns only text that downstream code must regex/split to recover values that should be separate fields (`order_id`, status code, path, retry delay, validation errors, etc.) | T1 | Backend, Frontend |

## ERR — Error handling patterns

| ID | Item | Min tier | Owner |
|----|------|----------|-------|
| ERR-1 | Missing retry / backoff on a call that provably benefits (transient network, known-idempotent op) | T2 | Backend |
| ERR-2 | Missing idempotency on a mutation that may be retried (HTTP POST under retry, queue consumer) | T2 | Backend |
| ERR-3 | Missing circuit breaker / load shedding on a dependency that fails under load | T3 | Backend |
| ERR-4 | Missing error boundary on a client component tree that can throw | T2 | Frontend |
| ERR-5 | Panic / unwrap / uncaught `throw` on a fallible path where graceful degradation is expected | T1 | Backend, Frontend |

## CONC — Concurrency correctness

| ID | Item | Min tier | Owner |
|----|------|----------|-------|
| CONC-1 | Race condition — shared mutable state without synchronization | T1 | Backend, Frontend |
| CONC-2 | Floating / unawaited promise, unhandled coroutine, orphan goroutine | T1 | Backend, Frontend |
| CONC-3 | Unbounded fan-out — spawn-per-request with no pool / semaphore | T2 | Backend |
| CONC-4 | Missing cancellation propagation — long work cannot be interrupted | T2 | Backend, Frontend |
| CONC-5 | Deadlock-prone lock ordering, re-entrant lock misuse | T2 | Backend |
| CONC-6 | Racy asynchronous completion — caller proceeds before spawned work, event handlers, stream writes, subprocesses, queue jobs, promise chains, goroutines, tasks, or worker messages have actually completed; correctness depends on timing rather than an awaited completion signal | T1 | Backend, Frontend |
| CONC-7 | Poll/sleep/timeout used as synchronization where an event, promise, channel, condition variable, callback, watcher, stream completion, process exit, or test-runner hook can signal readiness/completion directly | T1 | Backend, Frontend |

## OBS — Observability beyond logs

| ID | Item | Min tier | Owner |
|----|------|----------|-------|
| OBS-1 | Missing metrics on a path that needs SLO tracking (rate, error, latency) | T3 | Backend |
| OBS-2 | Missing distributed tracing / correlation-ID propagation across a service boundary | T3 | Backend |
| OBS-3 | Missing `/health` or readiness endpoint where the deploy platform expects one | T2 | Backend |
| OBS-4 | Telemetry event schema drift — emitted payload diverges from documented contract | T2 | Backend, Frontend |

## LOG — Logging

| ID | Item | Min tier | Owner |
|----|------|----------|-------|
| LOG-1 | Missing ERROR where a failure happens silently | T1 | Backend |
| LOG-2 | Missing WARN for recoverable issues | T1 | Backend |
| LOG-3 | Missing INFO at lifecycle boundaries (startup/shutdown, job begin/end) | T2 | Backend |
| LOG-4 | Missing DEBUG for per-item flow details | T2 | Backend |
| LOG-5 | Wrong severity level used (e.g., INFO for a caught exception) | T1 | Backend |
| LOG-6 | Message text contradicts the actual event | T1 | Backend |
| LOG-7 | Inconsistent phrasing across a subsystem (mixed tenses, mixed subjects, inconsistent IDs) | T2 | Backend |

## TYPE — Type safety

| ID | Item | Min tier | Owner |
|----|------|----------|-------|
| TYPE-1 | Unsafe escape hatch — `any`, `@ts-ignore`, `# type: ignore`, `unsafe`, raw cast — without justification comment | T1 | Backend, Frontend |
| TYPE-2 | Public API surface typed as `unknown`/`any` where a real type would fit | T2 | Backend, Frontend |
| TYPE-3 | Optional-chaining noise hiding a missing null-check at a real boundary | T1 | Backend, Frontend |

## A11Y — Accessibility (frontend)

| ID | Item | Min tier | Owner |
|----|------|----------|-------|
| A11Y-1 | Interactive element without accessible name (button/link without text or `aria-label`) | T1 | Frontend |
| A11Y-2 | Missing keyboard operability (click-only handler, modal without focus trap) | T1 | Frontend |
| A11Y-3 | Color-only signal, or contrast below WCAG AA | T2 | Frontend, Styling |
| A11Y-4 | Missing or wrong landmark / heading structure (multiple `<h1>`, missing `<main>`) | T2 | Frontend |
| A11Y-5 | Missing `alt` on meaningful images; decorative images without `alt=""` | T1 | Frontend |

## I18N — Internationalization

Only triggers when the repo shows i18n intent (framework present, locale dir, bidi CSS). Otherwise `[-] N/A — no i18n intent`.

| ID | Item | Min tier | Owner |
|----|------|----------|-------|
| I18N-1 | Hardcoded user-visible string where an i18n framework is already in use | T1 | Frontend |
| I18N-2 | Plural / locale formatting done manually where framework supports it | T2 | Frontend |
| I18N-3 | Missing RTL / bidi support on a layout that breaks in RTL | T3 | Frontend |

## SEO — SEO / frontend metadata

Only triggers for user-facing web apps (not internal tools, not CLI UIs, not dashboards behind auth with no SEO value).

| ID | Item | Min tier | Owner |
|----|------|----------|-------|
| SEO-1 | Missing / duplicated `<title>` or `<meta name="description">` on rendered routes | T2 | Frontend |
| SEO-2 | Missing Open Graph / Twitter card metadata on shareable pages | T2 | Frontend |
| SEO-3 | Missing canonical URL / robots directives where they matter | T3 | Frontend |

## API — API contract

| ID | Item | Min tier | Owner |
|----|------|----------|-------|
| API-1 | Breaking change in public API without version bump or deprecation path | T2 | Backend |
| API-2 | OpenAPI / schema file drifted from handler signature | T2 | Backend |
| API-3 | Response-shape inconsistency across endpoints in the same API surface | T2 | Backend |
| API-4 | Wrong HTTP status for the semantic (POST-created returning 200, 404 for auth failure, etc.) | T1 | Backend |
| API-5 | Response omits structured fields that callers need and already exist upstream, forcing clients to scrape message strings or infer values from prose | T1 | Backend |

## DEP — Dependencies

For concrete frontend overlap patterns (icons, dates, HTTP clients, UI kits, state libs), see `FE-9..FE-14` — raise those instead of a generic DEP-2 when a frontend-specific pattern fits, so the finding lands in a frontend cluster rather than a generic "dependency bloat" bucket.

**Version-freshness rule.** `DEP-1` and `DEP-6` findings require a live source for "latest stable version" — never cite from LLM memory. Run the project's native outdated command (`bun outdated`, `npm outdated`, `pnpm outdated`, `cargo outdated`, `pip list --outdated`, `go list -m -u all`, etc.) or web-search at analysis time. See `analyst-ground-rules.md` "Dependency freshness checks" for the full rule and source-citation contract. Synthesis §8 demotes unsourced version claims.

| ID | Item | Min tier | Owner |
|----|------|----------|-------|
| DEP-1 | Outdated package versions | T1 | Backend, Frontend |
| DEP-2 | Redundant or overlapping packages (two do the same job) — use FE-9..FE-14 for frontend-specific overlap patterns | T1 | Backend, Frontend |
| DEP-3 | Declared package with no imports (unused in manifest). Documentation-only mentions do not count as usage — a package must be imported/required in source, test, or build-config files to be considered "used" | T1 | Backend, Frontend |
| DEP-4 | Hand-rolled implementation where a maintained package fits better | T2 | Backend, Frontend |
| DEP-5 | Non-optimal stdlib module choice for the actual use case | T1 | Backend, Frontend |
| DEP-6 | Deprecated or abandoned package still in use | T1 | Backend, Frontend |
| DEP-7 | Backwards-compat shims for modules no longer needed | T1 | Backend, Frontend |
| DEP-8 | Unintended dependency on host-system software or globally installed tools | T1 | Backend, Frontend |
| DEP-9 | Runtime-native functionality replaced by external package — using a third-party package for something the project's declared runtime provides as a built-in. Cross-reference the Scout's runtime identification against installed packages. Examples: `ws` on Bun (native WebSocket via `Bun.serve`), `node-fetch` on Node 18+/Bun/Deno (native `fetch`), `dotenv` on Bun (auto `.env` loading), `bcrypt` native addon where `Bun.password` exists, `glob` on Node 22+ (native `fs.glob`). The runtime must be explicitly declared in the project — do not assume | T1 | Backend, Frontend |

## NAM — Naming & layout

| ID | Item | Min tier | Owner |
|----|------|----------|-------|
| NAM-1 | Class/type naming off-convention | T1 | Backend, Frontend |
| NAM-2 | Function / method naming off-convention | T1 | Backend, Frontend |
| NAM-3 | Variable naming off-convention | T1 | Backend, Frontend |
| NAM-4 | Parameter naming off-convention | T1 | Backend, Frontend |
| NAM-5 | API / endpoint naming off-convention | T2 | Backend, Frontend |
| NAM-6 | File naming off-convention for the language/framework | T1 | Backend, Frontend |
| NAM-7 | Directory layout off-convention for the language/framework | T1 | Backend, Frontend |
| NAM-8 | Typos / grammar in user-visible text (UI strings → Frontend; log messages + CLI output → Backend; `*.md` + inline comments → Docs) | T1 | Frontend, Backend, Docs |

## FE — Frontend code practices

Covers how markup, styles, and framework code are written — orthogonal to `A11Y` (accessibility), `UX` (user-facing interaction feel), `PERF-2` (bundle weight), `SEO` (metadata), and `DEP-2` (generic dep overlap). When a finding could plausibly land in FE and in another category, prefer FE so it clusters with its fellow frontend fixes.

| ID | Item | Min tier | Owner |
|----|------|----------|-------|
| FE-1 | Inline `style="..."` or `!important` used to force cascade where a class / utility / scoped-CSS rule fits | T1 | Frontend, Styling |
| FE-2 | Layout via HTML hacks — `<br>` / `&nbsp;` for spacing, `<table>` for non-tabular layout, spacer divs — where CSS (flex / grid / `gap`) fits | T1 | Frontend |
| FE-3 | Inline event handlers in HTML (`onclick=`, `onsubmit=`) mixed with framework-managed handlers in the same codebase | T1 | Frontend |
| FE-4 | Non-semantic HTML — `<div>` / `<span>` used as a button / link / heading / list where the correct element exists | T1 | Frontend |
| FE-5 | Raw DOM manipulation (`document.querySelector`, `.innerHTML`, manual `addEventListener`) inside framework components where the framework's API fits | T1 | Frontend |
| FE-6 | Mixed styling systems without a documented split — two or more of Tailwind, CSS Modules, styled-components / Emotion, plain global CSS, inline styles — all carrying real styling load | T2 | Frontend, Styling |
| FE-7 | Deep CSS nesting / specificity wars (>3 levels, or chains like `div.container > ul > li > a.active`) where a flat class would fit | T1 | Frontend, Styling |
| FE-8 | Global-CSS leaks in a project that otherwise scopes styles (unscoped selectors in a CSS-Modules / Svelte-scoped / Vue-scoped project) | T1 | Frontend, Styling |
| FE-9 | Overlapping UI component libraries (MUI + Bootstrap + Chakra; partial shadcn adoption alongside a second design system) | T2 | Frontend |
| FE-10 | Overlapping state libraries — more than one of Redux / Zustand / Jotai / MobX / Pinia / TanStack-Query-as-store / framework context carrying real state for the same domain | T2 | Frontend |
| FE-11 | Overlapping HTTP clients (`fetch` + `axios` + `ky` + `got`) in one app without a documented split of responsibilities | T1 | Frontend |
| FE-12 | Overlapping date / time libraries (moment + date-fns + dayjs + luxon); moment still used in new code; `Temporal` polyfill alongside a legacy lib | T1 | Frontend |
| FE-13 | Overlapping icon sets, or duplicate icon packages shipping the same glyph set twice (react-icons + @heroicons + lucide-react + svg imports) | T1 | Frontend |
| FE-14 | Legacy helpers used where the framework / modern stdlib already covers the need — jQuery alongside a reactive framework; Lodash / Underscore for things ES2020+ provides natively; `classnames` where template literals or `clsx` already in the repo | T1 | Frontend |
| FE-15 | Reactive anti-patterns — effect used where derived state fits (React `useEffect(() => setX(derived(props)))`; Svelte 5 `$effect` where `$derived` fits; Vue `watch` where `computed` fits); prop drilling through >3 levels where existing context / store would carry it; redundant re-renders from new object/array literals in props | T1 | Frontend |
| FE-16 | `<img>` / `<video>` / embedded media rendered without intrinsic `width`/`height` or `aspect-ratio`, causing layout shift | T1 | Frontend |
| FE-17 | Missing `loading="lazy"` / `decoding="async"` on off-screen media; render-blocking custom fonts without `font-display: swap` or preload hints; CSS / JS `<link>` without `rel="preload"` where it's on the critical path | T2 | Frontend |
| FE-18 | Forms without bound `<label>`s, missing `name`/`autocomplete`/`inputmode`/`type`, or SPA submit handlers missing `preventDefault` so the page reloads | T1 | Frontend |
| FE-19 | Component-scoped subscription leaks — `addEventListener`, `ResizeObserver`, `IntersectionObserver`, `setInterval` / `setTimeout`, media-query listeners — not cleaned up on unmount / teardown | T1 | Frontend |
| FE-20 | Client bundle pulls server-only / Node-only APIs (tree-shake failed, or a `node:` import shipped to browser) causing either runtime errors or silently bloating the bundle with shims | T2 | Frontend |
| FE-21 | Duplicated CSS property blocks — same set of properties/values repeated across multiple selectors instead of extracted to a shared class, mixin, or CSS custom-property group. Look for ≥3 selectors sharing ≥3 identical declarations | T1 | Frontend, Styling |
| FE-22 | Missing component base classes — repeated UI elements (buttons, inputs, cards, menus, modals, badges) styled individually instead of sharing a common base class with variant modifiers. Changing one instance's style doesn't propagate to others | T1 | Frontend, Styling |
| FE-23 | Inconsistent CSS class naming — no naming convention (BEM, utility-first, SMACSS, etc.) or convention exists but is violated; class names mix casing styles (`btn-primary` vs `submitButton` vs `card_header`) within the same project | T1 | Frontend, Styling |

## STYLE — Styling system

Sole owner: Styling Analyst. These IDs catch cross-file CSS pathologies that the Frontend Analyst's per-file lens misses by design (z-index wars, token fragmentation, cascade brittleness). The Styling Analyst's system-inventory pre-pass (see `styling-prepass.md`) is mandatory before filing STYLE-1, STYLE-4, STYLE-5, STYLE-6, or STYLE-7 findings. Run only when the Scout emits `styling-surface: present`.

| ID | Item | Min tier | Owner |
|----|------|----------|-------|
| STYLE-1 | z-index war — multiple z-index values without a documented stacking system; magic numbers (`9999`, `99999`) used to win cascade. Look for the same z-index repeated across unrelated components, escalation chains (`9`, `99`, `999`), or `position` interaction bugs (e.g., `transform` / `filter` / `will-change` creating a stacking context that traps `z-index`) | T1 | Styling |
| STYLE-2 | Specificity escalation — `.foo.foo`, descendant chains, or `!important` ladders used to override prior rules instead of refactoring. Includes attribute-selector duplication (`[data-x][data-x]`) and ID-then-class chains | T1 | Styling |
| STYLE-3 | Spaghetti inheritance — child rule depends on 3+ ancestor selectors' computed values; refactor-fragile. Look for selectors like `.a .b .c .d` where the depth carries semantic load (not just specificity) | T2 | Styling |
| STYLE-4 | Design-token fragmentation — same color/size/spacing magic value (`#3b82f6`, `12px`, `24px`) repeated across files when a token system exists OR should. Threshold: ≥3 occurrences across ≥2 files for a value that's not 0, 1, auto, or 100% | T1 | Styling |
| STYLE-5 | Custom-property duplication — `--brand-blue` (or equivalent) defined in 2+ places with drift (different values across the duplicates) | T1 | Styling |
| STYLE-6 | Breakpoint inconsistency — mixed media-query vocabularies (`768px` here, `48em` there, `md` in Tailwind classes elsewhere) without a unified breakpoint constant set | T2 | Styling |
| STYLE-7 | Dead CSS — selectors with no matching markup; orphaned classes; unused `@keyframes`. Static check: grep markup for class names referenced in CSS and vice versa. Mark Plausible if dynamic class composition is detected (template literals, `clsx`, `classnames`, `cva`, runtime concat) — analyst cannot know runtime usage | T1 | Styling |
| STYLE-8 | Tailwind config bloat — unused `theme.extend` keys (no usage in any class string), custom utilities duplicating built-ins, arbitrary values (`w-[127px]`) where a token fits. Only when Tailwind is in use | T1 | Styling |
| STYLE-9 | CSS-in-JS recreation — style objects, `styled.X` template literals with closure-captured props, or `css\`…\`` instances built inside the render path each render without memoization. Look for inline literals inside JSX, hooks, or render functions | T2 | Styling |
| STYLE-10 | Shorthand/longhand conflict — `margin: 0` followed by `margin-top: 8px` in the same rule, or longhand silently reset by a later shorthand in cascade order | T1 | Styling |
| STYLE-11 | Cascade ordering brittleness — final rendered look depends on stylesheet load order; reordering imports or build-output concatenation breaks UI. Symptom: a `@layer`-less mix of base/components/utilities + reliance on a specific import sequence in `main.css` / `app.tsx` | T2 | Styling |

## UX — Frontend UX (non-A11y)

| ID | Item | Min tier | Owner |
|----|------|----------|-------|
| UX-1 | Inconsistent or confusing UI look & feel (spacing, typography, iconography, affordances) | T2 | Frontend, Styling |
| UX-2 | Inconsistent keyboard shortcuts or mouse interactions | T2 | Frontend |

## DB — Database schema

| ID | Item | Min tier | Owner |
|----|------|----------|-------|
| DB-1 | Schema design (missing constraints, wrong types, missing FKs, denormalization pain) | T1 | Database |
| DB-2 | Over-engineered schema for tier (unused tables/columns, premature partitioning, speculative indirection) | T1 | Database |
| DB-3 | Over-simplified schema (missing indexes, no constraints, text where enum fits) | T1 | Database |
| DB-4 | Inefficient queries (N+1, missing index, full scan, unbounded results) | T1 | Database |
| DB-5 | Inefficient query patterns (transaction boundaries, batching, chattiness, ORM misuse) | T1 | Database |

## MIG — Migration safety

Split out from DB: a good schema can still be delivered unsafely.

| ID | Item | Min tier | Owner |
|----|------|----------|-------|
| MIG-1 | Non-concurrent index creation on a table that'd lock under load | T2 | Database |
| MIG-2 | Add-NOT-NULL-without-default (or equivalent) that'd break existing rows | T2 | Database |
| MIG-3 | Irreversible down migration without documented rationale | T2 | Database |
| MIG-4 | Migration touching a large table without batching | T2 | Database |
| MIG-5 | Schema change and data backfill mixed into one migration | T2 | Database |

## TEST — Tests

| ID | Item | Min tier | Owner |
|----|------|----------|-------|
| TEST-1 | Test name does not match what is actually tested | T1 | Test |
| TEST-2 | Vague or non-descriptive test name | T1 | Test |
| TEST-3 | Missing unit test for behavior that should have one | T1 | Test |
| TEST-4 | Missing E2E test for a user-visible flow | T2 | Test |
| TEST-5 | Redundant tests — same setup, same assertion | T1 | Test |
| TEST-6 | Tautological tests — assert the mock's return value, not the system's contract | T1 | Test |
| TEST-7 | Repeated heavy setup where once would suffice | T1 | Test |
| TEST-8 | Concurrency-unsafe test suite (fails under parallel workers) | T2 | Test |
| TEST-9 | Slow tests not tagged per project convention | T2 | Test |
| TEST-10 | Spec file mixes unrelated concerns | T1 | Test |
| TEST-11 | Async test relies on sleeps/timeouts/polling instead of waiting on explicit events, promises, stream/process completion, fake timers, or test-runner lifecycle hooks | T1 | Test |
| TEST-12 | Test starts async work without awaiting or otherwise joining it, so pass/fail depends on scheduler timing or leaked work from a previous test | T1 | Test |

## DET — Test determinism

| ID | Item | Min tier | Owner |
|----|------|----------|-------|
| DET-1 | Test depends on wall-clock time / timezone without pinning | T1 | Test |
| DET-2 | Test depends on RNG without seed | T1 | Test |
| DET-3 | Test depends on filesystem state not set up per-test | T1 | Test |
| DET-4 | Test depends on execution order of sibling tests | T1 | Test |

## FUZZ — Property / fuzz opportunities

| ID | Item | Min tier | Owner |
|----|------|----------|-------|
| FUZZ-1 | Security-sensitive parser / decoder / builder (input to shell, SQL, path, deserializer, auth token decoder) with no fuzz or property tests | T2 | Security, Test |

## COV — Test coverage

Owned by the Coverage & Profiling Analyst, dispatched in the regular Step 3 parallel fan-out. The analyst auto-detects the project's coverage command and runs it unattended; if no coverage system is detected, COV-4 fires with severity scaled to project tier. Static checks (source→test mapping, public-surface inference, config review) always run regardless of dynamic-pass success. COV-4 / COV-5 / COV-6 emit at tier-graded severity (Low / Medium / High mapping to user-stated minor / medium / major); the checklist Min tier column controls applicability (the items always apply, hence T1) while the analyst chooses the per-finding severity.

| ID | Item | Min tier | Owner |
|----|------|----------|-------|
| COV-1 | Source files with zero test coverage (static: no `*.test.*` / `*.spec.*` / `tests/` sibling pointing at them; dynamic: 0% line coverage in a reachable file) | T1 | Coverage |
| COV-2 | Public API surface (exported functions / HTTP handlers / CLI subcommands) with no tests exercising the surface, even when the internals are tested | T2 | Coverage |
| COV-3 | Coverage-config gaps — exclusions that hide real code (e.g., `**/*.ts` without narrowing), no coverage threshold gate in CI where one would fit the project tier | T2 | Coverage |
| COV-4 | Missing test coverage tracking system — no `*.test.*` / `*.spec.*` runner config (`vitest.config.*`, `jest.config.*`, `pytest.ini`, `pyproject.toml [tool.pytest.*]`, `bunfig.toml`, etc.) AND no coverage-producing flag in any `package.json` script / Makefile target / justfile recipe / Taskfile target. Severity scales with tier: T1 = Low, T2 = Medium, T3 = High. T1 hobby projects can reasonably skip but absence is still a Low signal; T2 small-team projects need it to gate regressions; T3 production projects need it to ship | T1 | Coverage |
| COV-5 | Coverage threshold not documented — coverage tracking exists but no hard/aspired threshold is named in the coverage config OR in an instruction file (`AGENTS.md` / `CLAUDE.md` / `GEMINI.md` / `README.md`). Severity = Low at all tiers. Tooling-config-only documentation IS sufficient (e.g., `vitest.config.ts` with `coverage: { thresholds: { lines: 70 } }` counts as documented); the AGENTS.md preference applies only when nothing is documented anywhere. Fix: implementation session asks the maintainer for the threshold and writes it into the project's preferred instruction file | T1 | Coverage |
| COV-6 | Coverage below documented or recommended threshold — current line coverage is below either (a) the documented threshold from coverage config / instruction file, or (b) the derived recommended floor `max(tier_floor, current − 5pp)` where `tier_floor = 50% / 65% / 80%` for T1 / T2 / T3. Line metric only — branch / function / statement get noisy. Severity scales with tier: T1 = Low, T2 = Medium, T3 = High | T1 | Coverage |

## PROF — Profiling / benchmarking

| ID | Item | Min tier | Owner |
|----|------|----------|-------|
| PROF-1 | Performance-sensitive path (declared as such in code comments, benchmarked in-repo, or flagged by a PERF-\* finding) without a repeatable bench target | T2 | Coverage |
| PROF-2 | Existing bench/profile artifacts (`*.prof`, flamegraphs) in-repo are stale (>6 months older than the code paths they cover) or orphaned (refer to symbols that no longer exist) | T2 | Coverage |

## SEC — Security

Single bucket on purpose; severity + location carry the detail.

| ID | Item | Min tier | Owner |
|----|------|----------|-------|
| SEC-1 | Any vulnerability: authn/authz gaps, input validation, injection (SQL/shell/HTML/path), secrets handling, crypto misuse, deserialization, SSRF, ReDoS, subprocess safety, file access, OWASP top 10 | T1 | Security |

## CONT — Container / image security

Only if Dockerfile / Containerfile / OCI build present.

| ID | Item | Min tier | Owner |
|----|------|----------|-------|
| CONT-1 | Container runs as root (no `USER` non-root directive) | T2 | Tooling, Security |
| CONT-2 | Base image uses `:latest` or otherwise unpinned tag | T2 | Tooling |
| CONT-3 | Secrets baked into image layers (env, COPY) | T1 | Security |
| CONT-4 | Multi-stage build absent where it'd cut image size meaningfully | T2 | Tooling |

## CI — CI supply chain & workflow security

Only if CI config (`.github/workflows/**`, `.gitlab-ci.yml`, etc.) present.

| ID | Item | Min tier | Owner |
|----|------|----------|-------|
| CI-1 | Third-party Action pinned to tag (`@v3`) instead of commit SHA | T2 | Tooling, Security |
| CI-2 | Workflow with `permissions: write-all` or unset (defaults to write on older repos) | T2 | Tooling, Security |
| CI-3 | Secrets exposed to `pull_request` (fork) triggers instead of `pull_request_target` with guards | T2 | Tooling, Security |
| CI-4 | Self-hosted runner on a public repo without protections | T3 | Tooling, Security |
| CI-5 | Tests run against a different artifact than the one CI just built or will release — e.g., running source files directly while publishing a Bun/SEA/pkg/Nuitka/PyInstaller binary, Docker image, transpiled bundle, minified browser bundle, generated client, or compiled package without smoke-testing that artifact | T1 | Tooling, Security |

## TOOL — Tooling & build (non-CI, non-CONT, non-BUILD)

**Version-freshness rule for TOOL-3.** Same contract as DEP-1 — cite a live source (native outdated command, web search, or registry query) for "latest stable version" claims. Do not cite from LLM memory. See `analyst-ground-rules.md` "Dependency freshness checks".


| ID | Item | Min tier | Owner |
|----|------|----------|-------|
| TOOL-1 | Redundant tooling — multiple tools doing the same job (npm + pnpm + bun; tsc + esbuild where `bun build` suffices) | T1 | Tooling |
| TOOL-2 | Non-idiomatic tooling usage for the stack | T1 | Tooling |
| TOOL-3 | Outdated tooling versions | T1 | Tooling |
| TOOL-4 | Over-engineered build / dev tooling for the project's tier | T1 | Tooling |
| TOOL-5 | Over-simplified build / dev tooling (no cache, no type check, no lint) | T2 | Tooling |
| TOOL-6 | CI/CD inefficiency (uncached steps, serial jobs that could parallelize, redundant matrix) | T2 | Tooling |
| TOOL-7 | Workflow errors — wrong triggers, wrong permissions, wrong `on:` events | T2 | Tooling |

## BUILD — Build reproducibility

| ID | Item | Min tier | Owner |
|----|------|----------|-------|
| BUILD-1 | Lockfile missing / not committed for a language that supports one | T2 | Tooling |
| BUILD-2 | Lockfile ↔ manifest drift (declared deps don't match resolved) | T1 | Tooling |
| BUILD-3 | Toolchain version unpinned (missing `.nvmrc` / `.tool-versions` / `rust-toolchain` / `pyproject` python-requires) | T2 | Tooling |
| BUILD-4 | Built/release artifact is not verified after packaging — tests, smoke checks, or contract checks exercise source/intermediate files only, not the actual executable, image, bundle, package, or generated artifact users receive | T1 | Tooling |

## GIT — Git hygiene

| ID | Item | Min tier | Owner |
|----|------|----------|-------|
| GIT-1 | Missing top-level LICENSE file | T2 | Docs |
| GIT-2 | Large generated / binary file tracked that belongs in build output | T2 | Tooling |
| GIT-3 | Apparent secret committed in history (reachable by `git log -p`) | T1 | Security |
| GIT-4 | `.gitignore` gaps — build outputs, OS files, editor files tracked | T1 | Tooling |

## IAC — Infrastructure as Code

Only if terraform / k8s manifests / helm / pulumi / cloudformation present.

| ID | Item | Min tier | Owner |
|----|------|----------|-------|
| IAC-1 | Resource without limits/requests (k8s), without size cap (cloud storage), or with wildcard IAM (`*`) | T2 | Tooling, Security |
| IAC-2 | Ingress/egress rules broader than the workload needs | T2 | Tooling, Security |
| IAC-3 | State file handling insecure (local-only backend on shared infra) | T3 | Tooling, Security |

## MONO — Monorepo boundary violations

Only if workspaces / monorepo layout present.

| ID | Item | Min tier | Owner |
|----|------|----------|-------|
| MONO-1 | Package imports across a boundary the layout implies is private | T2 | Backend, Frontend |
| MONO-2 | Circular dependency between packages | T2 | Backend, Frontend |

## DEAD — Dead flags, deprecations, stale TODOs

Complements EFF-3 (dead code).

| ID | Item | Min tier | Owner |
|----|------|----------|-------|
| DEAD-1 | Feature flag still referenced after its decision is made (always-true or always-false everywhere) | T2 | Backend, Frontend |
| DEAD-2 | `@deprecated` symbol still imported by live callsites | T1 | Backend, Frontend |
| DEAD-3 | TODO / FIXME older than ~12 months (by blame) with no tracking ticket or rationale | T1 | Docs |

## COM — Comments & inline documentation

| ID | Item | Min tier | Owner |
|----|------|----------|-------|
| COM-1 | Under-commented non-obvious code (hidden invariant, subtle side effect, tricky dependency) | T1 | Backend, Frontend |
| COM-2 | Redundant or stale comments (describe what the code obviously does, or describe old behavior) | T1 | Backend, Frontend |
| COM-3 | Comments that lie (contradict the code they sit above) | T1 | Backend, Frontend |

## DOC — Documentation

| ID | Item | Min tier | Owner |
|----|------|----------|-------|
| DOC-1 | Code disagrees with its own inline comments | T1 | Docs |
| DOC-2 | Code disagrees with `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` | T1 | Docs |
| DOC-3 | Code disagrees with `README.md` or `docs/**` | T1 | Docs |
| DOC-4 | Ambiguous or hard-to-follow documentation | T2 | Docs |
| DOC-5 | Documentation that would be more useful to an LLM or new contributor if restructured or rephrased — give a concrete pointer | T2 | Docs |

## META — Agent-instruction maintenance

| ID | Item | Min tier | Owner |
|----|------|----------|-------|
| META-1 | Missing agent-instruction rule that would have prevented a recurring finding. List the finding IDs it would cover and draft the one-line rule for the project's preferred instruction file. | T1 | Docs |

META-1 is drafted during synthesis (see `synthesis.md` §7), not during the Docs agent's first pass. The Docs agent owns the checklist line; input comes from merged findings.
