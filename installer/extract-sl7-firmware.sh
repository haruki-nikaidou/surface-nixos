#!/usr/bin/env bash
# Collect Surface Laptop 7 (romulus) firmware into a directory laid out like /lib/firmware,
# ready to be packaged by a Nix derivation. Writes nothing outside $OUT.
#
# Usage (in WSL or any Linux with Nix):
#   nix shell nixpkgs#msitools nixpkgs#curl nixpkgs#python3 nixpkgs#zstd -c bash ./extract-sl7-firmware.sh ./firmware
#
# Every input can be supplied as a local file instead of being downloaded:
#   MSI=/path/SurfaceLaptop7_ARM_Win11_....msi   Surface driver package
#                                                (current one: https://www.microsoft.com/en-us/download/details.aspx?id=106120)
#   BOARD=/path/board-2.bin                      ath12k WCN7850 board file to patch
#   BDENC=/path/ath12k-bdencoder                 Qualcomm's board-file tool
#
# By default board-2.bin is taken from nixpkgs' linux-firmware (served by the Nix binary
# cache, no rate limits); git.codelinaro.org is only a fallback.
#
# Based on bryce-hoehn/linux-surface-laptop-7: romulus-firmware-extract.sh + fix-board-2-wifi.sh
set -euo pipefail

OUT="$(realpath -m "${1:-$PWD/firmware}")"
QCOM_DIR="$OUT/qcom/x1e80100/microsoft"
ATH_DIR="$OUT/ath12k/WCN7850/hw2.0"
BOARD_REL="lib/firmware/ath12k/WCN7850/hw2.0/board-2.bin"

MSI="${MSI:-}"
BOARD="${BOARD:-}"
BDENC="${BDENC:-}"
MSI_URL="${MSI_URL:-https://download.microsoft.com/download/b7ca2c3f-d320-4795-be0f-529a0117abb4/SurfaceLaptop7_ARM_Win11_26100_26.091.9400.0.msi}"
BOARD_URL="https://git.codelinaro.org/clo/ath-firmware/ath12k-firmware/-/raw/main/WCN7850/hw2.0/board-2.bin?ref_type=heads"
BDENC_URL="https://raw.githubusercontent.com/qca/qca-swiss-army-knife/master/tools/scripts/ath12k/ath12k-bdencoder"

FW_FILES=(
  adsp_dtbs.elf adspr.jsn adsps.jsn adspua.jsn battmgr.jsn
  cdsp_dtbs.elf cdspr.jsn
  qcadsp8380.mbn qccdsp8380.mbn qcdxkmsuc8380.mbn
)

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
mkdir -p "$QCOM_DIR" "$ATH_DIR" "$work/msi"

# fetch NAME URL DEST — labelled download; curl retries 429/5xx with backoff (honours Retry-After).
fetch() {
  local name="$1" url="$2" dest="$3"
  echo "  downloading $name"
  echo "    from $url"
  if ! curl -fL --retry 6 --retry-connrefused --progress-bar -o "$dest" "$url"; then
    echo "  FAILED: $name" >&2
    return 1
  fi
}

die() { echo "error: $*" >&2; exit 1; }

# ---------------------------------------------------------------------------
echo "[1/3] DSP / GPU / battery blobs from the Surface Laptop 7 driver MSI"
if [[ -z "$MSI" ]]; then
  MSI="$work/sl7.msi"
  fetch "Surface driver MSI (~500 MB)" "$MSI_URL" "$MSI" \
    || die "get the current MSI from https://www.microsoft.com/en-us/download/details.aspx?id=106120 and rerun with MSI=/path/to/file.msi"
else
  echo "  using $MSI"
fi
msiextract -C "$work/msi" "$MSI" >/dev/null

missing=0
for f in "${FW_FILES[@]}"; do
  src="$(find "$work/msi" -type f -name "$f" -print -quit)"
  if [[ -n "$src" ]]; then
    install -m644 "$src" "$QCOM_DIR/$f"
    echo "  ok       $f"
  else
    echo "  MISSING  $f" >&2
    missing=1
  fi
done

# ---------------------------------------------------------------------------
echo "[2/3] Inputs for the Wi-Fi board file"

if [[ -n "$BOARD" ]]; then
  echo "  using $BOARD"
  cp "$BOARD" "$work/board-2.bin"
elif command -v nix >/dev/null 2>&1 && lf="$(nix build --no-link --print-out-paths nixpkgs#linux-firmware 2>/dev/null)"; then
  echo "  board-2.bin from nixpkgs linux-firmware ($lf)"
  if   [[ -f "$lf/$BOARD_REL"     ]]; then cp "$lf/$BOARD_REL" "$work/board-2.bin"
  elif [[ -f "$lf/$BOARD_REL.zst" ]]; then zstd -qdc "$lf/$BOARD_REL.zst" > "$work/board-2.bin"
  elif [[ -f "$lf/$BOARD_REL.xz"  ]]; then xz -dc "$lf/$BOARD_REL.xz" > "$work/board-2.bin"
  else die "linux-firmware has no $BOARD_REL; rerun with BOARD=/path/to/board-2.bin"
  fi
else
  fetch "board-2.bin (git.codelinaro.org)" "$BOARD_URL" "$work/board-2.bin" \
    || die "download board-2.bin in a browser and rerun with BOARD=/path/to/board-2.bin"
fi
chmod u+w "$work/board-2.bin"

if [[ -n "$BDENC" ]]; then
  echo "  using $BDENC"
  cp "$BDENC" "$work/ath12k-bdencoder"
else
  fetch "ath12k-bdencoder (raw.githubusercontent.com)" "$BDENC_URL" "$work/ath12k-bdencoder" \
    || die "download it in a browser and rerun with BDENC=/path/to/ath12k-bdencoder"
fi

# ---------------------------------------------------------------------------
echo "[3/3] Adding the Surface Laptop 7 alias to board-2.bin"
( cd "$work" && python3 ath12k-bdencoder -e board-2.bin >/dev/null )

python3 - "$work/board-2.json" <<'PY'
import json, sys

path = sys.argv[1]
ref = ("bus=pci,vendor=17cb,device=1107,subsystem-vendor=17cb,"
       "subsystem-device=3378,qmi-chip-id=2,qmi-board-id=255")
alias = ref.replace("subsystem-device=3378", "subsystem-device=1107")

with open(path, encoding="utf-8") as fh:
    data = json.load(fh)

entry = next(
    (b for g in data if isinstance(g, dict)
       for b in g.get("board", []) if ref in b.get("names", [])),
    None,
)
if entry is None:
    sys.exit("reference board entry (subsystem-device=3378) not found in board-2.json")

if alias not in entry["names"]:
    entry["names"].append(alias)

with open(path, "w", encoding="utf-8") as fh:
    json.dump(data, fh, indent=4)
    fh.write("\n")
PY

( cd "$work" && python3 ath12k-bdencoder -c board-2.json >/dev/null )
install -m644 "$work/board-2.bin" "$ATH_DIR/board-2.bin"
echo "  ok       board-2.bin"

# ---------------------------------------------------------------------------
echo
echo "Firmware tree written to $OUT:"
find "$OUT" -type f | sed "s|^$OUT/|  |" | sort
exit "$missing"
