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
