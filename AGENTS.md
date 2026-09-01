# RBLX Menu — AI Documentation

> Documentation for AI assistants (LLMs, agents, code review bots).
> Read this before answering any question about this codebase.

## 1. Project Overview

**RBLX Menu** is a Lua UI library for Roblox scripts (commonly used with exploit executors like Synapse, Script-Ware, Fluxus, etc.). It provides a single-file, zero-dependency, dark-themed graphical interface with tabs, toggles, sliders, dropdowns, inputs, and labels.

- **Language:** Lua (Roblox Luau environment)
- **Distribution:** Single self-contained file (`menu.lua`) consumed via `loadstring(game:HttpGet(...))`
- **Audience:** Script authors who want a clean UI without writing one from scratch
- **License:** (Add your license — MIT recommended for script libraries)

## 2. File Structure

```
rblxmenu/
├── menu.lua        # The entire library. ~700 lines. Self-contained.
├── example.lua     # Usage example. Not loaded by the library.
└── README.md       # Human-facing docs (separate from this file)
```

There is **only one source file**. Do not split it unless asked. The whole library must remain a single `loadstring`-friendly module.

## 3. Architecture

The library follows this top-down flow:

```
ScreenGui (parented to CoreGui / gethui / syn.protect_gui)
├── ToggleButton (TextButton, FAB-style, opens the window)
└── Window (Frame, draggable, hidden by default)
    ├── TitleBar (Frame, drag handle, close button)
    ├── Sidebar (Frame, contains tab buttons)
    │   └── TabsList (ScrollingFrame, vertical list of tab buttons)
    └── Content (Frame, hosts tab containers)
        └── Tab Container (ScrollingFrame per tab)
            └── Elements (Toggles, Buttons, Sliders, Dropdowns, Inputs, Labels, Sections)
```

### Layers of abstraction

1. **Utilities** (`Corner`, `Stroke`, `Padding`, `ListLayout`, `AddShadow`, `Tween`, `MakeDraggable`) — pure instance factories. Don't refactor unless duplicated logic appears.
2. **Theme table** at the top of the file. To retheme the UI, only edit `Theme` — never hardcode colors inside element builders.
3. **Window API** (`Menu:CreateWindow`) — returns a window object.
4. **Tab API** (`Window:CreateTab`) — returns an `elements` table that exposes all UI builders.
5. **Element builders** — `CreateToggle`, `CreateButton`, `CreateSlider`, `CreateDropdown`, `CreateInput`, `CreateLabel`, `CreateSection`. Each pushes into either the active section (via `elements._currentSection`) or the tab container directly.

### State management

- Toggles, sliders, dropdowns keep state **inside their closure** (`local state = ...`). They do not register globally.
- The library exposes **no globals** except `Menu` (the returned module table).
- Hotkey handling is centralized in one `UserInputService.InputBegan` listener (RightShift toggle).

## 4. Public API Reference

### `Menu:CreateWindow(opts) -> window`

| Field   | Type   | Default       | Notes                              |
|---------|--------|---------------|------------------------------------|
| `Title` | string | `"RBLX Menu"` | Sets the title bar text            |

Returns a `window` object.

### `window:CreateTab(name, icon?) -> elements`

| Field  | Type   | Required | Notes                                              |
|--------|--------|----------|----------------------------------------------------|
| `name` | string | yes      | Tab title; also used as internal key               |
| `icon` | string | no       | Unicode emoji prefix (e.g. `"⚔"`); prepended to label |

Returns an `elements` builder table. The first created tab becomes active.

### Element Builders

All builders take a `callback` as the last argument. Callbacks fire on user interaction (click, drag, focus loss, selection) — never on creation.

```lua
elements:CreateToggle(text, default?, callback?)
elements:CreateButton(text, callback?)
elements:CreateSlider(text, opts?, callback?)
elements:CreateDropdown(text, options[], default?, callback?)
elements:CreateInput(text, placeholder, callback?)   -- placeholder is currently unused; `text` serves as placeholder label
elements:CreateLabel(text)
elements:CreateSection(text)
```

`CreateSlider` `opts`:
```lua
{ Min = 0, Max = 100, Default = 0, Suffix = "" }
```

`CreateSection` switches the **target container** for subsequent element calls until another section is opened. Sections render as titled cards. Useful for grouping.

### Internal convention

- Every interactive row must have `corner = 6`, `height = 34` (buttons/toggles/dropdowns/inputs), `height = 50` (sliders), or `height = 26` (labels).
- `elements._currentSection` tracks the active section. **Never** have two sections "open" at once — the API does not stack them.

## 5. Code Conventions

### Style

- **Indentation:** 4 spaces. No tabs.
- **Quotes:** Double quotes for strings. Single quotes only inside already-double-quoted contexts.
- **Local-first:** Every function and helper is declared `local`. Globals only via `_G` for the returned module table.
- **No comments inside element builders.** The library ships without inline commentary; the public docs are the source of truth.
- **Naming:** `PascalCase` for the returned tables (`Menu`, `Window`), `camelCase` for methods on them (`CreateWindow`, `CreateTab`). Utilities are `PascalCase` factory functions.

### Ordering inside `menu.lua`

The file is intentionally ordered:

1. Module table + index
2. Services
3. `Theme` table
4. Utility factories (`Corner`, `Stroke`, `Padding`, `ListLayout`, `AddShadow`, `Tween`, `MakeDraggable`)
5. Re-entry guard
6. `ScreenGui` creation + executor detection
7. `ToggleButton` (FAB)
8. `Window` + `TitleBar` + `CloseBtn`
9. `Sidebar` + `TabsList`
10. `Content` frame
11. Window open/close logic + hotkey
12. `Menu:CreateWindow` public API
13. `CreateTab` and element builders

**Do not reorder** when adding new builders — keep new elements grouped with their siblings at the bottom of `CreateTab`'s closure.

### Theming

All colors come from the `Theme` table. Never call `Color3.fromRGB(...)` inside an element builder. If a new color is needed, add it to `Theme`.

### Tween policy

All visual transitions use `Tween()` (Quart-out, 0.15–0.2s). Hover effects are tweened, not snapped. Don't introduce `:TweenSize`/`TweenService` shortcuts — go through the helper.

## 6. Adding a New Element Type

When asked to add a new element (e.g. `CreateKeybind`, `CreateColorPicker`, `CreateTextArea`):

1. Add a builder function inside the `CreateTab` closure, after existing builders.
2. Use `MakeRow(parent, height)` for the container — never invent a new row layout.
3. Store state in a `local` closure variable. Do not introduce a global state table.
4. Return nothing — elements are fire-and-forget; behavior lives in the user callback.
5. Update **both** `example.lua` (a usage example) and section 4 of this file.
6. If the element toggles multiple values (e.g. color picker with R/G/B/A), use the slider pattern internally.

## 7. Executor Compatibility

The library must work across common Roblox executors. It detects the environment in this order:

```lua
if syn and syn.protect_gui then ...       -- Synapse X
elseif gethui then ...                    -- Script-Ware, Fluxus, etc.
else CoreGui ...                          -- fallback
end
```

When adding features that depend on executor-only APIs, follow the same fallback chain. Never assume a specific executor.

## 8. Common Pitfalls

- **`ZIndex` ordering:** The dropdown's option list uses `ZIndex = 5+` because it overlays other rows. Mirror this pattern for any overlay element (color picker popup, context menu, etc.).
- **`AutomaticCanvasSize`:** Tab containers and the sidebar tab list both rely on this. Don't switch to manual `CanvasSize` math unless asked.
- **Title-bar corner fix:** `Window` has rounded corners; the title bar uses a small rectangular frame to mask the lower corners of the title bar's own corner radius. Don't remove the `fix` instance — the UI will look broken.
- **Sidebar corner symmetry:** Same pattern applies on the right edge via `SidebarFix`.
- **Re-entry:** The library self-destroys a previous instance on load. Don't remove this guard; users commonly re-execute the loader.
- **First tab auto-activation:** When creating the very first tab, it must call `showTab(name)`. The first tab in the list is auto-activated — verify this still holds when refactoring tab creation logic.

## 9. Testing

There is no automated test suite. Manual test checklist (executor-required):

- [ ] Window opens via FAB
- [ ] Window opens via RightShift
- [ ] Window is draggable
- [ ] Close button hides window without destroying it
- [ ] Tabs switch and the previous tab's container hides
- [ ] Toggle animates both the knob and the track color
- [ ] Slider drags smoothly and clamps to `[Min, Max]`
- [ ] Dropdown overlays the rows beneath it without clipping
- [ ] Input fires only on `FocusLost` with `EnterPressed`
- [ ] Multiple `CreateSection` calls redirect subsequent elements correctly
- [ ] Re-executing the loader doesn't duplicate the GUI

## 10. Versioning

Single-file libraries don't expose a version constant. When making breaking changes:

1. Bump the human-facing `README.md` usage example.
2. Note breaking changes in commit messages.
3. Tag releases (`v1.x.x`) so users can pin `loadstring` URLs.

Backwards-compatibility matters: existing scripts in the wild call `CreateWindow`, `CreateTab`, and the seven element builders. Don't rename or remove any of these.

## 11. What "Done" Looks Like

A change is complete when:

- The file still loads via `loadstring` without syntax errors.
- All existing example.lua usages still work.
- New elements are documented in section 4 of this file.
- No new globals were introduced.
- No hardcoded colors outside the `Theme` table.
- The file remains a single, self-contained module.
