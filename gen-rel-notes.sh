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
- openssl: **${OPENSSL_VER}**
- curl: **${CURL_VER}**
- libpng: **${LIBPNG_VER}**
- libjpeg-turbo: **${LIBJPEGTURBO_VER}**
- giflib: **${GIFLIB_VER}**
- libtiff: **${LIBTIFF_VER}**
- libwebp: **${LIBWEBP_VER}**
- leptonica: **${LEPTONICA_VER}**

The tesseract binaries are **NOT** under the same license as the scripts in this repository. Please visit https://github.com/tesseract-ocr/tesseract/blob/main/LICENSE to view the license for tesseract. The author(s) of the scripts in this repository make no additional claims of copyright over the produced binaries nor the upstream tesseract project.
END
