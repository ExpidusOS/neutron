conf_data_graphics = configuration_data()
conf_data_graphics.merge_from(conf_data)

build_conf_graphics = configure_file(input: 'src/build.h', output: 'neutron-graphics-build.h',
  configuration: conf_data_graphics)

graphics_sources = [
  'src/renderer.c'
]

graphics_cflags = []

graphics_inc = include_directories('include')
graphics_deps = [elemental, flutter_engine]

install_subdir('include', strip_directory: true, install_dir: includedir)

libgraphics = both_libraries('neutron-graphics', graphics_sources,
  c_args: graphics_cflags,
  include_directories: graphics_inc,
  dependencies: graphics_deps,
  version: version,
  gnu_symbol_visibility: 'hidden',
  install: true)
graphics = declare_dependency(link_with: libgraphics,
  include_directories: graphics_inc,
  dependencies: graphics_deps)

pkg.generate(libgraphics,
  name: 'neutron-graphics',
  description: 'Graphical API for ExpidusOS\'s Neutron',
  url: 'https://github.com/ExpidusOS/neutron',
  version: shortver)

subdir('docs', if_found: [gtkdoc])
