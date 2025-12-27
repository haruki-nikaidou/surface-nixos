{ config, lib, pkgs, modulesPath, ... }:

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

  # GRUB settings - gfxterm is needed for keyboard to work in GRUB on Surface
  boot.loader.grub.extraConfig = ''
    # Enable graphics terminal - required for keyboard on Surface Laptop 7
    terminal_output gfxterm
    terminal_input console
    
    # Increase timeout to give time to select
    set timeout=30
  '';

  # Create a custom GRUB config snippet that will be included
  boot.loader.grub.extraPrepareConfig = ''
    mkdir -p $out/EFI/dtbs
    cp -r ${config.boot.kernelPackages.kernel}/dtbs/qcom $out/EFI/dtbs/ || true
  '';

  # Alternative: Use extraEntries for DTB-loading menu entries
  # Note: added cma=128M which helps with memory allocation on X Elite
  boot.loader.grub.extraEntries = ''
    menuentry "NixOS Installer - Surface Laptop 7 (15 inch)" --class nixos {
      terminal_output gfxterm
      search --set=root --label ${config.isoImage.volumeID}
      linux /boot/${config.system.boot.loader.kernelFile} init=${config.system.build.toplevel}/init ${lib.concatStringsSep " " config.boot.kernelParams} cma=128M
      initrd /boot/${config.system.boot.loader.initrdFile}
      devicetree /dtbs/qcom/x1e80100-microsoft-romulus15.dtb
    }
    menuentry "NixOS Installer - Surface Laptop 7 (13.8 inch)" --class nixos {
      terminal_output gfxterm
      search --set=root --label ${config.isoImage.volumeID}
      linux /boot/${config.system.boot.loader.kernelFile} init=${config.system.build.toplevel}/init ${lib.concatStringsSep " " config.boot.kernelParams} cma=128M
      initrd /boot/${config.system.boot.loader.initrdFile}
      devicetree /dtbs/qcom/x1e80100-microsoft-romulus13.dtb
    }
    menuentry "NixOS Installer - Debug (break=top, 15 inch)" --class nixos {
      terminal_output gfxterm
      search --set=root --label ${config.isoImage.volumeID}
      linux /boot/${config.system.boot.loader.kernelFile} init=${config.system.build.toplevel}/init ${lib.concatStringsSep " " config.boot.kernelParams} cma=128M break=top
      initrd /boot/${config.system.boot.loader.initrdFile}
      devicetree /dtbs/qcom/x1e80100-microsoft-romulus15.dtb
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
    wireless.enable = false;  # We'll use NetworkManager
    networkmanager.enable = true;
  };

  # Useful packages in installer
  environment.systemPackages = with pkgs; [
    # Essentials
    vim
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
    
    # Firmware tools
    fwupd
  ];

  # Console font (readable on HiDPI)
  console = {
    font = "ter-v32n";
    packages = [ pkgs.terminus_font ];
  };
}
