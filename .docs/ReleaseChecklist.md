# WoW Addon Release Gate Checklist

Do not mark work complete until this checklist has been applied.

## 1. API and branch validation

- [ ] Target branch is identified or the Retail assumption is stated.
- [ ] API-sensitive code was checked against live references when available.
- [ ] Any unverified or branch-sensitive behavior is clearly labeled.
- [ ] No invented API, event, mixin, enum, template, or XML attribute appears in the final output.
- [ ] Compatibility wrappers exist for branch-sensitive behavior when appropriate.

## 2. Packaging and load order

- [ ] `.toc` entries are complete and ordered correctly.
- [ ] XML files load before Lua that depends on XML-defined templates or named frames.
- [ ] Optional dependencies are explicitly declared.
- [ ] External libraries, assets, and helper modules are declared rather than assumed.
- [ ] Companion test addon dependencies are explicit.

## 3. Namespace hygiene

- [ ] Shared files use `local ADDON_NAME, ns = ...` where appropriate.
- [ ] No accidental globals were introduced.
- [ ] Helpers remain local unless intentionally shared through `ns`.
- [ ] `_G` writes are absent or explicitly justified.
- [ ] Frame names, templates, mixins, slash commands, and saved variables are addon-prefixed and collision-resistant.

## 4. XML / Lua separation

- [ ] XML owns stable layout and reusable templates.
- [ ] Lua owns controller logic, runtime state, and dynamic behavior.
- [ ] XML script snippets do not hide business logic that belongs in Lua.
- [ ] Owning Lua modules for major XML roots or templates are clear.
- [ ] UI remains usable under non-default UI scale and long localized strings.

## 5. Taint and secure execution review

- [ ] Protected frames and secure templates were identified where relevant.
- [ ] In-combat vs out-of-combat restrictions are explicit.
- [ ] Attribute mutation, visibility changes, anchoring changes, and hooks were reviewed for taint risk.
- [ ] Combat-unsafe operations are isolated or guarded.
- [ ] Safer alternatives are used when possible.

## 6. Performance review

- [ ] Hot paths are identified.
- [ ] Event-driven updates are used instead of polling where possible.
- [ ] `OnUpdate` is absent or explicitly justified.
- [ ] Allocation churn in frequent handlers is minimized.
- [ ] Repeated `SetPoint`, string formatting, table creation, and closure creation in hot code were reviewed.

## 7. Settings and migrations

- [ ] Defaults are explicit.
- [ ] Loaded settings are sanitized.
- [ ] Migration logic exists where schema changes justify it.
- [ ] Runtime caches are not accidentally persisted.
- [ ] Reset-to-default behavior exists when useful.

## 8. Tests

- [ ] For complex addons, wowunit coverage was added or proposed.
- [ ] Complex bug fixes include or propose regression tests unless inherently integration-only or secure-environment-only.
- [ ] Companion test addon structure is clean and separate from production code.
- [ ] Mocks, stubs, and fixtures stay out of the shipping addon unless explicitly requested.

## 9. Output integrity

- [ ] Output is grouped by file.
- [ ] File references, names, and module links are internally consistent.
- [ ] `.toc`, XML, mixins, slash commands, and saved variables align.
- [ ] The smallest correct deliverable was chosen.
- [ ] Tradeoffs, assumptions, and remaining risks are stated clearly.

## 10. Review-mode requirements

When performing an audit or review, confirm that the final result explicitly covers:
- [ ] architecture and flow
- [ ] API correctness
- [ ] namespace hygiene
- [ ] XML/Lua separation
- [ ] taint and secure execution risks
- [ ] performance hot paths
- [ ] settings and migration robustness
- [ ] configurability gaps
- [ ] packaging and load order
- [ ] testability and wowunit opportunities
