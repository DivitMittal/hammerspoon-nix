_: {
  flake.homeManagerModules = {
    default = import ./home/hammerspoon.nix;
    hammerspoon = builtins.import ./home/hammerspoon.nix;
  };
}
