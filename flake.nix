{
  description = "ntfsplus: High-performance NTFS kernel driver and utilities";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    linux-ntfs = {
      url = "github:namjaejeon/linux-ntfs";
      flake = false;
    };
  };
  outputs = { self, nixpkgs, linux-ntfs }: {
    nixosModules.default = { config, pkgs, lib, ... }:
      let
        cfg = config.services.ntfsplus;
        kernel = config.boot.kernelPackages.kernel;
        
        ntfsplus-mod = pkgs.stdenv.mkDerivation {
          pname = "ntfsplus-module";
          version = linux-ntfs.shortRev or linux-ntfs.rev;
          src = linux-ntfs;
          nativeBuildInputs = kernel.moduleBuildDependencies;
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
          boot.extraModulePackages = [ ntfsplus-mod ];
          boot.kernelModules = [ "ntfs" ];
          boot.extraModprobeConfig = ''
            alias fs-ntfs ntfs
            alias ntfsplus ntfs
          '';
          services.udev.extraRules = ''
            SUBSYSTEM=="block", ENV{ID_FS_TYPE}=="ntfs", ENV{ID_FS_TYPE}="ntfs"
          '';
          environment.systemPackages = [ pkgs.ntfsprogs-plus ];
        };
      };
  };
}
