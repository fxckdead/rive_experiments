#!/bin/bash
set -e

# Default build type
BUILD_TYPE=Debug

if [[ "$1" == "--release" ]]; then
  BUILD_TYPE=Release
fi

rm -rf build/$BUILD_TYPE
echo "✅ Cleaned build/$BUILD_TYPE"
