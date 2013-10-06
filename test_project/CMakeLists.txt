
cmake_minimum_required(VERSION 2.8)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/..")


include(FindUBSan)
include(FindTSan)
include(FindASan)
include(FindMSan)

add_executable(test test.cpp)
