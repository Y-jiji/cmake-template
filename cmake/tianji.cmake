
# -- Manage External Dependencies Using Git

set(AUTO_PUBLIC_DEPS)
set(AUTO_PRIVATE_DEPS)

function(Execute)
    cmake_parse_arguments(EX "" "WORKING_DIRECTORY" "COMMAND" "${ARGV}")
    list(JOIN EX_COMMAND " " EX_COMMAND)
    message(STATUS "+ " ${EX_COMMAND})
    execute_process(
        ${ARGN}
        WORKING_DIRECTORY ${EX_WORKING_DIRECTORY}
        COMMAND_ERROR_IS_FATAL ANY
        OUTPUT_QUIET ERROR_QUIET
    )
endfunction()

function(CMakeInstall)
    cmake_parse_arguments(CMI "HEADER_ONLY" "USER;REPO;PACK;FLAGS" "" "${ARGV}")
    Execute(
        COMMAND                 cmake -S . -B build ${CMI_FLAGS} 
            -DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/3rd_party_build
            -DCMAKE_INSTALL_BINDIR=bin
            -DCMAKE_INSTALL_LIBDIR=lib
            -DCMAKE_INSTALL_INCLUDEDIR=include
        WORKING_DIRECTORY       ${CMAKE_BINARY_DIR}/3rd_party/${CMI_USER}/${CMI_REPO}
    )
    Execute(
        COMMAND                 cmake --build build --target install -j
        WORKING_DIRECTORY       ${CMAKE_BINARY_DIR}/3rd_party/${CMI_USER}/${CMI_REPO}
    )
    if(NOT ${CMI_HEADER_ONLY} STREQUAL "TRUE")
        set(CMAKE_PREFIX_PATH "${CMAKE_BINARY_DIR}")
        message(STATUS "+ FIND PACKAGE ${CMI_PACK}")
        find_package(${CMI_PACK} REQUIRED QUIET)
    endif()
endfunction()

function(Git)
    cmake_parse_arguments(GH "HEADER_ONLY;PUBLIC;PRIVATE" "SITE;USER;REPO;BRANCH;PIPELINE;PACK;FLAGS;DIR" "" "${ARGV}")
    message(STATUS "GIT " ${GH_USER}/${GH_REPO} @ ${GH_BRANCH})
    # support for ssh
    if ("${GH_SITE}" MATCHES "^git.*")
        set(URL ${GH_SITE}:${GH_USER}/${GH_REPO})
    else()
        set(URL ${GH_SITE}/${GH_USER}/${GH_REPO})
    endif()
    # download package from using git clone
    if (NOT EXISTS "${CMAKE_BINARY_DIR}/3rd_party/${GH_USER}/${GH_REPO}/.git")
        Execute(
            COMMAND                 git clone
                --recurse-submodules -j8 --quiet --depth 1 
                --branch "${GH_BRANCH}" "${URL}" 
                "${CMAKE_BINARY_DIR}/3rd_party/${GH_USER}/${GH_REPO}"
            WORKING_DIRECTORY       "${CMAKE_BINARY_DIR}"
        )
    else()
        Execute(
            COMMAND                 git pull
            WORKING_DIRECTORY       "${CMAKE_BINARY_DIR}/3rd_party/${GH_USER}/${GH_REPO}"
        )
    endif()
    # set default package name if it is empty
    if("${GH_PACK}" STREQUAL "")
        set(GH_PACK ${GH_REPO})
    endif()
    # configure how this package is added to current project
    if(${GH_PIPELINE} STREQUAL "INCLUDE ROOT")
        # do nothing, but include it as header only library
        include_directories(${CMAKE_BINARY_DIR}/3rd_party/${GH_USER})
    elseif(${GH_PIPELINE} STREQUAL "CMAKE SUBDIR")
        set(CMAKE_MESSAGE_LOG_LEVEL__ ${CMAKE_MESSAGE_LOG_LEVEL})
        set(CMAKE_MESSAGE_LOG_LEVEL ERROR)
        add_subdirectory(
            ${CMAKE_BINARY_DIR}/3rd_party/${GH_USER}/${GH_REPO}
            ${CMAKE_BINARY_DIR}/3rd_party_subdirs
            EXCLUDE_FROM_ALL
        )
        set(CMAKE_MESSAGE_LOG_LEVEL ${CMAKE_MESSAGE_LOG_LEVEL__})
    elseif(${GH_PIPELINE} STREQUAL "CMAKE INSTALL")
        # install headers to given directory
        CMakeInstall(
            REPO    ${GH_REPO}
            USER    ${GH_USER}
            PACK    ${GH_PACK}
            FLAGS   ${GH_FLAGS}
            HEADER_ONLY ${GH_HEADER_ONLY}
        )
    elseif(${GH_PIPELINE} STREQUAL "AUTOMAKE INSTALL")
        # run the build command if it targeted directory don't exists
        if(NOT EXISTS ${CMAKE_BINARY_DIR}/3rd_party/${GH_USER}/${GH_REPO}/install)
            Execute(
                COMMAND                 ./autogen.sh --prefix ${CMAKE_BINARY_DIR}/3rd_party/${GH_USER}/${GH_REPO}/install
                WORKING_DIRECTORY       ${CMAKE_BINARY_DIR}/3rd_party/${GH_USER}/${GH_REPO}
            )
            Execute(
                COMMAND                 make install -j4
                WORKING_DIRECTORY       ${CMAKE_BINARY_DIR}/3rd_party/${GH_USER}/${GH_REPO}
            )
        endif()
        include_directories(${CMAKE_BINARY_DIR}/3rd_party/${GH_USER}/${GH_REPO}/install/include)
        link_directories(${CMAKE_BINARY_DIR}/3rd_party/${GH_USER}/${GH_REPO}/install/lib)
    else()
        message(FATAL_ERROR "UNKNOWN THIRD PARTY PIPELINE ${GH_PIPELINE}")
    endif()
    # add dependency to project
    if(${GH_PUBLIC})
        message(STATUS "+ " "add ${GH_PACK} as public dependency")
        list(APPEND AUTO_PUBLIC_DEPS ${GH_PACK})
    else()
        message(STATUS "+ " "add ${GH_PACK} as private dependency")
        list(APPEND AUTO_PRIVATE_DEPS ${GH_PACK})
    endif()
endfunction()

# -- Scan and Build

function(AutoBuild)
    cmake_parse_arguments(AUTO "STATIC;SHARED;INTERFACE" "LIB_DIR;BIN_DIR" "" "${ARGV}")

    # List Lib Source & Distinguish Unit Tests
    file(GLOB_RECURSE SRC ${AUTO_LIB_DIR}/*.cpp ${AUTO_LIB_DIR}/*.c ${AUTO_LIB_DIR}/*.cc)
    file(GLOB_RECURSE INC ${AUTO_LIB_DIR}/*.hpp ${AUTO_LIB_DIR}/*.h)
    file(GLOB_RECURSE SRC_TEST ${AUTO_LIB_DIR}/*.test.cpp ${AUTO_LIB_DIR}/*.test.cc)
    file(GLOB_RECURSE INC_TEST ${AUTO_LIB_DIR}/*.test.hpp ${AUTO_LIB_DIR}/*.test.h)

    list(REMOVE_ITEM SRC ${SRC_TEST}) # remove *.test.cpp and *.test.hpp from target
    list(REMOVE_ITEM INC ${INC_TEST})

    # Copy Headers & Install Headers Manually
    foreach(F ${INC})
        file(RELATIVE_PATH R ${CMAKE_CURRENT_SOURCE_DIR}/${AUTO_LIB_DIR} ${F})
        get_filename_component(D ${R} DIRECTORY)
        configure_file(${AUTO_LIB_DIR}/${R} include/${CMAKE_PROJECT_NAME}/${R} COPYONLY)
        install(FILES ${F} DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${CMAKE_PROJECT_NAME}/${D})
    endforeach(F R D)

    # Add current project as library
    if(${AUTO_STATIC})
        message(STATUS "STATIC LIBRARY ${CMAKE_PROJECT_NAME}")
        add_library(${CMAKE_PROJECT_NAME} STATIC ${SRC})
    elseif(${AUTO_SHARED})
        message(STATUS "SHARED LIBRARY ${CMAKE_PROJECT_NAME}")
        add_library(${CMAKE_PROJECT_NAME} SHARED ${SRC})
    elseif(${AUTO_INTERFACE})
        message(STATUS "INTERFACE LIBRARY ${CMAKE_PROJECT_NAME}")
        add_library(${CMAKE_PROJECT_NAME} INTERFACE ${SRC})
    else()
        message(FATAL_ERROR "PLEASE ADD 'STATIC', 'INTERFACE' OR 'SHARED' FOR LIB TYPE")
    endif()

    if(${AUTO_INTERFACE})
        target_include_directories(
            ${CMAKE_PROJECT_NAME}
            INTERFACE  ${CMAKE_BINARY_DIR}/3rd_party_build/include
        )
        target_include_directories(
            ${CMAKE_PROJECT_NAME}
            INTERFACE  ${CMAKE_BINARY_DIR}/include
        )
        target_compile_features(
            ${CMAKE_PROJECT_NAME}
            INTERFACE cxx_std_20
        )
    else()
        target_include_directories(
            ${CMAKE_PROJECT_NAME}
            PUBLIC  ${CMAKE_BINARY_DIR}/3rd_party_build/include
        )
        target_include_directories(
            ${CMAKE_PROJECT_NAME}
            INTERFACE  ${CMAKE_BINARY_DIR}/include
        )
        target_compile_features(
            ${CMAKE_PROJECT_NAME}
            PUBLIC cxx_std_20
        )
    endif()

    target_link_libraries(
        ${CMAKE_PROJECT_NAME}
        PUBLIC  ${AUTO_PUBLIC_DEPS}
        PRIVATE ${AUTO_PRIVATE_DEPS}
    )

    include(GNUInstallDirs)
    install(TARGETS ${CMAKE_PROJECT_NAME})

    # Make Tests Suitable for `ctest`
    set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)

    message(STATUS "SOURCE OF ${CMAKE_PROJECT_NAME}")
    foreach(F ${SRC})
        message(STATUS "+ " ${F})
    endforeach(F R)

    message(STATUS "UNIT TESTS")
    include(GoogleTest)
    foreach(F ${SRC_TEST}) # unit tests
        file(RELATIVE_PATH R ${CMAKE_CURRENT_SOURCE_DIR} ${F})
        string(REPLACE "/" "-" R ${R})
        string(REPLACE ".cpp" "" R ${R})
        message(STATUS "+ " ${F})
        add_executable(${R} ${F})
        target_link_libraries(${R} GTest::gtest_main GTest::gtest ${CMAKE_PROJECT_NAME})
        set_target_properties(${R} PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/Testing)
        gtest_add_tests(TARGET "${R}")
    endforeach(F N)

    # Remove source variables
    unset(SRC_TEST)
    unset(INC_TEST)
    unset(INC)
    unset(SRC)

    # Process binaries
    file(GLOB_RECURSE SRC ${AUTO_BIN_DIR}/*.cpp)

    message(STATUS "EXECUTABLES")
    foreach(F ${SRC})
        message(STATUS "+ " ${F})
        file(RELATIVE_PATH R ${CMAKE_CURRENT_SOURCE_DIR}/${AUTO_BIN_DIR} ${F})
        string(REPLACE ".cpp" "" R ${R})
        add_executable(${R} ${F})
        target_link_libraries(${R} PRIVATE ${CMAKE_PROJECT_NAME})
    endforeach(F R)

    unset(SRC)

endfunction()