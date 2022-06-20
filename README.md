# tesseract-static
Statically linked Tesseract OCR binary for Linux x86_64 (and anything else people port it to).

# Downloading
Download the latest 'tesseract' binary from https://github.com/DanielMYT/tesseract-static/releases, make it executable (`chmod +x tesseract`), and run it with `./tesseract`.

Note that in order to use the binary you will most likely need training data. This can be obtained from https://github.com/tesseract-ocr/tessdata. Consult the tesseract documenation for more information.

The binary does not have a hardcoded tessdata path; it assumes the tessdata is in the same directory as the binary is executed from.

# Compiling
You will need a static cross Musl GCC toolchain, e.g. https://git.zv.io/toolchains/musl-cross-make.

Precompiled toolchains are provided at https://musl.cc, but they have aggressive static-PIE modifications which may result in build or runtime issues, so use them at your own risk.

A Glibc-based toolchain such as the host's one **CANNOT** be used. Glibc does not have the ability to *fully* statically link executables. The toolchains linked above are static and can be deployed anywhere, including on a system with a different host toolchain, so you *don't* need to go out of your way to install a distro which uses Musl.

You also need wget, pkg-config, Make, CMake and autoconf/automake/related installed on the host system.

Once you have the toolchain in a convenient location, checkout this repo and run the script like this:
```
git clone https://github.com/DanielMYT/tesseract-static
cd tesseract-static
CC=/my/toolchain/path/bin/x86_64-linux-musl-gcc CXX=/my/toolchain/path/bin/x86_64-linux-musl-g++ ./tesseract-static.sh
```
Obviously `/my/toolchain/path` is a placeholder; replace it with wherever you put your toolchain.

The script may take a while to run but after it finishes you should have the `tesseract` binary in the directory you ran the script from.

# Why is this needed?
If you are developing a program incorporating text-in-image recognition which makes use of the Tesseract C/C++ API, you won't need this.

However if your program is written in Python and you are using the [pytesseract](https://pypi.org/project/pytesseract) module, this could be useful since it requires a `tesseract` binary which may not be available in limited environments such as containers.

Or if you're not a developer at all but need Tesseract for some reason, this could be useful for you. It even works on broken systems that don't have a working C library, since it's completely statically linked.
