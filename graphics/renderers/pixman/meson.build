graphics_docs_inc_paths += join_paths(meson.current_source_dir(), 'include')
graphics_inc += include_directories('include')
graphics_renderers += 'pixman'
graphics_sources += join_paths(meson.current_source_dir(), 'src', 'pixman-renderer.c')
graphics_deps += pixman

install_subdir('include', strip_directory: true, install_dir: includedir)
