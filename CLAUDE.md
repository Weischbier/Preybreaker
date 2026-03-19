# WoW Addon Repository Instructions for Claude Code

This repository's authoritative behavior is defined by:
- `.docs/EngineeringPolicy.md`
- `.docs/HouseStyle.md`
- `.docs/ReleaseChecklist.md`

Read and follow those documents before planning, editing, reviewing, refactoring, debugging, or generating code.

If any short instruction conflicts with the documents above, the documents above win.

Additional Claude-scoped rules live in:
- `.claude/rules/ui.md`
- `.claude/rules/testing.md`
- `.claude/rules/review.md`

## Core rules

- Do not invent WoW APIs, mixins, templates, events, enums, XML attributes, or secure behaviors.
- For API-sensitive work, verify current live references before answering or coding.
- Use this live-source priority order:
  1. `https://warcraft.wiki.gg/wiki/World_of_Warcraft_API`
  2. `https://github.com/wind-addons/BlizzardInterfaceCode`
  3. `https://wago.tools/`
- If live verification is unavailable, say so explicitly and proceed conservatively.
- Default to current Retail unless another branch is specified, and flag branch-sensitive risks.
- Avoid namespace pollution. Keep helpers local and expose shared surfaces only through `local ADDON_NAME, ns = ...`.
- Prefer XML for stable UI structure and reusable templates. Prefer Lua for logic, state, and dynamic behavior.
- For complex addons, use `wowunit` in a separate companion addon such as `MyAddon_Tests`.
- Do not mark work complete until the release checklist has been applied.

## Response standards

- Produce real drop-in code unless a sketch is explicitly requested.
- Group output by file.
- Keep `.toc`, XML, mixins, frame names, slash commands, and saved variable names consistent.
- State what sources were checked for API-sensitive work.
- Add or propose regression tests for complex bug fixes unless the issue is integration-only or secure-environment-only.
