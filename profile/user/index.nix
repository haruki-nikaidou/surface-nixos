{ pkgs, ... }:

{
  home.username = "haruki";
  home.homeDirectory = "/home/haruki";

  services.kdeconnect = {
    enable = true;
    indicator = true;
  };

  home.packages = with pkgs; [
    whitesur-kde
    whitesur-icon-theme
    whitesur-gtk-theme
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
  };

  programs.git = {
    enable = true;
    settings.user = {
      email = "nharuki@pm.me";
      name = "Nikaidou Haruki";
    };
  };

  home.stateVersion = "26.11";
}
