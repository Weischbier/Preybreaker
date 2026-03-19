# WoW Addon House Style Guide

Use these conventions unless a task explicitly requires another pattern.

## General philosophy

Prefer:
- clean architecture over quick patches
- explicit ownership over implicit coupling
- local scope over globals
- deterministic state transitions
- event-driven updates over polling
- reusable modules over duplicated code
- production-ready code over sketches
- readable code over clever code

The default standard is:
- shippable
- maintainable
- branch-aware
- low-taint
- low-overhead
- easy to audit
- easy to extend

## Default addon structure

Preferred structure for medium and large addons:

- `AddonName.toc`
- `AddonName.xml`
- `Core/`
  - `Bootstrap.lua`
  - `Events.lua`
  - `State.lua`
  - `Config.lua`
  - `Utils.lua`
- `UI/`
  - `MainFrame.xml`
  - `MainFrame.lua`
  - `Templates.xml`
  - `Widgets.lua`
  - `Options.xml`
  - `Options.lua`
- `Data/`
  - `Defaults.lua`
  - `Constants.lua`
- `Locale/`
  - `enUS.lua`
  - `deDE.lua`
- `Integrations/`
- `README.md`

Preferred structure for complex addons with tests:
- `AddonName/` production addon
- `AddonName_Tests/` companion test addon

Test addon layout:
- `AddonName_Tests.toc`
- `TestBootstrap.lua`
- `Tests/`
  - `ConfigTests.lua`
  - `StateTests.lua`
  - `MigrationTests.lua`
  - `ControllerTests.lua`
- `TestDoubles/`
  - `WoWApiMock.lua`
  - `FrameStub.lua`
- `Fixtures/`
  - `SavedVariableFixtures.lua`
  - `EventFixtures.lua`

## Namespace and pollution rules

Always start shared files with:

```lua
local ADDON_NAME, ns = ...
```

Rules:
- keep internal helpers local
- expose shared APIs only through `ns`
- do not leak helpers into `_G`
- do not create accidental globals
- do not use bare globals for module state
- do not mutate Blizzard globals unless explicitly required
- do not create unprefixed frame names
- do not create generic slash commands that may collide with other addons

Preferred naming:
- addon namespace: `ns`
- internal module tables: `ns.ModuleName`
- constants: `ns.Constants`
- defaults: `ns.Defaults`
- shared utilities: `ns.Util`

Frame and template naming must be addon-prefixed:
- `MyAddonMainFrame`
- `MyAddonStatusBarTemplate`
- `MyAddonOptionsPanel`

Saved variables must be addon-prefixed and stable:
- `MyAddonDB`
- `MyAddonSettings`
- `MyAddonState`

Slash commands must be specific and collision-resistant:
- `/myaddon`
- `/mad`
- avoid generic commands like `/config`, `/debug`, `/reloadui`

## File naming conventions

Use clear, predictable names.

Preferred file naming:
- `Bootstrap.lua`
- `Config.lua`
- `State.lua`
- `Events.lua`
- `MainFrame.lua`
- `MainFrame.xml`
- `Options.lua`
- `Options.xml`
- `Templates.xml`

Avoid vague names like:
- `Misc.lua`
- `Stuff.lua`
- `Helper2.lua`
- `ManagerFinal.lua`

## Module boundaries

Each module should have one primary responsibility.

Preferred split:
- `Bootstrap`: startup, init ordering, registration handoff
- `Config`: defaults, sanitization, migration entry points
- `State`: runtime state ownership and mutations
- `Events`: event registration and dispatch
- `UI`: frame creation, view logic, templates, display state
- `Integrations`: optional external bridges

Avoid:
- mixing config migration with UI rendering
- mixing state mutation with XML layout details
- mixing raw event routing with business logic when a controller module is cleaner

## XML house style

Use XML for stable structural layout.

Prefer XML for:
- root frames
- windows and panels
- reusable templates
- settings panels
- repeated button groups
- scroll containers
- static or semi-static widget hierarchies

Prefer Lua for:
- behavior
- state transitions
- event responses
- data binding
- runtime decisions
- dynamic row or item generation
- controller logic

XML rules:
- frame and template names must be addon-prefixed
- mixin names must be explicit and addon-prefixed where appropriate
- avoid putting business logic in XML script blocks if it belongs in Lua
- document the owning Lua file for each major XML root or template
- keep anchor chains simple and readable
- avoid fragile deeply nested layouts when a flatter structure is cleaner

## Lua house style

Preferred style:
- local-first
- explicit guards
- predictable return values
- simple tables
- minimal metatable trickery
- no unnecessary abstraction

Guidelines:
- use early returns
- avoid deep nesting
- avoid hidden mutation
- avoid unnecessary closures in hot paths
- cache expensive repeated lookups where appropriate
- keep public and shared surfaces small

## Event handling conventions

Prefer a clear event owner.

Recommended patterns:
- one event frame with explicit dispatch table
- or a dedicated `Events` module with controlled registration

Prefer:
- explicit `RegisterEvent` ownership
- clean unregister behavior
- minimal work inside event handlers
- forwarding into controller or state modules as needed

Avoid:
- spreading unrelated event handlers across many anonymous frames
- heavy logic directly inside raw event callbacks
- repeated registration without guards

Event callback naming:
- `OnPlayerLogin`
- `OnAddonLoaded`
- `OnUnitAura`
- `OnConfigChanged`

## Ace3 usage rules

Use Ace3 only when it materially improves maintainability.

Allowed common uses:
- `AceAddon-3.0` for lifecycle and module structure
- `AceEvent-3.0` for event handling
- `AceConsole-3.0` for slash commands
- `AceDB-3.0` for settings
- `AceConfig-3.0` and `AceConfigDialog-3.0` for options UI

Rules:
- do not half-adopt Ace3 patterns
- if `AceAddon` is used, structure consistently around it
- if `AceDB` is used, use profiles intentionally, not accidentally
- do not mix Ace3 conventions and ad hoc architecture sloppily
- do not add Ace3 to tiny addons unless it genuinely helps

## Saved variables style

Requirements:
- define defaults explicitly
- sanitize loaded settings
- support migrations
- preserve backward compatibility when practical
- keep runtime caches out of persisted DB
- never trust legacy values blindly

Migration rules:
- track schema version explicitly when complexity justifies it
- migrate once during controlled bootstrap
- keep migration functions isolated and testable
- add wowunit tests for migrations in complex addons

## Slash command style

Slash commands must be:
- specific
- short
- discoverable
- non-colliding

Preferred:
- `/myaddon`
- `/mad`
- `/myaddon debug`
- `/myaddon reset`

Command parsing rules:
- centralize parsing
- validate subcommands
- return helpful usage text
- do not scatter slash command behavior across multiple files

## Localization style

Default locale file order:
- `enUS.lua` as baseline
- additional locale files after baseline

Rules:
- keep localization keys stable
- avoid embedding user-facing strings directly in logic-heavy modules
- keep fallback behavior predictable
- do not localize debug-only internal identifiers unless needed

## Performance style

Always assume some handlers are hot.

Watch especially:
- aura updates
- widget updates
- combat-related events
- repeated layout passes
- repeated string formatting
- repeated table allocations
- repeated global lookups in tight loops

Prefer:
- cached references where useful
- table reuse where appropriate
- throttling or debouncing for spammy updates
- event-driven state recalculation
- incremental refresh over full redraw where practical

Avoid:
- unconditional `OnUpdate`
- repeated `SetPoint` churn
- rebuilding widgets unnecessarily
- allocating fresh tables in tight loops unless justified

## Taint and secure style

Treat secure UI boundaries conservatively.

Always review:
- secure templates
- protected frames
- combat lockdown
- action and unit button interactions
- attribute mutation
- frame visibility or position updates during combat

When secure behavior is involved:
- explicitly classify what is safe out of combat only
- isolate combat-unsafe operations
- prefer safer non-protected alternatives where possible
- do not casually hook or mutate Blizzard protected flows

## Debugging style

Debugging support should be deliberate.

Preferred:
- one debug flag location
- one debug print helper
- clearly prefixed output

Rules:
- do not spam logs in hot paths
- do not leave noisy debug output enabled by default
- do not leak debug helpers globally

## wowunit test house style

For complex addons, use a separate test addon.

Test priorities:
- config sanitization
- migrations
- state transitions
- controller logic
- filtering and sorting
- branch wrappers
- regression tests for fixed bugs

Test style rules:
- one clear subject per suite
- table-driven tests where useful
- isolate WoW API boundaries with wrappers or mocks
- avoid testing incidental private implementation details
- test behavior and contracts
- keep fixtures readable
- test failure paths and invalid inputs

Preferred suite naming:
- `ConfigTests.lua`
- `MigrationTests.lua`
- `StateTests.lua`
- `ControllerTests.lua`

## README house style

For serious addons, README should include:
- purpose
- supported branches
- feature summary
- installation
- slash commands
- settings overview
- compatibility notes
- known limitations
- test addon usage if applicable

## Review and audit house style

When reviewing addon code, always evaluate:
- architecture
- namespace hygiene
- accidental globals
- API correctness
- XML/Lua separation
- taint risk
- performance
- settings robustness
- migration quality
- maintainability
- configurability
- testability

If issues are found, present them in priority order:
1. correctness or runtime breakage
2. taint or secure risk
3. data-loss or migration risk
4. performance risk
5. maintainability and extensibility issues
6. UX polish gaps
