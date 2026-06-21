---
description: Personal Hammerspoon Lua config — entry point, key binding conventions, and module structure
applyTo: "myCfg/**"
---

## Entry Point

`myCfg/init.lua` is the Hammerspoon entry point. It:
- Sets global font defaults.
- `require`s every sibling module in order.

When adding a new top-level module, create `myCfg/newmodule.lua` and add `require "newmodule"` in `myCfg/init.lua`.

## Key Binding Prefixes

All hotkeys are defined using two shared modifier sets:

```lua
TLKeys.hyper  = { "alt", "ctrl", "shift", "cmd" }  -- system-level controls (Bluetooth, power, etc.)
TLKeys.window = { "alt", "ctrl", "cmd" }            -- window management
```

Always use the `Bind()` helper to register hotkeys — never call `hs.hotkey.bind` directly. This keeps binding style consistent and makes it easy to audit all registered keys.

## Top-Level Modules

| File | Purpose |
|------|---------|
| `init.lua` | Entry point — font defaults, requires all modules |
| `prefs.lua` | Hammerspoon application preferences |
| `binds.lua` | Global hotkey bindings (non-window) |
| `vim.lua` | VimMode Spoon configuration with per-app exclusion list |

## WindowManager Submodule

`WindowManager/init.lua` sets up window management keybinds and requires the submodules below. Adding a new window feature: create the file in `WindowManager/`, then `require` it from `WindowManager/init.lua`.

| File | Purpose |
|------|---------|
| `window.lua` | Pure Hammerspoon window positioning — halves, quarters, maximize. No external deps. |
| `yabai.lua` | yabai tiling WM integration for tiling layouts and space movement. Requires yabai running. |
| `spaces.lua` | Native macOS Spaces management via Hammerspoon APIs. Alternative to yabai. |

**Important:** `yabai.lua` and `spaces.lua` are parallel implementations — only one should be active at a time. Comment out or remove the `require` for whichever is not in use.

## External Tool Dependencies

The config assumes these tools are available on `$PATH`:

| Tool | Used for |
|------|---------|
| `wezterm` | Terminal launch bindings |
| `blueutil` | Bluetooth toggle |
| `pmset` | Power management controls |
| `rg` + `awk` | Status line parsing |

If a tool is absent, the binding that calls it will silently fail or error — add a guard check (`hs.execute("which <tool>")`) if robustness is needed.

## Adding a New Feature

1. Create `myCfg/newmodule.lua` (or `myCfg/WindowManager/newmodule.lua` for window features).
2. Export bindings using `TLKeys.hyper` or `TLKeys.window` with the `Bind()` helper.
3. Add `require "newmodule"` in the appropriate `init.lua`.
4. Format with `stylua` (`nix fmt`) before committing.
