conf_data_elemental = configuration_data()
conf_data_elemental.merge_from(conf_data)

build_conf_elemental = configure_file(input: 'src/build.h', output: 'neutron-elemental-build.h',
  configuration: conf_data_elemental)

elemental_sources = [
  'src/type.c'
]

elemental_inc = include_directories('include')
elemental_deps = [pthread]

install_subdir('include', strip_directory: true, install_dir: includedir)

libelemental = both_libraries('neutron-elemental', elemental_sources,
  include_directories: elemental_inc,
  dependencies: elemental_deps,
  version: version,
  gnu_symbol_visibility: 'hidden',
  install: true)
elemental = declare_dependency(link_with: libelemental,
  include_directories: elemental_inc,
  dependencies: elemental_deps)

if meson.can_run_host_binaries() and check.found()
  libelemental_native = both_libraries('neutron-elemental-host', elemental_sources,
    include_directories: elemental_inc,
    dependencies: elemental_deps,
    version: version,
    gnu_symbol_visibility: 'hidden',
    install: false,
    native: true)
  elemental_native = declare_dependency(link_with: libelemental_native,
    include_directories: elemental_inc,
    dependencies: elemental_deps)
endif

pkg.generate(libelemental,
  name: 'neutron-elemental',
  description: 'A minimal resource usage type system for C',
  url: 'https://github.com/ExpidusOS/neutron',
  version: longver)

subdir('tests', if_found: [check])
