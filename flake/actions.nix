{inputs, ...}: {
  imports = [inputs.actions-nix.flakeModules.default];

  flake.actions-nix = {
    pre-commit.enable = true;
    defaults = {
      jobs = {
        runs-on = "ubuntu-latest";
        timeout-minutes = 30;
      };
    };

    workflows = let
      on = {
        push = {
          branches = ["main"];
          paths-ignore = [
            "**/*.md"
            ".github/**"
          ];
        };
        pull_request = {
          branches = ["main"];
        };
        workflow_dispatch = {};
      };
      permissions = {
        contents = "write";
        id-token = "write";
      };
      common-actions = [
        {
          name = "Checkout repo";
          uses = "actions/checkout@main";
          "with" = {
            fetch-depth = 1;
          };
        }
        inputs.actions-nix.lib.steps.DeterminateSystemsNixInstallerAction
        {
          name = "Magic Nix Cache(Use GitHub Actions Cache)";
          uses = "DeterminateSystems/magic-nix-cache-action@main";
        }
      ];
    in {
      ".github/workflows/flake-check.yml" = {
        inherit on;
        jobs.checking-flake = {
          inherit permissions;
          steps =
            common-actions
            ++ [
              {
                name = "Run nix flake check";
                run = "nix flake check --impure --all-systems --no-build";
              }
            ];
        };
      };
    };
  };
}