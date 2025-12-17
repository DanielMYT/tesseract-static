#!/usr/bin/env bash
set -e

# Generate user-friendly release notes based on software versions set in
# 'software-versions.conf'. Generate in Markdown format suitable for GitHub.

# Ensure software-versions.conf exists and is readable by us.
if test ! -r software-versions.conf; then
  echo "Error: software-versions.conf file not accessible." >&2
  exit 1
fi

# Source software-versions.conf
. software-versions.conf

# Main tesseract version.
cat > /dev/stdout << END
Statically linked **tesseract ${TESSERACT_VER}** binaries for Linux.

Compiled using version **${TOOLCHAIN_VER}** of the toolchain available from https://github.com/DanielMYT/musl-cross-make-nightly/releases.

Statically linked with the following library versions:

- zlib: **${ZLIB_VER}**
- bzip2: **${BZIP2_VER}**
- xz: **${XZ_VER}**
- zstd: **${ZSTD_VER}**
- openssl: **${OPENSSL_VER}**
- curl: **${CURL_VER}**
- libarchive: **${LIBARCHIVE_VER}**
- libpng: **${LIBPNG_VER}**
- libjpeg-turbo: **${LIBJPEGTURBO_VER}**
- giflib: **${GIFLIB_VER}**
- libtiff: **${LIBTIFF_VER}**
- libwebp: **${LIBWEBP_VER}**
- leptonica: **${LEPTONICA_VER}**

The license for the tesseract binaries can be found in the \`license.tesseract.txt\` asset available on this release. Similarly, the license for all third party libraries which were statically linked into the binaries can be found in \`license.libraries.txt\`. The author(s) of the scripts in this repository make no additional claims of copyright over the produced binaries, the static libraries linked into them, nor the upstream projects they originate from.
END
