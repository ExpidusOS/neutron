conf_data_platform = configuration_data()
conf_data_platform.merge_from(conf_data)

build_conf_platform = configure_file(input: 'src/build.h', output: 'neutron-platform-build.h',
  configuration: conf_data_platform)

platform_sources = [
  'src/device-enum.c', 'src/platform.c'
]

platform_cflags = [
  '-D@0@=1'.format(target_machine.system().to_upper()),
  '-D@0@=1'.format(target_machine.cpu_family().to_upper())
]

platform_inc = include_directories('include')
platform_deps = [elemental]

install_subdir('include', strip_directory: true, install_dir: includedir)

libplatform = both_libraries('neutron-platform', platform_sources,
  c_args: platform_cflags,
  include_directories: platform_inc,
  dependencies: platform_deps,
  version: version,
  gnu_symbol_visibility: 'hidden',
  install: true)
platform = declare_dependency(link_with: libplatform,
  include_directories: platform_inc,
  dependencies: platform_deps)

pkg.generate(libplatform,
  name: 'neutron-platform',
  description: 'Platform specific API bindings',
  url: 'https://github.com/ExpidusOS/neutron',
  version: shortver)

subdir('tests', if_found: [check])
subdir('docs', if_found: [gtkdoc])
