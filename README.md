# tesseract-static
Statically linked Tesseract OCR binary for Linux x86_64 and aarch64.

# Downloading
Download the latest 'tesseract' binary from [the releases page](https://github.com/DanielMYT/tesseract-static/releases), make it executable (`chmod +x tesseract`), and run it with `./tesseract`.

Note that as of the (recent) addition of aarch64 support, the released binaries are now named `tesseract.x86_64` and `tesseract.aarch64` respectively. You will need to update your workflows to handle this. You can rename the downloaded binary back to `tesseract` (without the architecture file extension) if desired.

Note also that in order to use the binary you will most likely need training data. This can be obtained from https://github.com/tesseract-ocr/tessdata. Consult the tesseract documenation for more information.

The binary does not have a hardcoded tessdata path; it assumes the tessdata is in the same directory as the binary is executed from. You can alternatively set the `TESSDATA_PREFIX` environment variable, if your tessdata is located in a different location to the tesseract binary.

# Compiling
You will need a static cross Musl GCC toolchain. We recommend using the included `get-toolchain.sh` script, which will download one for you. See the commands below for more information.

A Glibc-based toolchain, such as the default one on most distros, **CANNOT** be used, since Glibc does not have the ability to _fully_ statically link executables. Statically linked executables with Glibc depend on an equivalent or newer Glibc version on the host system at runtime. Musl, on the other hand, can create fully static executables that don't depend on anything besides a Linux kernel at runtime. Hence why we need to use a Musl-based toolchain.

You also need curl, pkg-config, Make, CMake, autoconf/automake, and related build tools installed on the system you wish to build on. These packages are, however, libc-agnostic, unlike the toolchain, so distro-provided packages should work fine for these.

Use the following commands to check out the repo, download a toolchain, and build.
```
git clone https://github.com/DanielMYT/tesseract-static
cd tesseract-static
./get-toolchain.sh
CC="${PWD}/toolchain/bin/x86_64-linux-musl-gcc" CXX="${PWD}/toolchain/bin/x86_64-linux-musl-g++" ./tesseract-static.sh
```
The script may take a while to run but after it finishes you should have the `tesseract` binary in the directory you ran the script from.

Please note that there is a flaw in the tesseract build system that under normal circumstances causes it to throw an error when at the link of the final executable when static linking. This happens because the build system tries to forcibly link against `libstdc++.so` (shared library), even when static linking is explicitly requested (which should link to `libstdc++.a`). Previously this issue was fixed by an extremely hacky workaround in the build script. However, we now apply a slightly cleaner hack as part of the toolchain retrival (`get-toolchain.sh`) instead. As a result, we recommend using the toolchain downloaded from `get-toolchain.sh` for building `tesseract-static`, and **NOT** attempting to use your own toolchain. The older extremely-hacky-workaround has been removed from the build script.

# Why is this needed?
If you are developing a program incorporating text-in-image recognition which makes use of the Tesseract C/C++ API, you won't need this.

However if your program is written in Python and you are using the [pytesseract](https://pypi.org/project/pytesseract) module, this could be useful since it requires a `tesseract` binary which may not be available in limited environments such as containers.

Or if you're not a developer at all but need Tesseract for some reason, this could be useful for you. It even works on broken systems that don't have a working C library, since it's completely statically linked.
