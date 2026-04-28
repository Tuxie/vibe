# Accessibility Analyst + Senior-1M model tier — design

**Skill:** `codebase-deep-analysis`
**Target version:** 3.10.0
**Status:** design (awaiting implementation plan)
**Author intent:** Two coupled changes shipping in one version. (1) Spin out an **Accessibility Analyst** from the overloaded Frontend Analyst — A11Y-1..5 + UX-2 transfer sole, plus 5 new A11Y-6..A11Y-10 IDs covering modern concerns (ARIA, focus management, reduced motion, form-error semantics, touch targets). Frontend's roster cell shrinks; a11y gains a dedicated lens. (2) Add **Senior-1M** as a fourth model tier above Senior, decoupling context-window capacity from raw model strength. Auto-escalates from Senior under thresholds; reserved for synthesis on big-finding-set runs and Security on large monorepos.

## Goals

1. **Reduce Frontend Analyst overload** by sole-transferring A11Y-1..5 and UX-2 to a dedicated Accessibility Analyst (~5–6 IDs out of Frontend's ~88).
2. **Catch more a11y issues** by adding 5 new A11Y-6..A11Y-10 IDs the existing 5 don't cover (ARIA misuse, focus management, reduced motion, form-error association, touch target size).
3. **Decouple context capacity from model strength** by adding Senior-1M as a fourth tier; surgically applied via auto-escalation, never default.
4. **Stay within the existing skill architecture** — no new dispatch infrastructure, no new file types.

## Non-goals

- **Not** a complete WCAG audit. The skill is read-only static analysis; some WCAG criteria require browser rendering or human judgment (visible-focus contrast, animation distraction tolerance, audio descriptions). Out of scope.
- **Not** auto-applying Senior-1M to every analyst on T3 projects. Senior-1M is expensive; gate it on actual scope evidence, not project tier alone.
- **Not** adding axe-core / pa11y / similar automated a11y tooling integration. Future v-next consideration.
- **Not** redesigning the model-tier escalation rules across the board — Senior-1M extends the existing Standard → Senior chain; doesn't replace it.

## Architecture

### Accessibility Analyst — roster entry

| Agent | Default model tier | In-scope paths / patterns | Owned checklist IDs |
|-------|--------------------|---------------------------|---------------------|
| **Accessibility Analyst** | Standard | `src/routes/**`, `src/components/**`, `src/lib/**` client files, `*.svelte`, `*.tsx`, `*.jsx`, `*.vue`, `*.astro`, `*.html`, `*.css`, `*.scss`, `*.postcss` (for contrast cross-check), `*.module.{css,scss}`, theme/token files (`**/theme.{ts,js,json,css}`, `**/tokens.{ts,js,json,css}`, `**/design-tokens/**`) | A11Y-1..A11Y-10 (sole owner — A11Y-1..A11Y-5 transfer from Frontend, A11Y-6..A11Y-10 are new), UX-2 (sole — transfer from Frontend), A11Y-3 stays joint with Styling (color contrast straddles a11y + styling system) |

Inserted between **Styling Analyst** and **Database Analyst** in the roster table — keeps visual-layer agents adjacent (Frontend → Styling → Accessibility → Database).

**Applicability gate:** Same as Frontend — runs only when Scout emits `web-facing-ui: present` (any sub-flag). When Frontend skips, Accessibility skips too. CLI tools, pure backend libraries, internal jobs without UI → no Accessibility dispatch.

**Sub-flag handling:**
- `web-facing-ui: present, auth-gated` — Accessibility runs as normal. Auth-gated UIs still need a11y; the gate doesn't change A11Y-* applicability the way it changes SEO-* applicability.
- `web-facing-ui: present, local-only` — Accessibility runs as normal. Local-only desktop apps and dev dashboards need a11y too.
- `web-facing-ui: absent, bind-gated` — skip.

### Frontend Analyst — what changes

Frontend Analyst loses A11Y-1..A11Y-5 and UX-2 from its owned-IDs list (sole transfer, not joint). The Frontend roster cell shrinks by ~6 IDs. Frontend's lens stays *component-shape* and *framework-correctness*; a11y becomes Accessibility's specialty.

A11Y-3 (color-only signal / contrast) was joint with Frontend + Styling per v3.8. Under v3.10 ownership transitions to **Styling + Accessibility** (two-way joint, Frontend exits). The lens-split:
- Styling-side: "is this token system internally coherent" — does the palette have any combinations that would fail contrast at expected text sizes.
- Accessibility-side: "is this combination actually rendered against that background in the markup" — finds the JSX/template sites that combine the tokens problematically.

UX-1 (visual look-and-feel inconsistency) stays joint with Styling, NOT moved to Accessibility. UX-1 is a design-system concern (spacing/typography/iconography); a11y is interaction concern. The split holds.

### New A11Y-6 through A11Y-10 — checklist additions

Added to the existing `## A11Y — Accessibility (frontend)` section in `references/checklist.md`. The section heading and applicability paragraph are updated to mention the new owner.

| ID | Item | Min tier |
|----|------|----------|
| A11Y-6 | ARIA misuse — wrong role for the element type, conflicting `aria-*` attributes, redundant ARIA on native-semantic elements (`<button role="button">`, `<a role="link">`), or `aria-hidden` on focusable elements (creates an unreachable focus target). Look for `role="..."` overriding semantic-HTML defaults, attribute combinations that violate the ARIA spec (e.g., `aria-disabled` without disabling actual interactivity), and `aria-label` on elements that derive their name from text content (label conflicts with content, screen reader announces wrong name) | T2 |
| A11Y-7 | Focus management failures — modal/dialog/sheet/drawer that opens without trapping focus, doesn't return focus to the trigger on close, or skips focus to a non-interactive element. Route changes (SPA navigation) that don't move focus to the new page's heading or main landmark. Skip-to-main link missing on long navigation chains | T1 |
| A11Y-8 | `prefers-reduced-motion` not respected — animations, transitions, parallax, auto-play video, or motion-heavy effects emitted unconditionally. Look for keyframes / transitions / `requestAnimationFrame` usage in components without a `@media (prefers-reduced-motion: reduce)` guard or programmatic equivalent | T2 |
| A11Y-9 | Form errors not announced to assistive tech — error messages rendered visually next to fields without `aria-describedby` association, or error containers without `role="alert"` / `aria-live` for dynamic announcements. Form-level error summaries that don't focus or announce on submit. Includes single-field validation that paints red borders without text equivalent | T1 |
| A11Y-10 | Touch target size below 24×24 CSS px on interactive elements (`<button>`, `<a>`, `<input>` excepting native sliders, custom-pointer roles). Includes nested touch targets where the visible hit area is smaller than the actual `<button>` element. WCAG 2.2 baseline; default min for primary actions is 44×44, but 24×24 catches the egregious cases | T2 |

### Tier assignments rationale

- **A11Y-7 at T1**: focus management is a real correctness bug at any scale. Modals are universal; broken focus traps lock keyboard users out of dismissing them.
- **A11Y-9 at T1**: forms are universal. Visually-only errors are a fail-shaped UX defect, not a tier-conditional polish.
- **A11Y-6, A11Y-8, A11Y-10 at T2**: ARIA usage tends to escalate with project sophistication; reduced-motion is rare in hobby projects (most don't have heavy motion); 24×24 minima are a polish concern that most T1 projects won't pass anyway and shouldn't be flagged spuriously.

### Cluster-hint vocabulary

Closed enum, mirrors the Styling Analyst's pattern (prevents slug sprawl):

| Hint slug | Covers IDs |
|-----------|------------|
| `semantic-markup-pass` | A11Y-1, A11Y-4, A11Y-5 (accessible name, landmarks, image alt) |
| `keyboard-and-focus` | A11Y-2, A11Y-7, UX-2 (keyboard ops, focus trap/return, keyboard shortcuts) |
| `aria-cleanup` | A11Y-6 |
| `motion-respect` | A11Y-8 |
| `form-a11y` | A11Y-9 + FE-18 (joint with Frontend on form-binding finding shapes) |
| `touch-targets` | A11Y-10 |
| `palette-and-contrast` | A11Y-3 (already exists, three-way joint Frontend / Styling / Accessibility — collapses on this hint at synthesis) |

### Cross-file reasoning pre-pass for the Accessibility Analyst

Like Styling, accessibility benefits from cross-file reasoning. Add `references/accessibility-prepass.md` (mirrors `styling-prepass.md`):

```
## Accessibility-specific pre-pass

Before filing any A11Y-1, A11Y-4, A11Y-6, A11Y-7, or A11Y-9 finding, build a **system inventory** by reading across your scope:

1. **Interactive-element census** — list every `<button>`, `<a>`, `<input>`, `<select>`, `<textarea>`, `[role="button"|"link"|"checkbox"|"radio"|"tab"]` in your scope with file:line. A11Y-1 findings cite this census (which interactive elements have accessible names from text content vs aria-label vs neither).
2. **Landmark inventory** — list every `<main>`, `<nav>`, `<header>`, `<footer>`, `<aside>`, `<section>` (with implicit/explicit name), and `[role="main"|"navigation"|...]` per page/route. A11Y-4 findings cite gaps (missing `<main>`, multiple `<h1>`, navs without names).
3. **Modal/dialog inventory** — list every dialog/modal/sheet/drawer component (look for `<dialog>`, `[role="dialog"]`, common library names like `Dialog`, `Modal`, `Sheet`, `Drawer`, `Popover`, `Menu`). A11Y-7 findings audit each for focus-trap and focus-return.
4. **Form-error inventory** — list every form's error-rendering site. Cross-reference each error to the field via `aria-describedby` / `id` / `for` linkage. A11Y-9 findings cite unbound errors.
5. **ARIA-role census** — list every `role="..."` and `aria-*` attribute usage. Flag obvious misuse (role overriding semantic HTML, conflicting attrs).

Emit the pre-pass output as a single optional `### A11y inventory` block under `### Findings`. Synthesis reads it for §5 themes. Empty categories: state explicitly (`Modal/dialog inventory: 0 found in scope`).
```

This file is dispatched-only-for-Accessibility, like `styling-prepass.md`. SKILL.md Step 3 dispatch logic gets one more conditional append.

### Senior-1M model tier — design

**Position in tier vocabulary:** Above Senior. Full tier list becomes:

| Tier | Description | Default users |
|------|-------------|---------------|
| Junior | Cheap, fast model. Pattern-matching and enumeration only. | Structure Scout |
| Standard | Default tier. ~200k context. | All analysts (excepting Security) |
| Senior | Higher-strength model, ~200k context. Stronger reasoning. | Security Analyst (default), escalation target |
| **Senior-1M** | **Senior-strength model with the largest available context window (currently 1M tokens). Reserved for genuine context-saturation scenarios.** | None default; escalation target only |

**Naming caveat:** "1M" denotes "the largest context window the harness supports" rather than a literal hard-coded number. As model offerings evolve (e.g., 2M context becomes available), the tier may be renamed or its concrete model assignment may change without renaming. The retrospective template (`analysis-analysis-template.md`) records the actual model used so future calibration is traceable.

**Auto-escalation paths (two; either can fire):**

**Path A — gradient escalation, after a first-pass run:**

| Trigger | Escalation |
|---------|------------|
| Analyst's declared scope >50k LOC, OR first-pass output contains >30 H/C findings | Standard → Senior |
| Analyst's declared scope >150k LOC, OR first-pass output >2k lines (signals genuine context pressure), OR synthesis input total exceeds an estimated 100k tokens | Senior → Senior-1M |

Path A is the existing-style after-the-fact escalation: an analyst returned weak / overloaded output and a senior-tier re-dispatch follows. The gradient prevents over-escalation in normal cases.

**Path B — Scout-driven direct dispatch at Senior-1M:**

The Scout, during Step 1's mapping pass, emits a new optional block:

```
Recommend senior-1m for: {analyst-name-list, or "none"}
Reason: {one sentence per analyst — the specific evidence that motivated the recommendation}
```

The orchestrator reads the recommendation in Step 2 and dispatches the named analysts directly at Senior-1M, **bypassing both Standard and Senior tiers**. No prior pass is required. The two-step gradient (Path A) does not apply to analysts that started on Senior-1M — they're already at the top.

**Scout's criteria for recommending Senior-1M (any one is enough):**

1. **Single-analyst scope >300k non-vendored LOC.** Twice the Senior threshold. The analyst's declared scope alone genuinely exceeds what a 200k-context model can reason about coherently.
2. **Polyglot single-analyst scope.** Backend Analyst on a repo where backend code spans ≥4 language families (e.g., Go services + Python ML + Rust core + TypeScript edge) and cross-module reasoning requires holding several languages' idioms simultaneously.
3. **Mid-large monorepo cross-cutting Security.** Project total non-vendored LOC >1M AND `security-surface: present` — Security Analyst by definition spans the entire repo; on a 1M+ LOC enterprise monorepo the standard 200k context fragments security reasoning.
4. **Synthesis pre-prediction.** Scout estimates that the project's tier + scope + analyst count will produce a synthesis input above 100k tokens. Recommend `synthesis` (the orchestrator's own pass, not an analyst) for Senior-1M directly. This duplicates the synthesis-specific auto-escalation rule below; either path can satisfy the trigger.

The Scout's recommendation block is optional output — most runs emit `Recommend senior-1m for: none`. The orchestrator does not second-guess a "none" recommendation; if the run later trips Path A's thresholds, the gradient kicks in normally.

If the Scout itself ran on Junior tier (the default) and the scope evidence is borderline, it emits the recommendation with `Reason: ...; confidence: low` — the orchestrator then uses the standard gradient (Path A) instead of the Scout's Path B recommendation, but logs the deferred recommendation in Run metadata so the retrospective can record whether ignoring it cost quality.

Run metadata records, per analyst:
- `Tier: <tier>` — tier the analyst actually ran on.
- `Tier path: <path>` — `default` | `gradient: standard→senior` | `gradient: senior→senior-1m` | `scout-direct: senior-1m` | `user-directive`.

**Synthesis-specific rule:**

Synthesis (Step 4 of cda) is a single long pass that holds all analysts' outputs in one reasoning context. It auto-escalates to Senior-1M when **all** hold:

- Project tier = T3.
- Active analyst count ≥ 10 (after applicability pruning).
- Total findings post-collection (Step 4 §1) ≥ 100, OR total findings-text ≥ 50k tokens (estimated by character count / 3.5).

Otherwise synthesis runs at Standard. Most synthesis passes — including most T3 runs — stay at Standard.

**Step 0 directive vocabulary expansion:**

The closed directive list (v3.9) gets one new shape:

- `use senior-1m on <analyst-name>` — model-tier override; recorded in Run metadata as `Analyst override: per user request, <analyst> ran on senior-1m`.

The existing `use senior on <analyst-name>` stays. User can pick either.

**Cost discipline (documented in roster Escalation section):**

Senior-1M is roughly 2x Senior input cost AND payload typically 3-5x larger → 6-10x more expensive than Senior, 30-50x more than Standard. Reserve for genuine concentration points: synthesis on big runs, Security on large monorepos, cross-cluster orchestration in `implement-analysis-report`. Do **not** default any analyst to Senior-1M unless evidence demands it.

**`model-hint:` cluster frontmatter expansion:**

`synthesis.md` §6 step 8 currently allows `junior | standard | senior` as `model-hint:` values. The list expands to `junior | standard | senior | senior-1m`. The Model-hint selection rules (Step 6 in `synthesis.md`) gain a fourth bullet:

- **Upgrade to `senior-1m` when ALL hold:** cluster `Autonomy: needs-spec`, highest severity is High or Critical, cluster spans >15 distinct files OR cluster's source-file footprint exceeds an estimated 50k LOC (e.g., entire backend module rewrite). The fix subagent needs to hold the entire affected subsystem in context simultaneously.

The user-facing override path stays the same (`use senior-1m on <cluster-slug>` in directive vocabulary, same closed-list discipline).

### Files to change

| File | Change |
|------|--------|
| `references/agent-roster.md` | Add Accessibility Analyst row between Styling and Database; update Frontend row (drop A11Y-1..5, drop UX-2); update Escalation section to document both Senior → Senior-1M (gradient, Path A) and Scout-direct Senior-1M (Path B); add Senior-1M to the model-tier vocabulary explanation |
| `references/checklist.md` | Update `## A11Y` section preamble (new owner: Accessibility Analyst); update Owner column on A11Y-1..A11Y-5 (Frontend → Accessibility, with A11Y-3 three-way joint Frontend/Styling/Accessibility); update Owner on UX-2 (Frontend → Accessibility); add A11Y-6..A11Y-10 rows |
| `references/accessibility-prepass.md` | Create new file (mirrors `styling-prepass.md`) holding the system-inventory pre-pass addendum |
| `SKILL.md` | Step 3 dispatch — add Accessibility Analyst dispatch addendum (mirrors Styling Analyst pattern); Step 2 applicability pruning — add `web-facing-ui: absent → skip Accessibility too`; Step 2 — add a one-paragraph rule for reading the Scout's `Recommend senior-1m for:` block and dispatching named analysts directly at Senior-1M; Model selection section — add Senior-1M tier definition + the two escalation paths (Path A gradient, Path B Scout-direct); Common mistakes — add an entry warning against ignoring the Scout's recommendation in Step 2 |
| `references/structure-scout-prompt.md` | Add a new optional output block: `Recommend senior-1m for: <analyst-list>` with one-line `Reason:` per analyst. Document the criteria the Scout uses (single-analyst scope >300k LOC; polyglot single-analyst scope ≥4 language families; mid-large monorepo Security on >1M LOC; synthesis pre-prediction >100k tokens). Most runs emit `Recommend senior-1m for: none`. |
| `references/synthesis.md` | §1b health check thresholds — apply unchanged to Accessibility; §3 right-sizing — apply unchanged; §6 step 7 — add Accessibility's cluster-hint vocabulary note (mirrors Styling note); §6 step 8 (model-hint selection) — add the senior-1m upgrade rule |
| `references/analyst-ground-rules.md` | Update read-depth requirement to mention "ARIA attribute semantics" alongside CSS rule blocks; otherwise unchanged |
| `references/analysis-analysis-template.md` | Run-identity block adds an optional `Senior-1M usage:` line capturing which analysts (if any) escalated and the trigger reason; existing fields unchanged |
| `VERSION` (codebase-deep-analysis) | 3.9.0 → 3.10.0 |
| `VERSION` (implement-analysis-report) | 3.9.0 → 3.10.0 |
| `plugin.json` | 3.9.0 → 3.10.0 |

Total: 10 files modified, 1 file created.

### Frontend Analyst row update (sole-transfer accounting)

Before v3.10, Frontend's owned-IDs list (post v3.9) reads (abbreviated):

```
... A11Y-1, A11Y-2, A11Y-3 (joint with Styling), A11Y-4, A11Y-5, ...
... UX-1 (joint with Styling), UX-2, ...
```

After v3.10:

```
... [A11Y removed entirely; Accessibility owns sole or joint], ...
... UX-1 (joint with Styling), [UX-2 transferred to Accessibility], ...
```

Frontend's net loss: 5 IDs (A11Y-1, A11Y-2, A11Y-4, A11Y-5, UX-2) leave; A11Y-3 transitions from Frontend+Styling joint to Styling+Accessibility joint (Frontend exits, Accessibility enters). Frontend's roster cell shrinks by ~80-100 chars depending on rendering.

The lens-split convention from `agent-roster.md` Ownership-collisions section is preserved: where joint, both sides annotate with `(joint with X)`.

## Risks & mitigations

| Risk | Mitigation |
|------|------------|
| **Two-eye loss on a11y findings.** Sole transfer means if Accessibility misses something, Frontend won't catch it (current shallow Frontend a11y coverage is replaced by deep Accessibility coverage with no overlap). | Frontend simply doesn't own A11Y-* IDs anymore — the dispatch wrapper passes Frontend's owned-IDs without A11Y-*, so the analyst won't file A11Y findings. Cross-scope observations still go in `Notes` per the existing `analyst-ground-rules.md` convention; that catches the rare case where Frontend spots something Accessibility might miss. The system-inventory pre-pass for Accessibility encodes the cross-file reasoning that the current shallow-Frontend pass lacks; missed-finding rate should drop, not rise. The retrospective Part A captures whether this holds. |
| **A11Y-3 two-way joint complexity.** Styling and Accessibility both own A11Y-3 with different lenses. Synthesis dedup is the backstop. | Documented in `agent-roster.md` Ownership-collisions section with explicit per-side scope: Styling = palette internal coherence; Accessibility = rendered combinations in markup. Frontend's v3.8-era joint role on A11Y-3 retires cleanly with the rest of its A11Y-* sole transfer to Accessibility. |
| **Senior-1M cost runaway.** A misconfigured auto-escalation or Scout-direct dispatch kicks every analyst on a T3 monorepo to Senior-1M. | Path A's gradient discipline (must already be at Senior) prevents the gradient case. Path B (Scout-direct) requires concrete evidence — single-analyst scope >300k LOC OR polyglot ≥4 language families OR repo >1M LOC for cross-cutting Security; the Scout cannot recommend Senior-1M on vibes. Both synthesis-specific rules have three AND-ed conditions. Tier defaults are Standard except Security at Senior. Run metadata records every escalation with `Tier path:` showing whether it was gradient, Scout-direct, or user-directive. Expect Path B to fire on <5% of T3 runs and effectively never on T1/T2. The retrospective Part A surfaces over-escalation. |
| **Scout's Senior-1M recommendation rests on a Junior-tier model's judgment.** The Scout default tier is Junior; asking it to predict context-saturation may produce false positives. | The Scout's recommendation is criteria-driven, not vibes-driven — the four trigger conditions are concrete numeric thresholds (LOC counts, language-family count) plus one categorical (`security-surface: present`). Junior models can count files and identify language families reliably. Subjective judgments are explicitly out of scope ("complex", "hard to reason about" — the Scout doesn't get to recommend on those). When evidence is borderline, the Scout emits `confidence: low` and the orchestrator defers to Path A; the Scout's recommendation never overrides existing gradient logic. |
| **Senior-1M name rot.** "1M" stops being meaningful when 2M+ models ship. | Naming caveat captured in spec + roster Escalation section: "1M" means "the largest context the harness supports". Concrete model assignment lives in the orchestrator's working memory, recorded per-run in `analysis-analysis.md` so future calibration is traceable. Skill can rename Senior-1M to Senior-XL or similar in v-next without breaking semantics. |
| **A11Y-6..A11Y-10 false-positive rate.** Five new IDs at first-real-run; false-positive risk on novel patterns (especially A11Y-6 ARIA misuse — ARIA spec is nuanced). | All five IDs go into the standard right-sizing filter at Step 4 §3. The Confidence: Verified bar requires the analyst to cite the specific failure mode (e.g., "role='button' on a `<button>` is redundant"); Plausible/Speculative findings get filtered down. Calibration note in `accessibility-prepass.md` flags A11Y-6 as the highest-risk ID for first-run feedback. |
| **Frontend's roster cell still long.** Even after losing 5 IDs, Frontend remains the largest-mandate analyst (~83 IDs). | Acknowledged. Future versions might split FE-* further (form-handling, reactive-anti-patterns, bundle-pollution) but those are coherent within Frontend's framework-correctness lens. v3.10's targeted shrinkage doesn't try to solve the bigger structural Frontend question. |
| **Accessibility Analyst applicability gates may be too narrow.** Skipping when `web-facing-ui: absent` means a CLI tool that has a small embedded help-output renderer, or an Electron app with minimal UI, gets no a11y check. | Same applicability gate as Frontend (which already does the right thing for these cases). Sub-flags (`auth-gated`, `local-only`) explicitly keep Accessibility running. If a project has UI that Frontend covers, Accessibility covers it too. The corner cases (CLI text formatters, etc.) genuinely don't have a11y surface. |
| **Pre-pass token cost.** Adding a system-inventory pre-pass to Accessibility (mirroring Styling) increases dispatch cost per Accessibility run. | The pre-pass output goes under `### A11y inventory` which synthesis reads for themes — same model as Styling. Cost is proportional to scope, gated by `web-facing-ui: present`, and the depth-vs-coverage trade is the whole point. Worth it for the quality lift on a11y findings. |

## Self-evolving feedback loop

After 1–2 v3.10 runs, the v-next author should look for in `analysis-analysis.md`:

- A11Y-6 false-positive rate (highest-risk new ID).
- A11Y-9 / FE-18 joint-ownership overlap behavior — both file form-related findings; synthesis dedup quality.
- Senior-1M escalation frequency. If <2% of runs hit it, threshold is too tight; if >20%, too loose.
- Senior-1M actual cost vs predicted cost (the 6-10x estimate). Update the calibration note.
- Whether Frontend's deferral-to-Accessibility on A11Y is honored (Frontend prompt instructs deferral; does the analyst actually defer in practice or shadow-file).
- Cluster-hint slug usage statistics for the Accessibility vocabulary (`semantic-markup-pass`, `keyboard-and-focus`, etc.).

Same retrospective contract as every other change — no special instrumentation.

## Out of scope

- **Browser-rendered a11y testing** (axe-core, pa11y, Lighthouse). Static read-only stays the boundary.
- **Visible-focus contrast** (a real WCAG criterion) — requires rendered output or framework-specific knowledge of focus-ring CSS.
- **Animation distraction tolerance** beyond `prefers-reduced-motion` respect — needs human judgment.
- **Audio descriptions / captions** for video — requires watching/listening to media.
- **Senior-1M per-cluster model-hint enforcement at fix time.** `implement-analysis-report` reads the cluster's `model-hint:` field and dispatches accordingly. v3.10 just adds the value to the vocabulary; iar consumes it natively (fourth value in an existing list, no schema change).
- **Renaming of UX-1 / UX-2.** Numbering preserved for stability; UX-2 ownership change is just a column edit, not a renumber.
- **Restructuring `agent-roster.md`** to consolidate joint-ownership annotations into a separate table. The existing inline `(joint with X)` convention scales fine to v3.10.
