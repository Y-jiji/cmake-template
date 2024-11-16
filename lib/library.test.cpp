#include <gtest/gtest.h>
#include <my_project/library.hpp>
#include <assert.h>

TEST(library, simple) {
    std::cout << "Hello World" << std::endl;
}

TEST(library, add) {
    assert(add(1, 2) == 3);
}