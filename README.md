# NixOS on the Surface Laptop 7 (13.8", Snapdragon X Elite)

| Directory          | What it is                                                                                                                                                                          |
| ------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `installer/`       | Installer ISO and the `x1e` hardware NixOS module (kernel, device tree, firmware). Based on [kuruczgy/x1e-nixos-config](https://github.com/kuruczgy/x1e-nixos-config); see its [README](installer/README.md). |
| `installer/custom/` | Personal customisation of the ISO. `ssh.nix` holds **my** SSH public keys for the live system: replace them or drop the module from `deviceISO` in `installer/flake.nix`.         |
| `profile/`         | My actual system: a separate flake using the `x1e` module, KDE Plasma 6, home-manager, Japanese region settings with an English UI.                                                 |

`installer/firmware/` holds proprietary blobs extracted from the Windows driver package by `installer/extract-sl7-firmware.sh`.

## Build the ISO

```console
$ cd installer
$ nix build .#microsoft-surface-laptop-7-iso
$ dd if=result/iso/nixos-x1e80100-microsoft-romulus13.iso of=/dev/sdX bs=4M status=progress conv=fdatasync
```

This cross-compiles from `x86_64-linux`. Boot it with Secure Boot disabled. Then connect to Wi-Fi with `nmtui` and SSH in as `nixos`.

## Install the profile

Partition and mount the target at `/mnt` (root ext4 + ESP at `/mnt/boot`). The filesystem UUIDs in `profile/system/hardware.nix` must match the disk.

The profile pulls in `../installer` as a relative flake input, so the whole repository has to be on the laptop. New files must be at least `git add`ed, because flakes only see tracked files.

```console
$ rsync -a --exclude result ./ nixos@<laptop>:surface-nixos/
$ ssh nixos@<laptop>
$ sudo nixos-install --root /mnt --no-channel-copy --no-root-password --flake ~/surface-nixos/profile#nixos-surface
```

Once the repository is pushed, `--flake 'github:haruki-nikaidou/surface-nixos?dir=profile#nixos-surface'` works too.

The kernel carries a Surface-specific patch, so `nixos-install` compiles it on the laptop.

If the firmware doesn't pick up systemd-boot after a reboot, add the boot entry from the ISO's EFI shell. The steps are in the [installer README](installer/README.md#installation).

After the first boot, log in as `haruki` with password `nixos`, then change it with `passwd`. SSH accepts keys only, for `haruki` and for `root`.

## Update remotely

```console
$ cd profile
$ nixos-rebuild switch --flake .#nixos-surface --target-host root@<laptop> --build-host root@<laptop>
```

## License

MIT, see [LICENSE](LICENSE).
