cmake_minimum_required(VERSION 3.16.3)

project(baseband)


set(CMAKE_CXX_FLAGS "-Wall -Wextra")
set(CMAKE_CXX_FLAGS_DEBUG "-g")
set(CMAKE_CXX_FLAGS_RELEASE "-O2")


add_library(tx tx.c)
set_property(TARGET tx PROPERTY INTERPROCEDURAL_OPTIMIZATION True)

add_subdirectory(third_party)
target_link_libraries(tx LINK_PUBLIC fft)

include(cmake/googletest.cmake)
fetch_googletest(
    ${PROJECT_SOURCE_DIR}/cmake
    ${PROJECT_BINARY_DIR}/googletest
    )

enable_testing()
add_subdirectory(test)
