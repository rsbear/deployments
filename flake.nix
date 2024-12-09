{
  description = "Example kickstart Go module project.";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.nixtea.url = "github:rsbear/nixtea";

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];

      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        system,
        ...
      }: let
        name = "example";
        version = "latest";
        vendorHash = null; # update whenever go.mod changes
      in {
        packages = {
          nixtea = inputs'.nixtea.packages.${system}.default;

        };
      };
    };
}
