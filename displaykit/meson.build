conf_data_displaykit = configuration_data()
conf_data_displaykit.merge_from(conf_data)

build_confi_displaykit = configure_file(input: 'src/build.h', output: 'neutron-displaykit-build.h',
  configuration: conf_data_graphics)

displaykit_sources = [
  'src/client.c', 'src/compositor.c', 'src/context.c',
  'src/input.c', 'src/output.c', 'src/view.c',
  'src/input/keyboard.c', 'src/input/mouse.c'
]
displaykit_cflags = []

displaykit_inc = [include_directories('include')]
displaykit_docs_inc_paths = []
displaykit_deps = [elemental]

displaykit_compositors = []
displaykit_clients = []

subdir('include/neutron/displaykit')
install_subdir('include', strip_directory: true,
  install_dir: includedir,
  exclude_files: [
    'neutron/displaykit/build.h.in',
    'neutron/displaykit/meson.build'
  ])

libdisplaykit = library('neutron-displaykit', displaykit_sources,
  c_args: displaykit_cflags,
  include_directories: displaykit_inc,
  dependencies: displaykit_deps,
  version: version,
  gnu_symbol_visibility: 'hidden',
  install: true)
displaykit = declare_dependency(link_with: libdisplaykit,
  include_directories: displaykit_inc,
  dependencies: displaykit_deps)
libs += [libdisplaykit]
neutron_inc += displaykit_inc
neutron_deps += displaykit_deps

foreach src : displaykit_sources
  neutron_sources += ['displaykit' / src]
endforeach

pkg.generate(libdisplaykit,
  name: 'neutron-displaykit',
  description: 'Display server API for compositors and clients for ExpidusOS\'s Neutron',
  url: 'https://github.com/ExpidusOS/neutron',
  version: shortver)

subdir('docs', if_found: [gtkdoc])

summary({
    'Clients': displaykit_clients,
    'Compositors': displaykit_compositors
  }, section: 'DisplayKit')
