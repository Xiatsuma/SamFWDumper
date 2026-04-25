#!/bin/bash
# =============================================================================
# SamFWDumper - Automated Samsung Firmware Extraction
# Copyright (C) 2026 Xiatsuma
# Licensed under PolyForm Noncommercial License 1.0.0
# https://polyformproject.org/licenses/noncommercial/1.0.0
#
# You may NOT use this file except in compliance with the License.
# Commercial use, removal of this header, or distribution without attribution
# is strictly prohibited. For permissions: https://github.com/Xiatsuma
# =============================================================================
set -e

echo "═══════════════════════════════════════"
echo "   Universal Samsung Firmware Extractor"
echo "═══════════════════════════════════════"

URL="$1"
COMPRESSION_LEVEL="${2:-6}"
SELECTED_PARTITIONS="$3"

[ -z "$URL" ] && { echo "❌ No URL"; exit 1; }
[ -z "$SELECTED_PARTITIONS" ] && { echo "❌ No partitions selected"; exit 1; }

# Set compression flag
case "$COMPRESSION_LEVEL" in
  0) XZ_FLAGS="-0" ;;
  3) XZ_FLAGS="-3" ;;
  6) XZ_FLAGS="-6" ;;
  9) XZ_FLAGS="-9" ;;
  *) XZ_FLAGS="-6" ;;
esac

echo "Compression level: $COMPRESSION_LEVEL"
echo "Partitions to extract: $SELECTED_PARTITIONS"

chmod +x bin/lp/* bin/ext4/* bin/erofs-utils/* bin/py_scripts/* 2>/dev/null || true

SUPER_PARTS="system system_ext product vendor vendor_dlkm system_dlkm odm odm_dlkm"
NEED_SUPER=false
for PART in $SELECTED_PARTITIONS; do
  for SP in $SUPER_PARTS; do
    if [ "$PART" = "$SP" ]; then
      NEED_SUPER=true
      break 2
    fi
  done
done

echo ""; echo "[1/5] Downloading..."
wget --no-check-certificate -O "firmware.zip" "$URL" 2>&1 | tail -3
[ ! -f "firmware.zip" ] && { echo "❌ Download failed"; exit 1; }
FILESIZE=$(stat -c%s "firmware.zip")
[ "$FILESIZE" -eq 0 ] && { echo "❌ Empty file"; exit 1; }
echo "✅ Downloaded: $(numfmt --to=iec $FILESIZE)"

echo ""; echo "[2/5] Extracting ZIP..."
unzip -o "firmware.zip" >/dev/null 2>&1
rm -f "firmware.zip"
echo "✅ Done"

echo ""; echo "[3/5] Extracting AP..."
AP_FILE=$(find . -name "AP_*.tar.md5" -o -name "AP_*.tar" | head -n 1)
[ -z "$AP_FILE" ] && { echo "❌ AP file not found"; exit 1; }
echo "  Extracting: $(basename "$AP_FILE")"

EXTRACT_ARGS=()
for PART in $SELECTED_PARTITIONS; do
  EXTRACT_ARGS+=("*${PART}.img*" "*${PART}_a.img*" "*${PART}_b.img*")
done
$NEED_SUPER && EXTRACT_ARGS+=("*super.img*")

tar --no-anchored --wildcards -xf "$AP_FILE" "${EXTRACT_ARGS[@]}" 2>/dev/null || tar -xf "$AP_FILE" >/dev/null 2>&1
rm -f "$AP_FILE"
echo "✅ Done"

echo ""; echo "[4/5] Extracting partitions..."
mkdir -p processed

# Process individual partitions first (keep original names: _a, _b, or none)
echo "  Processing individual partitions..."
for PART in $SELECTED_PARTITIONS; do
  # Skip if already processed
  [ -f "processed/${PART}.img.xz" ] && continue
  [ -f "processed/${PART}_a.img.xz" ] && continue
  [ -f "processed/${PART}_b.img.xz" ] && continue
  
  # Find file with any suffix variant
  FILE=$(find . -maxdepth 1 \( -name "${PART}.img.lz4" -o -name "${PART}.img" -o -name "${PART}_a.img.lz4" -o -name "${PART}_a.img" -o -name "${PART}_b.img.lz4" -o -name "${PART}_b.img" \) | head -n 1)
  if [ -n "$FILE" ] && [ -f "$FILE" ]; then
    echo "    ✓ Found: $(basename "$FILE")"
    
    # Decompress LZ4 if needed
    if [[ "$FILE" == *.lz4 ]]; then
      lz4 -d "$FILE" "${FILE%.lz4}" 2>/dev/null || true
      FILE="${FILE%.lz4}"
    fi
    
    # Keep original basename and compress
    BASENAME=$(basename "$FILE")
    if xz $XZ_FLAGS -T0 "$FILE" 2>/dev/null; then
      mv "${FILE}.xz" "processed/${BASENAME}.xz"
    else
      cp "$FILE" "processed/${BASENAME}"
    fi
  fi
done

# Extract super.img partitions (ONLY selected ones)
SUPER_FILE=$(find . -maxdepth 1 -name "super.img*" | head -n 1)
if $NEED_SUPER && [ -n "$SUPER_FILE" ] && [ -f "$SUPER_FILE" ]; then
  echo ""; echo "  Extracting super.img..."
  
  # Decompress LZ4
  if [[ "$SUPER_FILE" == *.lz4 ]]; then
    echo "    Decompressing LZ4..."
    lz4 -d "$SUPER_FILE" "super.img" 2>/dev/null || { echo "    ❌ LZ4 failed"; exit 1; }
    SUPER_FILE="super.img"
  fi
  
  # Convert sparse if needed
  if file "$SUPER_FILE" 2>/dev/null | grep -q "sparse"; then
    echo "    Converting sparse image..."
    if command -v simg2img &>/dev/null; then
      simg2img "$SUPER_FILE" "super.raw.img" 2>/dev/null
    elif [ -f "bin/ext4/simg2img" ]; then
      bin/ext4/simg2img "$SUPER_FILE" "super.raw.img" 2>/dev/null
    else
      echo "    ⚠️ simg2img not found"
      exit 1
    fi
    [ -f "super.raw.img" ] && SUPER_FILE="super.raw.img"
  fi
  
  # Extract with lpunpack
  echo "    Extracting dynamic partitions..."
  mkdir -p super_dump
  
  if [ -f "bin/lp/lpunpack" ]; then
    bin/lp/lpunpack "$SUPER_FILE" super_dump 2>/dev/null || { echo "      ❌ lpunpack failed"; exit 1; }
  else
    echo "      ❌ lpunpack not found"
    exit 1
  fi
  
  # ONLY compress selected partitions (keep original names: _a, _b, or none)
  echo "    Compressing ONLY selected partitions..."
  for PART in $SELECTED_PARTITIONS; do
    # Try _a slot first, then non-suffixed, then _b slot
    for SUFFIX in "_a" "" "_b"; do
      IMG_FILE="super_dump/${PART}${SUFFIX}.img"
      if [ -f "$IMG_FILE" ]; then
        BASENAME="${PART}${SUFFIX}.img"
        echo "      ✓ $BASENAME"
        if xz $XZ_FLAGS -T0 "$IMG_FILE" 2>/dev/null; then
          mv "${IMG_FILE}.xz" "processed/${BASENAME}.xz"
        else
          cp "$IMG_FILE" "processed/${BASENAME}"
        fi
        break  # Move to next partition once we find it
      fi
    done
  done
  
  rm -rf super_dump super.img super.raw.img
elif $NEED_SUPER; then
  echo "  ⚠️ super.img not found"
fi

echo ""; echo "[5/5] Results:"; cd processed
FILE_COUNT=$(ls -1 | wc -l)
[ "$FILE_COUNT" -eq 0 ] && { echo "❌ Nothing extracted!"; exit 1; }

TOTAL_SIZE=$(du -sh . | cut -f1)
echo "═══════════════════════════════════════"
echo "✅ Extracted $FILE_COUNT partitions"
echo "Total size: $TOTAL_SIZE"
echo "Compression: Level $COMPRESSION_LEVEL"
echo ""; echo "Files:"
ls -lh
echo "═══════════════════════════════════════"
echo "✅ Done!"
