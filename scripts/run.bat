@echo off
setlocal

set BUILD_TYPE=Debug
if "%1"=="--release" (
    set BUILD_TYPE=Release
)

build\%BUILD_TYPE%\rive_tests.exe
