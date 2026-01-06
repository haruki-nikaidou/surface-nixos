{
  lib,
  pkgs,
  ...
}:

let
  inherit (lib.kernel) yes module;

  # Use latest kernel - 6.18+ has Surface Laptop 7 (Romulus) support
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

    # GPU (Adreno)
    DRM = yes;
    DRM_MSM_DPU = yes;
    DRM_MSM_DSI = yes;
    DRM_MSM_MDSS = yes;

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
      name = "arm64: dts: qcom: Add support for X1-based Surface Pro 11";
      patch = pkgs.fetchpatch {
        url = "https://lore.kernel.org/all/qptvyecgevfbknaepnyplv2543wojt2cgj26kdsaaytnt6r3rk@kko2bjurdbyp/raw";
        sha256 = "15wwrazy9l2i293yxfhq88kzvj7ypx309y11v85xryfxaqqhardd";
      };
    }
    {
      name = "surface-laptop7-x1p64100";
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

  # Enable device tree - Surface Laptop 7 uses x1p64100-microsoft-romulus13.dtb
  hardware.deviceTree = {
    enable = false;
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
