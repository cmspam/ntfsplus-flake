{
  description = "ntfsplus: High-performance NTFS kernel driver and utilities";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    nixosModules.default = { config, pkgs, lib, ... }:
      let
        cfg = config.services.ntfsplus;
        kernel = config.boot.kernelPackages.kernel;
        
        # 1. THE KERNEL MODULE DERIVATION
        ntfsplus-mod = pkgs.stdenv.mkDerivation {
          pname = "ntfsplus-module";
          version = "2026.03.03";

          src = pkgs.fetchFromGitHub {
            owner = "namjaejeon";
            repo = "linux-ntfs";
            rev = "6f6beff";
            hash = "sha256-7NmpG6a8PuY3p/vCtbKNXk/+Ys6t1qLTj9HHp413HLY=";
          };

          nativeBuildInputs = kernel.moduleBuildDependencies;

          # We pull the Makefile from the local 'files' folder
          preBuild = ''
            cp ${./Makefile} Makefile
          '';

          makeFlags = [
            "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
            "KVERSION=${kernel.modDirVersion}"
            "CONFIG_NTFS_FS_POSIX_ACL=y"
          ];

          installPhase = ''
            mkdir -p $out/lib/modules/${kernel.modDirVersion}/extra
            cp ntfs.ko $out/lib/modules/${kernel.modDirVersion}/extra/
          '';
        };
      in
      {
        options.services.ntfsplus = {
          enable = lib.mkEnableOption "ntfsplus kernel driver and utilities";
        };

        config = lib.mkIf cfg.enable {
          # Register the kernel module
          boot.extraModulePackages = [ ntfsplus-mod ];
          
          # Load the driver and set up aliases
          boot.kernelModules = [ "ntfs" ];
          boot.extraModprobeConfig = ''
            alias fs-ntfs ntfs
            alias ntfsplus ntfs
          '';

          # Ensure udev treats it correctly
          services.udev.extraRules = ''
            SUBSYSTEM=="block", ENV{ID_FS_TYPE}=="ntfs", ENV{ID_FS_TYPE}="ntfs"
          '';

          # Use the official utilities from nixpkgs
          environment.systemPackages = [ pkgs.ntfsprogs-plus ];
        };
      };
  };
}
