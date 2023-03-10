cmake_minimum_required(VERSION 3.10)
project(neutron_library VERSION 0.1.0 LANGUAGES NONE)

find_program(ZIG zig REQUIRED)

if(NOT DEFINED FLUTTER_LIBRARY)
  if(NOT DEFINED $ENV{FLUTTER_LIBRARY})
    message(FATAL_ERROR "$FLUTTER_LIBRARY environmental variable is not set")
  else()
    set(FLUTTER_LIBRARY $ENV{FLUTTER_LIBRARY})
  endif()
endif()

set(ZIG_OPTIONS "-Dflutter-engine=${FLUTTER_LIBRARY}" "--cache-dir" "${CMAKE_CURRENT_BINARY_DIR}/zig-cache")
add_custom_command(OUTPUT lib/libneutron${CMAKE_SHARED_LIBRARY_SUFFIX}
  COMMAND ${ZIG} build ${ZIG_OPTIONS} --prefix ${CMAKE_CURRENT_BINARY_DIR}
  DEPENDS build.zig)
add_custom_target(libneutron ALL DEPENDS lib/libneutron${CMAKE_SHARED_LIBRARY_SUFFIX})

set(neutron_bundled_libraries ${CMAKE_CURRENT_BINARY_DIR}/lib/libneutron${CMAKE_SHARED_LIBRARY_SUFFIX}.${PROJECT_VERSION} PARENT_SCOPE)
