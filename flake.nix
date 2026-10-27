{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs =
    {
      self,
      flake-utils,
      nixpkgs,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        scip-rust = pkgs.writeShellApplication {
          name = "scip-rust";
          runtimeEnv = {
            SCIP_RUST_FALLBACK_CARGO = "${pkgs.cargo}/bin";
            SCIP_RUST_FALLBACK_RUSTC = "${pkgs.rustc}/bin";
            SCIP_RUST_FALLBACK_RUST_ANALYZER = "${pkgs.rust-analyzer}/bin";
          };
          text = builtins.readFile ./scip-rust;
        };
        # Distrust the roots behind the compromised eMudhra intermediate CAs
        # (https://emudhra.we-have-a-problem.com/). The pinned cacert (3.123)
        # already distrusts Comodo AAA Services root for TLS; it is listed as
        # defence in depth. cacert 3.131.1 drops emSign ECC Root CA - G3, so
        # this override fails the build after a nixpkgs bump to it; remove it
        # then.
        dockerTools = pkgs.dockerTools.override {
          cacert = pkgs.cacert.override {
            blacklist = [
              "Comodo AAA Services root"
              "emSign ECC Root CA - G3"
            ];
          };
        };
        # Provides /bin/sh for callers that run commands in the container
        # through a shell. wget and ssl_client are left out: BusyBox does
        # not verify TLS certificates.
        busybox = pkgs.busybox.override {
          extraConfig = ''
            CONFIG_WGET n
            CONFIG_SSL_CLIENT n
          '';
        };
      in
      {
        packages = {
          inherit scip-rust;
          default = scip-rust;
        }
        // pkgs.lib.optionalAttrs pkgs.stdenv.isLinux {
          docker = dockerTools.buildLayeredImage {
            name = "scip-rust";
            tag = "latest";
            contents = [
              scip-rust
              busybox
              dockerTools.caCertificates
              pkgs.git
            ];
            fakeRootCommands = "mkdir -p /work /tmp";
            enableFakechroot = true;
            config = {
              Cmd = [ "scip-rust" ];
              WorkingDir = "/work";
              Env = [ "HOME=/tmp" ];
              Labels = {
                "org.opencontainers.image.source" = "https://github.com/scip-code/scip-rust";
              };
            };
          };
        };

        checks = {
          shellcheck = pkgs.runCommand "check-shellcheck" { } ''
            ${pkgs.shellcheck}/bin/shellcheck ${./scip-rust}
            touch $out
          '';
          formatting = pkgs.runCommand "check-formatting" { } ''
            ${pkgs.nixfmt}/bin/nixfmt --check ${./flake.nix}
            ${pkgs.shfmt}/bin/shfmt -i 4 -ci -d ${./scip-rust}
            touch $out
          '';
          renovate = pkgs.runCommand "check-renovate" { } ''
            LOG_LEVEL=warn ${pkgs.renovate}/bin/renovate-config-validator \
              ${./.github/renovate.json}
            touch $out
          '';
        };

        devShells.default = pkgs.mkShellNoCC {
          buildInputs = with pkgs; [
            cargo
            nixfmt
            rust-analyzer
            rustc
            shellcheck
            shfmt
          ];
        };
      }
    );
}
