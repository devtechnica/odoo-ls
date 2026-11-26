{
  lib,
  rustPlatform,
  writeShellScript,
  typeshed,
}:

let
  cargoToml = lib.importTOML ./server/Cargo.toml;
in
rustPlatform.buildRustPackage {
  pname = "odoo-ls";
  inherit (cargoToml.package) version;

  src = lib.fileset.toSource {
    root = ./server;
    fileset = lib.fileset.unions [
      ./server/Cargo.toml
      ./server/Cargo.lock
      ./server/src
      ./server/macros
      ./server/benches
    ];
  };

  cargoLock = {
    lockFile = ./server/Cargo.lock;
    allowBuiltinFetchGit = true;
  };

  cargoBuildFlags = [ "--bin" "odoo_ls_server" ];

  doCheck = false;

  postInstall =
    let
      wrapper = writeShellScript "odoo_ls_server" ''
        for arg in "$@"; do
          case "$arg" in
            --logs-directory|--logs-directory=*) exec "@out@/libexec/odoo-ls/odoo_ls_server" "$@" ;;
          esac
        done
        logs="''${XDG_STATE_HOME:-$HOME/.local/state}/odoo-ls/logs"
        mkdir -p "$logs"
        exec "@out@/libexec/odoo-ls/odoo_ls_server" --logs-directory "$logs" "$@"
      '';
    in
    ''
      mkdir -p $out/libexec/odoo-ls
      mv $out/bin/odoo_ls_server $out/libexec/odoo-ls/
      mkdir -p $out/libexec/odoo-ls/typeshed
      cp -r ${typeshed}/stdlib ${typeshed}/stubs $out/libexec/odoo-ls/typeshed/
      cp -r ${./server/additional_stubs} $out/libexec/odoo-ls/additional_stubs
      substitute ${wrapper} $out/bin/odoo_ls_server --subst-var out
      chmod +x $out/bin/odoo_ls_server
    '';

  meta = {
    description = "Language server for the Odoo framework";
    homepage = "https://github.com/odoo/odoo-ls";
    license = lib.licenses.lgpl3Only;
    mainProgram = "odoo_ls_server";
    platforms = lib.platforms.unix;
  };
}
