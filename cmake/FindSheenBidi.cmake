# FindSheenBidi.cmake
# ============================================================================
# CMake Find Module for SheenBidi
# This module finds and configures the SheenBidi bidirectional text library
#
# Usage:
#   find_package(SheenBidi REQUIRED)
#   target_link_libraries(your_target PRIVATE SheenBidi::SheenBidi)
#
# This module defines the following IMPORTED targets:
#   SheenBidi::SheenBidi - SheenBidi library
#
# Variables:
#   SheenBidi_FOUND          - True if SheenBidi is found
#   SheenBidi_INCLUDE_DIRS   - Include directories for SheenBidi
#   SheenBidi_LIBRARIES      - Libraries to link against
#   SHEENBIDI_ROOT_DIR       - Directory containing SheenBidi source (can be set by user)
# ============================================================================

# Allow user to specify the SheenBidi directory
if(NOT SHEENBIDI_ROOT_DIR)
    # Try to find it relative to common locations
    set(_sheenbidi_search_paths
        "${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/sheenbidi"
        "${CMAKE_CURRENT_SOURCE_DIR}/third_party/sheenbidi"
        "${CMAKE_CURRENT_SOURCE_DIR}/extern/sheenbidi"
        "${CMAKE_CURRENT_SOURCE_DIR}/external/sheenbidi"
        "${CMAKE_SOURCE_DIR}/thirdparty/sheenbidi"
        "${CMAKE_SOURCE_DIR}/third_party/sheenbidi"
        "${CMAKE_SOURCE_DIR}/extern/sheenbidi"
        "${CMAKE_SOURCE_DIR}/external/sheenbidi"
    )
    
    foreach(_path ${_sheenbidi_search_paths})
        if(EXISTS "${_path}/Headers/SheenBidi.h" OR EXISTS "${_path}/include/SheenBidi.h")
            set(SHEENBIDI_ROOT_DIR "${_path}")
            break()
        endif()
    endforeach()
endif()

# Check if we found the source
set(_sheenbidi_header_found FALSE)
if(SHEENBIDI_ROOT_DIR)
    if(EXISTS "${SHEENBIDI_ROOT_DIR}/Headers/SheenBidi.h")
        set(SHEENBIDI_INCLUDE_DIR "${SHEENBIDI_ROOT_DIR}/Headers")
        set(_sheenbidi_header_found TRUE)
    elseif(EXISTS "${SHEENBIDI_ROOT_DIR}/include/SheenBidi.h")
        set(SHEENBIDI_INCLUDE_DIR "${SHEENBIDI_ROOT_DIR}/include")
        set(_sheenbidi_header_found TRUE)
    endif()
endif()

if(NOT _sheenbidi_header_found)
    if(SheenBidi_FIND_REQUIRED)
        message(FATAL_ERROR "Could not find SheenBidi source directory. Please set SHEENBIDI_ROOT_DIR to the directory containing SheenBidi source.")
    else()
        set(SheenBidi_FOUND FALSE)
        return()
    endif()
endif()

# Only create target if it doesn't already exist
if(NOT TARGET SheenBidi::SheenBidi)
    # Collect source files
    file(GLOB_RECURSE sheenbidi_sources 
        "${SHEENBIDI_ROOT_DIR}/Source/*.c"
        "${SHEENBIDI_ROOT_DIR}/source/*.c"
        "${SHEENBIDI_ROOT_DIR}/src/*.c"
    )
    
    # Filter out any test files
    set(filtered_sources "")
    foreach(source ${sheenbidi_sources})
        if(NOT source MATCHES "/test/" AND NOT source MATCHES "_test\\.(c|cpp)$")
            list(APPEND filtered_sources ${source})
        endif()
    endforeach()
    
    if(NOT filtered_sources)
        if(SheenBidi_FIND_REQUIRED)
            message(FATAL_ERROR "Could not find SheenBidi source files in ${SHEENBIDI_ROOT_DIR}")
        else()
            set(SheenBidi_FOUND FALSE)
            return()
        endif()
    endif()
    
    # Create the library
    add_library(SheenBidi_SheenBidi STATIC ${filtered_sources})
    add_library(SheenBidi::SheenBidi ALIAS SheenBidi_SheenBidi)
    
    # Set include directories
    target_include_directories(SheenBidi_SheenBidi PUBLIC
        "${SHEENBIDI_INCLUDE_DIR}"
    )
    
    # Set C standard (SheenBidi is a C library)
    target_compile_features(SheenBidi_SheenBidi PUBLIC c_std_99)
    
    # Platform-specific compiler flags
    if(MSVC)
        target_compile_options(SheenBidi_SheenBidi PRIVATE /W3)
    else()
        target_compile_options(SheenBidi_SheenBidi PRIVATE -Wall -Wextra)
    endif()
    
    # Set properties
    set_target_properties(SheenBidi_SheenBidi PROPERTIES
        C_VISIBILITY_PRESET hidden
        VISIBILITY_INLINES_HIDDEN ON
        POSITION_INDEPENDENT_CODE ON
    )
endif()

# Set up standard CMake variables
set(SheenBidi_INCLUDE_DIRS "${SHEENBIDI_INCLUDE_DIR}")
set(SheenBidi_LIBRARIES SheenBidi::SheenBidi)

# Use FindPackageHandleStandardArgs to set SheenBidi_FOUND
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(SheenBidi
    REQUIRED_VARS SHEENBIDI_ROOT_DIR SHEENBIDI_INCLUDE_DIR
    VERSION_VAR "2.6"  # Current version as of 2024
)

# Set variables in parent scope if found and parent scope exists
if(SheenBidi_FOUND AND CMAKE_CURRENT_FUNCTION)
    set(SheenBidi_INCLUDE_DIRS ${SheenBidi_INCLUDE_DIRS} PARENT_SCOPE)
    set(SheenBidi_LIBRARIES ${SheenBidi_LIBRARIES} PARENT_SCOPE)
    set(SHEENBIDI_ROOT_DIR ${SHEENBIDI_ROOT_DIR} PARENT_SCOPE)
endif()

mark_as_advanced(SHEENBIDI_ROOT_DIR SHEENBIDI_INCLUDE_DIR) 
