conf_data_displaykit = configuration_data()
conf_data_displaykit.merge_from(conf_data)

build_confi_displaykit = configure_file(input: 'src/build.h', output: 'neutron-displaykit-build.h',
  configuration: conf_data_graphics)

displaykit_sources = []
displaykit_cflags = []

displaykit_inc = [include_directories('include')]
displaykit_docs_inc_paths = []
displaykit_deps = [elemental]

displaykit_servers = []
displaykit_clients = []

subdir('include/neutron/displaykit')
install_subdir('include', strip_directory: true,
  install_dir: includedir,
  exclude_files: [
    'neutron/displaykit/build.h.in',
    'neutron/displaykit/meson.build'
  ])

libdisplaykit = both_libraries('neutron-displaykit', displaykit_sources,
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

pkg.generate(libdisplaykit,
  name: 'neutron-displaykit',
  description: 'Display server and client API for ExpidusOS\'s Neutron',
  url: 'https://github.com/ExpidusOS/neutron',
  version: shortver)

subdir('docs', if_found: [gtkdoc])

summary({
    'Clients': displaykit_clients,
    'Servers': displaykit_servers
  }, section: 'DisplayKit')
