{
  lib,
  pkgs,
  ...
}:

let
  inherit (lib.kernel) yes module;

  # Use latest kernel - 6.18+ has Surface Laptop 7 (Romulus) support
  linuxPackage = pkgs.linuxPackages_latest;

  # Minimal kernel config for Snapdragon X Plus (X1E80100) - Surface Laptop 7
  # Only add Qualcomm-specific options; let NixOS handle common options
  kernelConfigOverrides = {
    # === Core Qualcomm Platform ===
    ARCH_QCOM = yes;

    # === Qualcomm SoC Infrastructure ===
    QCOM_SCM = yes;
    QCOM_COMMAND_DB = yes;
    QCOM_PDC = yes;
    QCOM_RPMH = yes;

    # === Clock Framework ===
    COMMON_CLK_QCOM = yes;
    QCOM_CLK_RPMH = yes;

    # === Interconnect ===
    INTERCONNECT_QCOM = yes;

    # === PCIe (required for NVMe) ===
    PCIE_QCOM = yes;

    # === USB ===
    USB_DWC3 = module;
    USB_DWC3_QCOM = module;

    # === I2C/SPI (for peripherals) ===
    I2C_QCOM_GENI = yes;
    SPI_QCOM_GENI = yes;

    # === SPMI (for PMIC) ===
    SPMI = yes;

    # === Regulators ===
    REGULATOR_QCOM_RPMH = yes;

    # === GPU (Adreno) ===
    DRM_MSM = module;

    # === WiFi (ath12k) ===
    ATH12K = module;

    # === Input devices ===
    HID_MULTITOUCH = module;
    I2C_HID_CORE = module;
    I2C_HID_ACPI = module;

    # === Device Tree ===
    OF = yes;

    # === EFI Boot ===
    EFI = yes;
    EFI_STUB = yes;
  };

in
{
  boot.kernelPackages = linuxPackage;

  # Apply kernel config overrides
  boot.kernelPatches = [
    {
      name = "surface-laptop7-x1e80100";
      patch = null;
      structuredExtraConfig = kernelConfigOverrides;
      # Ignore config validation errors for options with dependencies we can't control
      ignoreConfigErrors = true;
    }
  ];

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

  # Enable device tree - Surface Laptop 7 uses x1e80100-microsoft-romulus13.dtb
  hardware.deviceTree = {
    enable = true;
    filter = "qcom/*.dtb";
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
