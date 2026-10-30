# CLAUDE.md — gadget-wise (Claude Code)

gadget-wise is part of [Fiskwise](https://deepwaterimr.github.io/fiskwise/).

This is the **Claude Code** pointer. The full agent contract is in [`AGENTS.md`](AGENTS.md) — read
it. This file only adds Claude-specific notes.

- Skills install as `~/.claude/skills/gadget-*` (symlinks to `skills/`).
- **Public repository — never commit data, model output or private paths.** `.claudeignore` lists
  files not to read automatically.
- Before changing `project-template/`, run `Rscript config/validate-scaffold.R`; it must pass.
- Use `r-code-style` for R; wise-writing skills for documents.
- Development memory for this pack: `memory/MEMORY.md`.
