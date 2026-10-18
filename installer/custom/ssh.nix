# Personal installer customisation: lets the owner of this repository SSH into
# the live ISO. Replace these keys with your own (or drop this module from
# `deviceISO` in ../flake.nix) before building an ISO for yourself.
{
  services.openssh.enable = true;
  users.users.nixos.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDXGu52BRohwfz0YBuAYhEwLyGSdgK24s4dgP7DRvryD haruki@nixos-aorus"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEgEOGEbV4rAmGo5z6kRggkEuw65mDYSlbIbnF9RH7da haruki@nixos-xps"
  ];
}
