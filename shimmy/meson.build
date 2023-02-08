conf_data_shimmy = configuration_data()
conf_data_shimmy.merge_from(conf_data)

build_conf_shimmy = configure_file(input: 'src/build.h', output: 'neutron-shimmy-build.h',
  configuration: conf_data_shimmy)

shimmy_sources = [
  'src/shimmy.c'
]

shimmy_cflags = [
  '-D@0@=1'.format(target_machine.system().to_upper()),
  '-D@0@=1'.format(target_machine.cpu_family().to_upper())
]

shimmy_inc = include_directories('include')
shimmy_deps = [elemental, platform, pthread]

install_subdir('include', strip_directory: true, install_dir: includedir)

libshimmy = library('neutron-shimmy', shimmy_sources,
  c_args: shimmy_cflags,
  include_directories: shimmy_inc,
  dependencies: shimmy_deps,
  version: version,
  gnu_symbol_visibility: 'hidden',
  install: true)
shimmy = declare_dependency(link_with: libshimmy,
  include_directories: shimmy_inc,
  dependencies: shimmy_deps)
libs += [libshimmy]
neutron_inc += shimmy_inc
neutron_deps += shimmy_deps
neutron_cflags += shimmy_cflags

foreach src : shimmy_sources
  neutron_sources += ['shimmy' / src]
endforeach

pkg.generate(libshimmy,
  name: 'neutron-shimmy',
  description: 'Shims loader for Neutron',
  url: 'https://github.com/ExpidusOS/neutron',
  version: shortver)

subdir('tests', if_found: [check])
subdir('docs', if_found: [gtkdoc])
