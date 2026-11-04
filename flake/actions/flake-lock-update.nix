{
  lib,
  common-permissions,
  common-actions,
  ...
}: let
  # Cron ORs day-of-month and day-of-week when both are set, so "first Sunday"
  # can't be expressed directly: fire on days 1-7 and let this gate pick Sunday.
  gate = {
    name = "Gate to first Sunday of the month";
    id = "gate";
    run = ''
      if [ "$GITHUB_EVENT_NAME" != schedule ] || [ "$(date -u +%u)" = 7 ]; then
        echo "run=true" >> "$GITHUB_OUTPUT"
      else
        echo "run=false" >> "$GITHUB_OUTPUT"
      fi
    '';
  };
  gated = step: step // {"if" = "steps.gate.outputs.run == 'true'";};
in {
  flake.actions-nix.workflows.".github/workflows/flake-lock-update.yml" = {
    on = {
      workflow_dispatch = {};
      schedule = [
        {
          cron = "0 0 1-7 * *"; # Days 1-7; the gate step keeps only Sunday
        }
      ];
    };
    jobs.locking-flake = {
      permissions =
        common-permissions
        // {
          issues = "write";
          pull-requests = "write";
        };
      steps =
        [gate]
        ++ lib.map gated (common-actions
          ++ [
            {
              name = "Update flake.lock";
              uses = "DeterminateSystems/update-flake-lock@main";
            }
          ]);
    };
  };
}
