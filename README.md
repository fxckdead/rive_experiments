# Rive Tests - Cross-Platform SDL3 + OpenGL Project

A cross-platform C++ project using SDL3, OpenGL, and vcpkg for dependency management. Supports desktop (Windows, Linux, macOS) and WebAssembly platforms.

## Features

- 🖥️ **Cross-Platform**: Windows, Linux, macOS, WebAssembly
- 🎮 **SDL3**: Modern callback-based API
- 🎨 **OpenGL/OpenGL ES**: Hardware-accelerated rendering
- 📦 **vcpkg**: Dependency management
- 🔧 **CMake**: Build system
- 🌐 **GLAD**: OpenGL function loading (MX mode for multi-context support)

## Prerequisites

### All Platforms
- **CMake** 3.20 or newer
- **vcpkg** package manager
- **C++17** compatible compiler

### Platform-Specific Requirements

#### Windows
- **Visual Studio 2019+** or **MinGW-w64**
- **vcpkg** installed and `VCPKG_ROOT` environment variable set

#### macOS
- **Xcode** or **Xcode Command Line Tools**
- **Homebrew** (recommended for vcpkg installation)

#### Linux
- **GCC 9+** or **Clang 10+**
- Development packages: `build-essential`, `pkg-config`
- **X11** development libraries

#### WebAssembly
- **Emscripten SDK** (emsdk)
- Source the Emscripten environment before building

## Setup

### 1. Install vcpkg

**Windows:**
```bash
git clone https://github.com/Microsoft/vcpkg.git
cd vcpkg
.\bootstrap-vcpkg.bat
set VCPKG_ROOT=C:\path\to\vcpkg
```

**macOS/Linux:**
```bash
git clone https://github.com/Microsoft/vcpkg.git
cd vcpkg
./bootstrap-vcpkg.sh
export VCPKG_ROOT=/path/to/vcpkg
```

### 2. Install GLAD

This project uses a custom GLAD installation in `third_party/glad/`. 
Generate your GLAD files at https://glad.dav1d.de/ with:
- Language: C/C++
- Specification: OpenGL
- API: gl (Version 3.3+), gles2 (Version 2.0+)
- Profile: Core
- Options: Generate a loader

## Building

### Desktop Platforms

#### Quick Build (Current Platform)
```bash
# Configure
./scripts/configure.sh

# Build
./scripts/build.sh

# Run
./scripts/run.sh
```

#### Windows
```batch
scripts\build_windows.bat Debug
```

#### Cross-Platform Build
```bash
# Linux/macOS
./scripts/build.sh Debug
./scripts/build.sh Release
```

### WebAssembly

First, install and activate Emscripten:
```bash
# Install emsdk
git clone https://github.com/emscripten-core/emsdk.git
cd emsdk
./emsdk install latest
./emsdk activate latest
source ./emsdk_env.sh
```

Build for WebAssembly:
```bash
# Build for web (Debug by default)
./scripts/build_web.sh

# Or specify build type
./scripts/build_web.sh Release
```

The build script will:
- Validate that `VCPKG_ROOT` environment variable is set
- Download and compile SDL3 for WebAssembly (first build may take longer)
- Use a custom HTML shell template (`web/shell.html`) for better presentation
- Generate the following files in `build/web_debug/` or `build/web_release/`:
  - `index.html` - Main HTML file with custom styling and controls
  - `index.js` - JavaScript runtime
  - `index.wasm` - WebAssembly binary

**Serve locally:**
```bash
cd build/web_debug
python3 -m http.server 8080
```

Then open your browser to: **http://localhost:8080**

**Note:** WebAssembly applications require being served from a web server (not opened directly as a file) due to browser security restrictions.

## Project Structure

```
rive_tests/
├── src/
│   └── main.cpp              # Main application code
├── scripts/
│   ├── configure.sh          # Configure build (Unix)
│   ├── build.sh              # Build script (Unix)
│   ├── build_web.sh          # WebAssembly build script
│   ├── build_windows.bat     # Windows build script
│   ├── clean.sh              # Clean builds (Unix)
│   └── run.sh                # Run executable (Unix)
├── web/
│   └── shell.html            # Custom HTML shell for WebAssembly
├── third_party/
│   └── glad/                 # GLAD OpenGL loader
│       ├── include/
│       └── src/
├── CMakeLists.txt            # Cross-platform CMake configuration
├── vcpkg.json               # Dependencies manifest
└── README.md                # This file
```

## Platform Detection

The CMake configuration automatically detects the target platform and configures accordingly:

- **Desktop** (`PLATFORM_DESKTOP`): Uses OpenGL with `gladLoadGLContext`
- **Mobile** (`PLATFORM_MOBILE`): Uses OpenGL ES with `gladLoadGLES2Context`  
- **Web** (`PLATFORM_WEB`): Uses WebGL with `gladLoadGLES2Context`

## Dependencies

Managed by vcpkg:
- **SDL3**: Window management and input
- **fmt**: String formatting

Manually managed:
- **GLAD**: OpenGL function loading (in `third_party/`)

## Development

### Adding New Dependencies

1. Add to `vcpkg.json`:
```json
{
  "dependencies": [
    "sdl3",
    "fmt",
    "your-new-package"
  ]
}
```

2. Update `CMakeLists.txt`:
```cmake
find_package(your-package CONFIG REQUIRED)
target_link_libraries(rive_tests PRIVATE your-package::your-package)
```

### Platform-Specific Code

Use the provided preprocessor definitions:
```cpp
#ifdef PLATFORM_DESKTOP
    // Desktop-specific code
#elif defined(PLATFORM_MOBILE)
    // Mobile-specific code
#elif defined(PLATFORM_WEB)
    // Web-specific code
#endif
```

## Troubleshooting

### vcpkg Issues
- Ensure `VCPKG_ROOT` environment variable is set
- Try cleaning vcpkg cache: `vcpkg remove --outdated`

### Build Issues
- Clean build directory: `./scripts/clean.sh`
- Reconfigure: `./scripts/configure.sh`

### WebAssembly Issues
- **`VCPKG_ROOT` must be set**: The build script requires this environment variable
- First build may be slow as Emscripten downloads and compiles SDL3
- Ensure Emscripten SDK is properly installed and activated
- WebAssembly files must be served via HTTP server, not opened directly

### OpenGL Issues
- Verify GLAD generation includes correct OpenGL version
- Check platform-specific OpenGL context creation

## License

This project is public domain. Feel free to use it for any purpose!
