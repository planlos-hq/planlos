{
  description = "PlanLos: one dev shell with the tools of all repos";

  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1"; # unstable Nixpkgs

  outputs =
    { self, ... }@inputs:

    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forEachSupportedSystem =
        f:
        inputs.nixpkgs.lib.genAttrs supportedSystems (
          system:
          f {
            pkgs = import inputs.nixpkgs { inherit system; };
          }
        );
    in
    {
      devShells = forEachSupportedSystem (
        { pkgs }:
        {
          default = pkgs.mkShellNoCC {
            packages = [
              # planlos CLI: build from the checkout, then run
              (pkgs.writeShellScriptBin "planlos" ''
                set -e
                ${pkgs.go}/bin/go build -C "$PLANLOS_ROOT" -o "$PLANLOS_ROOT/.bin/planlos" .
                exec "$PLANLOS_ROOT/.bin/planlos" "$@"
              '')
            ]
            ++ (with pkgs; [
              # planlos (these scripts)
              git
              shellcheck
              gcc
              cobra-cli
              # planlos-server
              go # must satisfy the `go` directive in planlos-server/go.mod
              gotools
              golangci-lint
              # planlos-db
              pgformatter
              postgresql
              # planlos-web
              nodejs_22
              nixfmt
              # planlos-openapi
              jdk_headless
              uv
              # planlos-docs
              zensical
              (python3.withPackages (ps: [ ps.pyyaml ]))
            ]);

            shellHook = ''
              export PLANLOS_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
            '';
          };
        }
      );
    };
}
