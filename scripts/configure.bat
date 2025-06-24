@echo off
setlocal

:: Default build type
set BUILD_TYPE=Debug

:: Check for --release argument
if "%1"=="--release" (
    set BUILD_TYPE=Release
)

:: Use VCPKG_ROOT environment variable
set TOOLCHAIN_FILE=%VCPKG_ROOT%\scripts\buildsystems\vcpkg.cmake

cmake -S . -B build\%BUILD_TYPE% ^
  -DCMAKE_TOOLCHAIN_FILE=%TOOLCHAIN_FILE% ^
  -DCMAKE_BUILD_TYPE=%BUILD_TYPE%
