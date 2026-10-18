{ inputs, ... }:

let
  # Only the kernel is cross-compiled on an x86_64 machine; everything else
  # stays native aarch64 and comes from the binary cache. Build the system on
  # an x86_64 host with aarch64 binfmt and copy it over (see ../../README.md).
  # Rebuilding on the laptop itself works only while the resulting kernel is
  # already in its store.
  pkgsCross = import inputs.nixpkgs {
    localSystem.system = "x86_64-linux";
    crossSystem.system = "aarch64-linux";
  };
in
{
  hardware.microsoft-surface-laptop-7.enable = true;
  hardware.enableRedistributableFirmware = true;

  # boot.kernelPatches (the SL7 ath12k fix) is still applied on top.
  boot.kernelPackages = pkgsCross.linuxPackages_latest;

  boot.loader.systemd-boot = {
    enable = true;
    # Keep the 1 GiB ESP from filling up with kernels.
    configurationLimit = 5;
  };

  boot.initrd.systemd = {
    enable = true;
    # Not secure, but makes diagnosing early-boot failures possible.
    emergencyAccess = true;
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/b7a72ed7-2dc1-43a2-9d17-f1d4d7fe830b";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/F03E-EC14";
      fsType = "vfat";
      options = [ "umask=0077" ];
    };
  };

  # Enable some SysRq keys (80 = sync + process kill)
  # See: https://docs.kernel.org/admin-guide/sysrq.html
  boot.kernel.sysctl."kernel.sysrq" = 80;
}
