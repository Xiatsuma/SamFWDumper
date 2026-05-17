![Banner](banner.png)

# SamFWDumper

A free tool that downloads Samsung firmware and pulls out the parts you need. No software to install, it all runs in your browser through GitHub Actions.

## What This Actually Means

You know those big firmware files from SamFW? This tool:
- Downloads that file for you
- Opens it up
- Grabs only what you asked for
- Gives you a download link

You don't need a powerful computer. You don't need to install anything. GitHub's servers do all the work.

## Two Ways to Use It

### Extract Full Partition Images
Gets you the raw image files from the firmware. These are the big pieces that make up Android, you can flash them, inspect them, or use them in other projects.

**When you'd use this:** You need a specific image file to flash with Odin, look through, or include in a mod/patch.

**How:**
- Go to **Actions** → **Images Extractor**
- Paste your SamFW link
- Pick compression 0~9 (0 = fast but big file, 9 = slow but small file)
- Tick the partitions you want
- Hit **Run workflow**. Wait a few minutes. Download link appears.

### Pull Specific Files and Folders
Digs into the firmware and pulls out individual files like folders, apps, configs, libraries, ringtones, build.prop, PIT from CSC or whatever you tick.

**When you'd use this:** You want a folder, an app, a config file to study, camera tuning data, boot animation files, AI files, anything sitting inside the system.

**How:**
- Go to **Actions** → **System Files Extractor**
- Paste your SamFW link
- Tick what you need
- Hit **Run workflow**. Wait a few minutes. Download link appears.

## What's Happening Behind the Scenes

1. Downloads the firmware zip
2. Unzips it, finds the AP tar (and CSC when extracting PIT)
3. Checks for dynamic partitions and unpacks super.img if found
4. Grabs exactly what you selected, nothing extra
5. Compresses everything to save space
6. Uploads to **git releases** or a website like **GoFile** and gives you a link

Works on both legacy and modern Samsung devices. If the device uses A/B slots, partition names are kept untouched (`_a` and `_b`).

## Which Partitions Can You Grab?

`boot` `dtbo` `init_boot` `odm` `odm_dlkm` `product` `recovery` `system` `system_dlkm` `system_ext` `vbmeta` `vbmeta_system` `vendor` `vendor_boot` `vendor_dlkm`

## Which Files and Folders Can You Pull?

| What | What's inside |
|---|---|
| `app` | Preinstalled apps (APKs) |
| `bin` | System binaries |
| `cameradata` | Camera tuning files |
| `etc` | Configs and permissions |
| `lib` | 32-bit libraries |
| `lib64` | 64-bit libraries |
| `media` | Sounds, fonts, boot animation |
| `priv-app` | Privileged system apps |
| `saiv` | Samsung AI Vision stuff |
| `config` | XML configs |
| `super config` | Super image metadata (for repacking) |
| `build.prop` | Device info and fingerprint |
| `framework-res RRO` | Overlay APK from product partition |
| `PIT file` | Partition table from CSC |
| `wallpaper-res.apk` | Wallpaper APK from priv-app |

## License

This project is licensed under the [PolyForm Noncommercial License 1.0.0](LICENSE) — personal and non-commercial use only. See the [LICENSE](LICENSE) file for the full terms.

For commercial licensing inquiries, contact the repository owner via GitHub.

## Used tools

This project relies on several open-source tools:

- [android-tools](https://github.com/nmeum/android-tools) (Apache-2.0) — Android platform utilities
- [apktool](https://github.com/iBotPeaches/Apktool) (Apache-2.0) — APK reverse engineering
- [erofs-utils](https://github.com/sekaiacg/erofs-utils) (GPL-2.0/Apache-2.0) — EROFS filesystem tools
- [lpunpack/lpdump](https://github.com/LonelyFool/lpunpack_and_lpmake) (Apache-2.0) — Dynamic partition unpacking
- [platform/build](https://android.googlesource.com/platform/build) (Apache-2.0) — Android build system
- [e2fsprogs](https://github.com/tytso/e2fsprogs) (GPL-2.0/LGPL-2.1) — Ext4 filesystem utilities
- [xz](https://github.com/tukaani-project/xz) (LGPL-2.1/GPL-2.0) — Compression library
- [lz4](https://github.com/lz4/lz4) (BSD-2-Clause) — Fast compression

Upload integration via [GoFile API](https://gofile.io/api) and inspired by [Sushrut1101/GoFile-Upload](https://github.com/Sushrut1101/GoFile-Upload).

## Credits

<div align="center">

<a href="https://samfw.com" target="_blank"><img src="https://img.shields.io/badge/🌐_SamFW-Firmware_Source-181717?style=for-the-badge&labelColor=1428A0" alt="SamFW"></a><br>
<sub>The platform that makes firmware accessible to everyone. The backbone this project stands on.</sub>

---

<table>
<tr>
<td align="center" width="200">
<a href="https://github.com/DevCat3" target="_blank">
<img src="https://github.com/DevCat3.png" width="64" height="64" style="border-radius:50%"><br>
<b>DevCatowa</b>
</a><br>
<sub>For the inspiration that shaped the soul of this repo. A real catowa. </sub>
</td>
<td align="center" width="200">
<a href="https://github.com/QOS3" target="_blank">
<img src="https://github.com/QOS3.png" width="64" height="64" style="border-radius:50%"><br>
<b>QOS3</b>
</a><br>
<sub>For being our كطري </sub>
</td>
<td align="center" width="200">
<a href="https://github.com/mrx7014" target="_blank">
<img src="https://github.com/mrx7014.png" width="64" height="64" style="border-radius:50%"><br>
<b>MRX7014</b>
</a><br>
<sub>For the extraordinary commitment of being alive. Truly, it's enough we see you. </sub>
</td>
</tr>
</table>

</div>

---

Copyright © 2026 Xiatsuma. All rights reserved.
