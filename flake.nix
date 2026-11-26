{
  description = "Odoo Language Server (odoo_ls_server)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    typeshed = {
      url = "github:python/typeshed/80fd73de22748b0fa97d9cc414c0ba854bd6901e";
      flake = false;
    };
  };

  outputs =
    { self, nixpkgs, typeshed }:
    let
      inherit (nixpkgs) lib;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = f: lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs: rec {
        odoo-ls = pkgs.callPackage ./package.nix { inherit typeshed; };
        default = odoo-ls;
      });

      overlays.default = final: _prev: {
        odoo-ls = final.callPackage ./package.nix { inherit typeshed; };
      };

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            cargo
            rustc
            clippy
            rustfmt
          ];
        };
      });
    };
}
