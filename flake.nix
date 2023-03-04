{
  inputs = { nixpkgs = { url = "github:NixOS/nixpkgs/nixos-unstable"; }; };

  outputs = inputs:
    let
      lib = inputs.nixpkgs.lib;
      supportedSystems = lib.genAttrs [ "x86_64-linux" "aarch64-linux" ];
      pkgs = supportedSystems (system: inputs.nixpkgs.legacyPackages.${system});
    in {
      packages = supportedSystems (system:
        let pkgs' = pkgs.${system};
        in {
          nixhls = pkgs'.haskell.lib.overrideCabal
            (pkgs'.haskellPackages.callCabal2nix "nixhls" ./. { })
            (drv: { librarySystemDepends = with pkgs'; [ nix ]; });
        });
    };
}
