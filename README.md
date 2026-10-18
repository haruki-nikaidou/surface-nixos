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

The system is built on an x86_64 machine with aarch64 binfmt (`boot.binfmt.emulatedSystems = [ "aarch64-linux" ]`). The kernel is cross-compiled at native speed. Everything else is native aarch64 and comes from the binary cache. Flakes only see tracked files, so `git add` new files first.

```console
$ cd profile
$ nix build .#nixosConfigurations.nixos-surface.config.system.build.toplevel --out-link result-surface
```

Writing into the target's store needs root on the live ISO. Let root reuse the `nixos` user's keys:

```console
$ ssh nixos@<laptop> 'sudo install -d -m 700 /root/.ssh && sudo cp /etc/ssh/authorized_keys.d/nixos /root/.ssh/authorized_keys'
```

Copy the closure straight into `/mnt/nix/store`; the ISO's RAM-backed store is too small. Then install it:

```console
$ nix copy --to 'ssh://root@<laptop>?remote-store=local%3Froot=%2Fmnt' ./result-surface
$ ssh root@<laptop> nixos-install --root /mnt --no-channel-copy --no-root-password --system "$(readlink -f result-surface)"
```

Don't run `nixos-install --flake` on the laptop itself. It would try to build the cross-compiled kernel, which needs an x86_64 builder.

If the firmware doesn't pick up systemd-boot after a reboot, add the boot entry from the ISO's EFI shell. The steps are in the [installer README](installer/README.md#installation).

After the first boot, log in as `haruki` with password `nixos`, then change it with `passwd`. SSH accepts keys only, for `haruki` and for `root`.

## Update remotely

Build here and push the result to the laptop:

```console
$ cd profile
$ nixos-rebuild switch --flake .#nixos-surface --target-host root@<laptop>
```

`nixos-rebuild` on the laptop itself works only while its kernel is unchanged, because a new kernel needs the x86_64 cross build.

## Touchpad

The touchpad is a HID-over-SPI device that only sends raw heatmaps. `iptsd` turns those into touch input. The `x1e` module ships a generic calibration for it. If palm rejection or tap detection feels wrong, recalibrate on the laptop:

```console
$ sudo iptsd-find-hidraw
$ sudo iptsd-calibrate /dev/hidrawN
```

Move one finger over the whole surface, including the edges, then press Ctrl+C. Copy the printed `[Contacts]` values into `installer/modules/x1e80100.nix`.

## License

MIT, see [LICENSE](LICENSE).
