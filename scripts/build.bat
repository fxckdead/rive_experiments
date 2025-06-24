@echo off
setlocal

:: Default build type
set BUILD_TYPE=Debug

if "%1"=="--release" (
    set BUILD_TYPE=Release
)

cmake --build build\%BUILD_TYPE%
