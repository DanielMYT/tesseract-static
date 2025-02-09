#!/usr/bin/env bash

# Install all necessary build dependencies for tesseract-static on Ubuntu.
# This script is designed for use in minimal environments, i.e., Docker.

# Exit on error.
set -e

# Ensure we are running as root.
if test $EUID -ne 0; then
  echo "ERROR: $(basename "$0") must be run as root." >&2
  exit 1
fi

# Update repositories.
apt-get update

# Install the dependencies.
apt-get -y install build-essential cmake curl libtool pkg-config wget
