#!/bin/bash
set -e

# Default to Debug
BUILD_TYPE=Debug

# Check for --release flag
if [[ "$1" == "--release" ]]; then
  BUILD_TYPE=Release
fi

VCPKG_TOOLCHAIN="$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake"

cmake -S . -B build/$BUILD_TYPE \
  -DCMAKE_TOOLCHAIN_FILE=$VCPKG_TOOLCHAIN \
  -DCMAKE_BUILD_TYPE=$BUILD_TYPE
