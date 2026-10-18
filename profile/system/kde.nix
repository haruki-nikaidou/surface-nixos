{ pkgs, ... }:

{
  services.xserver.enable = true;
  programs.xwayland.enable = true;

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
  };

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };
  services.desktopManager.plasma6.enable = true;
  security.pam.services.sddm.kwallet.enable = true;

  services.speechd.enable = false;
  services.orca.enable = false;

  programs.partition-manager.enable = true;
  programs.firefox.enable = true;

  environment.systemPackages = with pkgs.kdePackages; [
    plasma-nm
  ];
}
