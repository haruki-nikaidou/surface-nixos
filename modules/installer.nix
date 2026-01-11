{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-graphical-calamares-plasma6.nix"
  ];

  # Disable ZFS - it's broken on kernel 6.18+
  boot.supportedFilesystems.zfs = lib.mkForce false;

  # Add DTBs to ISO and configure boot
  isoImage.contents = [
    {
      source = "${config.boot.kernelPackages.kernel}/dtbs";
      target = "/dtbs";
    }
  ];

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

  # Add Surface-specific kernel params
  boot.kernelParams = [ "cma=128M" ];

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
}
