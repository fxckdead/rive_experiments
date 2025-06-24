#!/bin/bash
set -e

# Default to Debug
BUILD_TYPE=Debug

if [[ "$1" == "--release" ]]; then
  BUILD_TYPE=Release
fi

cmake --build build/$BUILD_TYPE
