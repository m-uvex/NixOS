{ pkgs, lib, ... }:

{
  imports = [
    ../server.nix
    ./filesystem.nix
    ./users.nix
    ./restic-server.nix
    ./stacks/default.nix
  ];
}
