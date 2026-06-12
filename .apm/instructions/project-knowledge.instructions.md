## Project Overview

This is a Nix flake that provides both:
1. A **Home-Manager module** for configuring Hammerspoon (macOS automation tool)
2. A **personal Hammerspoon configuration** written in pure Lua

The project structure separates the Nix packaging/module logic from the Hammerspoon Lua configuration, making it both a reusable Home-Manager module and a functional Hammerspoon setup.

## Development Commands

### Nix Development Environment
```bash
# Enter the development shell (uses direnv automatically if .envrc is sourced)
nix develop

# Manual nix develop if direnv isn't set up
nix develop --impure
```

### Checking and Building
```bash
# Run comprehensive flake checks
nix flake check --impure --all-systems --no-build

# Build the Home-Manager module
nix build

# Update flake lock file
nix flake update
```

### Formatting and Linting
```bash
# Format all code (Nix with alejandra, Lua with stylua)
nix fmt
```

## Architecture

### Nix Module Structure (`modules/home/hammerspoon.nix`)
- **Purpose**: Home-Manager module that installs and configures Hammerspoon
- **Key Features**:
  - Configurable package management (can use any Hammerspoon derivation)
  - Automatic config directory setup via `xdg.configFile`
  - Spoon installation support (3rd party Hammerspoon extensions)
  - macOS defaults integration for config file paths
- **Architecture Pattern**: Standard Home-Manager module with options, config, and enable flag

### Hammerspoon Configuration (`myCfg/`)
The Lua configuration is modular and follows this structure:

#### Core Files
- `init.lua` - Entry point, sets Font defaults and requires all modules
- `prefs.lua` - Hammerspoon preferences and system integration settings
- `binds.lua` - Global hotkey bindings and system control functions
- `vim.lua` - VimMode spoon configuration with app exclusions

#### Window Management (`WindowManager/`)
- `init.lua` - Sets up window management keybinds and requires submodules
- `window.lua` - Pure Hammerspoon window positioning (halves, quarters, maximize)
- `yabai.lua` - Yabai integration for advanced tiling and space management
- `spaces.lua` - Native Hammerspoon spaces management (alternative to yabai)

#### Key Binding Architecture
- Uses consistent keybind prefixes:
  - `TLKeys.hyper` = `{ "alt", "ctrl", "shift", "cmd" }` - System controls
  - `TLKeys.window` = `{ "alt", "ctrl", "cmd" }` - Window management
- Modular binding system where each module defines its own binds

### Flake Architecture (`flake/`)
Uses flake-parts for modular flake organization:
- `checks.nix` - Pre-commit hooks and validation
- `devshells.nix` - Development environment with LSPs and formatters
- `formatters.nix` - treefmt configuration for Nix and Lua
- `actions/` - GitHub Actions workflows as Nix expressions

## Key Dependencies and External Tools

### System Tool Integration
The configuration integrates with several system tools that must be available:
- **wezterm**: Terminal emulator launch
- **yabai**: Advanced window tiling (optional, has pure Hammerspoon fallback)
- **blueutil**: Bluetooth control
- **pmset**: Power management (Low Power Mode toggle)
- **rg/awk**: Used for system status parsing

### Hammerspoon Spoons Used
- **VimMode**: Provides vim-like navigation in any app
- **Drag**: Window dragging utilities (used in spaces.lua)

## Development Patterns

### Adding New Hammerspoon Features
1. Create new .lua file in appropriate directory (`myCfg/` or `myCfg/WindowManager/`)
2. Follow the pattern of defining functions then binding them with `Bind()`
3. Require the module in the appropriate parent init.lua
4. Use existing `TLKeys` prefixes for consistency

### Modifying the Home-Manager Module
- The module supports three configuration modes:
  - Package only: `programs.hammerspoon.package = pkgs.hammerspoon`
  - Config only: `programs.hammerspoon.configPath = ./path/to/config`
  - Full setup: Both package and config with optional spoons

### Testing Changes
- Use `nix flake check` to validate Nix code
- Test Hammerspoon config by symlinking `myCfg/` to `~/.hammerspoon/`
- The module sets up XDG config paths automatically when enabled

## Integration Notes

- This flake is designed to be used within the broader [OS-nixCfg](https://github.com/DivitMittal/OS-nixCfg) system
- Uses custom library functions from OS-nixCfg (`specialArgs.customLib`)
- The personal config (`myCfg/`) assumes macOS with specific tools installed via Nix/homebrew
- Window management has two modes: native Hammerspoon (spaces.lua) and yabai integration (yabai.lua)
