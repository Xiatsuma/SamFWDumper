![Banner](banner.png)

# SamFWDumper

Automated Samsung firmware extraction powered by GitHub Actions. Download partitions from SamFW links with verified, secure delivery.

## Get Started

### Firmware Dumper
1. Go to **Actions** → **Firmware Dumper** → **Run workflow**
2. Paste your SamFW download link
3. Choose compression level and select partitions
4. Run the workflow and receive your download link with MD5 checksum

### System Files Extractor
1. Go to **Actions** → **System Files Extractor** → **Run workflow**
2. Paste your SamFW download link
3. Select the files or folders you need from system
4. Run the workflow and receive your download link

## What It Does

- Extracts firmware from both A/B and non-A/B Samsung devices
- Lets you pick exactly which partitions to extract
- Keeps original partition names intact (`_a`, `_b`, or standard)
- Compresses output with configurable XZ levels (0–9)
- Uploads to GoFile automatically with MD5 verification
- Leaves no trace—all temporary files are deleted after completion

## Available Partitions

system, system_ext, product, vendor, vendor_boot, vendor_dlkm, system_dlkm, odm, odm_dlkm, boot, init_boot, vbmeta, vbmeta_system, dtbo, recovery

## Available System Files & Folders

| Target | Description |
|---|---|
| `app` | Preinstalled APKs |
| `priv-app` | Privileged system APKs |
| `etc` | System configs and permissions |
| `config` | XML feature and permission configs |
| `lib` | Native libraries (32-bit) |
| `lib64` | Native libraries (64-bit) |
| `media` | Sounds, fonts, and bootanimation |
| `cameradata` | Camera tuning data |
| `build.prop` | Device properties and fingerprint |

## ⚖️ License & Terms

This project is licensed under the **PolyForm Noncommercial License 1.0.0**.

✅ **You may:**
- Use this tool for personal, non-commercial purposes.
- Modify the code for your own use.
- Share the original or modified version — **provided** you keep this license intact.

❌ **You may not:**
- Use this tool (or any derivative) for commercial purposes.
- Remove or alter copyright notices, license terms, or attribution to **Xiatsuma**.
- Distribute as part of a proprietary/closed-source product.

📩 For commercial licensing inquiries, contact the repository owner via GitHub.

## Built With

This project relies on several open-source tools:

- [android-tools](https://github.com/nmeum/android-tools) (Apache-2.0) — Android platform utilities
- [apktool](https://github.com/iBotPeaches/Apktool) (Apache-2.0) — APK reverse engineering
- [erofs-utils](https://github.com/sekaiacg/erofs-utils) (GPL-2.0/Apache-2.0) — EROFS filesystem tools
- [platform/build](https://android.googlesource.com/platform/build) (Apache-2.0) — Android build system
- [e2fsprogs](https://github.com/tytso/e2fsprogs) (GPL-2.0/LGPL-2.1) — Ext4 filesystem utilities
- [xz](https://github.com/tukaani-project/xz) (LGPL-2.1/GPL-2.0) — Compression library
- [lz4](https://github.com/lz4/lz4) (BSD-2-Clause) — Fast compression

Upload integration via [GoFile API](https://gofile.io/api) and inspired by [Sushrut1101/GoFile-Upload](https://github.com/Sushrut1101/GoFile-Upload).

## 🤝 Credits

<p align="center">
  <a href="https://github.com/DevCat3" target="_blank">
    <img src="https://img.shields.io/badge/✨_DevCat3-181717?style=for-the-badge&logo=github&logoColor=white&labelColor=0D1117" alt="DevCat3">
  </a>
  <a href="https://github.com/QOS3" target="_blank">
    <img src="https://img.shields.io/badge/✨_QOS3-181717?style=for-the-badge&logo=github&logoColor=white&labelColor=0D1117" alt="QOS3">
  </a>
  <a href="https://github.com/xenoZ0x" target="_blank">
    <img src="https://img.shields.io/badge/✨_xenoZ0x-181717?style=for-the-badge&logo=github&logoColor=white&labelColor=0D1117" alt="xenoZ0x">
  </a>
</p>

---

Copyright © 2026 Xiatsuma. All rights reserved.
