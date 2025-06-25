_: {
  flake.homeManagerModules = {
    default = builtins.import ./home;
    hammerspoon = builtins.import ./home/hammerspoon.nix;
  };
}