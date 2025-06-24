#!/bin/bash
set -e

BUILD_TYPE=Debug

if [[ "$1" == "--release" ]]; then
  BUILD_TYPE=Release
fi

./build/$BUILD_TYPE/rive_tests
