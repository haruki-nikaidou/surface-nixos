{
  lib,
  pkgs,
  ...
}:

let
  inherit (lib.kernel) yes module;

  # Use latest kernel - 6.18+ has Surface Laptop 7 (Denali) support
  linuxPackage = pkgs.linuxPackages_latest;

  # Minimal kernel config for Snapdragon X Plus (x1p64100) - Surface Laptop 7
  # Only add Qualcomm-specific options; let NixOS handle common options
  kernelConfigOverrides = {
    # Core Qualcomm Platform
    ARM64 = yes;
    ARCH_QCOM = yes;
    QCOM_SCM = yes;
    QCOM_SMEM = yes;
    QCOM_SOCINFO = yes;
    ARM_SMMU = yes;
    ARM_SMMU_V3 = yes;
    IOMMU_IO_PGTABLE_ARMV7S = yes;
    QCOM_RPMH = yes;
    QCOM_COMMAND_DB = yes;
    QCOM_PDC = yes;

    # Clock
    COMMON_CLK_QCOM = yes;
    QCOM_CLK_RPMH = yes;

    # Interconnect
    INTERCONNECT_QCOM = yes;

    # Pin control
    PINCTRL_QCOM_SPMI_PMIC = yes;
    PINCTRL_MSM = yes;

    # Regulators
    REGULATOR_QCOM_SPMI = yes;
    REGULATOR_QCOM_RPMH = yes;

    # Power
    ARM_QCOM_CPUFREQ_HW = yes;
    QCOM_TSENS = yes;
    THERMAL = yes;

    # Storage
    PCIE_QCOM = yes;
    BLK_DEV_NVME = yes;
    NVME_CORE = yes;
    NVME_AUTH = lib.mkForce yes;

    # USB
    USB_DWC3 = module;
    USB_DWC3_QCOM = module;
    TYPEC = module;
    TYPEC_UCSI = module;
    UCSI_PMIC_GLINK = module;

    # I2C/SPI (for peripherals)
    I2C_QCOM_GENI = yes;
    SPI_QCOM_GENI = yes;

    # SPMI (for PMIC)
    SPMI = yes;

    # WiFi (ath12k)
    WLAN = yes;
    ATH12K = module;

    # NPU (Hexagon)
    QCOM_FASTRPC = yes;
    REMOTEPROC = yes;

    # Audio
    SND_SOC_QDSP6 = module;
    SND_SOC_QDSP6_APM = module;
    SND_SOC_QDSP6_COMMON = module;

    # Input devices
    HID_MULTITOUCH = module;
    I2C_HID_CORE = module;
    I2C_HID_ACPI = module;

    # Device Tree
    OF = yes;
    OF_FLATTREE = yes;
    OF_EARLY_FLATTREE = yes;

    # EFI Boot
    EFI = yes;
    EFI_STUB = yes;

    STAGING_MEDIA = yes;
    APDS9960 = module;
  };

in
{
  boot.kernelPackages = linuxPackage;

  # Apply kernel config overrides
  boot.kernelPatches = [
    {
      name = "surface-laptop7-x1p64100";
      patch = ../surface.patch;
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
