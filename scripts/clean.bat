@echo off
setlocal

set BUILD_TYPE=Debug
if "%1"=="--release" (
    set BUILD_TYPE=Release
)

rd /s /q build\%BUILD_TYPE%
echo ✅ Cleaned build\%BUILD_TYPE%
