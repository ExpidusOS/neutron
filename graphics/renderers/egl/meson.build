graphics_docs_inc_paths += join_paths(meson.current_source_dir(), 'include')
graphics_inc += include_directories('include')
graphics_renderers += 'egl'
graphics_deps += egl
graphics_dart_inc_paths += [
  egl.get_variable('includedir'),
  join_paths(meson.current_source_dir(), 'include')
]

install_subdir('include', strip_directory: true, install_dir: includedir)
