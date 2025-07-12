# FindRIVE.cmake
# ============================================================================
# CMake Find Module for Rive
# Following YUP module system patterns for platform-specific builds
#
# Usage:
#   find_package(RIVE REQUIRED)
#   target_link_libraries(your_target PRIVATE RIVE::rive RIVE::renderer RIVE::decoders)
#
# This module defines the following IMPORTED targets:
#   RIVE::rive       - Core Rive library
#   RIVE::renderer   - Rive renderer (platform-specific)
#   RIVE::decoders   - Rive image decoders
#
# Variables:
#   RIVE_FOUND              - True if Rive is found
#   RIVE_INCLUDE_DIRS       - Include directories for Rive
#   RIVE_LIBRARIES          - Libraries to link against
#   RIVE_THIRDPARTY_DIR     - Directory containing Rive source (can be set by user)
# ============================================================================

# Allow user to specify the thirdparty directory
if(NOT RIVE_THIRDPARTY_DIR)
    set(_rive_search_paths
        "${CMAKE_CURRENT_SOURCE_DIR}/third_party"
        "${CMAKE_SOURCE_DIR}/third_party"
    )

    foreach(_path ${_rive_search_paths})
        if(EXISTS "${_path}/rive/rive.h")
            set(RIVE_THIRDPARTY_DIR "${_path}")
            break()
        endif()
    endforeach()
endif()

# Check if we found the source
if(NOT RIVE_THIRDPARTY_DIR OR NOT EXISTS "${RIVE_THIRDPARTY_DIR}/rive/rive.h")
    if(RIVE_FIND_REQUIRED)
        message(FATAL_ERROR "Could not find Rive source directory. Please set RIVE_THIRDPARTY_DIR to the directory containing the rive folder.")
    else()
        set(RIVE_FOUND FALSE)
        return()
    endif()
endif()

# Platform detection (following YUP pattern)
if(EMSCRIPTEN)
    set(RIVE_PLATFORM_WEB TRUE)
    set(RIVE_PLATFORM_NAME "emscripten")
elseif(WIN32)
    set(RIVE_PLATFORM_WINDOWS TRUE)
    set(RIVE_PLATFORM_DESKTOP TRUE)
    set(RIVE_PLATFORM_NAME "windows")
elseif(APPLE)
    set(RIVE_PLATFORM_APPLE TRUE)
    set(RIVE_PLATFORM_DESKTOP TRUE)
    if(IOS)
        set(RIVE_PLATFORM_IOS TRUE)
        set(RIVE_PLATFORM_MOBILE TRUE)
        set(RIVE_PLATFORM_NAME "ios")
    else()
        set(RIVE_PLATFORM_MACOS TRUE)
        set(RIVE_PLATFORM_NAME "macos")
    endif()
elseif(ANDROID)
    set(RIVE_PLATFORM_ANDROID TRUE)
    set(RIVE_PLATFORM_MOBILE TRUE)
    set(RIVE_PLATFORM_NAME "android")
elseif(UNIX)
    set(RIVE_PLATFORM_LINUX TRUE)
    set(RIVE_PLATFORM_DESKTOP TRUE)
    set(RIVE_PLATFORM_NAME "linux")
endif()

# Function to collect source files (RESTORE the original filtering logic)
function(_rive_collect_sources base_path output_var)
    file(GLOB_RECURSE all_sources
        "${base_path}/*.cpp"
        "${base_path}/*.c"
        "${base_path}/*.mm"
        "${base_path}/*.m"
    )

    set(filtered_sources "")
    foreach(source ${all_sources})
        set(include_file TRUE)

        # Platform-specific filtering (RESTORE original logic)
        if(NOT RIVE_PLATFORM_WINDOWS AND source MATCHES "_windows\\.(cpp|c|mm|m)$")
            set(include_file FALSE)
        endif()
        if(NOT RIVE_PLATFORM_APPLE AND source MATCHES "_apple\\.(cpp|c|mm|m)$")
            set(include_file FALSE)
        endif()
        if(NOT RIVE_PLATFORM_MACOS AND source MATCHES "_osx\\.(cpp|c|mm|m)$")
            set(include_file FALSE)
        endif()
        if(NOT RIVE_PLATFORM_MACOS AND source MATCHES "_mac\\.(cpp|c|mm|m)$")
            set(include_file FALSE)
        endif()
        if(NOT RIVE_PLATFORM_IOS AND source MATCHES "_ios\\.(cpp|c|mm|m)$")
            set(include_file FALSE)
        endif()
        if(NOT RIVE_PLATFORM_LINUX AND source MATCHES "_linux\\.(cpp|c|mm|m)$")
            set(include_file FALSE)
        endif()
        if(NOT RIVE_PLATFORM_MOBILE AND source MATCHES "_mobile\\.(cpp|c|mm|m)$")
            set(include_file FALSE)
        endif()
        if(NOT RIVE_PLATFORM_WEB AND source MATCHES "_emscripten\\.(cpp|c|mm|m)$")
            set(include_file FALSE)
        endif()
        if(NOT RIVE_PLATFORM_WEB AND source MATCHES "_wasm\\.(cpp|c|mm|m)$")
            set(include_file FALSE)
        endif()
        
        # EXTEND with additional Apple-specific filtering for web builds
        if(RIVE_PLATFORM_WEB AND source MATCHES "font_hb_apple\\.mm$")
            set(include_file FALSE)
        endif()
        
        # EXTEND with additional filtering for files that shouldn't be in web builds
        if(RIVE_PLATFORM_WEB AND source MATCHES "(coretext|metal|d3d)")
            set(include_file FALSE)
        endif()

        if(include_file)
            list(APPEND filtered_sources ${source})
        endif()
    endforeach()

    set(${output_var} ${filtered_sources} PARENT_SCOPE)
endfunction()

# Only create targets if they don't already exist
if(NOT TARGET RIVE::rive)
    # Core Rive Library
    set(rive_dir "${RIVE_THIRDPARTY_DIR}/rive")
    _rive_collect_sources("${rive_dir}/source" rive_sources)

    add_library(RIVE_rive STATIC ${rive_sources})
    add_library(RIVE::rive ALIAS RIVE_rive)

    target_compile_features(RIVE_rive PUBLIC cxx_std_17)

    target_include_directories(RIVE_rive PUBLIC
        "${rive_dir}/include"
        "${rive_dir}"
    )

    # Platform-specific defines (following YUP pattern)
    target_compile_definitions(RIVE_rive PUBLIC
        WITH_RIVE_TEXT=1
        WITH_RIVE_YOGA=1
        WITH_RIVE_LAYOUT=1
        _RIVE_INTERNAL_=1
    )

    # Platform-specific settings
    if(RIVE_PLATFORM_APPLE)
        target_link_libraries(RIVE_rive PUBLIC "-framework CoreText")
        if(RIVE_PLATFORM_MACOS)
            set_target_properties(RIVE_rive PROPERTIES
                XCODE_ATTRIBUTE_CLANG_ENABLE_OBJC_ARC YES
            )
        endif()
    endif()

    # Dependencies
    find_package(harfbuzz CONFIG REQUIRED)
    target_link_libraries(RIVE_rive PUBLIC harfbuzz::harfbuzz)

    if(APPLE AND NOT EMSCRIPTEN)
        # Optionally check for coretext support
        find_library(CORETEXT_LIBRARY CoreText)
        if(CORETEXT_LIBRARY)
            target_link_libraries(RIVE_rive PRIVATE ${CORETEXT_LIBRARY})
        endif()
    endif()

    # SheenBidi - try to find it
    find_package(SheenBidi QUIET)
    if(SheenBidi_FOUND)
        target_link_libraries(RIVE_rive PUBLIC SheenBidi::SheenBidi)
    endif()

    find_package(yoga QUIET)
    if(yoga_FOUND)
        if(TARGET yoga::yogacore)
            target_link_libraries(RIVE_rive PUBLIC yoga::yogacore)
        elseif(TARGET yoga::yoga)
            target_link_libraries(RIVE_rive PUBLIC yoga::yoga)
        endif()
    endif()
endif()

if(NOT TARGET RIVE::decoders)
    # Rive Decoders
    set(rive_decoders_dir "${RIVE_THIRDPARTY_DIR}/rive_decoders")
    _rive_collect_sources("${rive_decoders_dir}/source" rive_decoders_sources)

    add_library(RIVE_decoders STATIC ${rive_decoders_sources})
    add_library(RIVE::decoders ALIAS RIVE_decoders)

    target_include_directories(RIVE_decoders PUBLIC
        "${rive_decoders_dir}/include"
        "${rive_decoders_dir}"
    )

    # RESTORE: Create compatibility headers for image libraries
    # Create a compatibility header for libpng
    set(LIBPNG_COMPAT_DIR "${CMAKE_CURRENT_BINARY_DIR}/libpng_compat")
    file(MAKE_DIRECTORY "${LIBPNG_COMPAT_DIR}/libpng")
    file(WRITE "${LIBPNG_COMPAT_DIR}/libpng/libpng.h" "#include <png.h>\n")
    target_include_directories(RIVE_decoders PRIVATE "${LIBPNG_COMPAT_DIR}")

    # Create a compatibility header for libwebp
    set(LIBWEBP_COMPAT_DIR "${CMAKE_CURRENT_BINARY_DIR}/libwebp_compat")
    file(MAKE_DIRECTORY "${LIBWEBP_COMPAT_DIR}/libwebp")
    file(WRITE "${LIBWEBP_COMPAT_DIR}/libwebp/libwebp.h"
"#include <webp/decode.h>
#include <webp/demux.h>
#include <webp/encode.h>
#include <webp/mux.h>
")
    target_include_directories(RIVE_decoders PRIVATE "${LIBWEBP_COMPAT_DIR}")

    target_compile_definitions(RIVE_decoders PUBLIC
        _RIVE_INTERNAL_=1
    )

    # Image format support
    find_package(PNG QUIET)
    find_package(WebP QUIET)

    if(PNG_FOUND)
        target_compile_definitions(RIVE_decoders PUBLIC RIVE_PNG=1)
        target_link_libraries(RIVE_decoders PUBLIC PNG::PNG)
    endif()

    if(WebP_FOUND)
        target_compile_definitions(RIVE_decoders PUBLIC RIVE_WEBP=1)
        target_link_libraries(RIVE_decoders PUBLIC WebP::webp)
    endif()

    # Platform-specific settings
    if(RIVE_PLATFORM_APPLE)
        target_link_libraries(RIVE_decoders PUBLIC "-framework ImageIO")
        set_target_properties(RIVE_decoders PROPERTIES
            XCODE_ATTRIBUTE_CLANG_ENABLE_OBJC_ARC YES
        )
    endif()

    target_link_libraries(RIVE_decoders PUBLIC RIVE::rive)
endif()

if(NOT TARGET RIVE::renderer)
    # Rive Renderer - using YUP pattern with platform-specific files
    set(rive_renderer_dir "${RIVE_THIRDPARTY_DIR}/rive_renderer")
    
    # Use platform-specific source files (following YUP pattern exactly)
    set(rive_renderer_sources "")
    
    # Common sources (always included)
    list(APPEND rive_renderer_sources "${rive_renderer_dir}/rive_renderer.cpp")
    
    # Platform-specific renderer sources (following YUP module pattern)
    if(RIVE_PLATFORM_WEB)
        list(APPEND rive_renderer_sources "${rive_renderer_dir}/rive_renderer_emscripten.cpp")
    elseif(RIVE_PLATFORM_WINDOWS)
        list(APPEND rive_renderer_sources "${rive_renderer_dir}/rive_renderer_windows.cpp")
    elseif(RIVE_PLATFORM_APPLE)
        list(APPEND rive_renderer_sources "${rive_renderer_dir}/rive_renderer_apple.mm")
    elseif(RIVE_PLATFORM_ANDROID)
        list(APPEND rive_renderer_sources "${rive_renderer_dir}/rive_renderer_android.cpp")
    elseif(RIVE_PLATFORM_LINUX)
        list(APPEND rive_renderer_sources "${rive_renderer_dir}/rive_renderer_linux.cpp")
    endif()

    add_library(RIVE_renderer STATIC ${rive_renderer_sources})
    add_library(RIVE::renderer ALIAS RIVE_renderer)

    target_compile_features(RIVE_renderer PUBLIC cxx_std_17)

    # Include directories (following YUP searchpaths pattern)
    # YUP searchpaths: include source source/generated/shaders
    target_include_directories(RIVE_renderer PUBLIC
        "${RIVE_THIRDPARTY_DIR}"                                    # Makes rive_renderer/source/... work
        "${rive_renderer_dir}/include"                              # YUP searchpath: include
        "${rive_renderer_dir}/source"                               # YUP searchpath: source  
        "${rive_renderer_dir}/source/generated/shaders"            # YUP searchpath: source/generated/shaders
        "${rive_renderer_dir}"                                      # Base directory
    )

    # Platform-specific defines (following YUP pattern)
    target_compile_definitions(RIVE_renderer PUBLIC
        WITH_RIVE_TEXT=1
        RIVE_DECODERS=1
        _RIVE_INTERNAL_=1
    )

    # Platform-specific defines (following YUP module pattern)
    if(RIVE_PLATFORM_WEB)
        target_compile_definitions(RIVE_renderer PUBLIC RIVE_WEBGL=1)
    elseif(RIVE_PLATFORM_DESKTOP AND NOT RIVE_PLATFORM_APPLE)
        # Enable OpenGL for non-Apple desktop platforms (Windows, Linux)
        target_compile_definitions(RIVE_renderer PUBLIC 
            RIVE_DESKTOP_GL=1
            YUP_RIVE_USE_OPENGL=1
        )
        
        # GLAD dependency for desktop platforms
        find_package(GLAD QUIET)
        if(GLAD_FOUND AND TARGET GLAD::GLAD)
            target_link_libraries(RIVE_renderer PUBLIC GLAD::GLAD)
            message(STATUS "Using GLAD::GLAD from FindGlad.cmake")
        endif()
    endif()

    # Platform-specific frameworks and libraries (following YUP pattern)
    if(RIVE_PLATFORM_APPLE)
        target_compile_definitions(RIVE_renderer PUBLIC YUP_RIVE_USE_METAL=1)
        target_link_libraries(RIVE_renderer PUBLIC
            "-framework Metal"
            "-framework QuartzCore"
        )
        set_target_properties(RIVE_renderer PROPERTIES
            XCODE_ATTRIBUTE_CLANG_ENABLE_OBJC_ARC YES
        )
    elseif(RIVE_PLATFORM_ANDROID)
        target_compile_definitions(RIVE_renderer PUBLIC RIVE_ANDROID=1)
        target_link_libraries(RIVE_renderer PUBLIC EGL GLESv3)
    elseif(RIVE_PLATFORM_WINDOWS)
        target_compile_definitions(RIVE_renderer PUBLIC YUP_RIVE_USE_D3D=1)
        target_link_libraries(RIVE_renderer PUBLIC d3d11 d3dcompiler dxgi)
    endif()

    # Link dependencies
    target_link_libraries(RIVE_renderer PUBLIC
        RIVE::rive
        RIVE::decoders
    )
endif()

# Set up the standard CMake variables
set(RIVE_INCLUDE_DIRS
    "${RIVE_THIRDPARTY_DIR}"                                    # Makes rive_renderer/source/... work
    "${RIVE_THIRDPARTY_DIR}/rive/include"
    "${RIVE_THIRDPARTY_DIR}/rive_renderer/include"
    "${RIVE_THIRDPARTY_DIR}/rive_decoders/include"
)

set(RIVE_LIBRARIES RIVE::rive RIVE::renderer RIVE::decoders)

# Use FindPackageHandleStandardArgs to set RIVE_FOUND
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(RIVE
    REQUIRED_VARS RIVE_THIRDPARTY_DIR
    VERSION_VAR "1.0"
)

# Set variables in parent scope if found and parent scope exists
if(RIVE_FOUND AND CMAKE_CURRENT_FUNCTION)
    set(RIVE_INCLUDE_DIRS ${RIVE_INCLUDE_DIRS} PARENT_SCOPE)
    set(RIVE_LIBRARIES ${RIVE_LIBRARIES} PARENT_SCOPE)
    set(RIVE_THIRDPARTY_DIR ${RIVE_THIRDPARTY_DIR} PARENT_SCOPE)
endif()

mark_as_advanced(RIVE_THIRDPARTY_DIR)
