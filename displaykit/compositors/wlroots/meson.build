displaykit_compositors += 'wlroots'
displaykit_docs_inc_paths += join_paths(meson.current_source_dir(), 'include')
displaykit_inc += include_directories('include')
displaykit_deps += [wlroots, wayland_server, xkbcommon]
displaykit_cflags += '-DWLR_USE_UNSTABLE=1'
displaykit_sources += join_paths(meson.current_source_dir(), 'src', 'wlroots-compositor.c')

subdir('protocols')

install_subdir('include', strip_directory: true, install_dir: includedir)
