conf_data_elemental = configuration_data()
conf_data_elemental.merge_from(conf_data)

conf_data_elemental.set('HAS_EXECINFO_H', has_execinfo_h)
conf_data_elemental.set('HAS_POSIX', is_posix)
conf_data_elemental.set('NT_IS_@0@'.format(target_machine.system().to_upper()), true)
conf_data_elemental.set('NT_HAS_POSIX', is_posix)

build_conf_elemental = configure_file(input: 'src/build.h', output: 'neutron-elemental-build.h',
  configuration: conf_data_elemental)

elemental_sources = [
  'src/argument.c', 'src/backtrace.c', 'src/error.c',
  'src/fs.c', 'src/list.c', 'src/signal.c', 'src/string.c',
  'src/type.c'
]

elemental_cflags = [
  '-D@0@=1'.format(target_machine.system().to_upper()),
  '-D@0@=1'.format(target_machine.cpu_family().to_upper())
]

elemental_inc = include_directories('include')
elemental_deps = [thread]

subdir('include/neutron/elemental')
install_subdir('include', strip_directory: true,
  install_dir: includedir,
  exclude_files: [
    'neutron/elemental/build.h.in',
    'neutron/elemental/meson.build'
  ])

libelemental = library('neutron-elemental', elemental_sources,
  c_args: elemental_cflags,
  include_directories: elemental_inc,
  dependencies: elemental_deps,
  version: version,
  gnu_symbol_visibility: 'hidden',
  install: true)
elemental = declare_dependency(link_with: libelemental,
  include_directories: elemental_inc,
  dependencies: elemental_deps)
libelemental_name = fs.name(libelemental.full_path())

libs += [libelemental]
neutron_cflags += elemental_cflags
neutron_inc += elemental_inc
neutron_deps += elemental_deps

foreach src : elemental_sources
  neutron_sources += ['elemental' / src]
endforeach

pkg.generate(libelemental,
  name: 'neutron-elemental',
  description: 'A minimal resource usage type system for C',
  url: 'https://github.com/ExpidusOS/neutron',
  version: shortver)

if dart.found()
  elemental_cmake = configure_file(input: 'CMakeLists.txt.in', output: 'CMakeLists.txt',
    configuration: conf_data_elemental,
    install: true,
    install_dir: dartdir / 'elemental')
  install_data(elemental_cmake, install_dir: dartdir / 'elemental' / flutter_os)

  elemental_pub = run_command([dart, 'pub', 'get', '-C', meson.current_source_dir(), dart_pub_flags], check: false)

  if elemental_pub.returncode() != 0
    error('Elemental ffi generation is disabled due to: @0@'.format(elemental_pub.stderr()))
  endif

  install_data('pubspec.yaml', install_dir: dartdir / 'elemental')
  install_data('README.md', install_dir: dartdir / 'elemental')
endif

if not is_bootstrap
  subdir('lib')

  install_subdir('lib', strip_directory: true,
    install_dir: dartdir / 'elemental' / 'lib',
    exclude_files: [
      'path.dart.in',
      'meson.build'
    ])
endif

subdir('tests', if_found: [check])
subdir('docs', if_found: [gtkdoc])
