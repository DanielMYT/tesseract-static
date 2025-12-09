#!/usr/bin/env bash

# Copyright (C) 2022-2024 Daniel Massey.

# This script (NOT the output binary) is licensed under the MIT license. Please
# see the 'LICENSE' document in the source tree for the full license text.

# Find out which directory we are in.
savedir="$(realpath "$(dirname "$0")")"

# Try to get the software versions from 'software-versions.conf'.
if ! . "${savedir}"/software-versions.conf; then
  echo "Failed to get package info from 'software-versions.conf'." >&2
  echo "Ensure this configuration file exists and has no typos." >&2
  exit 1
fi

# Require CC and CXX to be set.
if [ -z "${CC}" ] || [ -z "${CXX}" ]; then
  echo "Please set CC and CXX in the environment." >&2
  echo "Ideally to the compiler of your Musl cross toolchain." >&2
  echo "If you don't have a toolchain, run 'get-toolchain.sh'." >&2
  echo "And note that Glibc-based toolchains CANNOT be used." >&2
  exit 1
fi

# Ensure the CC and CXX compilers are musl-based.
if ! "${CC}" -v 2>&1 | grep ^Target | cut -d' ' -f2 | grep -q musl || ! "${CC}" -v 2>&1 | grep ^Target | cut -d' ' -f2 | grep -q musl; then
  echo "The compiler you have specified is not Musl-based." >&2
  echo "Please set CC and CXX to the compiler of a Musl cross toolchain." >&2
  echo "If you don't have a toolchain, run 'get-toolchain.sh'." >&2
  echo "As a reminder, Glibc-based toolchains CANNOT be used." >&2
  exit 1
fi

# Ensure curl is installed for downloading sources.
if ! which curl &>/dev/null; then
  echo "Please install curl and add it to your path." >&2
  exit 1
fi

# Specify the working directory.
workdir="${savedir}/workdir"

# Ensure the working directory does not already exist.
if [ -e "${workdir}" ]; then
  echo "The working directory we want to use already exists." >&2
  echo "Please remove the 'workdir' directory first." >&2
  exit 1
fi

# Exit on error from here on.
set -e

# Change to the working directory.
mkdir "${workdir}"
pushd "${workdir}"

# Set up the build environment variables.
export CC="${CC} -static --static -static-libstdc++" CXX="${CXX} -static --static -static-libstdc++"
export CFLAGS="-I${workdir}/include -Os -static --static -static-libstdc++"
export CPPFLAGS="-I${workdir}/include -Os -static --static -static-libstdc++"
export CXXFLAGS="-I${workdir}/include -Os -static --static -static-libstdc++"
export LDFLAGS="-L${workdir}/lib -static --static -static-libstdc++"
export PKG_CONFIG_PATH="${workdir}/share/pkgconfig:${workdir}/lib/pkgconfig"
export PATH="${workdir}/bin:${PATH}"
export MAKEFLAGS="-j$(nproc)"

# Download the stuff.
curl -fL "${ZLIB_URL}" -o dl_zlib
curl -fL "${OPENSSL_URL}" -o dl_openssl
curl -fL "${CURL_URL}" -o dl_curl
curl -fL "${LIBPNG_URL}" -o dl_libpng
curl -fL "${LIBPNGAPNG_URL}" -o dl_libpngapng
curl -fL "${LIBJPEGTURBO_URL}" -o dl_libjpegturbo
curl -fL "${GIFLIB_URL}" -o dl_giflib
curl -fL "${LIBTIFF_URL}" -o dl_libtiff
curl -fL "${LIBWEBP_URL}" -o dl_libwebp
curl -fL "${LEPTONICA_URL}" -o dl_leptonica
curl -fL "${TESSERACT_URL}" -o dl_tesseract

# Prepare the checksum list.
echo "
${ZLIB_SHA256} dl_zlib
${OPENSSL_SHA256} dl_openssl
${CURL_SHA256} dl_curl
${LIBPNG_SHA256} dl_libpng
${LIBPNGAPNG_SHA256} dl_libpngapng
${LIBJPEGTURBO_SHA256} dl_libjpegturbo
${GIFLIB_SHA256} dl_giflib
${LIBTIFF_SHA256} dl_libtiff
${LIBWEBP_SHA256} dl_libwebp
${LEPTONICA_SHA256} dl_leptonica
${TESSERACT_SHA256} dl_tesseract
" | sha256sum -c


# Extract the stuff.
for i in dl_*; do
  if [ "$i" != "dl_libpngapng" ]; then
    mkdir "${i/dl/src}"
    tar -xf "${i}" -C "${i/dl/src}" --strip-components=1
  fi
done

# Build zlib.
pushd src_zlib
./configure --prefix="${workdir}" --static
make
make install
popd

# Build OpenSSL.
pushd src_openssl
./config --prefix="${workdir}" --libdir=lib no-docs no-shared
make
make install
popd

# Build curl.
pushd src_curl
./configure --prefix="${workdir}" --enable-static --disable-shared --disable-docs --enable-threaded-resolver --without-libpsl --with-openssl --with-ca-path=/etc/ssl/certs
make
make install
popd

# Build libpng.
pushd src_libpng
zcat ../dl_libpngapng | patch -Np1
./configure --prefix="${workdir}" --enable-static --disable-shared
make
make install
popd

# Build libjpeg-turbo.
pushd src_libjpegturbo
cmake -DCMAKE_INSTALL_PREFIX="${workdir}" -DCMAKE_BUILD_TYPE=MinSizeRel -DENABLE_STATIC=TRUE -DENABLE_SHARED=FALSE -DCMAKE_INSTALL_DEFAULT_LIBDIR=lib -Wno-dev -B build
make -C build
make -C build install
popd

# Build giflib.
pushd src_giflib
make libgif.a
install -t "${workdir}"/lib -Dm644 libgif.a
install -t "${workdir}"/include -Dm644 gif_lib.h
popd

# Build libtiff.
pushd src_libtiff
./configure --prefix="${workdir}" --enable-static --disable-shared --disable-docs --disable-tests --disable-tools
make
make install
popd

# Build libwebp.
pushd src_libwebp
./autogen.sh
./configure --prefix="${workdir}" --enable-static --disable-shared --enable-libwebpmux --enable-libwebpdemux --enable-libwebpdecoder --enable-libwebpextras --enable-swap-16bit-csp
make
make install
popd

# Build leptonica.
pushd src_leptonica
./configure --prefix="${workdir}" --enable-static --disable-shared --without-libopenjpeg
make
make install
cd ..
popd

# Build tesseract.
# NOTE: Hacky workaround has now been replaced with a toolchain hack.
# NOTE: See README.md for details.
pushd src_tesseract
./autogen.sh
./configure --prefix="${workdir}" --enable-static --disable-shared --disable-doc --disable-tessdata-prefix --without-archive
make
popd

# Strip unneeded symbols from the resulting binary.
$(${CC} -print-prog-name=strip) --strip-all src_tesseract/tesseract

# Move binary to the final location and clean up.
install -Dm755 src_tesseract/tesseract "${savedir}"/tesseract."$(uname -m)"
popd
rm -rf "${workdir}"

# Finishing message.
echo "The tesseract binary was successfully built (tesseract.$(uname -m))."
echo "Note that it is not be covered by the same license as this script."
echo "See the 'LICENSE' document in the source tree for more details."
