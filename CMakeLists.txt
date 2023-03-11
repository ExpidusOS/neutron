cmake_minimum_required(VERSION 3.10)
project(neutron_library VERSION 0.1.0 LANGUAGES NONE)

find_program(ZIG zig REQUIRED)

if(NOT DEFINED LOCAL_ENGINE)
  if(NOT DEFINED $ENV{LOCAL_ENGINE})
    message(FATAL_ERROR "$LOCAL_ENGINE environmental variable is not set")
  else()
    set(LOCAL_ENGINE $ENV{LOCAL_ENGINE})
  endif()
endif()

set(ZIG_OPTIONS "-Dflutter-engine=${LOCAL_ENGINE}" "--cache-dir" "${CMAKE_CURRENT_BINARY_DIR}/zig-cache")
add_custom_command(OUTPUT lib/libneutron${CMAKE_SHARED_LIBRARY_SUFFIX}
  COMMAND ${ZIG} build ${ZIG_OPTIONS} --prefix ${CMAKE_CURRENT_BINARY_DIR} --verbose --verbose-cc
  DEPENDS build.zig)
add_custom_target(libneutron ALL DEPENDS lib/libneutron${CMAKE_SHARED_LIBRARY_SUFFIX})

set(neutron_bundled_libraries ${CMAKE_CURRENT_BINARY_DIR}/lib/libneutron${CMAKE_SHARED_LIBRARY_SUFFIX}.${PROJECT_VERSION} PARENT_SCOPE)
