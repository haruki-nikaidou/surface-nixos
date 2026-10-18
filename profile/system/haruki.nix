{ pkgs, ... }:

let
  sshKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDXGu52BRohwfz0YBuAYhEwLyGSdgK24s4dgP7DRvryD haruki@nixos-aorus"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEgEOGEbV4rAmGo5z6kRggkEuw65mDYSlbIbnF9RH7da haruki@nixos-xps"
  ];
in
{
  programs.zsh.enable = true;

  users.users.haruki = {
    isNormalUser = true;
    description = "Nikaidou Haruki";
    extraGroups = [
      "networkmanager"
      "wheel"
      "bluetooth"
      "input"
    ];
    shell = pkgs.zsh;
    # Only applied when the user is first created; change it with `passwd`.
    initialPassword = "nixos";
    openssh.authorizedKeys.keys = sshKeys;
  };

  # Root login is key-only (PermitRootLogin defaults to prohibit-password),
  # used for `nixos-rebuild --target-host root@...`.
  users.users.root.openssh.authorizedKeys.keys = sshKeys;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };
}
