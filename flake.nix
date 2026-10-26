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
            packages = with pkgs; [
              # planlos (these scripts)
              git
              shellcheck
              # planlos-server
              go_1_25 # keep in sync with planlos-server/go.mod
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
            ];
          };
        }
      );
    };
}
