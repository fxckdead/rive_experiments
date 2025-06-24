@echo off
REM Build script for Windows

setlocal EnableDelayedExpansion

set BUILD_TYPE=%1
if "%BUILD_TYPE%"=="" set BUILD_TYPE=Debug

set BUILD_DIR=build\windows_%BUILD_TYPE%

echo Building for Windows - %BUILD_TYPE%

REM Check if vcpkg is available
if not defined VCPKG_ROOT (
    echo Error: VCPKG_ROOT environment variable not set
    echo Please set VCPKG_ROOT to your vcpkg installation directory
    exit /b 1
)

REM Create build directory
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"

REM Configure
echo Configuring project...
cmake -B "%BUILD_DIR%" -S . ^
    -DCMAKE_BUILD_TYPE=%BUILD_TYPE% ^
    -DCMAKE_TOOLCHAIN_FILE="%VCPKG_ROOT%\scripts\buildsystems\vcpkg.cmake"

if errorlevel 1 (
    echo Configuration failed!
    exit /b 1
)

REM Build
echo Building project...
cmake --build "%BUILD_DIR%" --config %BUILD_TYPE%

if errorlevel 1 (
    echo Build failed!
    exit /b 1
)

echo.
echo ✅ Windows build completed successfully!
echo 📁 Output: %BUILD_DIR%\rive_tests.exe
echo.
echo To run: %BUILD_DIR%\%BUILD_TYPE%\rive_tests.exe 
