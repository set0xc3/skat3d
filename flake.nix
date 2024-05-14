{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = {nixpkgs, ...}: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    devShells.${system}.default = pkgs.mkShell {
      LD_LIBRARY_PATH = "$LD_LIBRARY_PATH:${
        pkgs.lib.makeLibraryPath [
        ]
      }";

      buildInputs = with pkgs; [
        odin
        SDL2
        libGL
        xorg.libX11
      ];
    };
  };
}
