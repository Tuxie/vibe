# Styling Analyst Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a dedicated Styling Analyst (CSS, preprocessors, CSS-in-JS, utility-CSS configs, design tokens) with 11 new STYLE-* checklist IDs to the codebase-deep-analysis skill, integrated via joint ownership with Frontend on existing FE-styling/A11Y-3/UX-1/PERF-2 IDs and applicability-gated on a new `styling-surface` Scout flag.

**Architecture:** Pure documentation change to the skill's reference files. No new code, no new tests beyond the existing version-metadata validation script. Each task edits one file (or one logical unit per file) and commits independently so reviewers can land changes piecemeal if needed. Final task bumps the plugin version and verifies the metadata script still passes.

**Tech Stack:** Markdown documentation in `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/`. Bash validation script `plugins/codebase-deep-analysis/scripts/test-version-metadata.sh`. No build step.

**Spec:** `docs/specs/2026-04-28-styling-analyst-design.md`

**Note on TDD shape:** This skill is a documentation artifact; the only executable validation is the version-metadata script. Each task therefore has a "verify" step (read the diff, grep for the inserted content) rather than a failing-test → passing-test loop. Where a content shape is enforced (e.g., five canonical checklist line shapes), the task explicitly checks the shape after editing.

---

## File Structure

| File | Action | Responsibility |
|------|--------|----------------|
| `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/styling-prepass.md` | Create | System-inventory addendum appended to the Styling Analyst's prompt at dispatch |
| `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/structure-scout-prompt.md` | Modify | Add `styling-surface` applicability flag detection |
| `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/checklist.md` | Modify | Add `## STYLE — Styling system` section + update Owner column on existing joint IDs |
| `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/agent-roster.md` | Modify | Add Styling Analyst row + update ownership-collision and joint-item notes |
| `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/synthesis.md` | Modify | Add §4 collision example + §6 cluster-hint vocabulary note + §5 system-inventory pre-pass note |
| `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/SKILL.md` | Modify | Add Step 2 applicability-gate mention + Step 3 dispatch addendum (append `styling-prepass.md` for Styling) |
| `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/VERSION` | Modify | Bump `3.7.2` → `3.8.0` |
| `plugins/codebase-deep-analysis/skills/implement-analysis-report/VERSION` | Modify | Bump `3.7.2` → `3.8.0` (test-version-metadata.sh requires sync) |
| `plugins/codebase-deep-analysis/.claude-plugin/plugin.json` | Modify | Bump `version` `3.7.2` → `3.8.0` |

`references/agent-prompt-template.md` and `references/analyst-ground-rules.md` are intentionally NOT modified — the wrapper is generic and ground rules are universal.

---

### Task 1: Create the Styling Analyst pre-pass addendum

**Files:**
- Create: `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/styling-prepass.md`

This file holds the cross-file system-inventory pre-pass instructions that get appended to the wrapper output when dispatching the Styling Analyst. The pre-pass is the differentiator vs the existing Frontend Analyst's CSS coverage — without it, the Styling Analyst degrades into a per-file linter and misses z-index wars, token fragmentation, and dead selectors.

- [ ] **Step 1: Create the file with the full pre-pass text**

Write `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/styling-prepass.md` with this exact content:

```markdown
# Styling Analyst — system-inventory pre-pass

Append this section to the standard `agent-prompt-template.md` wrapper when dispatching the Styling Analyst. Do **not** paste it into other analysts' prompts. The pre-pass exists because cross-file CSS pathologies (z-index wars, token fragmentation, dead selectors) are invisible to a per-file scan; the analyst must build a system inventory before filing per-file findings.

```
## Styling-specific pre-pass

Before filing any STYLE-1, STYLE-4, STYLE-5, STYLE-6, or STYLE-7 finding, build a **system inventory** by reading across your scope:

1. **z-index inventory** — list every `z-index` declaration in your scope with its `file:line`, the selector, and the value. STYLE-1 findings cite this inventory. Watch for stacking-context traps: a `transform`, `filter`, `will-change`, or `position: fixed` ancestor creates a stacking context that traps `z-index` values inside.
2. **Color/size magic-number census** — list every literal color (hex, rgb, hsl, named), spacing value (px, rem, em), font-size, and border-radius used ≥3 times across ≥2 files. STYLE-4 findings cite this census. Skip 0, 1, 100%, auto.
3. **Custom-property roll-up** — list every `--*` definition across all stylesheets, grouped by name. STYLE-5 findings name the duplicates and quote the divergent values.
4. **Breakpoint vocabulary** — list every distinct media-query breakpoint value (px, em, rem) and every Tailwind responsive prefix used (`sm:`, `md:`, `lg:`, `xl:`, `2xl:`). STYLE-6 findings name the divergence between hardcoded values and the configured token set.
5. **Selector-to-markup cross-reference** — for STYLE-7, sample selectors from your scope (≥30 across the codebase, biased toward older files) and grep the project's markup paths (`*.tsx`, `*.jsx`, `*.svelte`, `*.vue`, `*.html`, `*.astro`) for matching class names. Mark Plausible, not Verified, if dynamic class composition is detected (`clsx(`, `classnames(`, template literals with `${...}`, `cva(`, `tw\``).

Emit the pre-pass output as a single optional `### System inventory` block under your `### Findings` section, before individual findings. Keep it dense — one bullet per inventory item, no prose. Synthesis reads it for cross-cutting themes (`synthesis.md` §5). If any inventory category is genuinely empty (e.g., no `--*` declarations exist anywhere), say so in one line: `Custom-property roll-up: 0 declarations across scope.` Do not omit the heading.
```
```

- [ ] **Step 2: Verify the file exists and is readable**

Run: `wc -l plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/styling-prepass.md`
Expected: a non-zero line count (the file should be ~25 lines).

Run: `grep -c '^##' plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/styling-prepass.md`
Expected: `1` (one top-level heading).

- [ ] **Step 3: Commit**

```bash
git add plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/styling-prepass.md
git commit -m "$(cat <<'EOF'
codebase-deep-analysis: add styling-prepass.md (system-inventory addendum)

The Styling Analyst (incoming v3.8.0) needs a cross-file pre-pass to
catch z-index wars, design-token fragmentation, custom-property
duplication, breakpoint inconsistency, and dead CSS — pathologies that
a per-file scan misses by design. This addendum gets appended to the
generic wrapper when dispatching the Styling Analyst.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 2: Add `styling-surface` applicability flag to the Scout

**Files:**
- Modify: `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/structure-scout-prompt.md` — insert one new bullet in the Applicability flags section after `i18n-intent` (around line 103).

The Scout emits applicability flags that the orchestrator uses to prune analysts. Adding `styling-surface` lets the orchestrator skip the Styling Analyst on backend-only / library-only repos.

- [ ] **Step 1: Locate the insertion point**

Run: `grep -n "i18n-intent" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/structure-scout-prompt.md`
Expected: one match around line 103, the `- \`i18n-intent\` — i18n framework import, ...` bullet.

- [ ] **Step 2: Insert the new flag definition immediately after the `i18n-intent` line**

Edit `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/structure-scout-prompt.md`. Find this line:

```
- `i18n-intent` — i18n framework import, `locales/` dir, bidi CSS, or explicit docs mention.
```

Replace with:

```
- `i18n-intent` — i18n framework import, `locales/` dir, bidi CSS, or explicit docs mention.
- `styling-surface` — any of: ≥1 file matching `*.css`, `*.scss`, `*.sass`, `*.postcss`, `*.less`, `*.styl`; ≥1 component file (`*.svelte`, `*.vue`, `*.astro`, `*.tsx`, `*.jsx`, `*.html`) containing a `<style>` block (grep first 200 lines, presence is enough); a CSS-in-JS dependency in the manifest (`styled-components`, `@emotion/*`, `@stitches/*`, `@vanilla-extract/*`, `linaria`, `@linaria/*`, `@pandacss/*`, `goober`, `@compiled/*`); or a utility-CSS config (`tailwind.config.{js,ts,mjs,cjs}`, `uno.config.*`, `panda.config.*`, `windi.config.*`, `unocss.config.*`). Independent of `web-facing-ui`: an Electron app, an email-template repo, or a static-site generator may have a styling surface without a public web UI. If none of the above is found, emit `styling-surface: absent — no stylesheets, no CSS-in-JS dep, no utility-CSS config`.
```

- [ ] **Step 3: Verify**

Run: `grep -c "styling-surface" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/structure-scout-prompt.md`
Expected: `1` (one match for the flag definition).

Run: `grep -n "i18n-intent\|styling-surface" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/structure-scout-prompt.md`
Expected: two consecutive lines, `styling-surface` directly after `i18n-intent`.

- [ ] **Step 4: Commit**

```bash
git add plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/structure-scout-prompt.md
git commit -m "$(cat <<'EOF'
codebase-deep-analysis: scout emits styling-surface applicability flag

Used by the orchestrator to skip the incoming Styling Analyst on
backend-only / library-only repos. Detection covers stylesheets,
component <style> blocks, CSS-in-JS deps, and utility-CSS configs;
independent of web-facing-ui so Electron apps and email-template
repos can opt in.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 3: Add the `## STYLE` checklist section

**Files:**
- Modify: `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/checklist.md` — insert a new `## STYLE — Styling system` section between `## FE — Frontend code practices` (ends at line 219) and `## UX — Frontend UX (non-A11y)` (starts at line 220).

11 new IDs (STYLE-1 through STYLE-11), sole owner = Styling Analyst.

- [ ] **Step 1: Locate the insertion point**

Run: `grep -n "^## " plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/checklist.md | head -20`
Confirm `## FE — Frontend code practices` and `## UX — Frontend UX (non-A11y)` are adjacent (FE ends ~line 219, UX starts ~line 220).

- [ ] **Step 2: Insert the new section**

Edit the file. Find this exact block (the last FE row followed by the UX heading):

```
| FE-23 | Inconsistent CSS class naming — no naming convention (BEM, utility-first, SMACSS, etc.) or convention exists but is violated; class names mix casing styles (`btn-primary` vs `submitButton` vs `card_header`) within the same project | T1 | Frontend |

## UX — Frontend UX (non-A11y)
```

Replace with:

```
| FE-23 | Inconsistent CSS class naming — no naming convention (BEM, utility-first, SMACSS, etc.) or convention exists but is violated; class names mix casing styles (`btn-primary` vs `submitButton` vs `card_header`) within the same project | T1 | Frontend |

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
```

- [ ] **Step 3: Verify the section landed**

Run: `grep -c "^| STYLE-" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/checklist.md`
Expected: `11` (eleven STYLE-* rows).

Run: `grep -n "^## STYLE\|^## UX" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/checklist.md`
Expected: `## STYLE` appears immediately before `## UX`.

- [ ] **Step 4: Commit**

```bash
git add plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/checklist.md
git commit -m "$(cat <<'EOF'
codebase-deep-analysis: add STYLE-1..STYLE-11 checklist IDs

Sole owner: incoming Styling Analyst. Covers z-index wars, specificity
escalation, spaghetti inheritance, design-token fragmentation, custom-
property duplication, breakpoint inconsistency, dead CSS, Tailwind
config bloat, CSS-in-JS render-path recreation, shorthand/longhand
conflicts, and cascade-ordering brittleness. Tier filtering puts the
T2 IDs (STYLE-3/6/9/11) on N/A for T1 hobby projects unless counter-
evidence of intent exists.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 4: Update Owner column on joint-ownership IDs

**Files:**
- Modify: `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/checklist.md` — change the Owner column on 10 existing rows: PERF-2 (line ~45), A11Y-3 (line ~125), FE-1 (line ~196), FE-6 (line ~201), FE-7 (line ~202), FE-8 (line ~203), FE-21 (line ~216), FE-22 (line ~217), FE-23 (line ~218), UX-1 (line ~224).

Joint ownership means both the original owner AND `Styling` appear in the Owner column. Synthesis already handles dedup by anchor (`synthesis.md` §2) and per-scope checklist line emission (`synthesis.md` §4).

- [ ] **Step 1: Edit each Owner cell**

Edit `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/checklist.md`. Apply each of these exact replacements:

PERF-2: replace
```
| PERF-2 | Bundle size / cold start — large imports, no code-splitting, duplicate deps in bundle | T2 | Frontend |
```
with
```
| PERF-2 | Bundle size / cold start — large imports, no code-splitting, duplicate deps in bundle. Joint ownership: Styling co-owns the CSS-bundle slice (unused utility classes shipping, duplicate keyframes, oversized stylesheet imports); Frontend keeps the JS-bundle slice. | T2 | Frontend, Styling |
```

A11Y-3: replace
```
| A11Y-3 | Color-only signal, or contrast below WCAG AA | T2 | Frontend |
```
with
```
| A11Y-3 | Color-only signal, or contrast below WCAG AA | T2 | Frontend, Styling |
```

FE-1: replace
```
| FE-1 | Inline `style="..."` or `!important` used to force cascade where a class / utility / scoped-CSS rule fits | T1 | Frontend |
```
with
```
| FE-1 | Inline `style="..."` or `!important` used to force cascade where a class / utility / scoped-CSS rule fits | T1 | Frontend, Styling |
```

FE-6: replace
```
| FE-6 | Mixed styling systems without a documented split — two or more of Tailwind, CSS Modules, styled-components / Emotion, plain global CSS, inline styles — all carrying real styling load | T2 | Frontend |
```
with
```
| FE-6 | Mixed styling systems without a documented split — two or more of Tailwind, CSS Modules, styled-components / Emotion, plain global CSS, inline styles — all carrying real styling load | T2 | Frontend, Styling |
```

FE-7: replace
```
| FE-7 | Deep CSS nesting / specificity wars (>3 levels, or chains like `div.container > ul > li > a.active`) where a flat class would fit | T1 | Frontend |
```
with
```
| FE-7 | Deep CSS nesting / specificity wars (>3 levels, or chains like `div.container > ul > li > a.active`) where a flat class would fit | T1 | Frontend, Styling |
```

FE-8: replace
```
| FE-8 | Global-CSS leaks in a project that otherwise scopes styles (unscoped selectors in a CSS-Modules / Svelte-scoped / Vue-scoped project) | T1 | Frontend |
```
with
```
| FE-8 | Global-CSS leaks in a project that otherwise scopes styles (unscoped selectors in a CSS-Modules / Svelte-scoped / Vue-scoped project) | T1 | Frontend, Styling |
```

FE-21: replace
```
| FE-21 | Duplicated CSS property blocks — same set of properties/values repeated across multiple selectors instead of extracted to a shared class, mixin, or CSS custom-property group. Look for ≥3 selectors sharing ≥3 identical declarations | T1 | Frontend |
```
with
```
| FE-21 | Duplicated CSS property blocks — same set of properties/values repeated across multiple selectors instead of extracted to a shared class, mixin, or CSS custom-property group. Look for ≥3 selectors sharing ≥3 identical declarations | T1 | Frontend, Styling |
```

FE-22: replace
```
| FE-22 | Missing component base classes — repeated UI elements (buttons, inputs, cards, menus, modals, badges) styled individually instead of sharing a common base class with variant modifiers. Changing one instance's style doesn't propagate to others | T1 | Frontend |
```
with
```
| FE-22 | Missing component base classes — repeated UI elements (buttons, inputs, cards, menus, modals, badges) styled individually instead of sharing a common base class with variant modifiers. Changing one instance's style doesn't propagate to others | T1 | Frontend, Styling |
```

FE-23: replace
```
| FE-23 | Inconsistent CSS class naming — no naming convention (BEM, utility-first, SMACSS, etc.) or convention exists but is violated; class names mix casing styles (`btn-primary` vs `submitButton` vs `card_header`) within the same project | T1 | Frontend |
```
with
```
| FE-23 | Inconsistent CSS class naming — no naming convention (BEM, utility-first, SMACSS, etc.) or convention exists but is violated; class names mix casing styles (`btn-primary` vs `submitButton` vs `card_header`) within the same project | T1 | Frontend, Styling |
```

UX-1: replace
```
| UX-1 | Inconsistent or confusing UI look & feel (spacing, typography, iconography, affordances) | T2 | Frontend |
```
with
```
| UX-1 | Inconsistent or confusing UI look & feel (spacing, typography, iconography, affordances) | T2 | Frontend, Styling |
```

- [ ] **Step 2: Verify**

Run: `grep -c "Frontend, Styling" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/checklist.md`
Expected: `10` (ten joint-ownership rows; PERF-2, A11Y-3, FE-1, FE-6, FE-7, FE-8, FE-21, FE-22, FE-23, UX-1).

Run: `grep -E "^\| (FE-1|FE-6|FE-7|FE-8|FE-21|FE-22|FE-23|A11Y-3|UX-1|PERF-2) " plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/checklist.md | grep -vc "Frontend, Styling"`
Expected: `0` (no joint-ID row should still say only `Frontend`).

- [ ] **Step 3: Commit**

```bash
git add plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/checklist.md
git commit -m "$(cat <<'EOF'
codebase-deep-analysis: joint Frontend+Styling ownership on visual IDs

FE-1, FE-6, FE-7, FE-8, FE-21, FE-22, FE-23, A11Y-3, UX-1, and the
CSS-bundle slice of PERF-2 become joint between Frontend and the
incoming Styling Analyst. Each analyst keeps its own checklist line
scoped to its lens (synthesis.md §4); findings dedup by file:line
anchor (synthesis.md §2). Mirrors the existing CI-1/FUZZ-1 joint
pattern.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 5: Add Styling Analyst row + ownership notes to roster

**Files:**
- Modify: `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/agent-roster.md` — insert a new row in the roster table between `Frontend Analyst` (line 14) and `Database Analyst` (line 15); update the "Ownership collisions" section (around lines 37–46).

- [ ] **Step 1: Insert the Styling Analyst row**

Edit `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/agent-roster.md`. Find the Frontend row and the Database row (they are adjacent in the table):

```
| **Frontend Analyst** | Standard | `src/routes/**`, `src/components/**`, `src/lib/**` client files, `*.svelte`, `*.tsx`, `*.jsx`, `*.vue`, `*.html`, `*.css`, `*.scss`, `*.postcss`, `public/**`, CSS/Tailwind configs | EFF-1..EFF-3 (frontend-scoped), PERF-1..PERF-3, PERF-5, QUAL-1..QUAL-11 (frontend-scoped), ERR-4, ERR-5, CONC-1, CONC-2, CONC-4, CONC-6, CONC-7, OBS-4, TYPE-1..TYPE-3, A11Y-1..A11Y-5, I18N-1..I18N-3 (if `i18n-intent`), SEO-1..SEO-3 (if `web-facing-ui`), FE-1..FE-23, UX-1, UX-2, DEP-1..DEP-9 (frontend-scoped; prefer FE-9..FE-14 for frontend-specific overlap patterns), NAM-1..NAM-7 (frontend-scoped), NAM-8 (UI strings), DEAD-1, DEAD-2, COM-1..COM-3, MONO-1, MONO-2 (if monorepo) |
| **Database Analyst** | Standard | `migrations/**`, `schema/**`, `*.sql`, ORM model files, query-builder usage sites | DB-1..DB-5, MIG-1..MIG-5 |
```

Replace with (Styling row inserted between Frontend and Database):

```
| **Frontend Analyst** | Standard | `src/routes/**`, `src/components/**`, `src/lib/**` client files, `*.svelte`, `*.tsx`, `*.jsx`, `*.vue`, `*.html`, `*.css`, `*.scss`, `*.postcss`, `public/**`, CSS/Tailwind configs | EFF-1..EFF-3 (frontend-scoped), PERF-1..PERF-3, PERF-5, QUAL-1..QUAL-11 (frontend-scoped), ERR-4, ERR-5, CONC-1, CONC-2, CONC-4, CONC-6, CONC-7, OBS-4, TYPE-1..TYPE-3, A11Y-1..A11Y-5, I18N-1..I18N-3 (if `i18n-intent`), SEO-1..SEO-3 (if `web-facing-ui`), FE-1..FE-23, UX-1, UX-2, DEP-1..DEP-9 (frontend-scoped; prefer FE-9..FE-14 for frontend-specific overlap patterns), NAM-1..NAM-7 (frontend-scoped), NAM-8 (UI strings), DEAD-1, DEAD-2, COM-1..COM-3, MONO-1, MONO-2 (if monorepo) |
| **Styling Analyst** | Standard | `**/*.css`, `**/*.scss`, `**/*.sass`, `**/*.postcss`, `**/*.less`, `**/*.styl`, `**/*.module.{css,scss}`, `<style>` blocks in `*.svelte` / `*.vue` / `*.astro` / `*.tsx` / `*.jsx` / `*.html`, CSS-in-JS literals (`styled.X\`…\``, `css\`…\``, `sx={…}`, `style={{…}}`), utility-CSS configs (`tailwind.config.*`, `uno.config.*`, `panda.config.*`, `windi.config.*`, `unocss.config.*`), theme/token files (`**/theme.{ts,js,json,css}`, `**/tokens.{ts,js,json,css}`, `**/design-tokens/**`). Runs only when Scout emits `styling-surface: present`. | STYLE-1..STYLE-11 (sole owner); FE-1, FE-6, FE-7, FE-8, FE-21, FE-22, FE-23 (joint with Frontend); A11Y-3 (joint with Frontend); UX-1 (joint with Frontend); PERF-2 (joint with Frontend, CSS-bundle slice only) |
| **Database Analyst** | Standard | `migrations/**`, `schema/**`, `*.sql`, ORM model files, query-builder usage sites | DB-1..DB-5, MIG-1..MIG-5 |
```

- [ ] **Step 2: Update the Ownership collisions section**

In the same file, find this block (around line 37–46):

```
## Ownership collisions

Where the same checklist ID appears under two agents (e.g., `QUAL-1` for both Backend and Frontend), each agent keeps its own checklist line scoped to its paths — they do **not** fight for a single `[x]`. Synthesis merges overlapping *findings* by anchor but leaves both checklist lines in the report with subscope noted (see `synthesis.md` §4).

Joint items (e.g., `CI-1` owned by Tooling + Security, `FUZZ-1` by Test + Security): each owner examines from its own lens. Tooling looks at CI workflow ergonomics; Security looks at trust boundaries and secret exposure. Synthesis merges by anchor.

`NAM-8` (user-visible text — typos, grammar) is intentionally split:
- Frontend owns UI strings.
- Backend owns log messages and CLI output.
- Docs owns `*.md` files and inline comments.
```

Replace with (a Styling-specific bullet inserted before the NAM-8 paragraph):

```
## Ownership collisions

Where the same checklist ID appears under two agents (e.g., `QUAL-1` for both Backend and Frontend), each agent keeps its own checklist line scoped to its paths — they do **not** fight for a single `[x]`. Synthesis merges overlapping *findings* by anchor but leaves both checklist lines in the report with subscope noted (see `synthesis.md` §4).

Joint items (e.g., `CI-1` owned by Tooling + Security, `FUZZ-1` by Test + Security): each owner examines from its own lens. Tooling looks at CI workflow ergonomics; Security looks at trust boundaries and secret exposure. Synthesis merges by anchor.

**Frontend + Styling joint ownership** on `FE-1`, `FE-6`, `FE-7`, `FE-8`, `FE-21`, `FE-22`, `FE-23`, `A11Y-3`, `UX-1`, and the CSS-bundle slice of `PERF-2`. Frontend's lens is component-shape (this `<div style={{}}>` indicates a missing prop type); Styling's lens is system-shape (this inline style is one of 47 magic colors that should be a token). Synthesis dedup by `file:line` anchor handles the overlap. For `PERF-2`, Frontend keeps JS-bundle weight; Styling owns CSS-bundle weight (unused utility classes, duplicate keyframes, oversized stylesheet imports).

`NAM-8` (user-visible text — typos, grammar) is intentionally split:
- Frontend owns UI strings.
- Backend owns log messages and CLI output.
- Docs owns `*.md` files and inline comments.
```

- [ ] **Step 3: Verify**

Run: `grep -c "Styling Analyst" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/agent-roster.md`
Expected: ≥2 (one in the table, one in the collisions section).

Run: `grep -n "Styling Analyst\|Database Analyst\|Frontend Analyst" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/agent-roster.md | head -10`
Expected: Frontend → Styling → Database in that order in the roster table.

- [ ] **Step 4: Commit**

```bash
git add plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/agent-roster.md
git commit -m "$(cat <<'EOF'
codebase-deep-analysis: register Styling Analyst in roster

New agent at Standard tier, applicability-gated on styling-surface.
Sole owner of STYLE-1..STYLE-11; joint owner with Frontend on
FE-1/6/7/8/21/22/23, A11Y-3, UX-1, and the CSS-bundle slice of PERF-2.
Ownership-collisions section now documents the Frontend/Styling
lens-split convention.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 6: Update synthesis.md with Styling references

**Files:**
- Modify: `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/synthesis.md` — three small edits: §4 (collision example), §5 (system-inventory pre-pass note), §6 (cluster-hint vocabulary note).

- [ ] **Step 1: Update §4 collision example**

Edit `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/synthesis.md`. Find this block (the §4 example):

```
When two agents own the same checklist ID for their respective scopes (e.g., Backend and Frontend both own `QUAL-1`), the report shows **both** checklist lines with subscope noted:

```
QUAL-1 [x] (backend) src/lib/server/enrichment.ts:120 — see finding #4
QUAL-1 [x] (frontend) clean — sampled all components under src/lib/components
```

The findings themselves dedup by anchor per §2; ownership collision is a checklist-display concern, not a findings concern.
```

Replace with (an additional Frontend/Styling example added):

```
When two agents own the same checklist ID for their respective scopes (e.g., Backend and Frontend both own `QUAL-1`), the report shows **both** checklist lines with subscope noted:

```
QUAL-1 [x] (backend) src/lib/server/enrichment.ts:120 — see finding #4
QUAL-1 [x] (frontend) clean — sampled all components under src/lib/components
```

Frontend/Styling joint items (`FE-1`, `FE-6`, `FE-7`, `FE-8`, `FE-21`, `FE-22`, `FE-23`, `A11Y-3`, `UX-1`, `PERF-2`) follow the same pattern with the lens-split documented in `agent-roster.md`:

```
FE-1 [x] (frontend) src/components/Header.tsx:42 — inline style on tag suggests missing prop typing
FE-1 [x] (styling) src/components/Header.tsx:42 — one of 47 magic colors; consolidate via tokens
```

The findings themselves dedup by anchor per §2; ownership collision is a checklist-display concern, not a findings concern.
```

- [ ] **Step 2: Add a §5 note acknowledging the system-inventory pre-pass**

In the same file, find this block (the §5 theme entry shape):

```
## 5. Promote cross-cutting themes

If the same pattern appears in **≥3 distinct files across ≥2 agents** after right-sizing, create a theme entry:
```

Replace with:

```
## 5. Promote cross-cutting themes

If the same pattern appears in **≥3 distinct files across ≥2 agents** after right-sizing, create a theme entry:

The Styling Analyst's optional `### System inventory` block (z-index inventory, magic-number census, custom-property roll-up, breakpoint vocabulary, selector-to-markup x-ref — see `styling-prepass.md`) feeds this step directly. An inventory entry that recurs across ≥2 source files is a theme candidate; promote it the same way as analyst findings, with `Raised by: Styling Analyst (system inventory)` as the attribution.
```

- [ ] **Step 3: Add a §6 note about the controlled cluster-hint vocabulary**

In the same file, find the §6 step 7 block ("Name clusters"):

```
7. **Name clusters.** Use kebab-case slugs that describe the work, not the area (`swap-console-log-for-pino`, not `logging`). Prefix numbering reflects recommended fix order (Critical/High first, independent clusters before dependent ones).
```

Replace with:

```
7. **Name clusters.** Use kebab-case slugs that describe the work, not the area (`swap-console-log-for-pino`, not `logging`). Prefix numbering reflects recommended fix order (Critical/High first, independent clusters before dependent ones). The Styling Analyst uses a closed cluster-hint vocabulary (documented in its prompt) to prevent slug sprawl on visual-layer findings — `z-stack-cleanup`, `cascade-spaghetti`, `design-token-consolidation`, `breakpoint-unification`, `dead-styles`, `tailwind-config-cleanup`, `css-in-js-render-path`, `shorthand-longhand-bugs`, `style-system-consolidation`, `nesting-and-specificity`, `scope-leak-fix`, `style-dedup-and-base-classes`, `class-naming-pass`, `inline-style-and-important`, `palette-and-contrast`, `css-bundle-trim`. Same-hint findings from Frontend and Styling merge during reshape (step 2 above). Future analysts may adopt the closed-vocabulary pattern; this is not a cross-skill registry, just per-analyst prompt discipline.
```

- [ ] **Step 4: Verify**

Run: `grep -c "Styling Analyst" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/synthesis.md`
Expected: ≥3 (one each in §4, §5, §6).

Run: `grep -c "z-stack-cleanup" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/synthesis.md`
Expected: `1`.

- [ ] **Step 5: Commit**

```bash
git add plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/synthesis.md
git commit -m "$(cat <<'EOF'
codebase-deep-analysis: synthesis docs Styling Analyst integration

§4 gets a Frontend/Styling collision example with the lens-split
convention. §5 acknowledges the System inventory pre-pass output as
theme-promotion input. §6 documents the closed cluster-hint vocabulary
the Styling Analyst uses to prevent slug sprawl on visual-layer
findings.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 7: Update SKILL.md for applicability gating + dispatch addendum

**Files:**
- Modify: `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/SKILL.md` — Step 2 (applicability pruning) and Step 3 (dispatch substitutions).

- [ ] **Step 1: Update Step 2 applicability-pruning examples**

Edit `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/SKILL.md`. Find this line in Step 2:

```
- **Applicability pruning.** Drop analysts whose scope is absent: no web UI → skip Frontend; no DB → skip Database; no CI config → Tooling still runs (it owns BUILD/GIT even without CI) but its CI-specific items become `[-] N/A`.
```

Replace with:

```
- **Applicability pruning.** Drop analysts whose scope is absent: no web UI → skip Frontend; no DB → skip Database; no styling surface → skip Styling; no CI config → Tooling still runs (it owns BUILD/GIT even without CI) but its CI-specific items become `[-] N/A`.
```

- [ ] **Step 2: Update Step 3 dispatch substitutions to mention the Styling addendum**

In the same file, find this block in Step 3 (the substitutions list ends with `{APPLICABILITY_FLAGS}`):

```
- `{APPLICABILITY_FLAGS}` — Scout's applicability flags block (including sub-flags like `web-facing-ui: present, auth-gated`). Analysts key default N/A behaviors off these.

Hard rules the wrapper + ground rules enforce (read both before editing):
```

Replace with (a single sentence inserted between the substitutions list and the Hard rules header):

```
- `{APPLICABILITY_FLAGS}` — Scout's applicability flags block (including sub-flags like `web-facing-ui: present, auth-gated`). Analysts key default N/A behaviors off these.

**Styling Analyst dispatch addendum.** When dispatching the Styling Analyst (and only that analyst), append the contents of `references/styling-prepass.md` to the wrapper output before sending. The pre-pass instructs the analyst to build a system inventory across its scope before filing per-file findings — it is the differentiator vs the Frontend Analyst's per-file CSS coverage. Other analysts receive the wrapper unchanged.

Hard rules the wrapper + ground rules enforce (read both before editing):
```

- [ ] **Step 3: Verify**

Run: `grep -c "no styling surface\|styling-prepass.md\|Styling Analyst dispatch addendum" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/SKILL.md`
Expected: `3` (one match each).

- [ ] **Step 4: Commit**

```bash
git add plugins/codebase-deep-analysis/skills/codebase-deep-analysis/SKILL.md
git commit -m "$(cat <<'EOF'
codebase-deep-analysis: SKILL.md handles Styling Analyst dispatch

Step 2 applicability pruning lists styling-surface alongside the
existing skip rules. Step 3 dispatch documents the styling-prepass.md
addendum that gets appended to the generic wrapper for Styling Analyst
runs only.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 8: Bump plugin and skill versions to 3.8.0

**Files:**
- Modify: `plugins/codebase-deep-analysis/.claude-plugin/plugin.json`
- Modify: `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/VERSION`
- Modify: `plugins/codebase-deep-analysis/skills/implement-analysis-report/VERSION`

`scripts/test-version-metadata.sh` requires all three to match. New analyst is a feature addition → bump minor (3.7.2 → 3.8.0).

- [ ] **Step 1: Update plugin.json**

Edit `plugins/codebase-deep-analysis/.claude-plugin/plugin.json`. Replace:

```
  "version": "3.7.2",
```

with:

```
  "version": "3.8.0",
```

- [ ] **Step 2: Update codebase-deep-analysis VERSION**

Replace the entire content of `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/VERSION` with:

```
3.8.0
```

(File should be exactly that one line plus a trailing newline.)

- [ ] **Step 3: Update implement-analysis-report VERSION**

Replace the entire content of `plugins/codebase-deep-analysis/skills/implement-analysis-report/VERSION` with:

```
3.8.0
```

- [ ] **Step 4: Run the version-metadata validator**

Run: `bash plugins/codebase-deep-analysis/scripts/test-version-metadata.sh`
Expected output:
```
codebase-deep-analysis plugin and bundled skill versions ok: 3.8.0
```
Expected exit code: `0`.

If the script reports a mismatch, re-check the three files — all must contain exactly `3.8.0` (and the JSON file's `version` field must be the string `"3.8.0"`).

- [ ] **Step 5: Commit**

```bash
git add plugins/codebase-deep-analysis/.claude-plugin/plugin.json plugins/codebase-deep-analysis/skills/codebase-deep-analysis/VERSION plugins/codebase-deep-analysis/skills/implement-analysis-report/VERSION
git commit -m "$(cat <<'EOF'
codebase-deep-analysis: bump to 3.8.0 (Styling Analyst)

Adds the Styling Analyst with 11 STYLE-* checklist IDs, joint
Frontend/Styling ownership on visual-layer items, applicability gating
on the new styling-surface Scout flag, and a system-inventory pre-pass
that catches z-index wars and design-token fragmentation the per-file
Frontend lens misses.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 9: Final verification pass

**Files:** none (read-only checks).

This task is a final sanity sweep before declaring the change complete. No edits, no commit (everything has already been committed task-by-task).

- [ ] **Step 1: Re-run the version-metadata validator**

Run: `bash plugins/codebase-deep-analysis/scripts/test-version-metadata.sh`
Expected: `codebase-deep-analysis plugin and bundled skill versions ok: 3.8.0` and exit code `0`.

- [ ] **Step 2: Verify the frontmatter validator script still works**

The frontmatter validator validates cluster frontmatter shape; it should be unaffected by these changes. Run a smoke check to confirm it executes without error on a no-clusters directory:

Run: `bash plugins/codebase-deep-analysis/skills/codebase-deep-analysis/scripts/validate-frontmatter.sh /tmp 2>&1 | head -20 || true`
Expected: either exits cleanly or emits a `no clusters/ subdir found` message — whichever the script does on an empty/missing report directory. The point is to confirm the script is still syntactically valid bash; we are not validating actual cluster files.

- [ ] **Step 3: Spot-check critical files for the changes**

Run these greps and confirm each returns the expected count:

```bash
grep -c "STYLE-" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/checklist.md
# Expected: ≥11 (the eleven STYLE-1..STYLE-11 rows; possibly more if STYLE- appears in prose)

grep -c "Styling Analyst" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/agent-roster.md
# Expected: ≥2

grep -c "styling-surface" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/structure-scout-prompt.md
# Expected: 1

grep -c "Styling Analyst\|styling-prepass" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/SKILL.md
# Expected: ≥2

cat plugins/codebase-deep-analysis/skills/codebase-deep-analysis/VERSION
# Expected: 3.8.0

cat plugins/codebase-deep-analysis/skills/implement-analysis-report/VERSION
# Expected: 3.8.0

node -e 'console.log(JSON.parse(require("fs").readFileSync(process.argv[1], "utf8")).version)' plugins/codebase-deep-analysis/.claude-plugin/plugin.json
# Expected: 3.8.0

ls plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/styling-prepass.md
# Expected: file exists, no error
```

- [ ] **Step 4: Verify commit history**

Run: `git log --oneline -10`
Expected: 8 new commits on top of the spec commit, in this order (most recent first):
1. version bump to 3.8.0
2. SKILL.md handles Styling Analyst dispatch
3. synthesis docs Styling Analyst integration
4. register Styling Analyst in roster
5. joint Frontend+Styling ownership on visual IDs
6. add STYLE-1..STYLE-11 checklist IDs
7. scout emits styling-surface applicability flag
8. add styling-prepass.md (system-inventory addendum)

If commits are missing or out of order, do not amend — note the discrepancy and report it. The test-version-metadata pass plus the spot-check greps are the load-bearing acceptance gates.

- [ ] **Step 5: Run the codebase-deep-analysis skill on a real project (manual smoke test)**

This step is the only end-to-end validation possible without running the analyst infrastructure. Pick a real frontend project (any repo with stylesheets or CSS-in-JS) and run:

```
/codebase-deep-analysis  # or however the skill is invoked in the user's harness
```

Expected during the run:
- Scout output's Applicability flags block includes a `styling-surface: present` (or `absent`) line.
- If `present`, the Step 3 parallel dispatch announces the Styling Analyst alongside Frontend/Backend/etc.
- Run metadata in the final report's README mentions the Styling Analyst.
- If the project has stylesheets, the report contains at least one STYLE-* finding OR a Styling-Analyst checklist block.

Do NOT make this a blocker. If the smoke run reveals a mismatch, file an issue and iterate; the static plan completion (Steps 1–4) is the merge gate.

---

## Self-Review

**Spec coverage:**

| Spec section | Plan task |
|--------------|-----------|
| Roster entry (Styling Analyst row) | Task 5 Step 1 |
| Applicability gating (`styling-surface` flag) | Task 2 |
| Joint-ownership rules (FE-1/6/7/8/21/22/23, A11Y-3, UX-1, PERF-2) | Task 4 (checklist column) + Task 5 Step 2 (roster note) |
| Cluster-hint vocabulary | Task 6 Step 3 (synthesis §6 note) |
| New checklist IDs (STYLE-1..STYLE-11) | Task 3 |
| Cross-file reasoning pre-pass addendum | Task 1 (file) + Task 7 Step 2 (dispatch wiring) |
| Escalation rules (no special-casing) | Implicit — no plan task needed; existing escalation rules in agent-roster.md "Escalation" section apply unchanged |
| Synthesis impact (§1b health, §3 right-sizing, §6 clustering) | Task 6 (the parts that need explicit edits); §1b/§3 work unchanged |
| Run metadata additions | Implicit — Run metadata is rendered by SKILL.md Step 5 from each analyst's dispatch decision; no template change needed |
| Files to change table | Tasks 1–8 cover every row; the analyst-prompt-template.md and analyst-ground-rules.md non-changes are documented |
| Version bump | Task 8 |

All spec sections are covered. The "Self-evolving feedback loop" and "Out of scope" sections in the spec are commentary, not implementation requirements.

**Placeholder scan:** None. All code/config blocks contain exact content, all commands are runnable, all expected outputs are stated.

**Type consistency:** No types in this plan (it's documentation editing). The flag name `styling-surface` is used identically across Tasks 2, 5, 7. The 11 STYLE-* IDs use the same min-tier values (T1/T2) as the spec's table. The 16 cluster-hint slugs in Task 6 Step 3 match the spec's vocabulary table. The 10 joint-ownership IDs in Task 4 match the spec's "Add Styling as joint owner" entries.
