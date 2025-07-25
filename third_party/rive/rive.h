/*
  ==============================================================================

   This file is part of the YUP library.
   Copyright (c) 2024 - kunitoki@gmail.com

   YUP is an open source library subject to open-source licensing.

   The code included in this file is provided under the terms of the ISC license
   http://www.isc.org/downloads/software-support-policy/isc-license. Permission
   to use, copy, modify, and/or distribute this software for any purpose with or
   without fee is hereby granted provided that the above copyright notice and
   this permission notice appear in all copies.

   YUP IS PROVIDED "AS IS" WITHOUT ANY WARRANTY, AND ALL WARRANTIES, WHETHER
   EXPRESSED OR IMPLIED, INCLUDING MERCHANTABILITY AND FITNESS FOR PURPOSE, ARE
   DISCLAIMED.

  ==============================================================================
*/

/*
  ==============================================================================

  BEGIN_YUP_MODULE_DECLARATION

    ID:                 rive
    vendor:             rive
    version:            1.0
    name:               Rive C++ is a runtime library for Rive.
    description:        Rive C++ is a runtime library for Rive, a real-time interactive design and animation tool.
    website:            https://github.com/rive-app/rive-runtime
    license:            MIT

    dependencies:       harfbuzz sheenbidi yoga_library
    defines:            WITH_RIVE_TEXT=1 WITH_RIVE_YOGA=1 WITH_RIVE_LAYOUT=1
    appleFrameworks:    CoreText
    searchpaths:        include

  END_YUP_MODULE_DECLARATION

  ==============================================================================
*/

#pragma once

#include "include/rive/text/utf.hpp"
#include "include/rive/artboard.hpp"
#include "include/rive/file.hpp"
#include "include/rive/static_scene.hpp"
#include "include/rive/layout.hpp"
#include "include/rive/custom_property_number.hpp"
#include "include/rive/custom_property_boolean.hpp"
#include "include/rive/custom_property_string.hpp"
#include "include/rive/animation/state_machine_instance.hpp"
#include "include/rive/animation/state_machine_input_instance.hpp"
