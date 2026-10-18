{ ... }:

{
  hardware.microsoft-surface-laptop-7.enable = true;
  hardware.enableRedistributableFirmware = true;

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
