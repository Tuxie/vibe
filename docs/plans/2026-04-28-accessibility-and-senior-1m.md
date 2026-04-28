# Accessibility Analyst + Senior-1M tier — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an Accessibility Analyst (sole-transferring A11Y-1..5 + UX-2 from Frontend; adds 5 new A11Y-6..A11Y-10 IDs; new system-inventory pre-pass), introduce a Senior-1M model tier (gradient + Scout-direct paths, never-downgrade harness resolution), promote Scout from Junior to Standard, and add a reasoning-effort axis (default/high/max) to the codebase-deep-analysis skill at v3.10.0.

**Architecture:** Documentation-only changes to one skill (no executable code). Each task edits one file (or one logical SKILL.md set of sections), runs verify greps, and commits independently. Final task bumps version + runs the metadata validator + manually inspects.

**Tech Stack:** Markdown documentation under `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/`. Bash validator `plugins/codebase-deep-analysis/scripts/test-version-metadata.sh`.

**Spec:** `docs/specs/2026-04-28-accessibility-and-senior-1m-design.md` (commit `e7248b6` + amendments through `0dcd830`).

**Note on TDD shape:** Same as v3.8 / v3.9 — documentation work, no test loop. Each task has explicit verify steps (greps, line counts, the version-metadata validator on Task 9) instead of a failing-test loop. Where a content shape is enforced (e.g., the closed cluster-hint vocabulary, the A11Y owner-column transitions), the task explicitly checks the shape after editing.

---

## File Structure

| File | Action | Responsibility |
|------|--------|----------------|
| `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/accessibility-prepass.md` | Create | System-inventory pre-pass addendum appended to the Accessibility Analyst's wrapper at dispatch (mirrors `styling-prepass.md`) |
| `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/checklist.md` | Modify | A11Y section preamble update; A11Y-1..A11Y-5 + UX-2 Owner column changes (Frontend → Accessibility); add A11Y-6..A11Y-10 rows |
| `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/agent-roster.md` | Modify | Add Accessibility Analyst row between Styling and Database; update Frontend row (drop A11Y-* + UX-2); update Ownership-collisions section to document the Frontend/Accessibility lens-split and the Styling+Accessibility two-way joint on A11Y-3; update Escalation section with both Senior-1M paths |
| `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/structure-scout-prompt.md` | Modify | Add the optional `Recommend senior-1m for: <analyst-list>` output block with criteria documentation |
| `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/synthesis.md` | Modify | §6 step 7 — add Accessibility Analyst's closed cluster-hint vocabulary note (mirrors Styling note); §6 step 8 — add senior-1m model-hint upgrade rule + parallel effort-hint rule |
| `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/analyst-ground-rules.md` | Modify | Read-depth requirement update — mention "ARIA attribute semantics" alongside CSS rule blocks; tiny edit |
| `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/analysis-analysis-template.md` | Modify | Run-identity block adds two optional lines: `Senior-1M usage:` and `Effort overrides:` |
| `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/SKILL.md` | Modify | Step 1 — Scout tier flip (Junior→Standard); Step 2 — applicability pruning entry for Accessibility + Scout-recommendation reading rule; Step 3 — Accessibility Analyst dispatch addendum; Model-selection section — Senior-1M tier definition + two escalation paths + Scout-default + harness-resolution rule + reasoning-effort axis; Common-mistakes — three new entries |
| `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/VERSION` | Modify | Bump 3.9.0 → 3.10.0 |
| `plugins/codebase-deep-analysis/skills/implement-analysis-report/VERSION` | Modify | Bump 3.9.0 → 3.10.0 |
| `plugins/codebase-deep-analysis/.claude-plugin/plugin.json` | Modify | Bump version 3.9.0 → 3.10.0 |

`agent-prompt-template.md` is intentionally NOT modified — the wrapper is generic.

Order of tasks is bottom-up (smaller / foundational files first, SKILL.md last) so the references SKILL.md points at are already in place when SKILL.md is rewritten.

---

### Task 1: Create the Accessibility Analyst pre-pass addendum

**Files:**
- Create: `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/accessibility-prepass.md`

The pre-pass instructs the Accessibility Analyst to build a system inventory across its scope before filing per-file findings. Mirrors `styling-prepass.md` in shape and dispatch wiring.

- [ ] **Step 1: Create the file with the full pre-pass text**

Write `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/accessibility-prepass.md` with this exact content (everything between the FILE-START and FILE-END markers, NOT including the markers):

=====FILE-START=====
# Accessibility Analyst — system-inventory pre-pass

Append this section to the standard `agent-prompt-template.md` wrapper when dispatching the Accessibility Analyst. Do **not** paste it into other analysts' prompts. The pre-pass exists because cross-file accessibility pathologies (multiple `<h1>` per page, focus traps that escape across components, ARIA roles that conflict between layout and child) are invisible to a per-file scan; the analyst must build a system inventory before filing per-file findings.

```
## Accessibility-specific pre-pass

Before filing any A11Y-1, A11Y-4, A11Y-6, A11Y-7, or A11Y-9 finding, build a **system inventory** by reading across your scope:

1. **Interactive-element census** — list every `<button>`, `<a>`, `<input>`, `<select>`, `<textarea>`, `[role="button"|"link"|"checkbox"|"radio"|"tab"|"menuitem"]` in your scope with `file:line`. For each, note the source of its accessible name (text content, `aria-label`, `aria-labelledby`, none). A11Y-1 findings cite this census — focus on the "none" entries and the conflicting-name entries (text content + aria-label both set, name conflict).
2. **Landmark inventory** — list every `<main>`, `<nav>`, `<header>`, `<footer>`, `<aside>`, `<section>` (with implicit/explicit name), and `[role="main"|"navigation"|...]` per page or top-level route. A11Y-4 findings cite gaps: missing `<main>`, multiple `<h1>` per page, navs without accessible names, heading-level skips.
3. **Modal/dialog inventory** — list every dialog/modal/sheet/drawer/popover component (look for `<dialog>`, `[role="dialog"]`, `[role="alertdialog"]`, common library names like `Dialog`, `Modal`, `Sheet`, `Drawer`, `Popover`, `Menu`, `Combobox`). For each, audit: focus trap on open? focus return on close? Escape-key handling? A11Y-7 findings cite specific failures.
4. **Form-error inventory** — list every form's error-rendering site. Cross-reference each error to its field via `aria-describedby` / `id` / `for` linkage, or `role="alert"` / `aria-live` for dynamic announcements. A11Y-9 findings cite unbound errors and forms whose submit-error summary does not focus or announce.
5. **ARIA-role census** — list every explicit `role="..."` and `aria-*` attribute usage. Flag obvious misuse: `role` overriding a native semantic element (`<button role="button">`); conflicting attributes (`aria-disabled` on an element that's still interactive); `aria-hidden` on a focusable element (creates an unreachable focus target); `aria-label` on an element whose text content already provides the name (name conflict).

Emit the pre-pass output as a single optional `### A11y inventory` block under your `### Findings` section, before individual findings. Keep it dense — one bullet per inventory item, no prose. Synthesis reads it for cross-cutting themes (`synthesis.md` §5). If any inventory category is genuinely empty (e.g., no modals exist anywhere in scope), say so in one line: `Modal/dialog inventory: 0 found across scope.` Do not omit the heading.

A note on dynamic class composition for selector-based audits: when scanning markup for `role="..."` or `aria-*` attributes inside template literals or `clsx()` / `classnames()` / `cva()` expressions, mark such findings Plausible (not Verified) unless you can statically resolve the value at a specific call site. The same rule applies to the Styling Analyst's STYLE-7 dead-CSS check; reuse the convention.
```
=====FILE-END=====

The file follows the same outer-Markdown + inner-fenced-prompt-block structure as `styling-prepass.md`. The outer file is markdown; the inner fenced block is the prompt-text-to-be-appended.

- [ ] **Step 2: Verify**

Run: `wc -l plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/accessibility-prepass.md`
Expected: ~17–25 lines.

Run: `grep -c '^##' plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/accessibility-prepass.md`
Expected: `1` (one match — the inner `## Accessibility-specific pre-pass` heading inside the fenced block; outer file's `# Accessibility Analyst...` heading uses single `#`).

Run: `head -1 plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/accessibility-prepass.md`
Expected: `# Accessibility Analyst — system-inventory pre-pass`.

- [ ] **Step 3: Commit**

```bash
git add plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/accessibility-prepass.md
git commit -m "$(cat <<'EOF'
codebase-deep-analysis: add accessibility-prepass.md (system-inventory addendum)

The Accessibility Analyst (incoming v3.10.0) needs a cross-file pre-pass
to catch a11y pathologies that a per-file scan misses by design:
multiple h1s per page, focus-trap escapes across components, ARIA-role
conflicts between layout and child, missing form-error association,
modal/dialog focus-return failures. This addendum gets appended to the
generic wrapper when dispatching the Accessibility Analyst, mirroring
the styling-prepass.md pattern.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 2: Update checklist.md — A11Y owners + new IDs

**Files:**
- Modify: `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/checklist.md`

Three concerns: update the `## A11Y` section preamble; change Owner column on A11Y-1..A11Y-5 (Frontend → Accessibility, with A11Y-3 transitioning from Frontend+Styling joint to Styling+Accessibility joint); change Owner column on UX-2 (Frontend → Accessibility); add A11Y-6 through A11Y-10 rows after A11Y-5.

- [ ] **Step 1: Update the A11Y section preamble**

Use Edit. Find:

```
## A11Y — Accessibility (frontend)
```

Replace with:

```
## A11Y — Accessibility (frontend)

Sole owner: Accessibility Analyst (introduced in v3.10). Runs only when the Scout emits `web-facing-ui: present` (any sub-flag including `auth-gated` and `local-only` — auth-gated UIs need a11y too). The Accessibility Analyst's system-inventory pre-pass (see `accessibility-prepass.md`) is mandatory before filing A11Y-1, A11Y-4, A11Y-6, A11Y-7, or A11Y-9 findings. A11Y-3 (color-only signal / contrast) is jointly owned with the Styling Analyst — Styling's lens is palette internal coherence; Accessibility's lens is rendered combinations in markup.
```

- [ ] **Step 2: Update Owner column on A11Y-1, A11Y-2, A11Y-4, A11Y-5**

Use Edit on each row. Find:

```
| A11Y-1 | Interactive element without accessible name (button/link without text or `aria-label`) | T1 | Frontend |
```
Replace with:
```
| A11Y-1 | Interactive element without accessible name (button/link without text or `aria-label`) | T1 | Accessibility |
```

Find:
```
| A11Y-2 | Missing keyboard operability (click-only handler, modal without focus trap) | T1 | Frontend |
```
Replace with:
```
| A11Y-2 | Missing keyboard operability (click-only handler, modal without focus trap) | T1 | Accessibility |
```

Find:
```
| A11Y-4 | Missing or wrong landmark / heading structure (multiple `<h1>`, missing `<main>`) | T2 | Frontend |
```
Replace with:
```
| A11Y-4 | Missing or wrong landmark / heading structure (multiple `<h1>`, missing `<main>`) | T2 | Accessibility |
```

Find:
```
| A11Y-5 | Missing `alt` on meaningful images; decorative images without `alt=""` | T1 | Frontend |
```
Replace with:
```
| A11Y-5 | Missing `alt` on meaningful images; decorative images without `alt=""` | T1 | Accessibility |
```

- [ ] **Step 3: Update Owner column on A11Y-3 (Frontend, Styling → Styling, Accessibility)**

Find:

```
| A11Y-3 | Color-only signal, or contrast below WCAG AA | T2 | Frontend, Styling |
```

Replace with:

```
| A11Y-3 | Color-only signal, or contrast below WCAG AA | T2 | Styling, Accessibility |
```

- [ ] **Step 4: Add A11Y-6 through A11Y-10 rows after A11Y-5**

Find this exact two-line block (A11Y-5 immediately followed by the next `## ` heading — `## I18N`):

```
| A11Y-5 | Missing `alt` on meaningful images; decorative images without `alt=""` | T1 | Accessibility |

## I18N — Internationalization
```

Replace with:

```
| A11Y-5 | Missing `alt` on meaningful images; decorative images without `alt=""` | T1 | Accessibility |
| A11Y-6 | ARIA misuse — wrong role for the element type, conflicting `aria-*` attributes, redundant ARIA on native-semantic elements (`<button role="button">`, `<a role="link">`), `aria-hidden` on focusable elements (creates unreachable focus targets), or `aria-label` on elements that derive their name from text content (name conflict, screen reader announces wrong name). Look for `role="..."` overriding semantic-HTML defaults, attribute combinations that violate the ARIA spec, and labelling conflicts | T2 | Accessibility |
| A11Y-7 | Focus management failures — modal/dialog/sheet/drawer that opens without trapping focus, doesn't return focus to the trigger on close, or skips focus to a non-interactive element. Route changes (SPA navigation) that don't move focus to the new page's heading or main landmark. Skip-to-main link missing on long navigation chains | T1 | Accessibility |
| A11Y-8 | `prefers-reduced-motion` not respected — animations, transitions, parallax, auto-play video, or motion-heavy effects emitted unconditionally. Look for keyframes / transitions / `requestAnimationFrame` usage in components without a `@media (prefers-reduced-motion: reduce)` guard or programmatic equivalent | T2 | Accessibility |
| A11Y-9 | Form errors not announced to assistive tech — error messages rendered visually next to fields without `aria-describedby` association, error containers without `role="alert"` / `aria-live` for dynamic announcements, or single-field validation that paints red borders without a text equivalent. Form-level error summaries that don't focus or announce on submit | T1 | Accessibility |
| A11Y-10 | Touch target size below 24×24 CSS px on interactive elements (`<button>`, `<a>`, `<input>` excepting native sliders, custom-pointer roles). Includes nested touch targets where the visible hit area is smaller than the actual `<button>` element. WCAG 2.2 baseline; default min for primary actions is 44×44, but 24×24 catches the egregious cases | T2 | Accessibility |

## I18N — Internationalization
```

- [ ] **Step 5: Update Owner column on UX-2**

Find:

```
| UX-2 | Inconsistent keyboard shortcuts or mouse interactions | T2 | Frontend |
```

Replace with:

```
| UX-2 | Inconsistent keyboard shortcuts or mouse interactions | T2 | Accessibility |
```

- [ ] **Step 6: Verify**

Run: `grep -c "^| A11Y-" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/checklist.md`
Expected: `10` (A11Y-1..A11Y-10).

Run: `grep -E "^\| (A11Y-1|A11Y-2|A11Y-4|A11Y-5|A11Y-6|A11Y-7|A11Y-8|A11Y-9|A11Y-10|UX-2) " plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/checklist.md | grep -vc "Accessibility"`
Expected: `0` (every A11Y-* and UX-2 row owner cell mentions Accessibility, with A11Y-3 being the only special case below).

Run: `grep -c "^| A11Y-3 " plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/checklist.md`
Expected: `1`.

Run: `grep "^| A11Y-3 " plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/checklist.md`
Expected output to contain: `Styling, Accessibility` (and NOT contain `Frontend`).

Run: `grep -c "Sole owner: Accessibility Analyst" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/checklist.md`
Expected: `1`.

- [ ] **Step 7: Commit**

```bash
git add plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/checklist.md
git commit -m "$(cat <<'EOF'
codebase-deep-analysis: A11Y owner transitions + add A11Y-6..A11Y-10

A11Y-1, A11Y-2, A11Y-4, A11Y-5 transfer sole from Frontend to
Accessibility. A11Y-3 transitions from Frontend+Styling joint to
Styling+Accessibility joint (Frontend exits cleanly). UX-2 transfers
sole to Accessibility. Five new A11Y-* IDs added covering ARIA misuse
(T2), focus management (T1), prefers-reduced-motion respect (T2),
form-error announcement (T1), and touch-target size (T2). A11Y
section preamble rewritten to reflect new ownership and the
mandatory system-inventory pre-pass for findings on the larger IDs.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 3: Update agent-roster.md — Accessibility row + Frontend cell + collisions + Escalation

**Files:**
- Modify: `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/agent-roster.md`

Four concerns: insert the Accessibility Analyst row between Styling and Database; update the Frontend row to drop A11Y-1..A11Y-5 and UX-2; update the Ownership-collisions section; update the Escalation section to document both Senior-1M paths.

- [ ] **Step 1: Insert the Accessibility Analyst row**

Use Edit. Find this exact block (Styling row immediately followed by Database row):

```
| **Styling Analyst** | Standard | `**/*.css`, `**/*.scss`, `**/*.sass`, `**/*.postcss`, `**/*.less`, `**/*.styl`, `**/*.module.{css,scss}`, `<style>` blocks in `*.svelte` / `*.vue` / `*.astro` / `*.tsx` / `*.jsx` / `*.html`, CSS-in-JS literals (`styled.X\`…\``, `css\`…\``, `sx={…}`, `style={{…}}`), utility-CSS configs (`tailwind.config.*`, `uno.config.*`, `panda.config.*`, `windi.config.*`, `unocss.config.*`), theme/token files (`**/theme.{ts,js,json,css}`, `**/tokens.{ts,js,json,css}`, `**/design-tokens/**`). Runs only when Scout emits `styling-surface: present`. | STYLE-1..STYLE-11 (sole owner); FE-1, FE-6, FE-7, FE-8, FE-21, FE-22, FE-23 (joint with Frontend); A11Y-3 (joint with Frontend); UX-1 (joint with Frontend); PERF-2 (joint with Frontend, CSS-bundle slice only) |
| **Database Analyst** | Standard | `migrations/**`, `schema/**`, `*.sql`, ORM model files, query-builder usage sites | DB-1..DB-5, MIG-1..MIG-5 |
```

Replace with this three-row block (Styling row's A11Y-3 joint partner switches to Accessibility; new Accessibility row inserted between Styling and Database):

```
| **Styling Analyst** | Standard | `**/*.css`, `**/*.scss`, `**/*.sass`, `**/*.postcss`, `**/*.less`, `**/*.styl`, `**/*.module.{css,scss}`, `<style>` blocks in `*.svelte` / `*.vue` / `*.astro` / `*.tsx` / `*.jsx` / `*.html`, CSS-in-JS literals (`styled.X\`…\``, `css\`…\``, `sx={…}`, `style={{…}}`), utility-CSS configs (`tailwind.config.*`, `uno.config.*`, `panda.config.*`, `windi.config.*`, `unocss.config.*`), theme/token files (`**/theme.{ts,js,json,css}`, `**/tokens.{ts,js,json,css}`, `**/design-tokens/**`). Runs only when Scout emits `styling-surface: present`. | STYLE-1..STYLE-11 (sole owner); FE-1, FE-6, FE-7, FE-8, FE-21, FE-22, FE-23 (joint with Frontend); A11Y-3 (joint with Accessibility); UX-1 (joint with Frontend); PERF-2 (joint with Frontend, CSS-bundle slice only) |
| **Accessibility Analyst** | Standard | `src/routes/**`, `src/components/**`, `src/lib/**` client files, `*.svelte`, `*.tsx`, `*.jsx`, `*.vue`, `*.astro`, `*.html`, `*.css`, `*.scss`, `*.postcss` (for contrast cross-check), `*.module.{css,scss}`, theme/token files (`**/theme.{ts,js,json,css}`, `**/tokens.{ts,js,json,css}`, `**/design-tokens/**`). Runs only when Scout emits `web-facing-ui: present` (any sub-flag including `auth-gated`, `local-only`). | A11Y-1, A11Y-2, A11Y-4, A11Y-5 (sole — transferred from Frontend in v3.10); A11Y-6..A11Y-10 (sole — new in v3.10); UX-2 (sole — transferred from Frontend in v3.10); A11Y-3 (joint with Styling) |
| **Database Analyst** | Standard | `migrations/**`, `schema/**`, `*.sql`, ORM model files, query-builder usage sites | DB-1..DB-5, MIG-1..MIG-5 |
```

- [ ] **Step 2: Update the Frontend row owned-IDs cell**

Find:

```
| **Frontend Analyst** | Standard | `src/routes/**`, `src/components/**`, `src/lib/**` client files, `*.svelte`, `*.tsx`, `*.jsx`, `*.vue`, `*.html`, `*.css`, `*.scss`, `*.postcss`, `public/**`, CSS/Tailwind configs | EFF-1..EFF-3 (frontend-scoped), PERF-1, PERF-2 (joint with Styling), PERF-3, PERF-5, QUAL-1..QUAL-11 (frontend-scoped), ERR-4, ERR-5, CONC-1, CONC-2, CONC-4, CONC-6, CONC-7, OBS-4, TYPE-1..TYPE-3, A11Y-1, A11Y-2, A11Y-3 (joint with Styling), A11Y-4, A11Y-5, I18N-1..I18N-3 (if `i18n-intent`), SEO-1..SEO-3 (if `web-facing-ui`), FE-1, FE-6, FE-7, FE-8, FE-21, FE-22, FE-23 (joint with Styling), FE-2..FE-5, FE-9..FE-20, UX-1 (joint with Styling), UX-2, DEP-1..DEP-9 (frontend-scoped; prefer FE-9..FE-14 for frontend-specific overlap patterns), NAM-1..NAM-7 (frontend-scoped), NAM-8 (UI strings), DEAD-1, DEAD-2, COM-1..COM-3, MONO-1, MONO-2 (if monorepo) |
```

Replace with (drop A11Y-1, A11Y-2, A11Y-3-joint, A11Y-4, A11Y-5, and UX-2):

```
| **Frontend Analyst** | Standard | `src/routes/**`, `src/components/**`, `src/lib/**` client files, `*.svelte`, `*.tsx`, `*.jsx`, `*.vue`, `*.html`, `*.css`, `*.scss`, `*.postcss`, `public/**`, CSS/Tailwind configs | EFF-1..EFF-3 (frontend-scoped), PERF-1, PERF-2 (joint with Styling), PERF-3, PERF-5, QUAL-1..QUAL-11 (frontend-scoped), ERR-4, ERR-5, CONC-1, CONC-2, CONC-4, CONC-6, CONC-7, OBS-4, TYPE-1..TYPE-3, I18N-1..I18N-3 (if `i18n-intent`), SEO-1..SEO-3 (if `web-facing-ui`), FE-1, FE-6, FE-7, FE-8, FE-21, FE-22, FE-23 (joint with Styling), FE-2..FE-5, FE-9..FE-20, UX-1 (joint with Styling), DEP-1..DEP-9 (frontend-scoped; prefer FE-9..FE-14 for frontend-specific overlap patterns), NAM-1..NAM-7 (frontend-scoped), NAM-8 (UI strings), DEAD-1, DEAD-2, COM-1..COM-3, MONO-1, MONO-2 (if monorepo) |
```

- [ ] **Step 3: Update the Ownership-collisions section**

Find this exact block (the existing Frontend+Styling joint paragraph followed by NAM-8 split):

```
**Frontend + Styling joint ownership** on `FE-1`, `FE-6`, `FE-7`, `FE-8`, `FE-21`, `FE-22`, `FE-23`, `A11Y-3`, `UX-1`, and the CSS-bundle slice of `PERF-2`. Frontend's lens is component-shape (this `<div style={{}}>` indicates a missing prop type); Styling's lens is system-shape (this inline style is one of 47 magic colors that should be a token). Synthesis dedup by `file:line` anchor handles the overlap. For `PERF-2`, Frontend keeps JS-bundle weight; Styling owns CSS-bundle weight (unused utility classes, duplicate keyframes, oversized stylesheet imports).

`NAM-8` (user-visible text — typos, grammar) is intentionally split:
```

Replace with (drop A11Y-3 from the Frontend+Styling joint paragraph; add a new Styling+Accessibility joint paragraph below):

```
**Frontend + Styling joint ownership** on `FE-1`, `FE-6`, `FE-7`, `FE-8`, `FE-21`, `FE-22`, `FE-23`, `UX-1`, and the CSS-bundle slice of `PERF-2`. Frontend's lens is component-shape (this `<div style={{}}>` indicates a missing prop type); Styling's lens is system-shape (this inline style is one of 47 magic colors that should be a token). Synthesis dedup by `file:line` anchor handles the overlap. For `PERF-2`, Frontend keeps JS-bundle weight; Styling owns CSS-bundle weight (unused utility classes, duplicate keyframes, oversized stylesheet imports).

**Styling + Accessibility joint ownership** on `A11Y-3` (color-only signal / WCAG AA contrast). Styling's lens: is the token system internally coherent — does the palette have any combinations that would fail contrast at expected text sizes? Accessibility's lens: is this combination actually rendered against that background in the markup — find the JSX/template sites that combine the tokens problematically. Synthesis dedup by anchor handles the overlap. (Frontend was a third joint owner on A11Y-3 in v3.8–v3.9; v3.10 retired Frontend's role here as part of the broader A11Y-* sole transfer to Accessibility.)

**Accessibility owns sole** on `A11Y-1`, `A11Y-2`, `A11Y-4`, `A11Y-5`, `A11Y-6`, `A11Y-7`, `A11Y-8`, `A11Y-9`, `A11Y-10`, `UX-2`. Frontend does not own A11Y-* and does not own UX-2 — the dispatch wrapper passes Frontend's owned-IDs without these, so the analyst won't file A11Y or keyboard-shortcut findings. Cross-scope observations (the rare case where Frontend spots something Accessibility might miss) still go in `Notes` per the existing convention.

`NAM-8` (user-visible text — typos, grammar) is intentionally split:
```

- [ ] **Step 4: Update the Escalation section**

Find this exact block:

```
## Escalation

A dispatched analyst re-runs on the senior model tier when **either** condition holds:

1. Its declared scope exceeds ~50k LOC (Scout's map numbers it).
2. Its first-pass output contains >30 findings at Severity High or Critical.

The second pass's output merges with the first pass during synthesis (same anchors → dedup per `synthesis.md` §2).
```

Replace with:

```
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
```

- [ ] **Step 5: Verify**

Run: `grep -c "^| \*\*Accessibility Analyst\*\*" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/agent-roster.md`
Expected: `1`.

Run: `grep -n "Frontend Analyst\|Styling Analyst\|Accessibility Analyst\|Database Analyst" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/agent-roster.md | head -10`
Expected: Frontend → Styling → Accessibility → Database in that order in the roster table.

Run: `grep -c "A11Y-3 (joint with Accessibility)" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/agent-roster.md`
Expected: `1` (in the Styling row only, not the Frontend row).

Run: `grep -c "A11Y-1\|A11Y-2\|A11Y-3\|A11Y-4\|A11Y-5" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/agent-roster.md | head -1`
Expected: ≥3 (should mention them in Accessibility row + collisions paragraph + sole-ownership paragraph).

Run: `grep "^| \*\*Frontend Analyst\*\*" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/agent-roster.md | grep -c "A11Y-"`
Expected: `0` (Frontend row no longer mentions any A11Y-* IDs).

Run: `grep -c "Path A — gradient\|Path B — Scout-direct\|Path C — user directive" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/agent-roster.md`
Expected: `3`.

Run: `grep -c "Resolution rule (load-bearing)" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/agent-roster.md`
Expected: `1`.

- [ ] **Step 6: Commit**

```bash
git add plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/agent-roster.md
git commit -m "$(cat <<'EOF'
codebase-deep-analysis: register Accessibility Analyst + Senior-1M tier in roster

New Accessibility Analyst at Standard tier, applicability-gated on
web-facing-ui: present (any sub-flag). Sole owner of A11Y-1..A11Y-10
and UX-2 (transferred from Frontend); joint with Styling on A11Y-3.
Frontend row drops A11Y-* and UX-2 from owned-IDs. Ownership-collisions
section documents the new Styling+Accessibility joint, the sole
ownership of A11Y-1/2/4..10 and UX-2, and the v3.10 retirement of
Frontend's role on A11Y-3. Escalation section rewritten to document
all three Senior-1M paths (gradient, Scout-direct, user-directive),
the reasoning-effort axis pointer, and the load-bearing resolution
rule that prevents silent downgrades on collapsed-senior harnesses.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 4: Update structure-scout-prompt.md — Senior-1M recommendation block

**Files:**
- Modify: `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/structure-scout-prompt.md`

Add an optional output block to the Scout's prompt: `Recommend senior-1m for: <analyst-list>` with one-line `Reason:` per analyst. Most runs emit `Recommend senior-1m for: none`. Insert the block after the existing "Pre-release surface" section (which already exists per the v3.8 work).

- [ ] **Step 1: Locate the insertion point**

Run: `grep -n "^## Pre-release\|^## Notable oddities\|^## Hard rules" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/structure-scout-prompt.md`

The new block goes between "Pre-release verification surface" and "Notable oddities" sections.

- [ ] **Step 2: Insert the recommendation block**

Use Edit. Find this exact block (the closing of "Pre-release surface" section + the start of "Notable oddities"):

```
Recommend `yes` when **both** are present. Synthesis uses this to decide whether to emit a `## Pre-release verification checklist` section in the report README.

## Notable oddities
```

Replace with:

```
Recommend `yes` when **both** are present. Synthesis uses this to decide whether to emit a `## Pre-release verification checklist` section in the report README.

## Senior-1M tier recommendations (optional)

The skill supports a Senior-1M model tier — a senior-class model with the harness's largest available context window — for analyst dispatches where 200k context is genuinely insufficient. Most runs do not need it. This section emits **either** a recommendation list **or** `Recommend senior-1m for: none`; do not omit the section entirely.

Apply these criteria mechanically. Do **not** recommend on subjective grounds ("complex", "hard to reason about", "looks tangled"). Vibes-based recommendations are explicitly out of scope and will be rejected by the orchestrator.

**Trigger criteria (any one is sufficient for the named analyst; multiple analysts may be recommended):**

1. **Single-analyst scope >300k non-vendored LOC.** Compute the analyst's declared scope (from `agent-roster.md` scope-globs) intersected with the file inventory you produced. Exclude `node_modules/`, `vendor/`, `dist/`, `build/`, generated files, and lockfiles. If any single analyst's scope LOC exceeds 300k, recommend that analyst for Senior-1M.

2. **Polyglot single-analyst scope.** When a single analyst's scope spans ≥4 distinct language families (e.g., Backend Analyst on a repo where backend code spans Go services + Python ML + Rust core + TypeScript edge — 4 families). Cross-module reasoning across this many idioms benefits from larger context. Use the language-family classification you produced in the "Tech stack" section above.

3. **Mid-large monorepo cross-cutting Security.** When project total non-vendored LOC >1M AND `security-surface: present`. Security Analyst spans the entire repo by definition; on a 1M+ LOC enterprise monorepo the standard 200k context fragments security reasoning.

4. **Synthesis pre-prediction.** Estimate whether the project's tier + scope + analyst count will produce a synthesis input above 100k tokens. The estimate: `expected_findings ≈ tier_factor × analyst_count × file_count_factor` where `tier_factor` is {T1: 0.5, T2: 1.0, T3: 2.0}, `analyst_count` is the post-applicability-pruning count, and `file_count_factor ≈ log10(non_vendored_files)`. If `expected_findings × 500` (rough chars-per-finding-block) exceeds 350k characters (≈100k tokens), recommend `synthesis` for Senior-1M. The orchestrator's synthesis-specific auto-escalation rule (in `SKILL.md`) provides the same trigger — either path satisfies it.

**Borderline evidence — emit `confidence: low`.**

When evidence is right at a threshold (LOC at 290k–310k, language-family count at 3 with one borderline-vendored language, monorepo at 900k–1.1M LOC, synthesis estimate within 10% of the 100k threshold), emit the recommendation but flag it: `Reason: ...; confidence: low`. The orchestrator defers low-confidence recommendations to Path A's gradient (existing post-hoc escalation) rather than dispatching directly at Senior-1M, but logs the deferred recommendation so the retrospective can record whether ignoring it cost quality.

### Output shape

```
Recommend senior-1m for: {analyst-name-list, or "none"}
Reason: {one bullet per recommended analyst — the specific evidence; include "; confidence: low" if borderline}
```

Examples:

```
Recommend senior-1m for: none
```

```
Recommend senior-1m for: Backend Analyst
Reason: Backend scope is 412k non-vendored LOC across src/server/**, src/lib/server/**, and api/** (criterion 1).
```

```
Recommend senior-1m for: Security Analyst, synthesis
Reason:
- Security Analyst: project total 1.4M non-vendored LOC AND security-surface: present (criterion 3).
- synthesis: T3 + 11 active analysts + ~140 files-per-analyst-avg = synthesis estimate ≈120k tokens (criterion 4).
```

```
Recommend senior-1m for: Frontend Analyst
Reason: Frontend scope is 287k non-vendored LOC; close to threshold (criterion 1); confidence: low.
```

The orchestrator reads this block in Step 2 and dispatches accordingly. Most projects will emit `Recommend senior-1m for: none` — the criteria are intentionally tight.

## Notable oddities
```

- [ ] **Step 3: Verify**

Run: `grep -c "^## Senior-1M tier recommendations" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/structure-scout-prompt.md`
Expected: `1`.

Run: `grep -c "Recommend senior-1m for" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/structure-scout-prompt.md`
Expected: ≥6 (one heading reference, the four example outputs, two prose mentions).

Run: `grep -c "confidence: low" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/structure-scout-prompt.md`
Expected: ≥3.

Run: `grep -n "^## " plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/structure-scout-prompt.md`
Expected: includes both `## Senior-1M tier recommendations (optional)` and `## Notable oddities` in that order.

- [ ] **Step 4: Commit**

```bash
git add plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/structure-scout-prompt.md
git commit -m "$(cat <<'EOF'
codebase-deep-analysis: scout emits Senior-1M tier recommendations

New optional output block 'Recommend senior-1m for: <analyst-list>'
with one-line per-analyst Reason. Four mechanical criteria: single-
analyst scope >300k LOC, polyglot ≥4 language families, mid-large
monorepo Security on >1M LOC, synthesis pre-prediction >100k tokens.
Vibes-based recommendations explicitly forbidden. Borderline evidence
emits 'confidence: low' which the orchestrator defers to Path A
gradient. Most runs emit 'Recommend senior-1m for: none' — criteria
are intentionally tight. The Scout default tier moves to Standard in
this version (separate change in SKILL.md Step 1) so the recommendation
rests on stronger reasoning.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 5: Update synthesis.md — cluster-hint vocabulary + model-hint + effort-hint rules

**Files:**
- Modify: `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/synthesis.md`

Two concerns: extend the §6 step 7 cluster-hint vocabulary note to mention the Accessibility Analyst's vocabulary; extend §6 step 8 model-hint selection rules with the senior-1m upgrade path AND a new parallel `effort-hint:` selection rule.

- [ ] **Step 1: Update §6 step 7 cluster-hint note**

Use Edit. Find this exact block (the existing Styling-vocabulary paragraph at the end of step 7):

```
7. **Name clusters.** Use kebab-case slugs that describe the work, not the area (`swap-console-log-for-pino`, not `logging`). Prefix numbering reflects recommended fix order (Critical/High first, independent clusters before dependent ones). The Styling Analyst uses a closed cluster-hint vocabulary (documented in its prompt) to prevent slug sprawl on visual-layer findings — `z-stack-cleanup`, `cascade-spaghetti`, `design-token-consolidation`, `breakpoint-unification`, `dead-styles`, `tailwind-config-cleanup`, `css-in-js-render-path`, `shorthand-longhand-bugs`, `style-system-consolidation`, `nesting-and-specificity`, `scope-leak-fix`, `style-dedup-and-base-classes`, `class-naming-pass`, `inline-style-and-important`, `palette-and-contrast`, `css-bundle-trim`. Same-hint findings from Frontend and Styling merge during reshape (step 2 above). Future analysts may adopt the closed-vocabulary pattern; this is not a cross-skill registry, just per-analyst prompt discipline.
```

Replace with:

```
7. **Name clusters.** Use kebab-case slugs that describe the work, not the area (`swap-console-log-for-pino`, not `logging`). Prefix numbering reflects recommended fix order (Critical/High first, independent clusters before dependent ones). The Styling Analyst uses a closed cluster-hint vocabulary (documented in its prompt) to prevent slug sprawl on visual-layer findings — `z-stack-cleanup`, `cascade-spaghetti`, `design-token-consolidation`, `breakpoint-unification`, `dead-styles`, `tailwind-config-cleanup`, `css-in-js-render-path`, `shorthand-longhand-bugs`, `style-system-consolidation`, `nesting-and-specificity`, `scope-leak-fix`, `style-dedup-and-base-classes`, `class-naming-pass`, `inline-style-and-important`, `palette-and-contrast`, `css-bundle-trim`. The Accessibility Analyst (v3.10) uses its own closed cluster-hint vocabulary — `semantic-markup-pass` (A11Y-1, A11Y-4, A11Y-5), `keyboard-and-focus` (A11Y-2, A11Y-7, UX-2), `aria-cleanup` (A11Y-6), `motion-respect` (A11Y-8), `form-a11y` (A11Y-9 + FE-18 joint), `touch-targets` (A11Y-10), `palette-and-contrast` (A11Y-3 joint with Styling — same slug as Styling's hint, collapsing during reshape is correct). Same-hint findings from multiple analysts merge during reshape (step 2 above). Future analysts may adopt the closed-vocabulary pattern; this is not a cross-skill registry, just per-analyst prompt discipline.
```

- [ ] **Step 2: Update §6 step 8 model-hint selection rules + add effort-hint rule**

Find the existing Model-hint selection rules block (in §6, after step 7 — search for `### Model-hint selection`):

```
### Model-hint selection

Populate `model-hint:` on every cluster. Use these rules; the field is not user-facing but drives `implement-analysis-report`'s per-cluster subagent dispatch.

- **Default:** `standard`.
- **Downgrade to `junior` when ALL hold:** `Autonomy: autofix-ready`, highest-severity-in-cluster is Low, no finding involves type narrowing (`any → unknown`, generic constraint changes, union refinement), no finding involves async/lifecycle changes (signal handling, cancellation, race fixes), no finding touches cross-module refactoring (shared-abstraction extraction, module split/merge).
- **Upgrade to `senior` when ALL hold:** `Autonomy: needs-spec`, highest-severity-in-cluster is High or Critical, cluster spans >5 distinct files, AND the fix requires maintainer interview + spec design synthesized into code. `senior` is the expensive option — reserve for clusters where the standard tier would likely return shape B ("cannot implement without further decision").

When in doubt: default to `standard`. The hint is a cost optimization, not a correctness constraint; `iar` may override based on its own runtime signal (e.g., a standard-tier cluster that returns shape B twice might escalate to senior on its third attempt — out of scope for this version).
```

Replace with:

```
### Model-hint selection

Populate `model-hint:` on every cluster. Use these rules; the field is not user-facing but drives `implement-analysis-report`'s per-cluster subagent dispatch.

- **Default:** `standard`.
- **Downgrade to `junior` when ALL hold:** `Autonomy: autofix-ready`, highest-severity-in-cluster is Low, no finding involves type narrowing (`any → unknown`, generic constraint changes, union refinement), no finding involves async/lifecycle changes (signal handling, cancellation, race fixes), no finding touches cross-module refactoring (shared-abstraction extraction, module split/merge).
- **Upgrade to `senior` when ALL hold:** `Autonomy: needs-spec`, highest-severity-in-cluster is High or Critical, cluster spans >5 distinct files, AND the fix requires maintainer interview + spec design synthesized into code. `senior` is the expensive option — reserve for clusters where the standard tier would likely return shape B ("cannot implement without further decision").
- **Upgrade to `senior-1m` when ALL hold (v3.10):** `Autonomy: needs-spec`, highest-severity-in-cluster is High or Critical, AND **either** cluster spans >15 distinct files **OR** cluster's source-file footprint exceeds an estimated 50k LOC (e.g., entire backend module rewrite, cross-package monorepo refactor). The fix subagent needs to hold the entire affected subsystem in context simultaneously — standard 200k context fragments the work.

When in doubt: default to `standard`. The hint is a cost optimization, not a correctness constraint; `iar` may override based on its own runtime signal (e.g., a standard-tier cluster that returns shape B twice might escalate to senior on its third attempt — out of scope for this version).

### Effort-hint selection (v3.10)

Populate `effort-hint:` on a cluster ONLY when one of the closed-list triggers fires. Otherwise omit the field (which means `default`). Vocabulary: `default | high | max`.

- **Set `effort-hint: max` when ALL hold:** the cluster has `model-hint: senior-1m` AND `Autonomy: needs-spec`. Synthesizing a fix design and writing code in one pass at this complexity needs maximum reasoning depth. Same model, more thinking budget.

The closed list is intentionally short. Most clusters do not get an effort-hint (omitted = default effort). The `iar` cluster execution honors `effort-hint:` at dispatch when present.

The skill also recommends `effort-hint: max` on the synthesis pass itself when the synthesis-Senior-1M auto-escalation trigger fires (T3 + ≥10 active analysts + ≥100 findings, OR text ≥50k tokens). That recommendation lives in `SKILL.md`'s Step 4 / Model-selection sections; synthesis does not write its own cluster file so this hint is documented in Run metadata under `Effort overrides:` for the retrospective.
```

- [ ] **Step 3: Verify**

Run: `grep -c "Accessibility Analyst (v3.10) uses its own closed cluster-hint vocabulary" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/synthesis.md`
Expected: `1`.

Run: `grep -c "semantic-markup-pass\|keyboard-and-focus\|aria-cleanup\|motion-respect\|form-a11y\|touch-targets" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/synthesis.md`
Expected: ≥1 (all 6 a11y slugs appear in one paragraph; grep counts the line, not occurrences).

Run: `grep -c "Upgrade to .senior-1m. when ALL hold" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/synthesis.md`
Expected: `1`.

Run: `grep -c "Effort-hint selection" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/synthesis.md`
Expected: `1`.

- [ ] **Step 4: Commit**

```bash
git add plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/synthesis.md
git commit -m "$(cat <<'EOF'
codebase-deep-analysis: synthesis docs Accessibility + Senior-1M + effort-hint

§6 step 7 cluster-hint vocabulary note extends to mention the
Accessibility Analyst's seven slugs (semantic-markup-pass,
keyboard-and-focus, aria-cleanup, motion-respect, form-a11y,
touch-targets, palette-and-contrast — same-slug joint with Styling).
§6 step 8 model-hint selection adds a senior-1m upgrade rule for
needs-spec clusters spanning >15 files OR >50k LOC. New §6 step 8
sub-section adds effort-hint selection rules: max effort on senior-1m
+ needs-spec clusters; default everywhere else; synthesis pass itself
gets max-effort recommendation when the synthesis-Senior-1M trigger
fires.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 6: Update analyst-ground-rules.md — read-depth wording

**Files:**
- Modify: `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/analyst-ground-rules.md`

Tiny edit: the existing read-depth requirement names CSS rule blocks as one example of "read beyond imports". Add ARIA attribute semantics as another. Helps nudge the Accessibility Analyst toward genuine attribute reasoning (not just selector matching).

- [ ] **Step 1: Locate the read-depth paragraph**

Run: `grep -n "Read depth requirement\|read beyond imports\|function bodies" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/analyst-ground-rules.md`

The relevant paragraph is the "### Read depth requirement" section near the end of the self-check rubric area.

- [ ] **Step 2: Update the paragraph**

Use Edit. Find:

```
For every file you analyze, you must read beyond imports and type signatures into the implementation — function bodies, event handlers, route handlers, CSS rule blocks, query builders, test assertions. Findings derived solely from file names, directory structure, or import statements are not findings — they are hypotheses that need verification by reading the code.
```

Replace with:

```
For every file you analyze, you must read beyond imports and type signatures into the implementation — function bodies, event handlers, route handlers, CSS rule blocks, ARIA attribute semantics on interactive elements, query builders, test assertions. Findings derived solely from file names, directory structure, or import statements are not findings — they are hypotheses that need verification by reading the code.
```

- [ ] **Step 3: Verify**

Run: `grep -c "ARIA attribute semantics" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/analyst-ground-rules.md`
Expected: `1`.

- [ ] **Step 4: Commit**

```bash
git add plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/analyst-ground-rules.md
git commit -m "$(cat <<'EOF'
codebase-deep-analysis: ground rules — name ARIA semantics in read-depth list

Tiny addition to the read-depth requirement: alongside CSS rule blocks
and query builders, ARIA attribute semantics on interactive elements
become an explicit "must actually read this" example. Nudges the
incoming Accessibility Analyst toward genuine attribute reasoning
rather than selector-matching.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 7: Update analysis-analysis-template.md — Run-identity additions

**Files:**
- Modify: `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/analysis-analysis-template.md`

Two new optional Run-identity lines: `Senior-1M usage:` and `Effort overrides:`. The retrospective template captures runtime feedback.

- [ ] **Step 1: Locate the Run-identity block**

Run: `grep -n "^### Run identity\|^Skill revision:\|^Step 0 confirmation:" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/analysis-analysis-template.md`

The Run-identity block was updated in v3.9 (Task 5 of v3.9 plan added the `Step 0 confirmation:` and `Coverage command:` lines). v3.10 adds two more.

- [ ] **Step 2: Add the new lines**

Use Edit. Find this exact block (the existing Run-identity lines added in v3.9):

```
Step 0 confirmation: {Proceed | Abort | Free-text directives applied: <list>}   (v3.9+: single confirmation prompt with optional directive slot; Coverage & Profiling dispatches in Step 3 with no separate consent)
Coverage command: {auto-detected:<cmd> | none-detected}   (v3.9+: bench command detection dropped)
```

Replace with (two new lines added):

```
Step 0 confirmation: {Proceed | Abort | Free-text directives applied: <list>}   (v3.9+: single confirmation prompt with optional directive slot; Coverage & Profiling dispatches in Step 3 with no separate consent)
Coverage command: {auto-detected:<cmd> | none-detected}   (v3.9+: bench command detection dropped)
Senior-1M usage: {none | <analyst-list> via <path: gradient | scout-direct | user-directive>}   (v3.10+: tier path the analyst actually ran on; "none" if no analyst escalated to senior-1m)
Effort overrides: {none | <list of "<analyst>: <requested-effort>; resolved as <actual-effort>">}   (v3.10+: any non-default effort recommendations, plus harness resolution outcomes; "none" if every dispatch ran at default effort)
```

- [ ] **Step 3: Verify**

Run: `grep -c "Senior-1M usage:" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/analysis-analysis-template.md`
Expected: `1`.

Run: `grep -c "Effort overrides:" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/analysis-analysis-template.md`
Expected: `1`.

- [ ] **Step 4: Commit**

```bash
git add plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/analysis-analysis-template.md
git commit -m "$(cat <<'EOF'
codebase-deep-analysis: retrospective template — Senior-1M + Effort lines

Run-identity block adds two optional lines for v3.10+: Senior-1M usage
(which analysts escalated, via which path) and Effort overrides (any
non-default effort recommendations and how the harness resolved them).
Both default to "none" — most runs won't use either. Captures the data
needed to retune the v3.10 escalation thresholds in v-next.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 8: Update SKILL.md — multi-section update

**Files:**
- Modify: `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/SKILL.md`

This is the largest file edit in the plan. Five concerns, applied as sequential Edits in one task (one commit at the end):

1. Step 1 — flip Scout default tier (Junior → Standard)
2. Step 2 — add Accessibility applicability pruning + Scout-recommendation reading rule
3. Step 3 — add Accessibility Analyst dispatch addendum
4. Model-selection section — add Senior-1M tier definition + the three escalation paths + Scout default + harness-resolution rule + reasoning-effort axis
5. Common-mistakes — add three new entries

Apply edits in order; verify after each. Single commit at the end.

- [ ] **Step 1: Flip Scout default tier in Step 1**

Use Edit. Find:

```
Dispatch **one** Explore subagent with the prompt in `references/structure-scout-prompt.md`. A junior/low-cost model is preferred for this pass; fall back to the default model if that tier is unavailable.
```

Replace with:

```
Dispatch **one** Explore subagent with the prompt in `references/structure-scout-prompt.md`. The Scout runs at **Standard** tier by default (changed from Junior in v3.10) — the Scout's output (tier classification, applicability flags, docs-drift signals, the v3.10 Senior-1M recommendation block) is reused by every downstream analyst, so reliability there has compounded value across the parallel fan-out. Cost increase per run is small (one dispatch, ~5x bump on a tiny absolute) and well-amortized.
```

- [ ] **Step 2: Update Step 2 applicability pruning**

Find:

```
- **Applicability pruning.** Drop analysts whose scope is absent: no web UI → skip Frontend; no DB → skip Database; no styling surface → skip Styling; no CI config → Tooling still runs (it owns BUILD/GIT even without CI) but its CI-specific items become `[-] N/A`.
```

Replace with:

```
- **Applicability pruning.** Drop analysts whose scope is absent: no web UI → skip Frontend AND Accessibility (both gate on `web-facing-ui: present`); no DB → skip Database; no styling surface → skip Styling; no CI config → Tooling still runs (it owns BUILD/GIT even without CI) but its CI-specific items become `[-] N/A`.
```

- [ ] **Step 3: Add Scout-recommendation reading rule to Step 2**

In the same file, find this exact block (the end of the Step 2 "Exceptions that always run" list):

```
Exceptions that always run:

- **Security Analyst always runs.** Even a "pure backend library" can ship a subprocess call or deserialization surface.
- **Docs Analyst always runs** if any of `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `README.md`, or `docs/**` exists.
- **Tooling Analyst always runs** unless the repo has literally no manifest/build config at all (rare; essentially `.txt` files only).

## Step 3 — Dispatch analysts (parallel)
```

Replace with:

```
Exceptions that always run:

- **Security Analyst always runs.** Even a "pure backend library" can ship a subprocess call or deserialization surface.
- **Docs Analyst always runs** if any of `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `README.md`, or `docs/**` exists.
- **Tooling Analyst always runs** unless the repo has literally no manifest/build config at all (rare; essentially `.txt` files only).

**Read the Scout's `Recommend senior-1m for:` block (v3.10+).** The Scout may emit a recommendation of analysts to dispatch directly at Senior-1M, bypassing both Standard and Senior tiers. Apply the recommendation in Step 3 dispatch:

- For each analyst named in the block, set its dispatch tier to Senior-1M and record `Tier path: scout-direct: senior-1m` in Run metadata.
- For analysts NOT in the block, dispatch at their default tier (Standard for most, Senior for Security). Path A's gradient still applies if their first-pass output trips the auto-escalation thresholds.
- If the Scout flagged a recommendation with `confidence: low`, **do not** apply it directly. Defer to Path A's gradient (the analyst dispatches at default; if first-pass output is weak/large, normal escalation kicks in). Log the deferred recommendation in Run metadata so the retrospective can record whether ignoring it cost quality.
- If the Scout emits `Recommend senior-1m for: none`, no Path B dispatch happens. Path A's gradient remains available.

The orchestrator never invents Senior-1M dispatches outside the Scout's recommendation, the Path A gradient triggers, and explicit user directives (`use senior-1m on <analyst>` from Step 0). Senior-1M dispatch always traces back to one of those three paths.

## Step 3 — Dispatch analysts (parallel)
```

- [ ] **Step 4: Add Accessibility Analyst dispatch addendum to Step 3**

Find this exact paragraph (the existing Styling Analyst dispatch addendum from v3.8):

```
**Styling Analyst dispatch addendum.** When dispatching the Styling Analyst (and only that analyst), append the **fenced inner block** of `references/styling-prepass.md` to the wrapper output before sending — the file's leading meta-paragraph and outer fence markers are dispatcher-only instructions and must NOT be sent to the analyst. The pre-pass instructs the analyst to build a system inventory across its scope before filing per-file findings — it is the differentiator vs the Frontend Analyst's per-file CSS coverage. Other analysts receive the wrapper unchanged.
```

Replace with (Styling addendum kept verbatim; new Accessibility addendum added after it):

```
**Styling Analyst dispatch addendum.** When dispatching the Styling Analyst (and only that analyst), append the **fenced inner block** of `references/styling-prepass.md` to the wrapper output before sending — the file's leading meta-paragraph and outer fence markers are dispatcher-only instructions and must NOT be sent to the analyst. The pre-pass instructs the analyst to build a system inventory across its scope before filing per-file findings — it is the differentiator vs the Frontend Analyst's per-file CSS coverage. Other analysts receive the wrapper unchanged.

**Accessibility Analyst dispatch addendum (v3.10).** When dispatching the Accessibility Analyst (and only that analyst), append the **fenced inner block** of `references/accessibility-prepass.md` to the wrapper output before sending — the file's leading meta-paragraph and outer fence markers are dispatcher-only instructions and must NOT be sent to the analyst. The pre-pass instructs the analyst to build a system inventory across its scope (interactive-element census, landmark inventory, modal/dialog inventory, form-error inventory, ARIA-role census) before filing per-file findings — it is the differentiator vs the v3.9-era shallow Frontend a11y coverage. Other analysts receive the wrapper unchanged.
```

- [ ] **Step 5: Replace the Model selection section**

Find this exact block (the entire `## Model selection` section, from heading through the user-override paragraph):

```
## Model selection

Default every analyst to the **standard** model tier. Escalations:

- **Security Analyst → senior** by default (cross-cutting; high cost of missing a finding).
- **Any analyst whose declared scope exceeds ~50k LOC, or which returns >30 High/Critical findings in the first pass → re-dispatch that agent on senior** for a second, deeper pass and merge outputs during synthesis.
- **Junior** only for Structure Scout (and any pure enumeration helper you add later).

There is **no** "when unsure, pick the more powerful tier" override. Unsure stays standard; synthesis escalates surgically rather than broadly.

If the user explicitly overrides model tiers for this run, honor the override and record it in Run metadata as `Analyst override: per user request, <scope of analysts> ran on <model/tier>`. The override does not disable the senior re-dispatch rules; if a scoped analyst still trips an escalation condition, record whether the override already satisfied it or whether a second pass ran.
```

Replace with:

```
## Model selection

Four logical tiers — Junior, Standard, Senior, Senior-1M — and a separate reasoning-effort axis. The skill's defaults are conservative; every escalation has an explicit trigger.

### Default tiers per dispatch

- **Structure Scout: Standard** (changed from Junior in v3.10 — the Scout's output calibrates the entire run; reliability matters more than the small cost bump).
- **Backend, Frontend, Styling, Accessibility, Database, Test, Tooling, Docs Consistency, Coverage & Profiling: Standard.**
- **Security Analyst: Senior** by default (cross-cutting scope; high cost of missing a finding).
- **Senior-1M: never the default for any analyst.** Reserved for escalation paths described below.
- **Junior: not used by any default dispatch in v3.10+.** Remains in the vocabulary for future enumeration-only helpers.

There is **no** "when unsure, pick the more powerful tier" override. Unsure stays standard; escalations are evidence-driven and surgical.

### Three escalation paths to Senior or Senior-1M

**Path A — gradient escalation (existing-style, after a first-pass run).**

| From | To | Trigger |
|------|----|---------|
| Standard | Senior | Analyst's declared scope exceeds ~50k LOC, OR first-pass output contains >30 H/C findings |
| Senior | Senior-1M | Declared scope exceeds ~150k LOC, OR first-pass output >2k lines, OR synthesis input >100k tokens |

**Path B — Scout-direct dispatch at Senior-1M (new in v3.10).**

The Scout, during Step 1's mapping pass, may emit a `Recommend senior-1m for: <analyst-list>` block. The orchestrator dispatches the named analysts directly at Senior-1M in Step 3, bypassing both Standard and Senior. Criteria are mechanical: single-analyst scope >300k LOC, polyglot ≥4 language families, mid-large monorepo cross-cutting Security on >1M LOC, or synthesis pre-prediction >100k tokens. Vibes-based recommendations are not allowed. `confidence: low` recommendations are deferred to Path A.

**Path C — user directive at Step 0.**

The Step 0 confirmation prompt accepts free-text directives:
- `use senior on <analyst-name>` (existing v3.9)
- `use senior-1m on <analyst-name>` (new v3.10)
- `use max-effort on <analyst-name>` (new v3.10, additive to model-tier directives — see Reasoning effort below)

Recorded in Run metadata as `Tier path: user-directive` / `Effort override: per user request`.

### Synthesis-specific Senior-1M auto-escalation

Synthesis (Step 4) is one long pass holding all analysts' outputs. It auto-escalates to Senior-1M when **all** hold:

- Project tier = T3.
- Active analyst count ≥ 10 (after applicability pruning).
- Total findings post-collection ≥ 100, OR total findings-text ≥ 50k tokens.

Otherwise synthesis runs at Standard. Most synthesis passes — including most T3 runs — stay at Standard.

### Reasoning effort axis (orthogonal to model tier)

Three levels: `default | high | max`. Orthogonal to model strength and context window. Default for every dispatch = harness default. The skill actively recommends bumping effort only on a closed list:

- **Synthesis when synthesis-Senior-1M trigger fires:** recommend `max` effort.
- **Security on a Senior-1M dispatch (Path B or Path A gradient):** recommend `high` effort. Use `max` if Scout's recommendation cites cross-cutting attack surface (auth + deserialization + subprocess).
- **Cluster execution in `implement-analysis-report` when cluster has both `model-hint: senior-1m` AND `Autonomy: needs-spec`:** recommend `max` effort via the cluster's `effort-hint:` frontmatter field.

Everything else stays at `default`. Don't over-specify.

### Resolution rule (load-bearing, never silently downgrade)

The four logical tiers map to whatever models the harness exposes. Two real-world topologies:

| Topology | Junior | Standard | Senior | Senior-1M |
|----------|--------|----------|--------|-----------|
| Business/enterprise (separate small-context and large-context senior options) | Haiku-class | Sonnet-class | Opus-class @ ~200k | Opus-class @ 1M |
| Personal plans (Claude Pro/Max, ChatGPT Plus/Pro, etc.) | Haiku-class | Sonnet-class | Opus-class @ ~1M | Same as Senior |

**Resolution semantics:**

- Both Senior + Senior-1M available as distinct concrete models → use them per the spec.
- Only one senior-class model exposed → it serves as both Senior and Senior-1M. Every Senior dispatch and every Senior-1M dispatch goes to that same model. The cost framing changes (no longer 6-10x of Senior; just 2-3x for the bigger context payload on the same model) but the dispatch path is unchanged.
- No senior-class model at all (rare; very-restricted plans) → use the highest available tier and log `Tier resolution: Senior unavailable in harness; using <highest-available-tier> instead` in Run metadata.
- Effort: same semantics. If `max` requested and harness only exposes `default`, log `Effort resolution: max requested; harness exposes only default; ran at default`.

The orchestrator does not auto-detect harness topology. Default fallback assumes "personal-plan-style collapsed senior tier" — the most common shape and the safer fallback (use the bigger model, not the smaller one) on ambiguity.

### Run metadata records

Per analyst:

- `Tier: <tier>` — actual tier the analyst ran on (`junior` | `standard` | `senior` | `senior-1m`).
- `Tier path: <path>` — `default` | `gradient: standard→senior` | `gradient: senior→senior-1m` | `scout-direct: senior-1m` | `user-directive`.
- `Effort: <effort>` — actual effort the analyst ran at (`default` | `high` | `max`).
- `Effort path: <path>` — `default` | `closed-list-trigger: <name>` | `user-directive`.
- Resolution warnings when harness couldn't honor the requested tier or effort.
```

- [ ] **Step 6: Add three new entries to Common mistakes**

Find this exact block (the existing entry near the end of the Common mistakes list):

```
- **Quoting secrets.** Describe presence, never contents.
- **Running anything outside the Coverage & Profiling Analyst.** No `bun test`, no `npm run build`, no migrations, no scripts run by any other analyst — and no bench commands run by anyone in v3.9+. The Coverage & Profiling Analyst is the single execution exception. Static reading only for everyone else.
```

Replace with (three new entries inserted between the two existing ones):

```
- **Quoting secrets.** Describe presence, never contents.
- **Ignoring the Scout's Senior-1M recommendation in Step 2.** When the Scout emits `Recommend senior-1m for: <analyst-list>` (high-confidence, not `confidence: low`), the orchestrator dispatches those analysts directly at Senior-1M. Skipping the recommendation defeats Path B and forces Path A's wasteful first-pass-then-escalate cost on runs the Scout already predicted would need it. The only valid reason to ignore is `confidence: low`.
- **Falling back to Standard when "Senior" is requested but only Senior-1M exists in the harness.** The collapsed-senior topology (personal plans) exposes only one senior-class model. Treat that model as BOTH Senior and Senior-1M. Never silently downgrade a Senior request to Standard merely because the small-context Senior variant doesn't exist — that weakens the analysis on work the spec explicitly marked as needing senior reasoning. See Model-selection section's resolution rule.
- **Silently dropping an effort recommendation when the harness exposes only default effort.** If the skill recommends `max` effort and the harness can't pass that through, log `Effort resolution: max requested; harness exposes only default; ran at default` in Run metadata. Don't strip the request; the retrospective needs the data to detect when effort-capped harnesses degraded analysis quality.
- **Running anything outside the Coverage & Profiling Analyst.** No `bun test`, no `npm run build`, no migrations, no scripts run by any other analyst — and no bench commands run by anyone in v3.9+. The Coverage & Profiling Analyst is the single execution exception. Static reading only for everyone else.
```

- [ ] **Step 7: Verify all changes landed**

Run: `grep -c "The Scout runs at \*\*Standard\*\* tier by default" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/SKILL.md`
Expected: `1`.

Run: `grep -c "skip Frontend AND Accessibility" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/SKILL.md`
Expected: `1`.

Run: `grep -c "Read the Scout's .Recommend senior-1m for:. block" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/SKILL.md`
Expected: `1`.

Run: `grep -c "Accessibility Analyst dispatch addendum" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/SKILL.md`
Expected: `1`.

Run: `grep -c "Path A — gradient escalation\|Path B — Scout-direct dispatch\|Path C — user directive" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/SKILL.md`
Expected: `3` (one match each).

Run: `grep -c "Resolution rule (load-bearing" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/SKILL.md`
Expected: `1`.

Run: `grep -c "Reasoning effort axis (orthogonal" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/SKILL.md`
Expected: `1`.

Run: `grep -c "Ignoring the Scout's Senior-1M recommendation\|Falling back to Standard when .Senior. is requested\|Silently dropping an effort recommendation" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/SKILL.md`
Expected: `3`.

Run: `grep -c "junior/low-cost model is preferred" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/SKILL.md`
Expected: `0` (the old Scout-tier sentence should be gone).

- [ ] **Step 8: Commit**

```bash
git add plugins/codebase-deep-analysis/skills/codebase-deep-analysis/SKILL.md
git commit -m "$(cat <<'EOF'
codebase-deep-analysis: SKILL.md — multi-section v3.10 update

Step 1 — flip Scout default tier from Junior to Standard.
Step 2 — applicability pruning lists "skip Frontend AND Accessibility"
together (both gate on web-facing-ui); add Scout-recommendation
reading rule for Path B Senior-1M dispatch.
Step 3 — add Accessibility Analyst dispatch addendum (mirrors Styling
pattern, points at the new accessibility-prepass.md).
Model selection — full rewrite. Four logical tiers (Junior/Standard/
Senior/Senior-1M) with clear defaults; three escalation paths (Path A
gradient, Path B Scout-direct, Path C user-directive); orthogonal
reasoning-effort axis (default/high/max) with closed-list triggers;
load-bearing harness-resolution rule that never silently downgrades on
collapsed-senior topologies (personal plans). Run metadata captures
tier path and effort path per analyst plus resolution warnings.
Common mistakes — three new entries: ignoring Scout's recommendation,
silent downgrade on collapsed-senior, silently dropping effort.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 9: Bump versions to 3.10.0

**Files:**
- Modify: `plugins/codebase-deep-analysis/.claude-plugin/plugin.json`
- Modify: `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/VERSION`
- Modify: `plugins/codebase-deep-analysis/skills/implement-analysis-report/VERSION`

`scripts/test-version-metadata.sh` requires all three to match.

- [ ] **Step 1: Update plugin.json**

Use Edit. Find:

```
  "version": "3.9.0",
```

Replace with:

```
  "version": "3.10.0",
```

- [ ] **Step 2: Update codebase-deep-analysis VERSION**

Read first. Then Write `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/VERSION` with exact content (one line + trailing newline):

```
3.10.0
```

- [ ] **Step 3: Update implement-analysis-report VERSION**

Read first. Then Write `plugins/codebase-deep-analysis/skills/implement-analysis-report/VERSION` with:

```
3.10.0
```

- [ ] **Step 4: Run validator**

Run: `bash plugins/codebase-deep-analysis/scripts/test-version-metadata.sh`
Expected stdout: `codebase-deep-analysis plugin and bundled skill versions ok: 3.10.0`
Expected exit code: `0`.

If validator fails, fix the mismatched file and re-run BEFORE committing.

- [ ] **Step 5: Commit**

```bash
git add plugins/codebase-deep-analysis/.claude-plugin/plugin.json plugins/codebase-deep-analysis/skills/codebase-deep-analysis/VERSION plugins/codebase-deep-analysis/skills/implement-analysis-report/VERSION
git commit -m "$(cat <<'EOF'
codebase-deep-analysis: bump to 3.10.0 (Accessibility Analyst + Senior-1M tier)

Adds the Accessibility Analyst (sole transfer of A11Y-1..5 + UX-2 from
Frontend, plus 5 new A11Y-6..A11Y-10 IDs covering ARIA misuse, focus
management, prefers-reduced-motion, form-error association, and touch-
target size). Introduces Senior-1M model tier with three escalation
paths (gradient, Scout-direct, user-directive) and never-downgrade
harness resolution. Promotes Scout from Junior to Standard. Adds
orthogonal reasoning-effort axis (default/high/max) gated on a closed
list of triggers.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 10: Final verification

**Files:** none (read-only checks).

- [ ] **Step 1: Re-run the version validator**

Run: `bash plugins/codebase-deep-analysis/scripts/test-version-metadata.sh`
Expected: `codebase-deep-analysis plugin and bundled skill versions ok: 3.10.0`, exit code 0.

- [ ] **Step 2: Confirm Accessibility Analyst landed**

Run: `grep -c "^| \*\*Accessibility Analyst\*\*" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/agent-roster.md`
Expected: `1`.

Run: `grep -c "^| A11Y-" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/checklist.md`
Expected: `10`.

Run: `ls -la plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/accessibility-prepass.md`
Expected: file exists, ~17-25 lines.

Run: `grep -c "Accessibility Analyst dispatch addendum" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/SKILL.md`
Expected: `1`.

- [ ] **Step 3: Confirm Senior-1M tier landed**

Run: `grep -c "Path A — gradient\|Path B — Scout-direct\|Path C — user directive" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/SKILL.md`
Expected: `3`.

Run: `grep -c "Senior-1M tier recommendations" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/structure-scout-prompt.md`
Expected: `1`.

Run: `grep -c "Resolution rule (load-bearing" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/SKILL.md`
Expected: `1`.

Run: `grep -c "Reasoning effort axis" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/SKILL.md`
Expected: `1`.

- [ ] **Step 4: Confirm Frontend cell shrunk**

Run: `grep "^| \*\*Frontend Analyst\*\*" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/agent-roster.md | grep -c "A11Y\|UX-2"`
Expected: `0` (no A11Y-* nor UX-2 mention in the Frontend row).

- [ ] **Step 5: Confirm Scout tier flipped**

Run: `grep -c "junior/low-cost model is preferred" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/SKILL.md`
Expected: `0`.

Run: `grep -c "The Scout runs at \*\*Standard\*\* tier by default" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/SKILL.md`
Expected: `1`.

- [ ] **Step 6: Verify commit log**

Run: `git log --oneline 0dcd830..HEAD`
Expected: 9 new commits on top of the spec amendments, in order (most recent first):

1. version bump to 3.10.0 (Task 9)
2. SKILL.md multi-section v3.10 update (Task 8)
3. retrospective template — Senior-1M + Effort lines (Task 7)
4. ground rules — name ARIA semantics in read-depth list (Task 6)
5. synthesis docs Accessibility + Senior-1M + effort-hint (Task 5)
6. scout emits Senior-1M tier recommendations (Task 4)
7. register Accessibility Analyst + Senior-1M tier in roster (Task 3)
8. A11Y owner transitions + add A11Y-6..A11Y-10 (Task 2)
9. add accessibility-prepass.md (Task 1)

If actual log is missing a commit unexpectedly, do NOT amend — note the discrepancy in the final report. The validator pass + the spot-check greps are the load-bearing acceptance gates.

- [ ] **Step 7: Optional manual smoke test**

Run the codebase-deep-analysis skill on a real frontend project. Confirm:

- The Step 0 prompt offers proceed / abort / instructions.
- The Scout's output includes a `Recommend senior-1m for:` block (most likely emits "none" on a small repo).
- If the project has UI, the Accessibility Analyst dispatches alongside the other analysts.
- The Accessibility Analyst's report contains an `### A11y inventory` block with at least the 5 inventory categories named.
- The Frontend Analyst's report does NOT contain A11Y-* or UX-2 findings.

Do NOT make this a blocker. The static plan completion (Tasks 1-9) is the merge gate.

---

## Self-Review

**Spec coverage:**

| Spec section | Plan task |
|--------------|-----------|
| Accessibility Analyst roster row | Task 3 Step 1 |
| Frontend roster cell update (drop A11Y-*, drop UX-2) | Task 3 Step 2 |
| Ownership-collisions section update | Task 3 Step 3 |
| Escalation section rewrite (3 paths + resolution rule pointer) | Task 3 Step 4 |
| Sole transfer of A11Y-1..5 + UX-2 (checklist Owner column) | Task 2 Steps 2 + 3 + 5 |
| A11Y-3 transition (Frontend+Styling joint → Styling+Accessibility joint) | Task 2 Step 3 |
| New A11Y-6..A11Y-10 rows | Task 2 Step 4 |
| A11Y section preamble update | Task 2 Step 1 |
| Pre-pass file creation (accessibility-prepass.md) | Task 1 |
| Pre-pass dispatch wiring in SKILL.md Step 3 | Task 8 Step 4 |
| Scout default tier flip Junior → Standard | Task 8 Step 1 + Task 4 (commit message references it) |
| Scout Senior-1M recommendation block | Task 4 Step 2 |
| Step 2 applicability pruning update | Task 8 Step 2 |
| Step 2 Scout-recommendation reading rule | Task 8 Step 3 |
| Senior-1M tier definition + 3 paths + harness resolution rule | Task 8 Step 5 (Model-selection section) |
| Reasoning-effort axis | Task 8 Step 5 (Model-selection section) |
| Synthesis §6 step 7 cluster-hint vocab note | Task 5 Step 1 |
| Synthesis §6 step 8 model-hint senior-1m rule | Task 5 Step 2 |
| Synthesis §6 step 8 effort-hint rule | Task 5 Step 2 |
| analyst-ground-rules.md ARIA mention | Task 6 |
| analysis-analysis-template.md Run-identity additions | Task 7 |
| Common-mistakes 3 new entries | Task 8 Step 6 |
| Version bump | Task 9 |

All spec sections covered. Risks/mitigations and Self-evolving-feedback-loop sections are commentary, not requirements.

**Placeholder scan:** None. All commands runnable, all replacements show exact content, all expected outputs stated.

**Type consistency:** Names used:
- `accessibility-prepass.md` — consistent across Tasks 1, 8 (Step 4 dispatch addendum), and the spec.
- `Tier path:` — consistent across Tasks 3 (roster Escalation section), 7 (retrospective template), 8 (SKILL.md Run metadata).
- `Effort overrides:` — consistent across Tasks 7 + 8.
- A11Y-1..A11Y-10 — consistent across Tasks 2, 3, 5.
- Path A / Path B / Path C nomenclature — consistent across Tasks 3 (roster), 8 (SKILL.md), and the spec.
- "Recommend senior-1m for:" — consistent across Tasks 4 (Scout prompt), 8 Step 3 (SKILL.md Step 2).
- "confidence: low" — consistent across Tasks 4 + 8.
- `model-hint: senior-1m` — consistent across Tasks 5 + 8.
- `effort-hint: max` — consistent across Tasks 5 + 8.

No drift detected.
