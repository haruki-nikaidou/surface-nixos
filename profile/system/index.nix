{ pkgs, ... }:

{
  imports = [
    ./hardware.nix
    ./kde.nix
    ./local.nix
    ./haruki.nix
  ];

  networking.hostName = "nixos-surface";

  nixpkgs.hostPlatform.system = "aarch64-linux";
  nixpkgs.config.allowUnfree = true;

  nix = {
    channel.enable = false;
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  networking.networkmanager.enable = true;
  # KDE Connect
  networking.firewall = {
    allowedTCPPortRanges = [
      {
        from = 1714;
        to = 1764;
      }
    ];
    allowedUDPPortRanges = [
      {
        from = 1714;
        to = 1764;
      }
    ];
  };

  hardware.bluetooth.enable = true;

  environment.systemPackages = with pkgs; [
    git
    wget
    neovim
  ];

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-color-emoji
    source-han-sans
    source-han-serif
    nerd-fonts.jetbrains-mono
    jetbrains-mono
  ];

  system.stateVersion = "26.11";
}
