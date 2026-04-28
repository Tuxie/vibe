# Styling Analyst — design

**Skill:** `codebase-deep-analysis`
**Target version:** 3.8.0
**Status:** design (awaiting implementation plan)
**Author intent:** the Frontend Analyst owns CSS today (FE-1, FE-6, FE-7, FE-8, FE-21, FE-22, FE-23) but is stretched across markup + framework code + styles. CSS pathologies that need cross-file reasoning — z-index wars, spaghetti inheritance, design-token fragmentation, dead selectors — slip through. Add a dedicated **Styling Analyst** with a styling-system mandate (CSS, preprocessors, CSS-in-JS, utility-CSS configs, design tokens) and 11 new STYLE-* checklist IDs.

## Goals

1. Catch CSS pathologies the current Frontend Analyst misses, especially those requiring cross-file reasoning.
2. Stay within the existing skill's read-only, parallel-dispatch, applicability-gated, tier-filtered architecture — no new infrastructure.
3. Slot cleanly into existing synthesis: dedup, clustering, executive summary, render-mode selection all work unchanged.

## Non-goals

- **Not** a runtime style auditor. Static read-only analysis only. Findings about "this rule is overridden at runtime" stay `Plausible` unless both rules can be named at file:line.
- **Not** an accessibility tool. A11Y-3 (color contrast / color-only signal) is added as joint ownership but the Styling Analyst's lens is "what palette/token is used and where", not "does this pass WCAG against rendered backgrounds." Frontend Analyst remains the primary A11Y owner.
- **Not** a redesign of the Frontend Analyst. Frontend keeps its existing scope and owned IDs. Joint ownership + synthesis dedup is the integration mechanism.
- **Not** a performance profiler. PERF-2 joint ownership is scoped to the CSS-bundle slice (unused Tailwind classes shipping, duplicate keyframes, oversized stylesheet imports). JS-bundle weight stays Frontend.

## Architecture

### Roster entry

| Agent | Default model tier | In-scope paths / patterns | Owned checklist IDs |
|-------|---------------|---------------------------|---------------------|
| **Styling Analyst** | Standard | `**/*.css`, `**/*.scss`, `**/*.sass`, `**/*.postcss`, `**/*.less`, `**/*.styl`, `**/*.module.{css,scss}`, `<style>` blocks in `*.svelte` / `*.vue` / `*.astro` / `*.tsx` / `*.jsx` / `*.html`, CSS-in-JS literals (`styled.X\`…\``, `css\`…\``, `sx={…}`, `style={{…}}`), utility-CSS configs (`tailwind.config.*`, `uno.config.*`, `panda.config.*`, `windi.config.*`, `unocss.config.*`), theme/token files (`**/theme.{ts,js,json,css}`, `**/tokens.{ts,js,json,css}`, `**/design-tokens/**`) | STYLE-1..STYLE-11 (sole owner); FE-1, FE-6, FE-7, FE-8, FE-21, FE-22, FE-23 (joint with Frontend); A11Y-3 (joint with Frontend); UX-1 (joint with Frontend); PERF-2 (joint with Frontend, CSS-bundle slice only) |

Inserted between **Frontend Analyst** and **Database Analyst** in `agent-roster.md`'s table to keep visual-layer agents adjacent.

### Applicability gating

New Scout flag: `styling-surface`. Detection rules (any one triggers `present`):

- ≥1 file matching `*.css`, `*.scss`, `*.sass`, `*.postcss`, `*.less`, `*.styl`.
- ≥1 component file (`*.svelte`, `*.vue`, `*.astro`) with a `<style>` block (grep first 200 lines).
- A CSS-in-JS dependency in the manifest: any of `styled-components`, `@emotion/*`, `@stitches/*`, `@vanilla-extract/*`, `linaria`, `@linaria/*`, `@pandacss/*`, `goober`, `@compiled/*`.
- A utility-CSS config: `tailwind.config.{js,ts,mjs,cjs}`, `uno.config.*`, `panda.config.*`, `windi.config.*`, `unocss.config.*`.

If none → emit `styling-surface: absent — no stylesheets, no CSS-in-JS dep, no utility-CSS config`. Styling Analyst is skipped. Run metadata records the skip.

`styling-surface: present` is independent of `web-facing-ui`. An Electron app, an email-template repo, an embedded-doc renderer, or a static-site generator can all have a styling surface without a public web UI. The flag exists precisely to catch those.

### Joint-ownership rules

The seven existing FE-* styling IDs (FE-1, FE-6, FE-7, FE-8, FE-21, FE-22, FE-23) plus A11Y-3, UX-1, and PERF-2 become **joint** between Frontend and Styling. Synthesis already handles this case:

- Each analyst emits its own checklist line scoped to its lens (per `synthesis.md` §4).
- Findings dedup by `file:line` anchor (per `synthesis.md` §2). When both analysts raise the same finding, severity is the max, confidence is the max, autonomy is the most-conservative, and the merged entry's `Raised by:` lists both.
- Frontend's lens stays component-shape ("this `<div style={{}}>` indicates a missing prop type"); Styling's lens is system-shape ("this inline style is one of 47 magic colors that should be a token").

No changes to Frontend's prompt or owned-ID list — its mandate is unchanged. The skill gains depth, not breadth, on the joint surface.

### Cluster-hint vocabulary

The Styling Analyst uses a controlled vocabulary of cluster hints to prevent the "every finding gets a unique slug → multi-file report is useless" failure mode (`SKILL.md` Common mistakes: "Cluster-hint sprawl"):

| Hint slug | Covers IDs | Description |
|-----------|------------|-------------|
| `z-stack-cleanup` | STYLE-1 | z-index war, magic-number stacking |
| `cascade-spaghetti` | STYLE-2, STYLE-3, STYLE-11 | specificity escalation, brittle inheritance, load-order brittleness |
| `design-token-consolidation` | STYLE-4, STYLE-5 | magic-value duplication, custom-property fragmentation |
| `breakpoint-unification` | STYLE-6 | mixed media-query vocabularies |
| `dead-styles` | STYLE-7 | unused selectors, orphaned classes/keyframes |
| `tailwind-config-cleanup` | STYLE-8 | Tailwind theme bloat, arbitrary-value abuse |
| `css-in-js-render-path` | STYLE-9 | per-render style object recreation |
| `shorthand-longhand-bugs` | STYLE-10 | shorthand/longhand conflicts |
| `style-system-consolidation` | FE-6 | mixed styling systems without documented split |
| `nesting-and-specificity` | FE-7 | deep nesting, specificity wars |
| `scope-leak-fix` | FE-8 | global-CSS leaks in scoped projects |
| `style-dedup-and-base-classes` | FE-21, FE-22 | duplicated blocks, missing base classes |
| `class-naming-pass` | FE-23 | inconsistent class naming |
| `inline-style-and-important` | FE-1 | inline-style/`!important` cleanup |
| `palette-and-contrast` | A11Y-3, UX-1 (color/spacing/typography slice) | joint with Frontend; color & visual-system coherence |
| `css-bundle-trim` | PERF-2 (CSS slice) | unused utility classes shipping, duplicate keyframes |

`synthesis.md` does not currently have a centralized cluster-hint registry. The vocabulary above lives **in the Styling Analyst's prompt as a closed enum** ("emit one of these slugs; if no fit, raise the closest"). `synthesis.md` §6 gets a one-paragraph note acknowledging the controlled-vocabulary pattern and pointing readers at this spec — without elevating cluster hints to a cross-skill registry, which would be a separate change. Same hint may seed clusters across analysts (Frontend and Styling both emitting `inline-style-and-important` is fine — synthesis merges by hint then dedups by file:line anchor).

### New checklist IDs (STYLE-*)

Added as a new top-level section in `references/checklist.md`, between FE and UX (visual layer adjacency). Sole owner: Styling Analyst.

| ID | Item | Min tier |
|----|------|----------|
| STYLE-1 | z-index war — multiple z-index values without a documented stacking system; magic numbers (`9999`, `99999`) used to win cascade. Look for the same z-index repeated across unrelated components, escalation chains (`9`, `99`, `999`), or `position` interaction bugs (e.g., `transform` creating a stacking context that traps `z-index`) | T1 |
| STYLE-2 | Specificity escalation — `.foo.foo`, descendant chains, or `!important` ladders used to override prior rules instead of refactoring. Includes attribute-selector duplication (`[data-x][data-x]`) and ID-then-class chains | T1 |
| STYLE-3 | Spaghetti inheritance — child rule depends on 3+ ancestor selectors' computed values; refactor-fragile. Look for selectors like `.a .b .c .d` where the depth carries semantic load (not just specificity) | T2 |
| STYLE-4 | Design-token fragmentation — same color/size/spacing magic value (`#3b82f6`, `12px`, `24px`) repeated across files when a token system exists OR should. Threshold: ≥3 occurrences across ≥2 files for a value that's not 0/1/auto/100% | T1 |
| STYLE-5 | Custom-property duplication — `--brand-blue` (or equivalent) defined in 2+ places with drift (different values across the duplicates) | T1 |
| STYLE-6 | Breakpoint inconsistency — mixed media-query vocabularies (`768px` here, `48em` there, `md` in Tailwind classes elsewhere) without a unified breakpoint constant set | T2 |
| STYLE-7 | Dead CSS — selectors with no matching markup; orphaned classes; unused `@keyframes`. Static check: grep markup for class names referenced in CSS and vice versa. Mark Plausible if dynamic class composition (template literals, `clsx`, runtime concat) is detected — analyst cannot know runtime usage | T1 |
| STYLE-8 | Tailwind config bloat — unused `theme.extend` keys (no usage in any class string), custom utilities duplicating built-ins, arbitrary values (`w-[127px]`) where a token fits. Only when Tailwind is in use | T1 |
| STYLE-9 | CSS-in-JS recreation — style objects, `styled.X` template literals with closure-captured props, or `css\`…\`` instances built inside the render path each render without memoization. Look for inline literals inside JSX, hooks, or render functions | T2 |
| STYLE-10 | Shorthand/longhand conflict — `margin: 0` followed by `margin-top: 8px` in the same rule, or longhand silently reset by a later shorthand in cascade order | T1 |
| STYLE-11 | Cascade ordering brittleness — final rendered look depends on stylesheet load order; reordering imports or build-output concatenation breaks UI. Symptom: a `@layer`-less mix of base/components/utilities + reliance on a specific import sequence in `main.css` / `app.tsx` | T2 |

### Cross-file reasoning is the differentiator

The prompt template wrapper handed to the Styling Analyst gets one Styling-specific addendum (everything else stays the existing wrapper):

```
## Styling-specific pre-pass

Before filing any STYLE-1, STYLE-4, STYLE-5, STYLE-6, or STYLE-7 finding, build a **system inventory** by reading across your scope:

1. **z-index inventory** — list every `z-index` declaration in your scope with its file:line, the selector, and the value. STYLE-1 findings cite this inventory.
2. **Color/size magic-number census** — list every literal color, spacing, font-size, and radius used ≥3 times in ≥2 files. STYLE-4 findings cite this census.
3. **Custom-property roll-up** — list every `--*` definition across all stylesheets, grouped by name. STYLE-5 findings name the duplicates.
4. **Breakpoint vocabulary** — list every distinct media-query breakpoint value (px, em, rem) and every Tailwind responsive prefix used. STYLE-6 findings name the divergence.
5. **Selector-to-markup cross-reference** — for STYLE-7, sample selectors from your scope and grep the project's markup paths for matching class names. Mark Plausible if dynamic class composition is detected.

The pre-pass output goes under `### Findings` as a single optional `### System inventory` block before individual findings — synthesis reads it to seed cross-cutting themes (`synthesis.md` §5).
```

Without this addendum, the Styling Analyst will degrade into a per-file linter and miss exactly the cross-file pathologies that motivate the agent's existence. The addendum is short (≤25 lines) so the wrapper stays under its 40-line target.

### Escalation rules

Same as every other analyst (no special-casing):

- Default Standard tier.
- Auto-escalate to Senior when scope >50k LOC OR first-pass returns >30 High/Critical findings.
- A T3 design-system monorepo will trip auto-escalate; a T1 hobby site will not.

### Synthesis impact

- §1b health check thresholds apply unchanged. The "high source-drop ratio" signal is more likely to fire on Styling than on most analysts (T1 projects produce a lot of below-threshold STYLE-3/STYLE-6/STYLE-9/STYLE-11 candidates), so the right-sizing filter and source-drop tally must be honest. No threshold tuning — the existing flags are calibration signal, not blockers.
- §3 right-sizing filter: T1 projects with ad-hoc styles get most STYLE-* findings dropped or rewritten. STYLE-1, STYLE-5, STYLE-7, STYLE-10 (T1 IDs) survive on T1; STYLE-3, STYLE-6, STYLE-9, STYLE-11 (T2) get filtered to `[-] N/A — below profile threshold` unless counter-evidence (e.g., a token system already present).
- §6 clustering: cluster hints from the controlled vocabulary above. Hint sprawl is a known failure mode — the controlled vocabulary is the prevention.
- §1b "Suspiciously thin output" threshold (<3 findings on >20 files) applies. A Styling Analyst returning 1 finding on a 50-stylesheet repo is a re-dispatch trigger.

### Run metadata additions

When Styling runs:

```
Styling Analyst: ran (scope: N stylesheets + M CSS-in-JS sites + K config files)
```

When skipped:

```
Styling Analyst: skipped — styling-surface: absent
```

When auto-escalated:

```
Styling Analyst: re-dispatched on senior tier (trigger: scope > 50k LOC | first-pass H/C count > 30)
```

## Files to change

| File | Change |
|------|--------|
| `references/agent-roster.md` | Add Styling Analyst row; update joint-ownership notes for FE-1/6/7/8/21/22/23, A11Y-3, UX-1, PERF-2 |
| `references/checklist.md` | Add `## STYLE — Styling system` section with STYLE-1..STYLE-11; update Owner column on FE-1, FE-6, FE-7, FE-8, FE-21, FE-22, FE-23, A11Y-3, UX-1, PERF-2 to include `Styling`; add note that PERF-2 joint ownership is scoped to CSS-bundle slice |
| `references/structure-scout-prompt.md` | Add `styling-surface` flag definition with detection rules (CSS files, `<style>` blocks, CSS-in-JS deps, utility-CSS configs) |
| `references/synthesis.md` | Add Styling Analyst to ownership-collision examples (§4); add a one-paragraph note to §6 acknowledging the controlled cluster-hint vocabulary used by the Styling Analyst (link to this spec, do not duplicate the table); note that `### System inventory` pre-pass output feeds §5 themes |
| `references/agent-prompt-template.md` | No change — wrapper is generic |
| `references/analyst-ground-rules.md` | Likely no change — ground rules are universal. Verify: cross-scope cite rule still works, sampling-statement contract still works for system-inventory pre-pass output |
| `SKILL.md` | Step 2 mention: Styling Analyst is applicability-gated like Frontend/Database; not in the always-run exception list |
| `VERSION` (skill) | Bump to `3.8.0` |
| `plugins/codebase-deep-analysis/.claude-plugin/plugin.json` | Bump to `3.8.0` |
| `skills/codebase-deep-analysis/scripts/test-frontmatter-validator.sh` | Verify still passes; cluster frontmatter shape unchanged |

No new files. The Styling-specific pre-pass addendum lives inside the prompt assembly logic at dispatch time (or as a small `references/styling-prepass.md` if the SKILL author prefers an external file — implementation-plan-time decision).

## Risks & mitigations

| Risk | Mitigation |
|------|------------|
| **Token cost rises noticeably.** A new analyst running on every styled project = +1 parallel agent at Standard tier. | The applicability flag `styling-surface: absent` skips the analyst entirely on backend-only / library-only repos. On frontend repos, the gain (cross-file CSS findings the current run misses) justifies the cost; the alternative is users repeatedly asking "why didn't it catch the z-index war." |
| **Joint-ownership creates duplicate findings.** Frontend and Styling both file `FE-1` on the same inline-style anchor. | Synthesis §2 dedup by `file:line` already handles this. Cost: ~10–20% raw-finding overlap pre-dedup. Worth it for the joint-lens coverage gain — matches the existing CI-1 / FUZZ-1 joint pattern. |
| **Hint vocabulary leaks.** Styling Analyst invents new hint slugs outside the controlled vocabulary. | Controlled vocabulary is documented in the analyst's prompt with the directive "Use only these hint slugs; if a finding doesn't fit, raise the closest." Synthesis §6.7 reshapes anyway, so vocabulary discipline is a quality lever, not a correctness blocker. |
| **Pre-pass produces a 1000-line inventory dump that bloats the report.** | Pre-pass output goes under `### System inventory` (optional sub-section); synthesis treats it as input for §5 themes, not as report content. The user-facing report shows themes, not raw inventories. Inventories may also live under `.scratch/` if size warrants — implementation-plan-time decision. |
| **CSS-in-JS detection is brittle.** New libraries appear; the manifest list above will go stale. | Detection list lives in the Scout's flag rules. Falsies are cheap (analyst doesn't run); falses-positive on a CSS-in-JS-named package that's actually unrelated is rare and the analyst's pre-pass would surface no findings anyway. Update the detection list as part of normal skill maintenance — not a hard-coded version pin. |
| **Right-sizing filter under-prunes on T1 styling.** A T1 hobby site has ad-hoc CSS by design and would generate dozens of STYLE-4 findings. | STYLE-4 (T1) and STYLE-1 (T1) survive on T1 because they catch real bugs at any scale; STYLE-3, STYLE-6, STYLE-9, STYLE-11 (T2) filter to N/A on T1. Synthesis §3 is the backstop — analysts also drop at source per the tier rule. The filter-activity tally will surface over-emission for review. |

## Self-evolving feedback loop

`analysis-analysis.md` (Step 6) already captures runtime feedback. After 1–2 runs of v3.8 with the Styling Analyst, the v-next author should look for:

- Health-check signals on the Styling Analyst (suspiciously thin output, high source-drop ratio).
- Cluster-hint slug usage statistics (which slugs were used, which never fired, which sprawled).
- Cross-scope cite count (Styling citing files outside its declared scope is a calibration signal).
- Filter activity on STYLE-* IDs (over- or under-emission patterns).

This is the same feedback contract every analyst has — no special instrumentation needed.

## Out of scope (recorded for posterity)

- **Visual regression testing.** Static analysis can't validate "this still looks right." Out of scope.
- **Animation correctness.** `transition` jank, `will-change` misuse, animation performance — these need a browser. Out of scope.
- **Container-query analysis.** Container queries are valid CSS and the analyst sees them, but evaluating "you should use a container query here instead of a media query" is a design call. Out of scope unless we add a STYLE-12 in v-next based on real-world findings.
- **CSS variable type checking.** TypeScript-typed CSS variables (`@property` registrations, typed-CSS frameworks) are an emerging surface. Defer.
- **Runtime style debugging hooks.** Out of scope; this is a static read-only skill.
