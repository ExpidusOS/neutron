cmake_minimum_required(VERSION 3.10)

set(PROJECT_NAME "neutron")
project(${PROJECT_NAME} LANGUAGES NONE)

add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/.." "${CMAKE_CURRENT_BINARY_DIR}/build")
set(neutron_bundled_libraries ${neutron_bundled_libraries} PARENT_SCOPE)
