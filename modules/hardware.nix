{
  pkgs,
  ...
}:

{
  # Linux firmware package (includes some Qualcomm firmware)
  hardware.firmware = [
    pkgs.linux-firmware
  ];

  # Enable all firmware regardless of license
  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = true;

  # GPU support (Adreno in X Elite)
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
    # Qualcomm X Elite platform devices
    SUBSYSTEM=="platform", DRIVER=="qcom-cpufreq-hw", TAG+="systemd"

    # Surface Laptop 7 specific
    ATTR{idVendor}=="045e", ATTR{idProduct}=="0c1a", MODE="0666"
  '';

  # Kernel modules to load
  boot.kernelModules = [
    "qcom_q6v5_pas"
    "qcom_pil_info"
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

  # CPU frequency scaling (if cpufreq works)
  services.thermald.enable = false; # Not compatible with Qualcomm

  # Disable services that won't work on this hardware
  services.fwupd.enable = false; # No LVFS support yet for Surface ARM
}
