{
  lib,
  pkgs,
  ...
}:

let
  inherit (lib.kernel) yes no module;

  # Use latest kernel - 6.18+ has Surface Laptop 7 (Romulus) support
  linuxPackage = pkgs.linuxPackages_latest;

  # Kernel config for Snapdragon X Plus (X1E80100) - Surface Laptop 7
  # Only include options that exist in mainline 6.18+
  kernelConfigOverrides = {
    # === ARM64 Platform ===
    ARCH_QCOM = yes;

    # === Qualcomm SoC Core Support ===
    QCOM_SCM = yes;
    QCOM_COMMAND_DB = yes;
    QCOM_PDC = yes;
    QCOM_RPMH = yes;
    QCOM_RPMHPD = yes;

    # === Clock Controllers ===
    COMMON_CLK_QCOM = yes;
    QCOM_CLK_RPMH = yes;

    # === CPU Frequency Scaling ===
    ARM_QCOM_CPUFREQ_HW = yes;

    # === Power Domains ===
    QCOM_AOSS_QMP = yes;

    # === Interconnect ===
    INTERCONNECT_QCOM = yes;

    # === PCIe (for NVMe, WiFi) ===
    PCIE_QCOM = yes;

    # === NVMe Storage ===
    NVME_CORE = yes;
    BLK_DEV_NVME = yes;

    # === USB Support ===
    USB_DWC3 = module;
    USB_DWC3_QCOM = module;
    PHY_QCOM_QMP_USB = yes;
    TYPEC = yes;
    TYPEC_UCSI = yes;

    # === I2C/SPI for peripherals ===
    I2C_QCOM_GENI = yes;
    SPI_QCOM_GENI = yes;

    # === GPIO/Pinctrl ===
    PINCTRL_QCOM_SPMI_PMIC = yes;
    PINCTRL_MSM = yes;

    # === SPMI (for PMIC) ===
    SPMI = yes;
    SPMI_MSM_PMIC_ARB = yes;

    # === Regulators ===
    REGULATOR_QCOM_RPMH = yes;
    REGULATOR_QCOM_SPMI = yes;

    # === GPU (Adreno 741 in X Elite/Plus) ===
    DRM_MSM = module;
    DRM_MSM_GPU_STATE = yes;

    # === WiFi (ath12k for Qualcomm WiFi 7) ===
    ATH12K = module;
    # Note: ATH12K_PCI is selected automatically when ATH12K is enabled

    # === Bluetooth ===
    BT_HCIUART = module;
    BT_HCIUART_QCA = yes;

    # === RTC ===
    RTC_DRV_PM8XXX = yes;

    # === Firmware loading ===
    FW_LOADER = yes;
    FW_LOADER_USER_HELPER = no;
    FW_LOADER_COMPRESS = yes;

    # === Remoteproc (for DSP/modem) ===
    REMOTEPROC = yes;
    QCOM_Q6V5_PAS = module;
    QCOM_PIL_INFO = yes;

    # === Sound (for audio DSP) ===
    SND_SOC_QCOM = module;

    # === Input (Surface keyboard/touchpad) ===
    HID_MULTITOUCH = yes;
    I2C_HID_CORE = yes;
    I2C_HID_ACPI = yes;

    # === Device Tree ===
    OF = yes;
    OF_OVERLAY = yes;

    # === EFI ===
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
    # Include Qualcomm DTBs
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
