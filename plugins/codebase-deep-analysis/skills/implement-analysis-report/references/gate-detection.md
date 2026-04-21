# Gate detection

How the orchestrator detects the verification gate set at preflight, and how per-cluster `gate:` frontmatter overrides interact with it.

## Baseline detection (run at preflight)

The baseline is the set of gates that run after every cluster commit unless a cluster's frontmatter overrides. Detect in this order; stop at the first hit per category.

### test

1. `package.json` scripts: exact key `test`, or keys matching `^test:.*` (e.g., `test:unit` is acceptable but prefer bare `test` if present).
2. `Makefile`: target `test` (look for `^test:` at start of line).
3. `justfile`: recipe `test`.
4. `Taskfile.yml` / `Taskfile.yaml`: task `test`.
5. `pyproject.toml` `[tool.poe.tasks]` / `[tool.pdm.scripts]` / equivalent: entry `test`.
6. `Cargo.toml` present → `cargo test`.
7. `go.mod` present → `go test ./...`.
8. None of the above → no `test` gate.

### typecheck

1. `package.json` scripts: keys matching `typecheck|tsc|check-types`.
2. `package.json` devDeps include `typescript` AND a `tsconfig.json` exists → fall back to `tsc --noEmit`.
3. `mypy` or `pyright` in `pyproject.toml` or `requirements-dev.txt` → `mypy` / `pyright` on the package root.
4. `Cargo.toml` present → `cargo check` (type + borrow checking).
5. None → no `typecheck` gate.

### lint

1. `package.json` scripts: keys matching `^lint$|^lint:.*`.
2. `eslint.config.*` or `.eslintrc*` present → `eslint .` (but prefer a configured script).
3. `.rubocop.yml` present → `rubocop`.
4. `pyproject.toml` `[tool.ruff]` or `[tool.flake8]` → the respective tool.
5. None → no `lint` gate.

### build

1. `package.json` scripts: key `build`.
2. `Makefile` target `build`.
3. `Cargo.toml` → `cargo build --release` only if the project has artifacts (an `[[bin]]` entry or a `Cargo.toml` at a workspace member with a `[lib]`).
4. None → no `build` gate.

## User editing at preflight

The preflight prompt (`preflight-prompt.md`) shows each detected command and lets the user edit or remove. An empty final set is allowed — the preflight shows a warning that clusters will close without gate enforcement, and the user must explicitly confirm.

## Per-cluster `gate:` frontmatter override

If a cluster's frontmatter has a `gate:` field, it replaces the baseline for that cluster. The override is a comma-separated list naming gates by key:

```
gate: test, typecheck
```

Missing gates (not listed) are skipped for that cluster. An empty override (`gate: `) means no gates at all for that cluster.

A cluster may also name a gate the baseline did not detect:

```
gate: test, custom:bun run coverage:check
```

The `custom:<cmd>` syntax adds an ad-hoc command. The orchestrator runs it with the same timeout rules as detected gates.

## Execution

For each gate in the active set:

1. Run the command from the project root. Capture stdout + stderr.
2. Exit code 0 → pass.
3. Non-zero exit → fail. Capture first 40 lines of stderr for the showstopper entry.

## Timeouts

Default per-gate timeout: 10 minutes (600 seconds).

Per-gate timeout override at preflight: the preflight prompt allows the user to set a custom timeout per gate (e.g., `build: 30 min` for a slow webpack build). Override lives in `PREFLIGHT_DECISIONS.gate_timeouts` keyed by gate name (seconds).

A gate that exceeds its timeout is killed (SIGTERM, then SIGKILL after 10 seconds grace) and treated as a failure.

## Common mistakes

- **Running all detected gates when only some are relevant.** If a cluster only touches CSS and the project has a test suite that doesn't cover CSS, running `test` for that cluster is wasted time. The cluster's frontmatter `gate:` override is the cleanest way to scope; absent that, the baseline runs.
- **Inventing gate commands.** If detection returns nothing for a category, leave it out. Don't default to `jest` or `mocha` or any framework the project does not declare.
- **Not capturing gate output on success.** The showstopper list only needs failed-gate output. Do not balloon the run log with passing-gate stdout.
- **Re-running a gate after an unchanged retry.** Second pass only runs gates if the subagent produced new edits. If the subagent returned shape B (`cannot implement`) in both passes, the cluster lands as `partial` without a second gate run.
