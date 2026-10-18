# iptsd 3.1.0 plus alex-lentz's fixes for the Surface Laptop 7 (Sensel haptic)
# touchpad: physical click parsing, button debounce, palm-suppression clicks.
{ iptsd, fetchFromGitHub }:

iptsd.overrideAttrs (old: {
  version = "3.1.0-unstable-2026-07-17";

  src = fetchFromGitHub {
    owner = "alex-lentz";
    repo = "iptsd";
    rev = "3663e96e758145801c3cb1ce7c72f362d0d4a5f5";
    hash = "sha256-wN9dg8W0uuDK9H/6z2NyAEinGAIZlEDZuMsPMBeq9pw=";
  };

  # The fork also installs a system-sleep hook into systemd's own store path.
  postPatch = old.postPatch + ''
    substituteInPlace etc/meson.build \
      --replace-fail "install_dir: sleepdir" "install_dir: '$out/lib/systemd/system-sleep'"
  '';
})
