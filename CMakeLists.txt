# ------------------------------- #
# -- Tianji's Project Template -- #
# ------------------------------- #

cmake_minimum_required(VERSION 3.16...3.27)
list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")
include(tianji NO_POLICY_SCOPE)

# -- Configure project compiler options

project(my_project LANGUAGES CXX C)
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
    PIPELINE "CMAKE INSTALL" HEADER_ONLY
)
Git(
    SITE    "https://github.com"
    USER    "nlohmann"
    REPO    "json"
    PACK    "nlohmann_json"
    BRANCH  "v3.11.3"
    PIPELINE "CMAKE INSTALL" FLAGS "-DJSON_BuildTests=OFF"
)
Git(
    SITE    "https://github.com"
    USER    "gflags"
    REPO    "gflags"
    BRANCH  "v2.2.2"
    PIPELINE "CMAKE INSTALL" FLAGS "-DBUILD_SHARED_LIBS=ON"
)
Git(
    SITE    "https://github.com"
    USER    "google"
    REPO    "glog"
    BRANCH  "v0.7.0"
    PIPELINE "CMAKE INSTALL" FLAGS "-Dgflags_DIR=${gflags_DIR}"
)
Git(
    SITE    "https://gitlab.com"
    PACK    "Eigen3"
    USER    "libeigen"
    REPO    "eigen"
    BRANCH  "3.4.0"
    PIPELINE "CMAKE INSTALL" HEADER_ONLY
)
Git(
    SITE    "https://github.com"
    USER    "google"
    REPO    "googletest"
    BRANCH  "v1.14.0"
    PACK    "GTest"
    PIPELINE "CMAKE SUBDIR"
)

# -- Process Main Library & Unit Tests
AutoBuild(
    LIB_DIR "lib"
    BIN_DIR "bin"
    SHARED
    PUBLIC_DEP "glog::glog" "gflags"
)
