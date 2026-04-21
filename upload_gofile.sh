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

FILE="$1"
if [ ! -f "$FILE" ]; then
  echo "❌ File not found: $FILE"
  exit 1
fi

echo "📤 Uploading to GoFile..."

# 1. Get API token
echo "🔑 Acquiring token..."
TOKEN_RESPONSE=$(curl -s -X POST https://api.gofile.io/accounts)
TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.data.token' 2>/dev/null)

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
  echo "❌ Failed to get GoFile token"
  exit 1
fi

# 2. Get optimal server
echo "🌍 Selecting server..."
SERVER=$(curl -s "https://api.gofile.io/servers?token=$TOKEN" | jq -r '.data.servers[0].name' 2>/dev/null)
[ -z "$SERVER" ] && SERVER="store1"

# 3. Upload
echo "⬆️ Uploading $(du -h "$FILE" | cut -f1)..."
RESPONSE=$(curl -s -X POST \
  -F "file=@$FILE" \
  -F "token=$TOKEN" \
  "https://${SERVER}.gofile.io/uploadFile")

# 4. Parse & output
if echo "$RESPONSE" | grep -q '"status":"ok"'; then
  DOWNLOAD_URL=$(echo "$RESPONSE" | jq -r '.data.downloadPage')
  
  echo "✅ Upload successful!"
  echo "🔗 $DOWNLOAD_URL"
  echo "$DOWNLOAD_URL" > download_url.txt
  
  cat > release_notes.txt <<EOF
## Firmware Dump
**Date:** $(date -u +"%Y-%m-%d %H:%M:%S UTC")
**Link:** $DOWNLOAD_URL
**File:** $(basename "$FILE") ($(du -h "$FILE" | cut -f1))
**MD5:** $(md5sum "$FILE" | cut -d' ' -f1)
EOF
  cat release_notes.txt
  exit 0
else
  echo "❌ Upload failed"
  echo "Response: $RESPONSE"
  exit 1
fi
