{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  # Disable ZFS - it's broken on kernel 6.18+
  boot.supportedFilesystems.zfs = lib.mkForce false;

  # ISO naming
  image.fileName = lib.mkForce "nixos-surface-laptop7-${config.system.nixos.label}-aarch64.iso";
  isoImage.volumeID = lib.mkForce "NIXOS_SL7";

  # Use GRUB for EFI boot (required for DTB loading)
  isoImage.makeEfiBootable = true;
  isoImage.makeUsbBootable = true;

  # GRUB configuration
  boot.loader.grub = {
    enable = lib.mkForce true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    device = "nodev";
    memtest86.enable = lib.mkForce false; # Not available on aarch64
  };

  # Add DTBs to ISO and configure boot
  isoImage.contents = [
    {
      source = "${config.boot.kernelPackages.kernel}/dtbs";
      target = "/dtbs";
    }
  ];

  # Squash some warnings
  isoImage.squashfsCompression = "zstd -Xcompression-level 6";

  # GRUB config to include DTB loading
  # This creates additional boot entries with devicetree
  boot.loader.grub.extraFiles = {
    "dtbs" = "${config.boot.kernelPackages.kernel}/dtbs";
  };

  # Note: boot.loader.grub.extraConfig is for the INSTALLED system's GRUB,
  # not the ISO boot menu. ISO boot menu is configured via isoImage.efiGrubCfg below.

  # Create a custom GRUB config snippet that will be included
  boot.loader.grub.extraPrepareConfig = ''
    mkdir -p $out/EFI/dtbs
    cp -r ${config.boot.kernelPackages.kernel}/dtbs/qcom $out/EFI/dtbs/ || true
  '';

  # Add Surface-specific kernel params
  boot.kernelParams = [ "cma=128M" ];

  # Custom GRUB config for the ISO boot menu (not the installed system!)
  # isoImage.efiGrubCfg overrides the default ISO boot menu
  isoImage.efiGrubCfg =
    let
      kernelFile = config.system.boot.loader.kernelFile;
      initrdFile = config.system.boot.loader.initrdFile;
      volumeID = config.isoImage.volumeID;
      # Boot params for live system
      bootParams = "findiso= root=live:LABEL=${volumeID} rd.live.image cma=128M clk_ignore_unused pd_ignore_unused arm64.nopauth loglevel=7";
    in
    ''
      # Enable graphics terminal - required for keyboard on Surface Laptop 7
      terminal_output gfxterm
      terminal_input console
      
      set timeout=30
      set default=0

      menuentry "NixOS Installer - Surface Laptop 7" --class nixos {
        search --set=root --label ${volumeID}
        linux /boot/${kernelFile} ${bootParams}
        initrd /boot/${initrdFile}
        devicetree /dtbs/qcom/x1p64100-microsoft-denali.dtb
      }
      menuentry "NixOS Installer - Debug (break=top)" --class nixos {
        search --set=root --label ${volumeID}
        linux /boot/${kernelFile} ${bootParams} break=top
        initrd /boot/${initrdFile}
        devicetree /dtbs/qcom/x1p64100-microsoft-denali.dtb
      }
      menuentry "NixOS Installer - Debug (break=premount)" --class nixos {
        search --set=root --label ${volumeID}
        linux /boot/${kernelFile} ${bootParams} break=premount
        initrd /boot/${initrdFile}
        devicetree /dtbs/qcom/x1p64100-microsoft-denali.dtb
      }
    '';

  # Enable SSH for headless install (useful if display doesn't work)
  systemd.services.sshd.wantedBy = lib.mkForce [ "multi-user.target" ];
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };
  users.users.root = {
    initialPassword = "nixos";
    initialHashedPassword = lib.mkForce null;
  };
  users.users.nixos = {
    initialPassword = "nixos";
    initialHashedPassword = lib.mkForce null;
  };

  # Networking for installation
  networking = {
    hostName = "nixos-installer";
    wireless.enable = true; # We'll use NetworkManager
    networkmanager.enable = true;
  };

  # XFCE Desktop Environment for GUI installation
  services.xserver = {
    enable = true;
    desktopManager.xfce.enable = true;
    displayManager.lightdm = {
      enable = true;
      greeters.slick.enable = true;
    };
  };
  services.displayManager.autoLogin = {
    enable = true;
    user = "nixos";
  };

  # Useful packages in installer
  environment.systemPackages = with pkgs; [
    # Essentials
    vim
    helix
    git
    wget
    curl

    # Disk tools
    parted
    gptfdisk
    dosfstools
    e2fsprogs
    btrfs-progs

    # Hardware debugging
    pciutils
    usbutils
    lshw
    dmidecode

    # DTB tools
    dtc

    # Network
    iw
    wirelesstools

    # Note: fwupd is excluded - it doesn't cross-compile (fwupd-efi needs native ld.bfd)
    # Install it after booting the native system
  ];

  # Console font (readable on HiDPI)
  console = {
    font = "ter-v32n";
    packages = [ pkgs.terminus_font ];
  };
}
