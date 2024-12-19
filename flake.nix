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
        # VCL configuration for Varnish
        varnishConfig = ''
          vcl 4.0;
          
          backend default {
            .host = "127.0.0.1";
            .port = "8080";
          }
          
          sub vcl_recv {
            # Handle different domains
            if (req.http.host == "walross.co") {
              return (pass);
            }
            elsif (req.http.host == "git.walross.co") {
              # Return static response for git subdomain
              return (synth(200, "Git service coming soon!"));
            }
          }
          
          sub vcl_synth {
            if (resp.status == 200) {
              set resp.http.Content-Type = "text/plain";
              synthetic(resp.reason);
              return (deliver);
            }
          }
        '';
        
        # Create a wrapped Varnish package with our config
        customVarnish = pkgs.writeShellScriptBin "varnish-server" ''
          VARNISH_DIR="$HOME/.local/share/varnish"
          mkdir -p "$VARNISH_DIR"
          
          # Write config to the local directory
          cat > "$VARNISH_DIR/default.vcl" <<'EOF'
          ${varnishConfig}
          EOF
          
          echo "Starting Varnish with config from $VARNISH_DIR/default.vcl..."
          exec ${pkgs.varnish}/bin/varnishd \
            -F \
            -f "$VARNISH_DIR/default.vcl" \
            -a :80 \
            -s malloc,256m
        '';
      in {
        packages = {
          walrossweb = walrossweb.packages.${system}.default;
          varnish-server = customVarnish;
        };
      };
    };
}
