{
  common-permissions,
  common-actions,
  ...
}: {
  flake.actions-nix.workflows.".github/workflows/flake-lock-update.yml" = {
    on = {
      workflow_dispatch = {};
      schedule = [
        {
          cron = "0 0 1-7 * 0"; # First Sunday of every month at midnight
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
        common-actions
        ++ [
          {
            name = "Update flake.lock";
            uses = "DeterminateSystems/update-flake-lock@main";
          }
        ];
    };
  };
}
