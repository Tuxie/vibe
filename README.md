# vibe

A small, hand-authored collection of agent skills. Each skill is self-contained under `plugins/<skill>/skills/<skill>/` and follows the 2025 **Agent Skills** format (SKILL.md with YAML frontmatter) that Anthropic, OpenAI, Google, and OpenCode have all converged on.

The repo is simultaneously:

- A **Claude Code plugin marketplace**, so CC users can install individual skills with a single command.
- A `.agents/skills/` directory so **Codex CLI**, **Gemini CLI**, and **OpenCode** can pick the same skills up by dropping a symlink or clone into place.

## Skills

| Skill | Summary |
|-------|---------|
| [`bootstrap-project`](./plugins/bootstrap-project/skills/bootstrap-project/SKILL.md) | Pre-implementation project bootstrap interview. Writes compact `AGENTS.md` plus focused `docs/bootstrap/` instructions, then gates actual code scaffolding until the human explicitly types `bootstrap!`. |
| [`codebase-deep-analysis`](./plugins/codebase-deep-analysis/skills/codebase-deep-analysis/SKILL.md) | Exhaustive parallel-analyst deep analysis, right-sized to project tier. Produces a multi-file report under `docs/code-analysis/{date}/` for cluster-by-cluster fix sessions. Includes a gated coverage/profiling pass and a self-evolution retrospective. |

## Install

### Claude Code (plugin marketplace)

```
/plugin marketplace add tuxie/vibe
/plugin install codebase-deep-analysis@tuxie-vibe
```

Replace `tuxie/vibe` with the full HTTPS URL (`https://gitlab.example/you/vibe.git`) or local path (`/src/vibe`) if you cloned elsewhere. Re-run `/plugin install <name>@tuxie-vibe` for each skill you want.

After install, skills are available as normal — invoke via `Skill` tool or let discovery surface them when their `description` matches.

### Codex CLI

Codex scans `.agents/skills/` up from the current working directory, then `~/.agents/skills/`. Pick one:

**Per-repo (recommended for project-scoped skills):**
```sh
git clone git@github.com:tuxie/vibe.git ~/src/vibe
ln -s ~/src/vibe/.agents/skills/codebase-deep-analysis \
       <your-project>/.agents/skills/codebase-deep-analysis
```

**User-wide:**
```sh
git clone git@github.com:tuxie/vibe.git ~/src/vibe
mkdir -p ~/.agents/skills
ln -s ~/src/vibe/.agents/skills/codebase-deep-analysis \
       ~/.agents/skills/codebase-deep-analysis
```

Codex will discover the skill automatically from its `description`. List explicitly with `/skills`.

### Gemini CLI

Gemini scans `.agents/skills/` (workspace or `$HOME`) with the same spec. Use the same symlink setup as Codex. Gemini activates skills via the `activate_skill` tool; you cannot force-invoke from the prompt, it chooses based on the `description`.

### OpenCode

OpenCode natively reads `.claude/skills/`, `.agents/skills/`, and `.opencode/skills/` (workspace walks up to git root, then `~/.config/opencode/skills/`, `~/.claude/skills/`, `~/.agents/skills/`). Use the same symlink setup as Codex or Gemini.

OpenCode exposes skills via its `skill` tool.

## Repo layout

```
.
├── .claude-plugin/
│   └── marketplace.json                   # Claude Code marketplace catalog
├── plugins/
│   └── <skill>/
│       ├── .claude-plugin/plugin.json     # Claude Code plugin manifest
│       └── skills/
│           └── <skill>/                   # canonical skill content
│               ├── SKILL.md
│               ├── references/
│               └── scripts/
├── .agents/
│   └── skills/
│       └── <skill> -> ../../plugins/<skill>/skills/<skill>   # symlink bridge
└── README.md
```

The deeply-nested CC plugin path exists because CC caches each plugin as a self-contained tree; the symlink under `.agents/skills/` is the cross-platform entry point so the three non-CC agents don't have to know about the plugin wrapping.

## Contributing a new skill

1. Author the skill under `plugins/<name>/skills/<name>/SKILL.md` (plus optional `references/`, `scripts/`). Follow the Agent Skills spec — YAML frontmatter with `name` and `description`, markdown body, ≤1024 chars total frontmatter.
2. Add `plugins/<name>/.claude-plugin/plugin.json` with `name`, `version`, `description`.
3. Append an entry to `.claude-plugin/marketplace.json` under `plugins[]`.
4. Symlink the canonical path into the bridge: `ln -s ../../plugins/<name>/skills/<name> .agents/skills/<name>`.
5. Add a row to the Skills table in this README.

The `superpowers:writing-skills` skill (or Anthropic's [skill authoring docs](https://agentskills.io/specification)) is the reference for frontmatter fields and testing conventions.

## Contact

Per Wigren — `per@wigren.eu`
