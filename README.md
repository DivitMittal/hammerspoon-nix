<h1 align='center'>hammerspoon-nix</h1>
<div align='center'>
    <p></p>
    <div align='center'>
        <a href='https://github.com/DivitMittal/hammerspoon-nix'>
            <img src='https://img.shields.io/github/repo-size/DivitMittal/hammerspoon-nix?&style=for-the-badge&logo=github'>
        </a>
        <a href='https://github.com/DivitMittal/hammerspoon-nix/blob/main/LICENSE'>
            <img src='https://img.shields.io/static/v1.svg?style=for-the-badge&label=License&message=MIT&logo=unlicense'/>
        </a>
    </div>
    <br>
</div>

---

<div align='center'>
    <img src="https://github.com/DivitMittal/hammerspoon-nix/actions/workflows/flake-check.yml/badge.svg" alt="nix-flake-check"/> <img src="https://github.com/DivitMittal/hammerspoon-nix/actions/workflows/flake-lock-update.yml/badge.svg" alt="Update flake.lock"/>
</div>

---

A Nix [home-manager](github.com/nix-community/home-manager) module for [hammerspoon](https://github.com/Hammerspoon/hammerspoon/) & my personal pure lua hammerspoon configuration for [OS-nixCfg](https://github.com/DivitMittal/OS-nixCfg).

## Usage with Home Manager

To use the Hammerspoon Home-Manager module, follow these steps:

### 1. Add Flake Input

First, add this repository as an input to your `flake.nix`:

```nix
{
  inputs = {
    # ... other inputs
    hammerspoon-nix.url = "github:DivitMittal/hammerspoon-nix";
  };

  outputs = { self, nixpkgs, home-manager, ... } @ inputs: {
    # ...
  };
}
```

### 2. Configure the Module

Then, enable and configure the `programs.hammerspoon` module in your `home.nix` or a similar Home-Manager configuration file.

```nix
{ config,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ## ... other imports
    inputs.hammerspoon-nix.homeManagerModules.hammerspoon
  ];

  programs.hammerspoon = {
    enable = true; # enable the Hammerspoon module

    ## Optional: Hammerspoon package
    package = pkgs.brewCasks.hammerspoon; # using brew-nix for nix derivation translation from homebrew api

    ## Optional: Path to your Hammerspoon configuration (init.lua or a directory)
    configPath = ./path/to/your/hammerspoon/config;

    # Optional: Install Hammerspoon Spoons
    spoons = {
      "MySpoon" = pkgs.fetchFromGitHub {
        owner = "username";
        repo = "MySpoon";
        rev = "commit-hash";
        sha256 = "sha256-hash";
      };
      "AnotherSpoon" = ./path/to/another/spoon.spoon;
    };
  };

  ## ... other home-manager configurations
}
```

#### Configuration Options:

- `programs.hammerspoon.enable`: (Boolean) Enables the Hammerspoon Home-Manager module. Set to `true` to activate.
- `programs.hammerspoon.package`: (Package or `null`) Specifies the Hammerspoon package to use. Defaults to `null`, which means Home-Manager will not manage the Hammerspoon application itself, only its configuration. You can set this to `pkgs.brewCasks.hammerspoon` or a custom build.
- `programs.hammerspoon.configPath`: (Path or `null`) Defines the path to your Hammerspoon configuration. This can be a single `init.lua` file or a directory containing your configuration files. If a directory, its contents will be copied.
- `programs.hammerspoon.spoons`: (Attribute set of Paths) An attribute set where keys are the desired spoon names (e.g., "ReloadConfiguration") and values are paths to the spoon directories (e.g., `pkgs.fetchFromGitHub { ... }` or `./path/to/spoon.spoon`). These spoons will be installed into the `Spoons/` subdirectory of your Hammerspoon configuration.