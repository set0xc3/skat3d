{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    devShells.${system}.default = pkgs.mkShell {
      LD_LIBRARY_PATH = "$LD_LIBRARY_PATH:${
        pkgs.lib.makeLibraryPath [
          pkgs.vulkan-extension-layer
          pkgs.vulkan-validation-layers
          pkgs.vulkan-utility-libraries
          pkgs.vulkan-headers
          pkgs.vulkan-loader
          pkgs.vulkan-tools
          pkgs.vulkan-tools-lunarg
          pkgs.glslang
          pkgs.shaderc

          pkgs.odin

          pkgs.SDL2
          pkgs.libGL

          pkgs.xorg.libX11
        ]
      }";

      buildInputs = [
        pkgs.renderdoc
        pkgs.gpu-viewer

        pkgs.vulkan-extension-layer
        pkgs.vulkan-validation-layers
        pkgs.vulkan-utility-libraries
        pkgs.vulkan-headers
        pkgs.vulkan-loader
        pkgs.vulkan-tools
        pkgs.vulkan-tools-lunarg
        pkgs.glslang
        pkgs.shaderc

        pkgs.odin

        pkgs.SDL2
        pkgs.libGL

        pkgs.xorg.libX11
      ];

      # shellHook = ''
      #   exec $SHELL
      # '';
    };
  };
}
