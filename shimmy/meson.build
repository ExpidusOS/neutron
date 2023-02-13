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
shimmy_deps = [elemental, platform, thread]

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
libshimmy_name = fs.name(libshimmy.full_path())
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

if dart.found()
  shimmy_cmake = configure_file(input: 'CMakeLists.txt.in', output: 'CMakeLists.txt',
    configuration: conf_data_shimmy,
    install: true,
    install_dir: dartdir / 'shimmy')
  install_data(shimmy_cmake, install_dir: dartdir / 'shimmy' / flutter_os)

  shimmy_pub = run_command([dart, 'pub', 'get', '-C', meson.current_source_dir(), dart_pub_flags], check: false)

  if shimmy_pub.returncode() != 0
    error('Shimmy ffi generation is disabled due to: @0@'.format(shimmy_pub.stderr()))
  endif

  install_data('pubspec.yaml', install_dir: dartdir / 'shimmy')
endif

subdir('lib')
install_subdir('lib', strip_directory: true,
  install_dir: dartdir / 'shimmy' / 'lib',
  exclude_files: [
    'path.dart.in',
    'meson.build'
  ])

subdir('tests', if_found: [check])
subdir('docs', if_found: [gtkdoc])
