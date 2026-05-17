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
COMPRESSION_LEVEL="${2:-0}"
WANT_APP="${3:-false}"
WANT_BIN="${4:-false}"
WANT_CAMERADATA="${5:-false}"
WANT_ETC="${6:-false}"
WANT_LIB="${7:-false}"
WANT_LIB64="${8:-false}"
WANT_MEDIA="${9:-false}"
WANT_PRIV_APP="${10:-false}"
WANT_SAIV="${11:-false}"
WANT_CONFIG="${12:-false}"
WANT_SUPER_CONFIG="${13:-false}"
WANT_BUILD_PROP="${14:-false}"
WANT_FRAMEWORK_RRO="${15:-false}"
WANT_PIT="${16:-false}"
WANT_WALLPAPER_RES="${17:-false}"

chmod +x bin/lp/* bin/ext4/* bin/erofs-utils/* bin/py_scripts/* 2>/dev/null || true

# Set compression flag
case "$COMPRESSION_LEVEL" in
  0) XZ_FLAGS="-0" ;;
  3) XZ_FLAGS="-3" ;;
  6) XZ_FLAGS="-6" ;;
  9) XZ_FLAGS="-9" ;;
  *) XZ_FLAGS="-0" ;;
esac

# Build TARGETS list (folders + config + build.prop)
TARGETS=""
[ "$WANT_APP" = "true" ] && TARGETS="$TARGETS app"
[ "$WANT_BIN" = "true" ] && TARGETS="$TARGETS bin"
[ "$WANT_CAMERADATA" = "true" ] && TARGETS="$TARGETS cameradata"
[ "$WANT_ETC" = "true" ] && TARGETS="$TARGETS etc"
[ "$WANT_LIB" = "true" ] && TARGETS="$TARGETS lib"
[ "$WANT_LIB64" = "true" ] && TARGETS="$TARGETS lib64"
[ "$WANT_MEDIA" = "true" ] && TARGETS="$TARGETS media"
[ "$WANT_PRIV_APP" = "true" ] && TARGETS="$TARGETS priv-app"
[ "$WANT_SAIV" = "true" ] && TARGETS="$TARGETS saiv"
[ "$WANT_CONFIG" = "true" ] && TARGETS="$TARGETS config"
[ "$WANT_BUILD_PROP" = "true" ] && TARGETS="$TARGETS build.prop"
TARGETS="${TARGETS# }"

# Validation
if [ -z "$TARGETS" ] && [ "$WANT_SUPER_CONFIG" != "true" ] && [ "$WANT_FRAMEWORK_RRO" != "true" ] && [ "$WANT_PIT" != "true" ] && [ "$WANT_WALLPAPER_RES" != "true" ]; then
  echo "❌ No targets selected!"
  exit 1
fi

echo ""; echo "[1/8] Downloading..."
wget -q --no-check-certificate -O "firmware.zip" "$URL"
[ ! -f "firmware.zip" ] && { echo "❌ Download failed"; exit 1; }
FILESIZE=$(stat -c%s "firmware.zip")
[ "$FILESIZE" -eq 0 ] && { echo "❌ Empty file"; exit 1; }
echo "✅ Downloaded: $(numfmt --to=iec $FILESIZE)"

echo ""; echo "[2/8] Extracting ZIP..."
unzip -o "firmware.zip" >/dev/null 2>&1
rm -f "firmware.zip"
echo "✅ Done"

mkdir -p output

# ── PIT extraction from CSC tar ──────────────────────────────────────────
if [ "$WANT_PIT" = "true" ]; then
  echo ""; echo "[3/8] Extracting PIT from CSC..."
  CSC_FILE=$(find . -maxdepth 1 -name "CSC_*.tar.md5" -o -name "CSC_*.tar" | head -n 1)
  if [ -z "$CSC_FILE" ]; then
    echo "  ⚠️ CSC tar not found"
  else
    PIT_FILE=$(tar -tf "$CSC_FILE" 2>/dev/null | grep -i "\.pit$" | head -n 1)
    if [ -z "$PIT_FILE" ]; then
      echo "  ⚠️ No .pit file inside CSC"
    else
      tar -xf "$CSC_FILE" "$PIT_FILE" 2>/dev/null
      cp "$PIT_FILE" "output/$(basename "$PIT_FILE")" 2>/dev/null && echo "    ✓ $(basename "$PIT_FILE")" || echo "  ⚠️ Extraction failed"
    fi
  fi
else
  echo ""; echo "[3/8] PIT extraction skipped"
fi

# ── AP extraction ────────────────────────────────────────────────────────
echo ""; echo "[4/8] Extracting AP..."
AP_FILE=$(find . -name "AP_*.tar.md5" -o -name "AP_*.tar" | head -n 1)
[ -z "$AP_FILE" ] && { echo "❌ AP file not found"; exit 1; }
tar -xf "$AP_FILE" >/dev/null 2>&1
rm -f "$AP_FILE"
echo "✅ Done"

# ── System & Product image setup ─────────────────────────────────────────
echo ""; echo "[5/8] Getting system.img and product.img..."
SUPER_FILE=$(find . -maxdepth 1 -name "super.img*" -o -name "super.img" | head -n 1)
if [ -n "$SUPER_FILE" ]; then
  # Dynamic partition device
  if [[ "$SUPER_FILE" == *.lz4 ]]; then
    lz4 -d "$SUPER_FILE" "super.img" 2>/dev/null
    SUPER_FILE="super.img"
  fi
  if file "$SUPER_FILE" 2>/dev/null | grep -q "sparse"; then
    simg2img "$SUPER_FILE" "super.raw.img" 2>/dev/null || bin/ext4/simg2img "$SUPER_FILE" "super.raw.img"
    SUPER_FILE="super.raw.img"
  fi
  mkdir -p super_dump
  bin/lp/lpunpack "$SUPER_FILE" super_dump 2>/dev/null

  # Super config
  if [ "$WANT_SUPER_CONFIG" = "true" ]; then
    if [ -d "super_dump/configs" ]; then
      cp -r "super_dump/configs" "output/super_config"
    elif [ -d "super_dump/config" ]; then
      cp -r "super_dump/config" "output/super_config"
    else
      mkdir -p "output/super_config"
      find super_dump -maxdepth 1 \( -name "*.cfg" -o -name "*_partition*" -o -name "misc_info*" \) -exec cp {} "output/super_config/" \; 2>/dev/null
      bin/lp/lpdump "$SUPER_FILE" > "output/super_config/lpdump.txt" 2>/dev/null || true
    fi
    echo "    ✓ super config saved"
  fi

  SYSTEM_IMG=$(find super_dump -name "system.img" -o -name "system_a.img" | head -n 1)
  PRODUCT_IMG=$(find super_dump -name "product.img" -o -name "product_a.img" | head -n 1)
else
  # Legacy device
  [ "$WANT_SUPER_CONFIG" = "true" ] && echo "  ⚠️ Legacy device — super config not available"
  SYSTEM_IMG=$(find . -maxdepth 1 -name "system.img.lz4" -o -name "system.img" | head -n 1)
  if [[ "$SYSTEM_IMG" == *.lz4 ]]; then
    lz4 -d "$SYSTEM_IMG" "system_raw.img" 2>/dev/null
    SYSTEM_IMG="system_raw.img"
  fi
  if [ -n "$SYSTEM_IMG" ] && file "$SYSTEM_IMG" 2>/dev/null | grep -q "sparse"; then
    simg2img "$SYSTEM_IMG" "system_unsparse.img" 2>/dev/null
    SYSTEM_IMG="system_unsparse.img"
  fi
  PRODUCT_IMG=$(find . -maxdepth 1 -name "product.img.lz4" -o -name "product.img" | head -n 1)
  if [[ "$PRODUCT_IMG" == *.lz4 ]]; then
    lz4 -d "$PRODUCT_IMG" "product_raw.img" 2>/dev/null
    PRODUCT_IMG="product_raw.img"
  fi
  if [ -n "$PRODUCT_IMG" ] && file "$PRODUCT_IMG" 2>/dev/null | grep -q "sparse"; then
    simg2img "$PRODUCT_IMG" "product_unsparse.img" 2>/dev/null
    PRODUCT_IMG="product_unsparse.img"
  fi
fi

# ── product.img extraction (framework RRO APK) ───────────────────────────
if [ "$WANT_FRAMEWORK_RRO" = "true" ]; then
  echo ""; echo "[6/8] Extracting framework RRO APK..."
  if [ -z "$PRODUCT_IMG" ] || [ ! -f "$PRODUCT_IMG" ]; then
    echo "  ⚠️ product.img not found"
  else
    mkdir -p product_extracted
    RRO_FOUND=false

    bin/erofs-utils/extract.erofs -i "$PRODUCT_IMG" -x -o product_extracted/ >/dev/null 2>&1 || {
      for SRC_PATH in "overlay" "product/overlay"; do
        if debugfs -R "ls $SRC_PATH" "$PRODUCT_IMG" 2>/dev/null | grep -q .; then
          mkdir -p "product_extracted/overlay"
          debugfs -R "rdump $SRC_PATH product_extracted/overlay" "$PRODUCT_IMG" 2>/dev/null
          break
        fi
      done
    }

    for BASE in \
      "product_extracted/product_a/product/overlay" \
      "product_extracted/product_a/overlay" \
      "product_extracted/product_b/product/overlay" \
      "product_extracted/product_b/overlay" \
      "product_extracted/product/overlay" \
      "product_extracted/overlay" \
      "product_extracted/system/product/overlay"; do
      APK_SRC=$(find "$BASE" -name "framework-res__*__auto_generated_rro_product.apk" 2>/dev/null | head -n 1)
      if [ -n "$APK_SRC" ]; then
        cp "$APK_SRC" "output/$(basename "$APK_SRC")"
        echo "    ✓ $(basename "$APK_SRC")"
        RRO_FOUND=true
        break
      fi
    done
    $RRO_FOUND || echo "  ⚠️ framework-res RRO APK not found"
    rm -rf product_extracted
  fi
else
  echo ""; echo "[6/8] Product extraction skipped"
fi

# ── system.img extraction ────────────────────────────────────────────────
if [ -z "$TARGETS" ] && [ "$WANT_WALLPAPER_RES" != "true" ]; then
  echo ""; echo "[7/8] No system targets — skipping"
else
  [ -z "$SYSTEM_IMG" ] || [ ! -f "$SYSTEM_IMG" ] && { echo "❌ system.img not found"; exit 1; }
  echo ""; echo "[7/8] Extracting system.img contents..."
  mkdir -p system_extracted

  SINGLE_FILES="build.prop floating_features.xml"

  if bin/erofs-utils/extract.erofs -i "$SYSTEM_IMG" -x -o system_extracted/ >/dev/null 2>&1; then
    echo "  ✅ Extracted via erofs"
  else
    echo "  erofs failed — trying debugfs..."
    DEBUGFS_TARGETS="$TARGETS"
    [ "$WANT_WALLPAPER_RES" = "true" ] && DEBUGFS_TARGETS="$DEBUGFS_TARGETS priv-app/wallpaper-res"

    for TARGET in $DEBUGFS_TARGETS; do
      IS_FILE=false
      for SF in $SINGLE_FILES; do
        [ "$TARGET" = "$SF" ] && IS_FILE=true && break
      done
      if $IS_FILE; then
        FOUND=false
        for SRC_PATH in "$TARGET" "system/$TARGET"; do
          if debugfs -R "stat $SRC_PATH" "$SYSTEM_IMG" 2>/dev/null | grep -q "Type: regular"; then
            debugfs -R "dump $SRC_PATH system_extracted/$TARGET" "$SYSTEM_IMG" 2>/dev/null
            FOUND=true
            break
          fi
        done
        $FOUND || echo "  ⚠️ $TARGET not found"
      else
        FOUND=false
        DEST_DIR="system_extracted/$TARGET"
        mkdir -p "$DEST_DIR"
        for SRC_PATH in "$TARGET" "system/$TARGET"; do
          if debugfs -R "ls $SRC_PATH" "$SYSTEM_IMG" 2>/dev/null | grep -q .; then
            debugfs -R "rdump $SRC_PATH $DEST_DIR" "$SYSTEM_IMG" 2>/dev/null
            FOUND=true
            break
          fi
        done
        $FOUND || echo "  ⚠️ $TARGET not found"
      fi
    done
  fi

  # ── Copy targets to output ─────────────────────────────────────────────
  echo ""; echo "[8/8] Copying selected targets..."

  # wallpaper-res.apk special handling
  if [ "$WANT_WALLPAPER_RES" = "true" ]; then
    APK_FOUND=false
    for BASE in \
      "system_extracted/priv-app/wallpaper-res" \
      "system_extracted/system/priv-app/wallpaper-res" \
      "system_extracted/system_a/priv-app/wallpaper-res" \
      "system_extracted/system/system/priv-app/wallpaper-res" \
      "system_extracted/system_a/system/priv-app/wallpaper-res"; do
      APK_SRC="$BASE/wallpaper-res.apk"
      if [ -f "$APK_SRC" ]; then
        cp "$APK_SRC" "output/wallpaper-res.apk"
        echo "    ✓ wallpaper-res.apk"
        APK_FOUND=true
        break
      fi
    done
    $APK_FOUND || echo "  ⚠️ wallpaper-res.apk not found"
  fi

  for TARGET in $TARGETS; do
    if [ -e "system_extracted/$TARGET" ]; then
      cp -r "system_extracted/$TARGET" "output/"
      echo "    ✓ $TARGET"
      continue
    fi
    for BASE in \
      "system_extracted/system" \
      "system_extracted/system_a" \
      "system_extracted/system/system" \
      "system_extracted/system_a/system"; do
      SRC="$BASE/$TARGET"
      if [ -e "$SRC" ]; then
        cp -r "$SRC" "output/"
        echo "    ✓ $TARGET"
        break
      fi
    done
    [ ! -e "output/$TARGET" ] && echo "  ⚠️ Not found: $TARGET"
  done

  rm -rf system_extracted
fi

# Cleanup
rm -rf super_dump super.img super.raw.img system_unsparse.img product_raw.img product_unsparse.img system_raw.img

# Compress output if level > 0
if [ "$COMPRESSION_LEVEL" != "0" ]; then
  echo ""; echo "Compressing output..."
  for ITEM in output/*; do
    [ -e "$ITEM" ] || continue
    NAME=$(basename "$ITEM")
    if [ -d "$ITEM" ]; then
      tar -cf - -C output "$NAME" | xz $XZ_FLAGS -T0 > "output/${NAME}.tar.xz" && rm -rf "$ITEM"
      echo "    ✓ ${NAME}.tar.xz"
    elif [ -f "$ITEM" ] && [[ "$ITEM" != *.xz ]]; then
      xz $XZ_FLAGS -T0 "$ITEM" 2>/dev/null && echo "    ✓ ${NAME}.xz" || true
    fi
  done
fi

# Results
echo ""; echo "═══════════════════════════════════════"
FILE_COUNT=$(ls -1 output 2>/dev/null | wc -l)
[ "$FILE_COUNT" -eq 0 ] && { echo "❌ Nothing extracted!"; exit 1; }
TOTAL_SIZE=$(du -sh output | cut -f1)
echo "✅ Extracted $FILE_COUNT items"
echo "Total size: $TOTAL_SIZE"
echo ""; echo "Files:"
ls -lh output
echo "═══════════════════════════════════════"
echo "✅ Done!"
