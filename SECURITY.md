# Security Policy

## Scope

This repo contains a Nix home-manager module and a personal Lua Hammerspoon configuration for macOS. It has no servers, no network services, and no credentials. The attack surface is limited to:

- **Lua scripts** executed by Hammerspoon with full macOS accessibility and automation permissions
- **Nix derivations** that install files into the user's home directory

## Reporting a Vulnerability

If you find a security issue (e.g. a Lua snippet that could be abused by a malicious config consumer, or a module option that expands to unsafe shell code):

1. Open a **GitHub issue** with the label `security`.
2. Include a description, reproduction steps, and impact assessment.

## What to Report

| In scope | Out of scope |
|----------|--------------|
| Unsafe shell expansion in Nix module options | Issues in upstream Hammerspoon or nixpkgs |
| Lua code that leaks data or escalates privileges when sourced | General macOS accessibility permission concerns |
| Module options that write world-readable sensitive files | Feature requests |


## Supported Versions

Only the latest commit on `main` is supported.
