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
    "-g -O0 -fsanitize=address"

    # Older deprecated flag for ASan
    "-g -O0 -faddress-sanitizer"
)


set(CMAKE_REQUIRED_QUIET_SAVE ${CMAKE_REQUIRED_QUIET})
set(CMAKE_REQUIRED_QUIET ${ASan_FIND_QUIETLY})

get_property(ENABLED_LANGUAGES GLOBAL PROPERTY ENABLED_LANGUAGES)
foreach (LANG ${ENABLED_LANGUAGES})
    # Sanitizer flags are not dependend on language, but the used compiler. So
    # instead of searching flags foreach language, search flags foreach compiler
    # used.
    set(COMPILER ${CMAKE_${LANG}_COMPILER_ID})
    if (NOT ASAN_${COMPILER}_FLAGS)
        foreach (FLAG ${ASAN_FLAG_CANDIDATES})
            if(NOT CMAKE_REQUIRED_QUIET)
                message(STATUS
                    "Try ${COMPILER} AddressSanitizer flag = [${FLAG}]")
            endif()

            set(CMAKE_REQUIRED_FLAGS "${FLAG}")
            unset(ASAN_FLAG_DETECTED CACHE)

            if (${LANG} STREQUAL "C")
                include(CheckCCompilerFlag)
                check_c_compiler_flag("${FLAG}" ASAN_FLAG_DETECTED)

            elseif (${LANG} STREQUAL "CXX")
                include(CheckCXXCompilerFlag)
                check_cxx_compiler_flag("${FLAG}" ASAN_FLAG_DETECTED)

            elseif (${LANG} STREQUAL "Fortran")
                # CheckFortranCompilerFlag was introduced in CMake 3.x. To be
                # compatible with older Cmake versions, we will check if this
                # module is present before we use it. Otherwise we will define
                # Fortran coverage support as not available.
                include(CheckFortranCompilerFlag OPTIONAL
                    RESULT_VARIABLE INCLUDED)
                if (INCLUDED)
                    check_fortran_compiler_flag("${FLAG}" ASAN_FLAG_DETECTED)
                elseif (NOT CMAKE_REQUIRED_QUIET)
                    message("-- Performing Test ASAN_FLAG_DETECTED")
                    message("-- Performing Test ASAN_FLAG_DETECTED - Failed "
                        "(Check not supported)")
                endif ()
            endif()

            if (ASAN_FLAG_DETECTED)
                set(ASAN_${COMPILER}_FLAGS "${FLAG}"
                    CACHE STRING "${COMPILER} flags for AddressSanitizer.")
                mark_as_advanced(ASAN_${COMPILER}_FLAGS)
                break()
            endif ()
        endforeach ()
    endif ()
endforeach ()

set(CMAKE_REQUIRED_QUIET ${CMAKE_REQUIRED_QUIET_SAVE})




include(sanitize-helpers)


function (sanitize_address TARGET)
    if (NOT SANITIZE_ADDRESS)
        return()
    endif ()

    # Get list of compilers used by target and check, if target can be checked
    # by sanitizer.
    sanitizer_target_compilers(${TARGET} TARGET_COMPILER)
    list(LENGTH TARGET_COMPILER NUM_COMPILERS)
    if (NUM_COMPILERS GREATER 1)
        message(AUTHOR_WARNING "AddressSanitizer disabled for target ${TARGET} "
            "because it will be compiled by different compilers.")
        return()

    elseif ((NUM_COMPILERS EQUAL 0) OR
        (NOT DEFINED "ASAN_${TARGET_COMPILER}_FLAGS"))
        message(AUTHOR_WARNING "AddressSanitizer disabled for target ${TARGET} "
            "because there is no sanitizer available for target sources.")
        return()
    endif()

    # Set compile- and link-flags for target.
    set_property(TARGET ${TARGET} APPEND_STRING
        PROPERTY COMPILE_FLAGS " ${ASAN_${TARGET_COMPILER}_FLAGS}")
    set_property(TARGET ${TARGET} APPEND_STRING
        PROPERTY LINK_FLAGS " ${ASAN_${TARGET_COMPILER}_FLAGS}")
endfunction ()
