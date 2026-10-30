---
name: gadget-update
description: Update gadget-wise to the latest version — git pull the repository and re-sync the gadget-* skills into the global skills folders. Use when the user says 'update gadget-wise', 'pull the latest gadget-wise', or asks for newer gadget3 model templates or skills.
---

<!-- pack-resources:start -->
**Pack resources:** resolve `gadget-wise` from `~/.gadget-wise/config.json` → `gadget_wise_path` (or
`~/.fiskwise/config.json` → `components.gadget-wise.path`). If neither exists, use the checkout
containing this skill, or locate/obtain the pack through its install instructions. Paths such as
`knowledge/`, `config/`, `examples/` and `project-template/` belong to that repository, not the
current model directory. Keep bundled `references/` links relative to the skill. Never assume
`../../` from an agent's global skills folder reaches the repository. Use absolute resolved paths.
<!-- pack-resources:end -->

# Update gadget-wise

For a managed update use `fiskwise-update`; if this skill was invoked by it, handle only
gadget-wise-specific work.

1. **Locate**: `gadget_wise_path` in `~/.gadget-wise/config.json`. Missing → run `gadget-install`.
2. **Pull**:
   ```bash
   git -C "<gadget_wise_path>" fetch --quiet
   git -C "<gadget_wise_path>" pull --ff-only
   ```
   Local changes: report them and let the user decide; never discard or stash silently.
3. **Re-sync** only the `gadget-*` skill entries (keep symlinks that resolve to the source; back up a
   differing entry first; never touch other packs).
4. **Packages**: if the update notes a newer gadget3/gadgetutils requirement, offer the install (with
   consent); never upgrade packages inside a project that has `renv.lock` without asking.
5. **Report** what changed (git log: skills, knowledge, templates). **Existing model projects are not
   migrated**; name changes that matter to them (a fixed helper, a corrected convention) and let the
   analyst decide when to adopt them — rarely in the middle of an advice round.
