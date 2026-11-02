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

      # ./<name>.sh in the checkout, exposed as planlos-<name>
      scripts = [
        "clone"
        "pull"
        "push"
        "commit"
        "testdata"
        "clear"
      ];
    in
    {
      devShells = forEachSupportedSystem (
        { pkgs }:
        {
          default = pkgs.mkShellNoCC {
            packages =
              (map (
                name:
                pkgs.writeShellScriptBin "planlos-${name}" ''
                  exec "$PLANLOS_ROOT/${name}.sh" "$@"
                ''
              ) scripts)
              ++ (with pkgs; [
                # planlos (these scripts)
                git
                shellcheck
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
