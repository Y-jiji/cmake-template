#include <highfive/H5File.hpp>
#include <iostream>
#include <my_project/library.hpp>
#include <highfive/highfive.hpp>

namespace H5 = HighFive;

int main() {
    H5::File file("");
    std::cout << "Hello World!" << std::endl;
}
