{
  description = "Exo lab: agents as code and one Exo instance in .exo/";

  inputs.demos.url = "github:andysmith-ai/demos/exoharness-demo";

  outputs =
    { demos, ... }:
    {
      devShells = builtins.mapAttrs (_: shells: { default = shells.exoharness; }) demos.devShells;
    };
}
