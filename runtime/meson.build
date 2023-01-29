conf_data_runtime = configuration_data()
conf_data_runtime.merge_from(conf_data)

build_conf_runtime = configure_file(input: 'src/build.h', output: 'neutron-runtime-build.h',
  configuration: conf_data_runtime)

runtime_sources = []

runtime_cflags = []
runtime_inc = include_directories('include')
runtime_deps = [elemental]

install_subdir('include', strip_directory: true, install_dir: includedir)

libruntime = both_libraries('neutron-runtime', runtime_sources,
  c_args: runtime_cflags,
  include_directories: runtime_inc,
  dependencies: runtime_deps,
  version: version,
  gnu_symbol_visibility: 'hidden',
  install: true)
runtime = declare_dependency(link_with: libruntime,
  include_directories: runtime_inc,
  dependencies: runtime_deps)
libs += [libruntime]

pkg.generate(libruntime,
  name: 'neutron-runtime',
  description: 'Runtime API for Neutron',
  url: 'https://github.com/ExpidusOS/neutron',
  version: shortver)

subdir('docs', if_found: [gtkdoc])
