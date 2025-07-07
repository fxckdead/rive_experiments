#!/bin/bash

# Build script for WebAssembly using Emscripten

set -e  # Exit on any error

BUILD_TYPE=${1:-Debug}
BUILD_DIR="build/web_$(echo ${BUILD_TYPE} | tr '[:upper:]' '[:lower:]')"

echo "Building for WebAssembly (Emscripten) - ${BUILD_TYPE}"

# Check if emscripten is available
if ! command -v emcmake &> /dev/null; then
    echo "Error: Emscripten not found. Please install and source the emsdk environment."
    echo "Visit: https://emscripten.org/docs/getting_started/downloads.html"
    exit 1
fi

# Create build directory
mkdir -p "${BUILD_DIR}"

# Check if VCPKG_ROOT is set
if [ -z "$VCPKG_ROOT" ]; then
    echo "Error: VCPKG_ROOT environment variable is not set."
    echo "Please set VCPKG_ROOT to your vcpkg installation directory:"
    echo "  export VCPKG_ROOT=/path/to/your/vcpkg"
    echo ""
    echo "Or add it to your shell profile (~/.bashrc, ~/.zshrc, etc.):"
    echo "  echo 'export VCPKG_ROOT=/path/to/your/vcpkg' >> ~/.bashrc"
    exit 1
fi

# Configure with Emscripten
echo "Configuring project for WebAssembly..."
emcmake cmake -B "${BUILD_DIR}" -S . \
    -DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
    -DEMSCRIPTEN=ON \
    -DVCPKG_TARGET_TRIPLET=wasm32-emscripten

# Build
echo "Building project..."
cmake --build "${BUILD_DIR}" --config ${BUILD_TYPE}

echo ""
echo "✅ WebAssembly build completed successfully!"
echo "📁 Output: ${BUILD_DIR}/index.html"
echo ""
echo "To serve locally:"
echo "  cd ${BUILD_DIR} && python3 -m http.server 8080"
echo "  Then open: http://localhost:8080" 
