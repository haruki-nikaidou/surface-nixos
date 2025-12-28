{
  pkgs,
  ...
}:

{
  # Linux firmware package (includes Qualcomm firmware)
  hardware.firmware = [
    pkgs.linux-firmware
  ];

  # Enable all firmware regardless of license
  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = true;

  # GPU support (Adreno 741 in Snapdragon X Elite/Plus)
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      mesa
    ];
  };

  # Power management
  powerManagement.enable = true;

  # Services that might help with hardware
  services.udev.extraRules = ''
    # Qualcomm X Elite/Plus platform devices
    SUBSYSTEM=="platform", DRIVER=="qcom-cpufreq-hw", TAG+="systemd"

    # Surface Laptop 7 specific
    ATTR{idVendor}=="045e", ATTR{idProduct}=="0c1a", MODE="0666"
  '';

  # Kernel modules to load at runtime
  boot.kernelModules = [
    # Load these after boot if available
  ];

  # Blacklist problematic modules if needed
  boot.blacklistedKernelModules = [
    # Add any modules that cause issues
  ];

  # For debugging: expose more kernel info
  boot.kernel.sysctl = {
    "kernel.printk" = "7 7 7 7";
    "kernel.panic" = 10;
    "kernel.panic_on_oops" = 1;
  };

  # Disable services not compatible with Qualcomm ARM64
  services.fwupd.enable = true;
}
