# Rive Tests - Cross-Platform SDL3 + Multi-Backend Project

A cross-platform C++ project using SDL3 with multiple graphics backends (OpenGL and Metal) for rendering Rive animations. Supports desktop (Windows, Linux, macOS) and WebAssembly platforms.

## Features

- 🖥️ **Cross-Platform**: Windows, Linux, macOS, WebAssembly
- 🎮 **SDL3**: Modern callback-based API
- 🎨 **Multiple Graphics Backends**:
  - **OpenGL/OpenGL ES**: Hardware-accelerated rendering (all platforms)
  - **Metal**: Native Apple graphics API (macOS only)
  - **Automatic Backend Detection**: Chooses best backend for your platform
- 📦 **vcpkg**: Dependency management
- 🔧 **CMake**: Build system
- 🌐 **GLAD**: OpenGL function loading (MX mode for multi-context support)
- 🎬 **Rive Animation**: Vector animation rendering with full Rive runtime support

## Graphics Backend Support

| Platform    | OpenGL  | Metal | Default |
|-------------|---------|-------|---------|
| macOS       | ❌      | ✅     | Metal   |
| Linux       | ✅      | ❌     | OpenGL  |
| Windows     | ✅      | ❌     | OpenGL  |
| WebAssembly | ✅      | ❌     | OpenGL  |

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
- **Metal**: Supported on macOS 10.11+ (automatically available)

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

# Run with auto-detected backend
./scripts/run.sh

# Run with specific backend
./scripts/run.sh --backend opengl
./scripts/run.sh --backend metal  # macOS only
```

#### Windows
```batch
scripts\build_windows.bat Debug
```

#### macOS
```bash
./scripts/build.sh
# Uses Metal by default, or specify backend:
./scripts/run.sh --backend metal
./scripts/run.sh --backend opengl
```

#### Linux
```bash
./scripts/build.sh
# Uses OpenGL (Metal not available on Linux)
./scripts/run.sh --backend opengl
```

### WebAssembly

**Requirements:**
- Emscripten SDK properly installed and activated
- `VCPKG_ROOT` environment variable set

```bash
# Activate emsdk first
source /path/to/emsdk/emsdk_env.sh

# Configure and build
emcmake cmake -G "Ninja" -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build

# Serve
python3 -m http.server -d build
```

## Runtime Backend Selection

The application automatically detects the best graphics backend for your platform:

### Automatic Selection
- **macOS**: Metal (preferred for performance)
- **Linux**: OpenGL
- **Windows**: OpenGL
- **WebAssembly**: OpenGL ES/WebGL

### Manual Selection
You can force a specific backend using command line arguments:

```bash
# Force OpenGL (available on all platforms)
./build/Debug/rive_tests --backend opengl

# Force Metal (macOS only)
./build/Debug/rive_tests --backend metal
```

### Controls
- **Space**: Pause/Resume animation
- **Window Resize**: Automatic scaling and centering

## Project Structure

```
├── src/
│   ├── main.cpp                 # Main application with multi-backend support
│   ├── graphics_backend.hpp     # Graphics backend interface
│   ├── graphics_backend.cpp     # Backend factory and detection
│   ├── opengl_backend.hpp       # OpenGL backend implementation
│   ├── opengl_backend.cpp       # OpenGL backend implementation
│   ├── metal_backend.hpp        # Metal backend implementation (macOS)
│   └── metal_backend.mm         # Metal backend implementation (macOS)
├── assets/
│   └── rive_files/
│       └── alien.riv            # Rive animation file
├── third_party/
│   ├── glad/                    # OpenGL function loader
│   ├── rive/                    # Rive animation runtime
│   ├── rive_renderer/           # Rive rendering engine (OpenGL/Metal)
│   └── rive_decoders/           # Rive image/media decoders
├── scripts/
│   ├── configure.sh             # CMake configuration
│   ├── build.sh                 # Build script with backend info
│   ├── run.sh                   # Run script with backend selection
│   └── clean.sh                 # Clean build artifacts
├── cmake/
│   └── FindRIVE.cmake          # Custom CMake module with Metal support
├── build/                       # Build output directory
├── web/
│   └── shell.html              # WebAssembly shell template
├── CMakeLists.txt              # Cross-platform CMake configuration
├── vcpkg.json                  # Dependencies manifest
└── README.md                   # This file
```

## Platform Detection

The CMake configuration automatically detects the target platform and configures accordingly:

- **Desktop** (`PLATFORM_DESKTOP`): Uses OpenGL or Metal
- **Mobile** (`PLATFORM_MOBILE`): Uses OpenGL ES
- **Web** (`PLATFORM_WEB`): Uses WebGL with `gladLoadGLES2Context`

## Dependencies

Managed by vcpkg:
- **SDL3**: Window management and input
- **glad**: OpenGL function loading
- **harfbuzz**: Text shaping
- **libpng**: PNG image support
- **libwebp**: WebP image support
- **yoga**: Layout engine
- **SheenBidi**: Bidirectional text support

Manually managed:
- **Rive Runtime**: Vector animation engine
- **Rive Renderer**: Multi-backend rendering (OpenGL/Metal)
- **Rive Decoders**: Image and media decoding

## Graphics Backend Architecture

The project uses a clean abstraction layer for graphics backends:

### Backend Interface
```cpp
class GraphicsBackendInterface {
    virtual bool initialize(void* window, int width, int height) = 0;
    virtual std::unique_ptr<rive::Renderer> createRenderer() = 0;
    // ... other methods
};
```

### Supported Backends
- **OpenGLBackend**: Cross-platform OpenGL 3.3+ support
- **MetalBackend**: Native Metal support for macOS (10.11+)

### Backend Selection
```cpp
// Automatic detection
GraphicsBackend backend = detectBestBackend();

// Manual selection
auto backend = createGraphicsBackend(GraphicsBackend::Metal);
```

## Development

### Adding New Dependencies

1. Add to `vcpkg.json`:
```json
{
  "dependencies": [
    "sdl3",
    "glad",
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

### Graphics Backend Development

To add a new graphics backend:

1. Create `new_backend.hpp` and `new_backend.cpp`
2. Implement `GraphicsBackendInterface`
3. Add to `createGraphicsBackend()` factory
4. Update CMake configuration
5. Update platform detection in `detectBestBackend()`

## Performance Notes

### Metal vs OpenGL on macOS
- **Metal**: Generally provides better performance and lower CPU overhead
- **OpenGL**: More compatible, easier to debug
- **Recommendation**: Use Metal for production, OpenGL for development/debugging

### Backend-Specific Optimizations
- **Metal**: Leverages Apple's optimized graphics pipeline
- **OpenGL**: Cross-platform compatibility with good performance

## Troubleshooting

### General Issues
- **vcpkg Issues**: Ensure `VCPKG_ROOT` environment variable is set
- **Build Issues**: Clean build directory with `./scripts/clean.sh`
- **Backend Selection**: Check console output for backend detection messages

### Metal-Specific Issues (macOS)
- **Metal Not Available**: Ensure macOS 10.11+ and compatible graphics hardware
- **ARC Issues**: Metal backend uses Automatic Reference Counting (enabled automatically)
- **Framework Issues**: Ensure Metal and QuartzCore frameworks are linked

### OpenGL-Specific Issues
- **GLAD Loading**: Verify OpenGL context creation before GLAD initialization
- **Version Issues**: Ensure graphics drivers support OpenGL 3.3+
- **Context Issues**: Check OpenGL context creation on window resize

### WebAssembly Issues
- **Build Requirements**: Ensure Emscripten SDK is activated before building
- **Serving**: WebAssembly files must be served via HTTP server
- **Performance**: WebGL performance varies by browser and hardware

## License

MIT License - See LICENSE file for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new graphics backends
4. Ensure cross-platform compatibility
5. Submit a pull request

## Acknowledgments

- **Rive**: Vector animation runtime and rendering engine
- **SDL3**: Cross-platform window management
- **YUP Framework**: Graphics backend architecture inspiration
- **vcpkg**: Dependency management
- **GLAD**: OpenGL function loading
