# FindRIVE.cmake
# ============================================================================
# CMake Find Module for Rive
# This module finds and configures the Rive animation library
#
# Usage:
#   find_package(RIVE REQUIRED)
#   target_link_libraries(your_target PRIVATE RIVE::rive RIVE::renderer RIVE::decoders)
#
# This module defines the following IMPORTED targets:
#   RIVE::rive       - Core Rive library
#   RIVE::renderer   - Rive OpenGL renderer
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
    # Try to find it relative to common locations
    set(_rive_search_paths
        "${CMAKE_CURRENT_SOURCE_DIR}/thirdparty"
        "${CMAKE_CURRENT_SOURCE_DIR}/../thirdparty"
        "${CMAKE_SOURCE_DIR}/thirdparty"
        "${CMAKE_SOURCE_DIR}/third_party"
        "${CMAKE_SOURCE_DIR}/extern"
        "${CMAKE_SOURCE_DIR}/external"
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

# Platform detection (same as before)
if(WIN32)
    set(RIVE_PLATFORM_WINDOWS TRUE)
    set(RIVE_PLATFORM_DESKTOP TRUE)
elseif(APPLE)
    set(RIVE_PLATFORM_APPLE TRUE)
    set(RIVE_PLATFORM_DESKTOP TRUE)
    if(IOS)
        set(RIVE_PLATFORM_IOS TRUE)
        set(RIVE_PLATFORM_MOBILE TRUE)
    else()
        set(RIVE_PLATFORM_MACOS TRUE)
    endif()
elseif(UNIX)
    set(RIVE_PLATFORM_LINUX TRUE)
    set(RIVE_PLATFORM_DESKTOP TRUE)
elseif(EMSCRIPTEN)
    set(RIVE_PLATFORM_WEB TRUE)
endif()

# Function to collect source files (same as before)
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

        # Platform-specific filtering
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

    # SheenBidi - try to find it
    find_package(SheenBidi QUIET)
    if(SheenBidi_FOUND)
        target_link_libraries(RIVE_rive PUBLIC SheenBidi::SheenBidi)
    else()
        # Try pkg-config as fallback
        find_package(PkgConfig QUIET)
        if(PkgConfig_FOUND)
            pkg_check_modules(SHEENBIDI QUIET sheenbidi)
            if(SHEENBIDI_FOUND)
                target_link_libraries(RIVE_rive PUBLIC ${SHEENBIDI_LIBRARIES})
                target_include_directories(RIVE_rive PUBLIC ${SHEENBIDI_INCLUDE_DIRS})
            else()
                message(WARNING "SheenBidi not found. Text bidirectional support may be limited.")
            endif()
        endif()
    endif()

    # Yoga - try to find it with different target names
    find_package(yoga QUIET)
    if(yoga_FOUND)
        # Check which target is available
        if(TARGET yoga::yogacore)
            target_link_libraries(RIVE_rive PUBLIC yoga::yogacore)
        elseif(TARGET yoga::yoga)
            target_link_libraries(RIVE_rive PUBLIC yoga::yoga)
        else()
            message(WARNING "Yoga found but no recognized target available.")
        endif()
    else()
        message(WARNING "Yoga layout engine not found. Layout features may be limited.")
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

    # Add this section to handle libpng compatibility:
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

    # Base compiler definitions for decoders
    target_compile_definitions(RIVE_decoders PUBLIC
        _RIVE_INTERNAL_=1
    )

    # Optional image format support
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

    # Add this missing dependency:
    target_link_libraries(RIVE_decoders PUBLIC RIVE::rive)
endif()

if(NOT TARGET RIVE::renderer)
    # Rive Renderer
    set(rive_renderer_dir "${RIVE_THIRDPARTY_DIR}/rive_renderer")
    _rive_collect_sources("${rive_renderer_dir}/source" rive_renderer_sources)

    # Platform-specific filtering for renderer backends
    set(filtered_renderer_sources "")
    foreach(source ${rive_renderer_sources})
        set(include_source TRUE)

        # Platform-specific backend filtering
        if(RIVE_PLATFORM_WINDOWS)
            # On Windows: exclude Metal, WebGPU (keep D3D, OpenGL, Vulkan)
            if(source MATCHES "/metal/" OR source MATCHES "/webgpu/")
                set(include_source FALSE)
            endif()
        elseif(RIVE_PLATFORM_APPLE)
            # On Apple: exclude D3D, Vulkan, WebGPU (keep Metal, OpenGL)
            if(source MATCHES "/d3d/" OR source MATCHES "/d3d11/" OR source MATCHES "/d3d12/" OR
               source MATCHES "/vulkan/" OR source MATCHES "/webgpu/")
                set(include_source FALSE)
            endif()
        elseif(RIVE_PLATFORM_LINUX)
            # On Linux: exclude D3D, Metal, WebGPU (keep OpenGL, Vulkan)
            if(source MATCHES "/d3d/" OR source MATCHES "/d3d11/" OR source MATCHES "/d3d12/" OR
               source MATCHES "/metal/" OR source MATCHES "/webgpu/")
                set(include_source FALSE)
            endif()
        elseif(RIVE_PLATFORM_WEB)
            # On Web: exclude D3D, Metal, Vulkan (keep WebGPU, OpenGL ES)
            if(source MATCHES "/d3d/" OR source MATCHES "/d3d11/" OR source MATCHES "/d3d12/" OR
               source MATCHES "/metal/" OR source MATCHES "/vulkan/")
                set(include_source FALSE)
            endif()
        endif()

        # Include if not excluded
        if(include_source)
            list(APPEND filtered_renderer_sources ${source})
        endif()
    endforeach()

    add_library(RIVE_renderer STATIC ${filtered_renderer_sources})
    add_library(RIVE::renderer ALIAS RIVE_renderer)

    target_compile_features(RIVE_renderer PUBLIC cxx_std_17)

    target_include_directories(RIVE_renderer PUBLIC
        "${rive_renderer_dir}/include"
        "${rive_renderer_dir}/source"
        "${rive_renderer_dir}/source/generated/shaders"
        "${rive_renderer_dir}"
    )

    # Create glad_custom.h compatibility header for ALL desktop platforms
    if(RIVE_PLATFORM_DESKTOP)
        set(GLAD_COMPAT_DIR "${CMAKE_CURRENT_BINARY_DIR}/glad_compat")
        file(MAKE_DIRECTORY "${GLAD_COMPAT_DIR}")
        file(WRITE "${GLAD_COMPAT_DIR}/glad_custom.h"
"#pragma once
#include <glad/glad.h>

// Ensure we have the same defines that Rive expects
#ifndef GLAPIENTRY
#define GLAPIENTRY APIENTRY
#endif

#ifndef GL_APIENTRY
#define GL_APIENTRY GLAPIENTRY
#endif

// Define missing ANGLE provoking vertex extension
#ifndef GL_ANGLE_provoking_vertex
#define GL_ANGLE_provoking_vertex 1
#define GL_FIRST_VERTEX_CONVENTION_ANGLE 0x8E4D
#define GL_LAST_VERTEX_CONVENTION_ANGLE 0x8E4E
#define GL_PROVOKING_VERTEX_ANGLE 0x8E4F
// Declare the function as a no-op for desktop GL
static inline void glProvokingVertexANGLE(GLenum provokeMode) { (void)provokeMode; }
#endif

// Define missing ANGLE polygon mode extension
#ifndef GL_ANGLE_polygon_mode
#define GL_ANGLE_polygon_mode 1
#define GL_FILL_ANGLE 0x1B02
#define GL_LINE_ANGLE 0x1B01
#define GL_POINT_ANGLE 0x1B00
static inline void glPolygonModeANGLE(GLenum face, GLenum mode) { (void)face; (void)mode; }
#endif

// Define missing EXT clip cull distance extension
#ifndef GL_EXT_clip_cull_distance
#define GL_EXT_clip_cull_distance 1
#define GL_CLIP_DISTANCE0_EXT 0x3000
#define GL_CLIP_DISTANCE1_EXT 0x3001
#define GL_CLIP_DISTANCE2_EXT 0x3002
#define GL_CLIP_DISTANCE3_EXT 0x3003
#define GL_CLIP_DISTANCE4_EXT 0x3004
#define GL_CLIP_DISTANCE5_EXT 0x3005
#define GL_CLIP_DISTANCE6_EXT 0x3006
#define GL_CLIP_DISTANCE7_EXT 0x3007
#endif

// Define missing ANGLE shader pixel local storage extension
#ifndef GL_ANGLE_shader_pixel_local_storage
#define GL_ANGLE_shader_pixel_local_storage 1
#define GL_MAX_PIXEL_LOCAL_STORAGE_PLANES_ANGLE 0x96E0
#define GL_MAX_COMBINED_DRAW_BUFFERS_AND_PIXEL_LOCAL_STORAGE_PLANES_ANGLE 0x96E1
#define GL_PIXEL_LOCAL_STORAGE_ACTIVE_PLANES_ANGLE 0x96E2
#define GL_LOAD_OP_ZERO_ANGLE 0x96E3
#define GL_LOAD_OP_CLEAR_ANGLE 0x96E4
#define GL_LOAD_OP_LOAD_ANGLE 0x96E5
#define GL_STORE_OP_STORE_ANGLE 0x96E6
#define GL_PIXEL_LOCAL_FORMAT_ANGLE 0x96E7
#define GL_PIXEL_LOCAL_TEXTURE_NAME_ANGLE 0x96E8
#define GL_PIXEL_LOCAL_TEXTURE_LEVEL_ANGLE 0x96E9
#define GL_PIXEL_LOCAL_TEXTURE_LAYER_ANGLE 0x96EA
#define GL_PIXEL_LOCAL_CLEAR_VALUE_FLOAT_ANGLE 0x96EB
#define GL_PIXEL_LOCAL_CLEAR_VALUE_INT_ANGLE 0x96EC
#define GL_PIXEL_LOCAL_CLEAR_VALUE_UNSIGNED_INT_ANGLE 0x96ED

// Declare no-op functions for desktop GL
static inline void glFramebufferTexturePixelLocalStorageANGLE(GLint plane, GLuint backingtexture, GLint level, GLint layer) {
    (void)plane; (void)backingtexture; (void)level; (void)layer;
}
static inline void glFramebufferPixelLocalClearValuefvANGLE(GLint plane, const GLfloat value[4]) {
    (void)plane; (void)value;
}
static inline void glBeginPixelLocalStorageANGLE(GLsizei n, const GLenum loadops[]) {
    (void)n; (void)loadops;
}
static inline void glEndPixelLocalStorageANGLE(GLsizei n, const GLenum storeops[]) {
    (void)n; (void)storeops;
}
static inline void glGetFramebufferPixelLocalStorageParameterivANGLE(GLint plane, GLenum pname, GLint* param) {
    (void)plane; (void)pname; if(param) *param = 0;
}
#endif

// Define missing KHR blend equation advanced constants
#ifndef GL_KHR_blend_equation_advanced
#define GL_KHR_blend_equation_advanced 1
#define GL_MULTIPLY_KHR 0x9294
#define GL_SCREEN_KHR 0x9295
#define GL_OVERLAY_KHR 0x9296
#define GL_DARKEN_KHR 0x9297
#define GL_LIGHTEN_KHR 0x9298
#define GL_COLORDODGE_KHR 0x9299
#define GL_COLORBURN_KHR 0x929A
#define GL_HARDLIGHT_KHR 0x929B
#define GL_SOFTLIGHT_KHR 0x929C
#define GL_DIFFERENCE_KHR 0x929E
#define GL_EXCLUSION_KHR 0x92A0
#define GL_HSL_HUE_KHR 0x92AD
#define GL_HSL_SATURATION_KHR 0x92AE
#define GL_HSL_COLOR_KHR 0x92AF
#define GL_HSL_LUMINOSITY_KHR 0x92B0
#define GL_BLEND_ADVANCED_COHERENT_KHR 0x9285
#endif

// Define other missing constants that might be needed
#ifndef GL_SHADER_PIXEL_LOCAL_STORAGE_EXT
#define GL_SHADER_PIXEL_LOCAL_STORAGE_EXT 0x8F64
#endif

#ifndef GL_FRAMEBUFFER_FETCH_NONCOHERENT_QCOM
#define GL_FRAMEBUFFER_FETCH_NONCOHERENT_QCOM 0x96A2
#endif

// Only define this if Rive hasn't already defined it
#ifndef glFramebufferFetchBarrierQCOM
static inline void glFramebufferFetchBarrierQCOM(void) {}
#endif

// Map EXT function names to standard glad functions if available
#ifndef glDrawElementsInstancedBaseInstanceEXT
#define glDrawElementsInstancedBaseInstanceEXT glDrawElementsInstancedBaseInstance
#endif

#ifndef glRenderbufferStorageMultisampleEXT
#define glRenderbufferStorageMultisampleEXT glRenderbufferStorageMultisample
#endif

#ifndef glFramebufferTexture2DMultisampleEXT
static inline void glFramebufferTexture2DMultisampleEXT(GLenum target, GLenum attachment, GLenum textarget, GLuint texture, GLint level, GLsizei samples) {
    // This is a mobile-specific extension, provide no-op for desktop
    (void)target; (void)attachment; (void)textarget; (void)texture; (void)level; (void)samples;
}
#endif

// Define GLAD extension detection variables that Rive expects
// Set to 0 for desktop GL since these are mobile/WebGL extensions
#ifndef GLAD_GL_version_major
extern int GLAD_GL_VERSION_MAJOR;
#define GLAD_GL_version_major GLAD_GL_VERSION_MAJOR
#endif

#ifndef GLAD_GL_version_minor
extern int GLAD_GL_VERSION_MINOR;
#define GLAD_GL_version_minor GLAD_GL_VERSION_MINOR
#endif

#ifndef GLAD_GL_version_es
#define GLAD_GL_version_es 0
#endif

#ifndef GLAD_GL_ANGLE_base_vertex_base_instance_shader_builtin
#define GLAD_GL_ANGLE_base_vertex_base_instance_shader_builtin 0
#endif

#ifndef GLAD_GL_ANGLE_polygon_mode
#define GLAD_GL_ANGLE_polygon_mode 0
#endif

#ifndef GLAD_GL_EXT_base_instance
#define GLAD_GL_EXT_base_instance 0
#endif
")
        target_include_directories(RIVE_renderer PRIVATE "${GLAD_COMPAT_DIR}")
    endif()

    # OpenGL dependency - prioritize vcpkg glad
    find_package(glad CONFIG QUIET)
    if(glad_FOUND AND TARGET glad::glad)
        target_link_libraries(RIVE_renderer PUBLIC glad::glad)
        message(STATUS "Using glad::glad from vcpkg")
    elseif(TARGET glad)
        # Fallback to manual glad target if it exists
        target_link_libraries(RIVE_renderer PUBLIC glad)
        message(STATUS "Using existing manual glad target")
    else()
        message(WARNING "glad not found. Please install via vcpkg or ensure glad is available")
    endif()

    target_compile_definitions(RIVE_renderer PUBLIC
        WITH_RIVE_TEXT=1
        RIVE_DECODERS=1
        YUP_RIVE_USE_OPENGL=1
        _RIVE_INTERNAL_=1
    )

    # Enable Metal support on Apple platforms
    if(RIVE_PLATFORM_APPLE)
        target_compile_definitions(RIVE_renderer PUBLIC YUP_RIVE_USE_METAL=1)
        target_link_libraries(RIVE_renderer PUBLIC
            "-framework Metal"
            "-framework QuartzCore"
        )
        # Enable ARC for Metal files
        set_target_properties(RIVE_renderer PROPERTIES
            XCODE_ATTRIBUTE_CLANG_ENABLE_OBJC_ARC YES
        )
    endif()

    # Platform-specific OpenGL definitions
    if(RIVE_PLATFORM_DESKTOP)
        target_compile_definitions(RIVE_renderer PUBLIC RIVE_DESKTOP_GL=1)
    elseif(RIVE_PLATFORM_WEB)
        target_compile_definitions(RIVE_renderer PUBLIC RIVE_WEBGL=1)
    endif()

    # Link dependencies
    target_link_libraries(RIVE_renderer PUBLIC
        RIVE::rive
        RIVE::decoders
    )
endif()

# Set up the standard CMake variables
set(RIVE_INCLUDE_DIRS
    "${RIVE_THIRDPARTY_DIR}/rive/include"
    "${RIVE_THIRDPARTY_DIR}/rive_renderer/include"
    "${RIVE_THIRDPARTY_DIR}/rive_decoders/include"
)

set(RIVE_LIBRARIES RIVE::rive RIVE::renderer RIVE::decoders)

# Use FindPackageHandleStandardArgs to set RIVE_FOUND
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(RIVE
    REQUIRED_VARS RIVE_THIRDPARTY_DIR
    VERSION_VAR "1.0"  # You can extract this from Rive headers if needed
)

# Set variables in parent scope if found and parent scope exists
if(RIVE_FOUND AND CMAKE_CURRENT_FUNCTION)
    set(RIVE_INCLUDE_DIRS ${RIVE_INCLUDE_DIRS} PARENT_SCOPE)
    set(RIVE_LIBRARIES ${RIVE_LIBRARIES} PARENT_SCOPE)
    set(RIVE_THIRDPARTY_DIR ${RIVE_THIRDPARTY_DIR} PARENT_SCOPE)
endif()

mark_as_advanced(RIVE_THIRDPARTY_DIR)
