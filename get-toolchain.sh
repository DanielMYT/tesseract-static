#!/usr/bin/env bash

# Copyright (C) 2024 Daniel Massey.

# This script (NOT the output binary) is licensed under the MIT license. Please
# see the 'LICENSE' document in the source tree for the full license text.

# Download a static musl toolchain for compiling tesseract.

# Find out which directory we are in.
savedir="$(realpath "$(dirname "$0")")"

# Try to get the toolchain version info from 'software-versions.conf'.
if ! . "${savedir}"/software-versions.conf; then
  echo "Failed to get package info from 'software-versions.conf'." >&2
  echo "Ensure this configuration file exists and has no typos." >&2
  exit 1
fi

# Specify the toolchain directory.
tcdir="${savedir}/toolchain"

# Make sure there isn't already a toolchain.
if [ -e "${tcdir}" ]; then
  echo "An existing toolchain was already detected." >&2
  echo "To redownload it, first remove the 'toolchain' directory." >&2
  exit 1
fi

# Exit on error from here on.
set -e

# Download it. Do NOT use builds older than 20231124.
mkdir "${tcdir}"
curl -L https://github.com/DanielMYT/musl-cross-make/releases/download/${TOOLCHAIN_VER}/x86_64-linux-musl-toolchain.tar.xz -o "${tcdir}"/dl_tc

# Verify checksum.
echo "${TOOLCHAIN_SHA256} ${tcdir}/dl_tc" | sha256sum -c

# Extract it.
tar -xf "${tcdir}"/dl_tc -C "${tcdir}" --strip-components=1

# Report finishing message.
echo
echo "Toolchain successfully downloaded. Run the build script like (e.g.):"
echo
echo "  CC=\"\${PWD}/toolchain/bin/x86_64-linux-musl-gcc\" \\"
echo "  CXX=\"\${PWD}/toolchain/bin/x86_64-linux-musl-g++\" \\"
echo "  ./tesseract-static.sh"
echo
