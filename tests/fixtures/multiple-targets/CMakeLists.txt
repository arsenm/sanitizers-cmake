# This file is part of CMake-sanitizers.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# Copyright (c)
#   2013-2015 Matt Arsenault
#   2015      RWTH Aachen University, Federal Republic of Germany
#

cmake_minimum_required(VERSION 3.13)
project(add_sanitizers_multiple_targets LANGUAGES NONE)

if(NOT DEFINED SANITIZERS_SOURCE)
    message(FATAL_ERROR "SANITIZERS_SOURCE must point to the source checkout")
endif()

set(CMAKE_MODULE_PATH "${SANITIZERS_SOURCE}/cmake" ${CMAKE_MODULE_PATH})
set(SANITIZE_ADDRESS ON)
find_package(Sanitizers REQUIRED)

# Record per-target dispatch without probing or invoking a compiler.
function(add_sanitize_address TARGET)
    set_property(GLOBAL APPEND PROPERTY SANITIZERS_PROCESSED_TARGETS "${TARGET}")
endfunction()

add_library(interface_first INTERFACE)
add_custom_target(ordinary_second)
add_sanitizers(interface_first ordinary_second)

get_property(processed_targets GLOBAL PROPERTY SANITIZERS_PROCESSED_TARGETS)
list(FIND processed_targets "ordinary_second" ordinary_target_index)
if(ordinary_target_index EQUAL -1)
    message(FATAL_ERROR "add_sanitizers did not process ordinary_second")
endif()
