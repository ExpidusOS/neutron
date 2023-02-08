platform_target = 'linux'
platform_docs_inc_paths += join_paths(meson.current_source_dir(), 'include')
platform_inc += include_directories('include')
platform_deps += libsystemd
platform_sources += [
  join_paths(meson.current_source_dir(), 'src', 'platform.c'),
  join_paths(meson.current_source_dir(), 'src', 'process.c'),
  join_paths(meson.current_source_dir(), 'src', 'systemd', 'device-enum.c'),
  join_paths(meson.current_source_dir(), 'src', 'systemd', 'device.c')
]

install_subdir('include', strip_directory: true, install_dir: includedir)
