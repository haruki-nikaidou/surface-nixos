# NixOS Installer for Surface Laptop 7 (Snapdragon X Elite)

Custom NixOS installer ISO with Qualcomm X Elite support for Surface Laptop 7.

## Prerequisites

- NixOS x86_64 system with Nix flakes enabled
- At least 32GB RAM recommended (kernel compilation is memory-hungry)
- ~50GB free disk space
- Fast internet connection (first build downloads a lot)

## Building the ISO

```bash
# Clone or copy this directory
cd surface-nixos

# Build the ISO (cross-compiles aarch64 on x86_64)
nix build .#iso --log-format bar-with-logs

# The ISO will be at:
# result/iso/nixos-surface-laptop7-*.iso
```

### Build Time Estimates

With your ~860s allmodconfig build time:
- Kernel alone: ~15-20 minutes
- Full ISO: ~30-45 minutes (first build)
- Subsequent builds: Much faster (Nix caching)

### Debugging Build Issues

```bash
# Build just the kernel first to verify it works
nix build .#kernel --log-format bar-with-logs

# Check what DTBs are included
ls result/dtbs/qcom/ | grep x1e

# Expected files for Surface Laptop 7:
# - x1p64100-microsoft-romulus15.dtb (15")
# - x1p64100-microsoft-romulus13.dtb (13.8")
```

## Writing the ISO to USB

```bash
# Find your USB device
lsblk

# Write ISO (replace /dev/sdX with your device!)
sudo dd if=result/iso/nixos-surface-laptop7-*.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

## Booting

1. Insert USB into Surface Laptop 7
2. Power off completely (hold power button 10+ seconds)
3. Hold Volume Down + Power to enter UEFI
4. Disable Secure Boot (Boot Configuration → Secure Boot → Disabled)
5. Configure boot order or use Boot Menu (Volume Up + Power at boot)
6. Select USB device
7. In GRUB menu, choose your model:
   - "Surface Laptop 7 (15")" for 15-inch model
   - "Surface Laptop 7 (13.8")" for 13.8-inch model

## What Should Work

- Display (via Adreno GPU)
- USB ports (some)
- NVMe storage
- Basic keyboard (in GRUB)

## What Won't Work (Yet)

- Built-in keyboard/touchpad after kernel boot (SAM driver issue)
- Touchscreen
- Audio
- WiFi (needs firmware from Windows)
- Battery reporting
- Cameras

## Workaround: External Keyboard

Until SAM drivers are working, you MUST have a USB keyboard connected to use the installer once Linux boots.

## Extracting Firmware from Windows

Some hardware needs firmware from the Windows partition. On Windows:

```powershell
# Find firmware location
Get-ChildItem -Path "C:\Windows\System32\DriverStore\FileRepository" -Filter "*.msi" -Recurse

# Common locations:
# - qcadsprpc (audio DSP)
# - qcwlanXXX (WiFi)
# - qcsubsys_XXX (various subsystems)
```

Copy these to `/lib/firmware/qcom/x1p64100/` on your NixOS install.

## Troubleshooting

### Black screen immediately after selecting boot entry

The DTB isn't being loaded. Try:
1. Verify the DTB exists: In GRUB, press `c` for console, then `ls ($root)/boot/dtbs/qcom/`
2. Try the "Generic X1E" fallback option
3. Add more kernel params: Press `e` on boot entry, add `nomodeset`

### Kernel panic or hang

Check if it's a DTB mismatch. The Surface Laptop 7 15" uses `romulus15`, 13.8" uses `romulus13`.

### No display at all

Try adding `video=efifb` to kernel params or booting with an external monitor via USB-C.

## Contributing

If you get something working, please:
1. Document what you did
2. Consider upstreaming to nixpkgs/nixos-hardware
3. Report to https://github.com/linux-surface/linux-surface/issues/1590

## References

- [linux-surface issue #1590](https://github.com/linux-surface/linux-surface/issues/1590)
- [Ubuntu Concept for X Elite](https://discourse.ubuntu.com/t/faq-ubuntu-25-04-on-snapdragon-x-elite/61016)
- [Kernel mailing list patches](https://lore.kernel.org/lkml/20240809-topic-sl7-v1-0-2090433d8dfc@quicinc.com/)
