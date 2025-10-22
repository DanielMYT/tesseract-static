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

# This project currently only supports x86_64 and aarch64 architectures.
if test "$(uname -m)" = "x86_64"; then
  TOOLCHAIN_SHA256="${TOOLCHAIN_SHA256_X64}"
elif test "$(uname -m)" = "aarch64"; then
  TOOLCHAIN_SHA256="${TOOLCHAIN_SHA256_A64}"
else
  echo "Sorry, this project does not currently support $(uname -m)." >&2
  echo "Please re-run this on an x86_64 or aarch64 machine." >&2
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

# Starting message.
echo "Downloading toolchain version ${TOOLCHAIN_VER} for $(uname -m)..."
echo

# Download it. Do NOT use builds older than 20251021.
# Note that the toolchain
mkdir "${tcdir}"
curl -L https://github.com/DanielMYT/musl-cross-make-nightly/releases/download/nightly-"${TOOLCHAIN_VER}"/"$(uname -m)"-linux-musl-toolchain.tar.xz -o "${tcdir}"/dl_tc

# Verify checksum.
echo "${TOOLCHAIN_SHA256} ${tcdir}/dl_tc" | sha256sum -c

# Extract it.
tar -xf "${tcdir}"/dl_tc -C "${tcdir}" --strip-components=1

# Report about applying the toolchain hack.
# This is required to fix the static build of tesseract.
echo
if test -z "${DISABLE_TOOLCHAIN_HACK}" || test "${DISABLE_TOOLCHAIN_HACK}" = "0"; then
  echo "[NOTE] Applying libstdc++ toolchain hack - see README.md for info." >&2
  rm -fv "${tcdir}"/"$(uname -m)"-linux-musl/lib/libstdc++.so
  ln -sfv libstdc++.a "${tcdir}"/"$(uname -m)"-linux-musl/lib/libstdc++.so
else
  echo "[NOTE] NOT applying libstdc++ toolchain hack - the build may fail." >&2
  echo "[NOTE] See README.md for details." >&2
fi

# Report finishing message.
echo
echo "Toolchain successfully downloaded. Run the build script like (e.g.):"
echo
echo "  CC=\"\${PWD}/toolchain/bin/$(uname -m)-linux-musl-gcc\" \\"
echo "  CXX=\"\${PWD}/toolchain/bin/$(uname -m)-linux-musl-g++\" \\"
echo "  ./tesseract-static.sh"
echo
