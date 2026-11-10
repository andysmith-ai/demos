{
  description = "Hands-on deployments of software tools";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      devShells = forAllSystems (pkgs: {
        exoharness = import ./exoharness/shell.nix { inherit pkgs; };
      });

      templates.exoharness = {
        path = ./exoharness/template;
        description = "Exo lab: agents, environments and one Exo instance in .exo/";
      };

      formatter = forAllSystems (pkgs: pkgs.nixfmt-rfc-style);
    };
}
