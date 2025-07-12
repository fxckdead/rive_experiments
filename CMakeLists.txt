cmake_minimum_required(VERSION 3.20)

# Set toolchain before project() if using vcpkg
if(NOT DEFINED CMAKE_TOOLCHAIN_FILE)
  set(CMAKE_TOOLCHAIN_FILE "$ENV{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake" CACHE STRING "Vcpkg toolchain")
endif()

project(rive_tests C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Tell CMake where to find our custom FindTMXLITE.cmake module.
# set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake ${CMAKE_MODULE_PATH})
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

# Enable folders in IDEs like Visual Studio
set_property(GLOBAL PROPERTY USE_FOLDERS ON)

# Platform detection
if(EMSCRIPTEN)
    set(PLATFORM_WEB TRUE)
    message(STATUS "Building for WebAssembly/Emscripten")
elseif(ANDROID)
    set(PLATFORM_MOBILE TRUE)
    message(STATUS "Building for Android")
elseif(IOS)
    set(PLATFORM_MOBILE TRUE)
    message(STATUS "Building for iOS")
elseif(WIN32)
    set(PLATFORM_DESKTOP TRUE)
    message(STATUS "Building for Windows")
elseif(APPLE)
    set(PLATFORM_DESKTOP TRUE)
    message(STATUS "Building for macOS")
elseif(UNIX)
    set(PLATFORM_DESKTOP TRUE)
    message(STATUS "Building for Linux")
else()
    message(WARNING "Unknown platform, assuming desktop")
    set(PLATFORM_DESKTOP TRUE)
endif()

# Dependencies
if(PLATFORM_WEB)
    # For Emscripten, we'll use the built-in SDL support
    # But we still need other packages for Rive decoders
    find_package(harfbuzz CONFIG REQUIRED)
    find_package(PNG REQUIRED)
    find_package(WebP CONFIG REQUIRED)
    find_package(yoga CONFIG REQUIRED)
    find_package(SheenBidi REQUIRED)
else()
    # For other platforms, use vcpkg packages
    find_package(SDL3 CONFIG REQUIRED)
    find_package(harfbuzz CONFIG REQUIRED)
    find_package(PNG REQUIRED)
    find_package(WebP CONFIG REQUIRED)
    find_package(yoga CONFIG REQUIRED)
    find_package(SheenBidi REQUIRED)
    find_package(GLAD REQUIRED)
endif()

find_package(RIVE REQUIRED)

# Platform-specific OpenGL setup
if(PLATFORM_DESKTOP)
    find_package(OpenGL REQUIRED)
    set(GL_LIBS OpenGL::GL)
elseif(PLATFORM_MOBILE OR PLATFORM_WEB)
    # Mobile and Web use OpenGL ES
    set(GL_LIBS "")  # GLES is handled by platform
endif()

# Graphics backend source files
set(GRAPHICS_BACKEND_SOURCES
    src/graphics_backend.hpp
    src/opengl_backend.cpp
    src/opengl_backend.hpp
)

# Add Metal backend on Apple platforms
if(APPLE)
    list(APPEND GRAPHICS_BACKEND_SOURCES
        src/graphics_backend.mm
        src/metal_backend.mm
        src/metal_backend.hpp
    )
else()
    list(APPEND GRAPHICS_BACKEND_SOURCES
        src/graphics_backend.cpp
    )
endif()

add_executable(rive_tests
    src/main.cpp
    ${GRAPHICS_BACKEND_SOURCES}
)

# Add Rive include directories to the main target
target_include_directories(rive_tests PRIVATE ${RIVE_INCLUDE_DIRS})

# Platform-specific executable properties
if(PLATFORM_WEB)
    # Emscripten-specific settings
    set_target_properties(rive_tests PROPERTIES
        SUFFIX ".html"
        OUTPUT_NAME "index"
    )
    target_compile_options(rive_tests PRIVATE
        "SHELL:-s USE_SDL=3"
    )
    target_link_options(rive_tests PRIVATE
        "SHELL:-s USE_SDL=3"
        "SHELL:-s USE_WEBGL2=1"
        "SHELL:-s FULL_ES3=1"
        "SHELL:-s WASM=1"
        "SHELL:-s ALLOW_MEMORY_GROWTH=1"
        "SHELL:-s EXPORTED_FUNCTIONS=['_main']"
        "SHELL:-s EXPORTED_RUNTIME_METHODS=['ccall','cwrap']"
        "SHELL:--shell-file=${CMAKE_SOURCE_DIR}/web/shell.html"
        "SHELL:--preload-file=${CMAKE_SOURCE_DIR}/assets@/assets"
    )
elseif(PLATFORM_MOBILE)
    if(IOS)
        set_target_properties(rive_tests PROPERTIES
            MACOSX_BUNDLE TRUE
            MACOSX_BUNDLE_GUI_IDENTIFIER "com.example.rivetests"
            MACOSX_BUNDLE_BUNDLE_VERSION "1.0"
            MACOSX_BUNDLE_SHORT_VERSION_STRING "1.0"
        )
    endif()
endif()

# Platform-specific preprocessor definitions
if(PLATFORM_WEB)
    target_compile_definitions(rive_tests PRIVATE PLATFORM_WEB)
elseif(PLATFORM_MOBILE)
    target_compile_definitions(rive_tests PRIVATE PLATFORM_MOBILE)
    if(ANDROID)
        target_compile_definitions(rive_tests PRIVATE PLATFORM_ANDROID)
    elseif(IOS)
        target_compile_definitions(rive_tests PRIVATE PLATFORM_IOS)
    endif()
elseif(PLATFORM_DESKTOP)
    target_compile_definitions(rive_tests PRIVATE PLATFORM_DESKTOP)
endif()

# Link libraries
if(PLATFORM_WEB)
    # For Emscripten, SDL is handled via link options
    # But we need image libraries for Rive decoders
    target_link_libraries(rive_tests
        PRIVATE
            RIVE::rive
            RIVE::renderer
            RIVE::decoders
            SheenBidi::SheenBidi
            harfbuzz::harfbuzz
            PNG::PNG
            WebP::webp
            WebP::webpdemux
            WebP::libwebpmux
            WebP::webpdecoder
            yoga::yogacore
    )
else()
    target_link_libraries(rive_tests
        PRIVATE
            SDL3::SDL3
            ${GL_LIBS}
            GLAD::GLAD
            harfbuzz::harfbuzz
            PNG::PNG
            WebP::webpdemux
            WebP::libwebpmux
            WebP::webpdecoder
            WebP::webp
            yoga::yogacore
            RIVE::rive
            RIVE::renderer
            RIVE::decoders
            SheenBidi::SheenBidi
    )
endif()

# Apple-specific frameworks for Metal support
if(APPLE)
    target_link_libraries(rive_tests
        PRIVATE
            "-framework Metal"
            "-framework QuartzCore"
            "-framework Cocoa"
    )
endif()

# Platform-specific compiler flags
if(PLATFORM_DESKTOP)
    if(MSVC)
        target_compile_options(rive_tests PRIVATE /W4)
    else()
        target_compile_options(rive_tests PRIVATE -Wall -Wextra -Wpedantic)
    endif()
endif()

# Install configuration
if(NOT PLATFORM_WEB AND NOT PLATFORM_MOBILE)
    install(TARGETS rive_tests
        RUNTIME DESTINATION bin
    )
endif()
