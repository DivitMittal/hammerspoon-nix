---
description: Nix flake support files — formatters, checks, devshells, and CI actions
applyTo: "flake/**"
---

## Flake Directory Overview

`flake.nix` auto-imports every `.nix` file under `flake/` via `customLib.scanPaths`. No explicit import list is maintained — dropping a new `.nix` file here is sufficient to include it.

## Files

- `formatters.nix` — treefmt configuration: **alejandra** for Nix files, **stylua** for Lua files.
- `checks.nix` — pre-commit hook definitions (whitespace trimming, large-file guard, merge-conflict detection, etc.).
- `devshells.nix` — developer shell providing: `nixd`, `alejandra`, `stylua`, `apm-cli`.
- `actions/` — GitHub Actions workflow definitions via **actions-nix**. These generate `.github/workflows/` files at build time. **Never edit `.github/workflows/` directly** — edit the source in `actions/` instead.

## Conventions

- Run `nix fmt` before every commit to apply alejandra and stylua formatting.
- Run `nix flake check` to validate all checks pass before opening a PR.
- When adding a new formatter or hook, add it in the appropriate file (`formatters.nix` or `checks.nix`) — not inline in `flake.nix`.
- CI workflow changes must go through `actions/`; the generated YAML is an output artifact, not a source of truth.
