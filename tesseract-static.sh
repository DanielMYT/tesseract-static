#!/usr/bin/env bash

# Copyright (c) 2022 Daniel Massey.

# This script (NOT the output binary) is licensed under the MIT license. Please
# see the 'LICENSE' document in the source tree for the full license text.

# Get the software versions from 'software-versions.conf' or die trying.
. software-versions.conf || exit 1

# Require CC and CXX to be set.
if [ -z "${CC}" ] || [ -z "${CXX}" ]; then
  echo "Please set CC and CXX in the environment." >&2
  echo "Ideally to the compiler of your Musl cross toolchain." >&2
  exit 1
fi

# Ensure wget is installed for downloading sources.
if ! which wget &>/dev/null; then
  echo "Please install wget and add it to your path." >&2
  exit 1
fi

# Change to a temporary directory.
savedir="$(pwd)"
workdir="$(mktemp -d)"
cd "${workdir}"

# Set up build environment.
export CC="${CC} -static --static -static-libstdc++" CXX="${CXX} -static --static -static-libstdc++"
export CFLAGS="-I${workdir}/include -Os -static --static -static-libstdc++"
export CPPFLAGS="-I${workdir}/include -Os -static --static -static-libstdc++"
export CXXFLAGS="-I${workdir}/include -Os -static --static -static-libstdc++"
export LDFLAGS="-L${workdir}/lib -static --static -static-libstdc++"
export PKG_CONFIG_PATH="${workdir}/share/pkgconfig:${workdir}/lib/pkgconfig"
export PATH="${workdir}/bin:${PATH}"
export MAKEFLAGS="-j$(nproc)"

# Exit on error from here on.
set -e

# Download the stuff.
wget https://zlib.net/zlib-${ZLIB_VER}.tar.xz
wget https://www.openssl.org/source/openssl-${OPENSSL_VER}.tar.gz
wget https://curl.se/download/curl-${CURL_VER}.tar.xz
wget https://downloads.sourceforge.net/libpng/libpng-${LIBPNG_VER}.tar.xz
wget https://downloads.sourceforge.net/libpng-apng/libpng-${LIBPNG_VER}-apng.patch.gz
wget https://github.com/libjpeg-turbo/libjpeg-turbo/archive/${LIBJPEGTURBO_VER}/libjpeg-turbo-${LIBJPEGTURBO_VER}.tar.gz
wget https://downloads.sourceforge.net/giflib/giflib-${GIFLIB_VER}.tar.gz
wget https://gitlab.com/libtiff/libtiff/-/archive/v${LIBTIFF_VER}/libtiff-v${LIBTIFF_VER}.tar.bz2
wget https://github.com/webmproject/libwebp/archive/v${LIBWEBP_VER}/libwebp-${LIBWEBP_VER}.tar.gz
wget https://github.com/DanBloomberg/leptonica/releases/download/${LEPTONICA_VER}/leptonica-${LEPTONICA_VER}.tar.gz
wget https://github.com/tesseract-ocr/tesseract/archive/${TESSERACT_VER}/tesseract-${TESSERACT_VER}.tar.gz

# Build zlib.
tar -xf zlib-${ZLIB_VER}.tar.xz
cd zlib-${ZLIB_VER}
./configure --prefix="${workdir}" --static
make
make install
cd ..
rm -rf zlib-${ZLIB_VER}

# Build OpenSSL.
tar -xf openssl-${OPENSSL_VER}.tar.gz
cd openssl-${OPENSSL_VER}
./config --prefix="${workdir}" --libdir=lib no-shared
make
make install
cd ..

rm -rf openssl-${OPENSSL_VER}
# Build curl.
tar -xf curl-${CURL_VER}.tar.xz
cd curl-${CURL_VER}
./configure --prefix="${workdir}" --enable-static --disable-shared --with-openssl --enable-threaded-resolver --with-ca-path=/etc/ssl/certs
make
make install
cd ..
rm -rf curl-${CURL_VER}

# Build libpng.
tar -xf libpng-${LIBPNG_VER}.tar.xz
cd libpng-${LIBPNG_VER}
gzip -cd ../libpng-${LIBPNG_VER}-apng.patch.gz | patch -Np1
./configure --prefix="${workdir}" --enable-static --disable-shared
make
make install
cd ..
rm -rf libpng-${LIBPNG_VER}

# Build libjpeg-turbo.
tar -xf libjpeg-turbo-${LIBJPEGTURBO_VER}.tar.gz
cd libjpeg-turbo-${LIBJPEGTURBO_VER}
mkdir turbojpeg-build
cd turbojpeg-build
cmake -DCMAKE_INSTALL_PREFIX="${workdir}" -DCMAKE_BUILD_TYPE=MinSizeRel -DENABLE_STATIC=TRUE -DENABLE_SHARED=FALSE -DCMAKE_INSTALL_DEFAULT_LIBDIR=lib -Wno-dev ..
make
make install
cd ../..
rm -rf libjpeg-turbo-${LIBJPEGTURBO_VER}

# Build giflib.
tar -xf giflib-${GIFLIB_VER}.tar.gz
cd giflib-${GIFLIB_VER}
make libgif.a
cp libgif.a "${workdir}"/lib/libgif.a
cp gif_lib.h "${workdir}"/include/gif_lib.h
cd ..
rm -rf giflib-${GIFLIB_VER}

# Build libtiff.
tar -xf libtiff-v${LIBTIFF_VER}.tar.bz2
cd libtiff-v${LIBTIFF_VER}
./autogen.sh
./configure --prefix="${workdir}" --enable-static --disable-shared
make
make install
cd ..
rm -rf libtiff-v${LIBTIFF_VER}

# Build libwebp.
tar -xf libwebp-${LIBWEBP_VER}.tar.gz
cd libwebp-${LIBWEBP_VER}
./autogen.sh
./configure --prefix="${workdir}" --enable-static --disable-shared --enable-libwebpmux --enable-libwebpdemux --enable-libwebpdecoder --enable-libwebpextras --enable-swap-16bit-csp
make
make install
cd ..
rm -rf libwebp-${LIBWEBP_VER}

# Build leptonica.
tar -xf leptonica-${LEPTONICA_VER}.tar.gz
cd leptonica-${LEPTONICA_VER}
./configure --prefix="${workdir}" --enable-static --disable-shared --without-libopenjpeg
make
make install
cd ..
rm -rf leptonica-${LEPTONICA_VER}

# Build tesseract.
tar -xf tesseract-${TESSERACT_VER}.tar.gz
cd tesseract-${TESSERACT_VER}
./autogen.sh
./configure --prefix="${workdir}" --enable-static --disable-shared --disable-doc --disable-tessdata-prefix --without-archive
# We might need to link tesseract ourselves, the included libtool is buggy.
set +e
make
MAKE_RETURN=$?
if [ $MAKE_RETURN -ne 0 ] && [ -e ./.libs/libtesseract.a ]; then
  echo "Looks like the final link failed, lets try linking it ourselves..." >&2
  ${CXX} $(grep -- "CXXFLAGS = ${CXXFLAGS}" Makefile | cut -d= -f2-) $(grep -q -- -fopenmp Makefile && echo '-fopenmp') -o tesseract src/tesseract-tesseract.o ${LDFLAGS} ./.libs/libtesseract.a -llept -lpng16 -lgif -ltiff -ljpeg -lwebp -lwebpmux -lm -lcurl -lssl -lcrypto -lz -lrt
  if [ $? -ne 0 ]; then
    echo "...nope, sorry. :(" >&2
    exit $MAKE_RETURN
  else
    echo "...and that seems to have worked (fingers crossed)!" >&2
  fi
else
  exit $MAKE_RETURN
fi
# Lets pretend that didn't have to happen and continue on...
set -e

# Strip unneeded debugging symbols from the resulting binary.
strip --strip-all tesseract

# Move binary to the final location and clean up.
cp tesseract "${savedir}"/tesseract
cd "${savedir}"
rm -rf "${workdir}"

# Finishing message.
echo "The tesseract binary was successfully built."
echo "Note that it is not be covered by the same license as this script."
echo "See the 'LICENSE' document in the source tree for more details."
