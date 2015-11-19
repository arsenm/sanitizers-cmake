# The MIT License (MIT)
#
# Copyright (c) 2013 Matthew Arsenault
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

# This module tests if address sanitizer is supported by the compiler. The
# necessary flags for compiler and linker will be stored in variables. ASan can
# be enabled for all targets with CMake build type "ASan", individual targets
# can enable ASan with the saitize_address() function.

option(SANITIZE_ADDRESS "Selects wheter Address Sanitizer will be enabled for
    individual targets" Off)

set(ASAN_FLAG_CANDIDATES
    # Clang 3.2+ use this version
    "-fsanitize=address"

    # Older deprecated flag for ASan
    "-faddress-sanitizer"
)


set(CMAKE_REQUIRED_QUIET_SAVE ${CMAKE_REQUIRED_QUIET})
set(CMAKE_REQUIRED_QUIET ${ASan_FIND_QUIETLY})

set(_ASAN_REQUIRED_VARS)
foreach (LANG C CXX)
    if (CMAKE_${LANG}_COMPILER_LOADED)
        list(APPEND _ASAN_REQUIRED_VARS ASAN_${LANG}_FLAGS)

        # If flags for this compiler were already found, do not try to find them
        # again.
        if (NOT ASAN_${LANG}_FLAGS)
            foreach (FLAG ${ASAN_FLAG_CANDIDATES})
                if(NOT CMAKE_REQUIRED_QUIET)
                    message(STATUS "Try Address sanitizer ${LANG} flag = [${FLAG}]")
                endif()

                set(CMAKE_REQUIRED_FLAGS "${FLAG}")
                unset(ASAN_FLAG_DETECTED CACHE)

                if (${LANG} STREQUAL "C")
                    include(CheckCCompilerFlag)
                    check_c_compiler_flag("${FLAG}" ASAN_FLAG_DETECTED)

                elseif (${LANG} STREQUAL "CXX")
                    include(CheckCXXCompilerFlag)
                    check_cxx_compiler_flag("${FLAG}" ASAN_FLAG_DETECTED)
                endif()

                if (ASAN_FLAG_DETECTED)
                    set(ASAN_${LANG}_FLAGS "${FLAG}"
                        CACHE STRING "${LANG} compiler flags for Address sanitizer")
                    break()
                endif ()
            endforeach()
        endif ()
    endif ()
endforeach ()

set(CMAKE_REQUIRED_QUIET ${CMAKE_REQUIRED_QUIET_SAVE})


if (_ASAN_REQUIRED_VARS)
    include(FindPackageHandleStandardArgs)
    find_package_handle_standard_args(ASan REQUIRED_VARS ${_ASAN_REQUIRED_VARS})
    mark_as_advanced(${_ASAN_REQUIRED_VARS})
    unset(_ASAN_REQUIRED_VARS)
else()
    message(SEND_ERROR "FindASan requires C or CXX language to be enabled")
endif()


# add build target ASan
if (ASan_FOUND)
    set(CMAKE_C_FLAGS_ASAN "${ASAN_C_FLAGS}" CACHE
        STRING "Flags used by the C compiler during ASan builds.")
    set(CMAKE_CXX_FLAGS_ASAN "${ASAN_CXX_FLAGS}" CACHE
        STRING "Flags used by the C++ compiler during ASan builds.")
    set(CMAKE_EXE_LINKER_FLAGS_ASAN "${ASAN_C_FLAGS}" CACHE
        STRING "Flags used for linking binaries during ASan builds.")
    set(CMAKE_SHARED_LINKER_FLAGS_ASAN "${ASAN_C_FLAGS}" CACHE
        STRING "Flags used by the shared libraries linker during ASan builds.")
    set(CMAKE_MODULE_LINKER_FLAGS_ASAN "${ASAN_C_FLAGS}" CACHE
        STRING "Flags used by the module libraries linker during ASan builds.")
    mark_as_advanced(CMAKE_C_FLAGS_ASAN
                     CMAKE_CXX_FLAGS_ASAN
                     CMAKE_EXE_LINKER_FLAGS_ASAN
                     CMAKE_SHARED_LINKER_FLAGS_ASAN
                     CMAKE_MODULE_LINKER_FLAGS_ASAN)
endif ()


function (sanitize_address TARGET)
    if (NOT SANITIZE_ADDRESS)
        return()
    endif ()

    set_property(TARGET ${TARGET} APPEND_STRING PROPERTY
        COMPILE_FLAGS " ${ASAN_C_FLAGS}")
    set_property(TARGET ${TARGET} APPEND_STRING PROPERTY
        LINK_FLAGS " ${ASAN_C_FLAGS}")
endfunction ()
