#!/bin/bash
set -e

# Default to Debug
BUILD_TYPE=Debug

if [[ "$1" == "--release" ]]; then
  BUILD_TYPE=Release
fi

echo "Building Rive Multi-Backend Example (${BUILD_TYPE})"
echo "Supported backends: OpenGL, Metal (macOS only)"
echo ""

mkdir -p build/$BUILD_TYPE
cmake --build build/$BUILD_TYPE

echo ""
echo "Build completed successfully!"
echo "Run './scripts/run.sh' to start with auto-detected backend"
echo "Run './scripts/run.sh --backend opengl' to force OpenGL"
echo "Run './scripts/run.sh --backend metal' to force Metal (macOS only)"
