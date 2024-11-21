# ------------------------------- #
# -- Tianji's Project Template -- #
# ------------------------------- #

cmake_minimum_required(VERSION 3.16...3.27)
list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")
include(tianji NO_POLICY_SCOPE)

# -- Your project name here

project(my_project LANGUAGES CXX C)

# -- Configure project compiler options

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS true)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(ENV{CC}     ${CMAKE_C_COMPILER})
set(ENV{CXX}    ${CMAKE_CXX_COMPILER})
enable_testing()

find_package(Threads REQUIRED)

# -- Manage Compile Options w/ ASAN flags

if(CMAKE_BUILD_TYPE MATCHES "Release")
    add_compile_options(-O3 -Werror -Wno-attributes -DNDEBUG)
elseif(CMAKE_BUILD_TYPE MATCHES "Debug")
    add_compile_options(-fsanitize=address)
    add_link_options(-fsanitize=address)
    add_compile_options(-O0 -ggdb -Werror -Wno-attributes -DDEBUG)
endif()

# -- Manage Third Party Dependencies

Git(
    SITE    "https://github.com"
    USER    "Rookfighter"
    REPO    "inifile-cpp"
    BRANCH  "main"
    PIPELINE "CMAKE INSTALL" HEADER_ONLY PUBLIC
)
Git(
    SITE    "https://github.com"
    USER    "gflags"
    REPO    "gflags"
    BRANCH  "v2.2.2"
    PIPELINE "CMAKE INSTALL" FLAGS "-DBUILD_SHARED_LIBS=ON" PUBLIC
)
Git(
    SITE    "https://github.com"
    USER    "google"
    REPO    "glog"
    BRANCH  "v0.7.0"
    PIPELINE "CMAKE INSTALL" PUBLIC
)
Git(
    SITE    "https://github.com"
    USER    "google"
    REPO    "googletest"
    BRANCH  "v1.14.0"
    PACK    "GTest"
    PIPELINE "CMAKE SUBDIR"
)
Git(
    SITE    "https://github.com"
    USER    "HDFGroup"
    REPO    "hdf5"
    BRANCH  "hdf5_1.14.5"
    PIPELINE "CMAKE INSTALL" FLAGS "-DHDF5_INSTALL_CMAKE_DIR=${CMAKE_BINARY_DIR}/3rd_party_build/lib/cmake" PUBLIC
)
Git(
    SITE    "https://github.com"
    USER    "BlueBrain"
    REPO    "HighFive"
    BRANCH  "v3.0.0-beta1"
    PACK    "HighFive"
    PIPELINE "CMAKE INSTALL" FLAGS "-DHDF5_DIR=${CMAKE_BINARY_DIR}/3rd_party_build/lib" PUBLIC HEADER_ONLY
)

# -- Process Main Library & Unit Tests
AutoBuild(
    LIB_DIR "lib" SHARED
    BIN_DIR "bin"
)
