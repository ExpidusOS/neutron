cmake_minimum_required(VERSION 3.10)

if(NOT DEFINED BINARY_NAME)
  set(BINARY_NAME "neutron-runner")
endif()

set(PROJECT_NAME "neutron")
project(${PROJECT_NAME} LANGUAGES NONE)

add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/.." "${CMAKE_CURRENT_BINARY_DIR}/build")
set(neutron_bundled_libraries ${neutron_bundled_libraries} PARENT_SCOPE)

install(FILES "${CMAKE_CURRENT_BINARY_DIR}/build/bin/neutron-runner"
  PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
  RENAME ${BINARY_NAME}
  DESTINATION "${CMAKE_INSTALL_PREFIX}"
  COMPONENT Runtime)
