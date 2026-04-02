{inputs, ...}: {
  flake.homeManagerModules = {
    ## Default Modules for all home-manager modules
    default = inputs.import-tree ./home;

    ## Individual Modules
    hammerspoon = import ./home/hammerspoon.nix;
  };
}
