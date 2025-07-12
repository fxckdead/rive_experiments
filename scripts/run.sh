#!/bin/bash
set -e

BUILD_TYPE=Debug
BACKEND=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --release)
      BUILD_TYPE=Release
      shift
      ;;
    --backend)
      BACKEND="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--release] [--backend opengl|metal]"
      exit 1
      ;;
  esac
done

echo "Running Rive Multi-Backend Example (${BUILD_TYPE})"
if [[ -n "$BACKEND" ]]; then
  echo "Using backend: $BACKEND"
  ./build/$BUILD_TYPE/rive_tests --backend $BACKEND
else
  echo "Using auto-detected backend"
  ./build/$BUILD_TYPE/rive_tests
fi
