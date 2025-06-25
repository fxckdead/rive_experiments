cmake_minimum_required(VERSION 3.20)

# Set toolchain before project() if using vcpkg
if(NOT DEFINED CMAKE_TOOLCHAIN_FILE AND NOT EMSCRIPTEN)
  set(CMAKE_TOOLCHAIN_FILE "$ENV{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake" CACHE STRING "Vcpkg toolchain")
endif()

project(rive_tests C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

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
    # No need to find SDL3 package
else()
    # For other platforms, use vcpkg SDL3
    find_package(SDL3 CONFIG REQUIRED)
endif()

# Add glad manually (since it's not installed via vcpkg)
add_library(glad STATIC
    third_party/glad/src/gl.c
)

# Platform-specific OpenGL setup
if(PLATFORM_DESKTOP)
    find_package(OpenGL REQUIRED)
    set(GL_LIBS OpenGL::GL)
elseif(PLATFORM_MOBILE OR PLATFORM_WEB)
    # Mobile and Web use OpenGL ES
    set(GL_LIBS "")  # GLES is handled by platform
    target_compile_definitions(glad PUBLIC GLAD_GLES2)
    
    if(PLATFORM_WEB)
        # Emscripten-specific settings
        target_compile_definitions(glad PUBLIC GLAD_GLES2_IMPLEMENTATION)
    endif()
endif()

# Add EGL source only for platforms that need it
if(PLATFORM_MOBILE)
    target_sources(glad PRIVATE third_party/glad/src/egl.c)
    target_compile_definitions(glad PUBLIC GLAD_EGL)
endif()

add_executable(rive_tests src/main.cpp)

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

# Include directories
target_include_directories(glad PUBLIC third_party/glad/include)
set_target_properties(glad PROPERTIES LINKER_LANGUAGE C)

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
    target_link_libraries(rive_tests
        PRIVATE
            glad
    )
else()
    target_link_libraries(rive_tests
        PRIVATE
            SDL3::SDL3
            ${GL_LIBS}
            glad
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
