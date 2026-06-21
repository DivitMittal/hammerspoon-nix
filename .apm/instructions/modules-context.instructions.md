---
description: Home-manager module for Hammerspoon — options, structure, and integration patterns
applyTo: "modules/**"
---

## Module Overview

`modules/home/hammerspoon.nix` is the home-manager module that installs and configures Hammerspoon on macOS.

It receives `specialArgs.customLib` from the consuming flake (provided by OS-nixCfg) — use that for any shared utility functions rather than reimplementing them locally.

## Declared Options

| Option | Type | Purpose |
|--------|------|---------|
| `programs.hammerspoon.package` | package | Any Hammerspoon derivation to install |
| `programs.hammerspoon.configPath` | path | Path to the Lua config directory (e.g. `myCfg/`) |
| `programs.hammerspoon.spoons` | list of paths | Spoon extensions to install alongside the config |

## What the Module Does

- Maps `configPath` into `xdg.configFile` so home-manager symlinks it into place.
- Writes macOS `defaults` to point Hammerspoon at the configured config path.
- Installs any listed `spoons` via additional `xdg.configFile` entries.

## Usage Modes

The module supports three activation modes — all are valid:

1. **Package only** — install Hammerspoon without managing config.
2. **Config only** — manage config/spoons without controlling the package (useful when Hammerspoon is installed via another channel).
3. **Both** — install the package and wire up the config, optionally with spoons.

## Conventions

- Keep option declarations clearly separated from the `config` block.
- Guard config/spoon wiring behind `mkIf` conditions so unused modes stay inert.
- Do not hardcode paths — derive them from `configPath` so the module stays reusable.
- Format with `nix fmt` (alejandra) before committing any changes here.
