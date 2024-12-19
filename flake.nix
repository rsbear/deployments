{
  description = "walross deployments";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";
  inputs.walrossweb.url = "github:rsbear/walrossweb";

  outputs = inputs @ {flake-parts, walrossweb, ...}:
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
        name = "rossdeploys";

        caddyConfig = ''
          {
            # Global options
            admin off  # Disable admin interface for security
            persist_config off  # Don't persist config to disk since we manage it via Nix
          }

          walross.co {
            reverse_proxy localhost:8080
          }

          git.walross.co {
            respond "Git service coming soon!" 200  # Placeholder response
          }
        '';

        # Create a wrapped Caddy package with our config
        customCaddy = pkgs.writeShellScriptBin "caddy-server" ''
          mkdir -p /var/lib/caddy
          cat > /var/lib/caddy/Caddyfile <<'EOF'
          ${caddyConfig}
          EOF
          exec ${pkgs.caddy}/bin/caddy run --config /var/lib/caddy/Caddyfile
        '';
      in {
        packages = {
          walrossweb = walrossweb.packages.${system}.default;
          caddy-server = customCaddy;
        };
      };
    };
}
