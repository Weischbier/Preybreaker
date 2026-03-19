# WoW Addon Engineering Policy

This repository is specialized for generating, maintaining, and reviewing high-fidelity World of Warcraft addons.

## Source priority

When live browsing is available and the task is API-sensitive, validate against these sources in this order:

1. Warcraft Wiki API index  
   `https://warcraft.wiki.gg/wiki/World_of_Warcraft_API`
2. BlizzardInterfaceCode mirror  
   `https://github.com/wind-addons/BlizzardInterfaceCode`
3. Wago.Tools  
   `https://wago.tools/`

Use repository code and project files as the primary project-specific source of truth, but use the live sources above to validate current API details, recent changes, templates, branch differences, and Blizzard UI internals.

If live browsing is unavailable:
- say so explicitly
- proceed conservatively
- never fabricate APIs
- clearly label assumptions
- prefer compatibility guards and fallback-safe design

## Source conflict resolution

If sources disagree, resolve them in this order:
1. explicit repository code and user-provided project files
2. BlizzardInterfaceCode for implementation reality
3. Warcraft Wiki API documentation for reference clarity
4. Wago.Tools for lookup and cross-reference support

If a conflict remains unresolved:
- state the conflict explicitly
- do not present the uncertain detail as confirmed
- provide the safest implementation path
- isolate compatibility-sensitive code

## API validation traceability

When answering API-sensitive questions or writing API-sensitive code:
- briefly state which live source or sources were checked
- explicitly label any uncertain symbol, template, event, mixin, enum, or secure behavior
- do not imply live verification happened if browsing was unavailable

## Branch policy

Always determine the target game branch first.

Supported targets:
- Retail
- Classic Era
- Cataclysm Classic
- MoP Classic
- explicitly named future branches

If unspecified:
- default to current Retail-style architecture
- state the assumption
- flag any API or behavior that may differ by branch

## Architecture policy

Prefer disciplined addon architecture over one-off patches.

Default structure:
- `AddonName.toc`
- `AddonName.xml`
- `Core/`
- `UI/`
- `Data/`
- `Locale/`
- `Integrations/`
- `README.md`

For complex projects, also support:
- `AddonName_Tests.toc`
- `Tests/`
- `TestDoubles/`
- `Fixtures/`

Favor:
- model/controller/view separation
- event-driven flow
- explicit ownership
- stable module boundaries
- clear initialization lifecycle

## Packaging and load-order discipline

Always ensure:
- `.toc` file order matches runtime dependencies
- XML is loaded before Lua files that depend on XML-defined objects or templates
- optional dependencies are declared explicitly when needed
- library load assumptions are never implicit
- companion test addon dependencies are declared explicitly

## Dependency declaration rule

Never assume external libraries, media, templates, assets, or helper files exist unless they are:
- generated in the file tree
- explicitly provided by the user
- clearly declared as dependencies

If a dependency is required, list it explicitly in the file tree and `.toc`.

## Namespace hygiene policy

Namespace pollution is a release-quality concern.

Required practices:
- use `local ADDON_NAME, ns = ...`
- keep internals local
- expose only deliberate cross-module APIs through `ns`
- avoid accidental globals
- avoid generic frame names
- avoid generic slash-command names
- uniquely prefix frame names, event identifiers, callback registries, saved variable names, and template names
- do not mutate `_G` unless explicitly required
- do not shadow Blizzard globals carelessly
- do not leak debug or test helpers into runtime globals

During review, explicitly check for:
- accidental globals
- missing `local`
- unsafe `_G[...]` assumptions
- frame-name collisions
- callback or event collision risk
- slash-command collisions
- mutable shared tables exposed too broadly
- library namespace conflicts

## XML UX policy

For UI-heavy addons, prefer XML for foundational layout and reusable templates.

Use XML for:
- root windows and panels
- reusable templates
- structured widget groups
- settings panels
- dialog shells
- scroll-frame structures

Use Lua for:
- controller logic
- data transformations
- runtime state
- conditional composition
- dynamic content behavior
- event handling
- secure logic decisions

Keep XML and Lua ownership explicit:
- the owning Lua file should be clear
- mixins should be named consistently
- root frames and templates should be addon-prefixed where possible
- do not bury business logic in fragile XML script snippets if it belongs in Lua

## UI resilience requirements

UI must remain usable under:
- non-default UI scale
- long localized strings
- repeated open and close cycles
- reloads
- missing or delayed data states

Avoid brittle fixed-width assumptions unless intentionally justified.

## Taint and secure execution policy

Treat secure boundaries as high risk.

Always examine:
- secure templates
- protected frames
- unit frames
- action buttons
- click-casting behavior
- combat-lockdown restrictions
- protected attribute changes
- layout mutation while protected
- hooks into Blizzard code that may taint flows

When applicable, clearly classify:
- safe in combat
- unsafe in combat
- out-of-combat-only
- secure workaround or safer alternative

## Taint hotspot audit

When secure or protected UI is involved, explicitly inspect and comment on:
- frame creation path
- attribute mutation path
- visibility changes
- anchoring changes
- hook points
- in-combat vs out-of-combat transitions

## Performance policy

Performance is not optional.

Prefer:
- events over polling
- throttling over unbounded repeated work
- frame reuse over churn
- cached references where appropriate
- minimal allocations in frequent paths
- low overhead in `OnEvent`, `OnUpdate`, aura processing, and widget processing

Flag:
- hot loops
- repeated table creation
- repeated string formatting
- repeated closure creation
- repeated global lookups in hot code
- excessive redraw or reanchor work

## Saved variables and migrations policy

Always:
- define explicit defaults
- sanitize loaded values
- support schema migrations when needed
- separate transient state from persisted data
- preserve backward compatibility where practical
- provide safe reset behavior

Test migrations when saved-variable complexity exists.

## Compatibility wrapper policy

For branch-sensitive or unstable APIs, prefer a dedicated compatibility module or adapter layer instead of scattering conditional checks throughout the codebase.

Centralize:
- `C_` API guards
- enum fallbacks
- template or mixin existence checks
- feature detection by branch

## wowunit testing policy

For non-trivial addons, testability matters.

Prioritize tests for:
- configuration sanitization
- schema migration
- state transitions
- event routing decisions
- controller logic
- data transformation
- filtering and sorting logic
- branch-specific compatibility wrappers
- regression-prone bug fixes

Avoid making critical logic untestable by burying it inside frame scripts where a module boundary could exist.

## Separate test addon policy

For complex addons, use a separate companion test addon.

Preferred naming:
- `AddonName`
- `AddonName_Tests`

The test addon should include:
- its own `.toc`
- wowunit dependency or configuration
- suite bootstrap
- mocks and stubs for WoW API boundaries
- fixtures for saved variables, event payloads, and controller states
- focused tests grouped by subsystem

The production addon should not carry broad test-only runtime baggage unless explicitly requested.

## Regression testing rule

Whenever fixing a bug in a complex addon, add or propose a wowunit regression test unless the bug is inherently integration-only or secure-environment-only.

## Code generation policy

When implementation is requested:
- provide drop-in code, not pseudo-code
- output by file
- ensure all file references line up
- ensure `.toc` entries are consistent
- ensure XML and Lua names match
- keep code internally coherent

When the addon is complex, include:
- test addon file tree
- test `.toc`
- wowunit suites
- mocks, stubs, and fixtures
- test instructions

## Audit policy

When reviewing existing addons, always evaluate:
- architecture and flow
- API correctness
- namespace hygiene
- accidental globals
- XML/Lua separation
- taint risk
- performance
- settings durability
- error handling
- configurability gaps
- packaging readiness
- testability and wowunit opportunities

## Output policy

Default response structure:

```text
<TaskType>Write|Debug|Review|Explain|Refactor|Document|Test</TaskType>
<Language>Lua|XML</Language>
<Target>addon, module, file, or function name</Target>
<Output>
[well-structured markdown with complete files or analysis]
</Output>
<Suggestions>
[next steps, hardening, tests, migration notes, or compatibility notes]
</Suggestions>
```
