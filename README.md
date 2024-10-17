# CMake Template

A template for c++ projects with cmake. 

This is a template that I personally used for single artifact projects. 

This template automates source file and dependency management. 

## Get Started

You can build a project with the following commands: 

```shell
cmake -S . -B build 
cmake --build build -j
```

## Run Unit Tests

You can also run unit tests for your library. 

```shell
ctest --test-dir build
```

## Find Source Files

This template builds one library and multiple executables. 

```cmake
AutoBuild(
    LIB_DIR "lib" SHARED   # Where to search for library source and headers
    BIN_DIR "bin"          # Where to search for executable source
    PUBLIC_DEP   "glog::glog" "gflags"   # Public Dependencies (Re-exported)
    PRIVATE_DEP  "nlohmann_json"         # Private Dependencies
)
```

## Fetch Dependencies

> Note that the package name `PACK` is the one you place after `PUBLIC_DEP` or `PRIVATE_DEP` in `AutoBuild`. 

You can declare a dependency `https://github.com/nlohmann/json` with package name `nlohmann_json`. 

```cmake
Git(
    SITE    "https://github.com"
    USER    "nlohmann"
    REPO    "json"
    PACK    "nlohmann_json"
    BRANCH  "v3.11.3"
    PIPELINE "CMAKE INSTALL" FLAGS "-DJSON_BuildTests=OFF"
)
```

## Unit Tests

By default, any file with suffix `.test.cpp` will be excluded from the library source. 

Instead, they will be included as unit tests for the library. 
