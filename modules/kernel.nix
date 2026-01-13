{ pkgs, ... }:
{
  boot.kernelPackages = pkgs.linuxPackages_testing;
  # Critical boot parameters for Snapdragon X Elite/Plus
  boot.kernelParams = [
    # Don't disable unused clocks/power domains during boot
    "clk_ignore_unused"
    "pd_ignore_unused"
    # Disable pointer authentication (can cause issues)
    "arm64.nopauth"
    # Verbose logging for debugging
    "loglevel=7"
    "earlyprintk=efi"
  ];

  # Enable device tree - Surface Laptop 7 uses x1p64100-microsoft-denali.dtb
  hardware.deviceTree = {
    enable = true;
  };

  # Modules needed in initrd for boot
  boot.initrd.includeDefaultModules = true;
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "xhci_hcd"
    "usb_storage"
    "uas"
    "usbhid"
    "hid_generic"
    "hid_multitouch"
  ];

  # Modules to load at boot
  boot.kernelModules = [
    "nvme"
  ];
}
