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
