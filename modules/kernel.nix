{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib.kernel) yes module freeform;

  # Use latest kernel - 6.18+ should have Surface Laptop 7 DTB
  linuxPackage = pkgs.linuxPackages_latest;

  # Kernel config overrides to ensure Qualcomm support
  kernelConfigOverrides = {
    # Qualcomm platform support
    ARCH_QCOM = yes;

    # Snapdragon X Elite (X1E80100) specific
    ARM_QCOM_CPUFREQ_HW = yes;
    QCOM_CPUCP = yes;

    # Power management
    QCOM_PDC = yes;
    QCOM_RPMH = yes;
    QCOM_RPMHPD = yes;
    QCOM_RPMPD = yes;

    # Clock controllers
    COMMON_CLK_QCOM = yes;
    CLK_X1E80100_GCC = yes;

    # Interconnect
    INTERCONNECT_QCOM = yes;
    INTERCONNECT_QCOM_X1E80100 = yes;

    # GPU (Adreno)
    DRM_MSM = yes;

    # PCIe
    PCIE_QCOM = yes;

    # USB
    USB_DWC3 = yes;
    USB_DWC3_QCOM = yes;
    PHY_QCOM_QMP = yes;
    PHY_QCOM_SNPS_EUSB2 = yes;

    # NVMe
    NVME_CORE = yes;
    BLK_DEV_NVME = yes;

    # I2C/SPI for peripherals
    I2C_QCOM_GENI = yes;
    SPI_QCOM_GENI = yes;

    # WiFi (ath12k for Qualcomm WiFi 7)
    ATH12K = module;
    ATH12K_PCI = module;

    # Pinctrl
    PINCTRL_QCOM_SPMI_PMIC = yes;
    PINCTRL_X1E80100 = yes;

    # RTC
    RTC_DRV_PM8XXX = yes;

    # Ensure DTBs are built
    BUILD_ARM64_DT_OVERLAY = yes;
  };

in
{
  boot.kernelPackages = linuxPackage;

  # Apply kernel config overrides
  boot.kernelPatches = [
    {
      name = "qcom-x1e-support";
      patch = null;
      structuredExtraConfig = kernelConfigOverrides;
    }
  ];

  # Critical boot parameters for X Elite
  boot.kernelParams = [
    "clk_ignore_unused"
    "pd_ignore_unused"
    "arm64.nopauth"
    "loglevel=7"
    "earlyprintk=efi"
  ];

  # Enable device tree
  hardware.deviceTree = {
    enable = true;
    # Filter to only include Qualcomm DTBs (reduces ISO size)
    filter = "qcom/*.dtb";
  };

  # Make sure firmware loading works
  boot.initrd.includeDefaultModules = true;
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "usb_storage"
    "uas"
    "usbhid"
    "hid_generic"
  ];
}
