conf_data_elemental = configuration_data()
conf_data_elemental.merge_from(conf_data)

if has_execinfo_h
  conf_data_elemental.set('HAS_EXECINFO_H', true)
else
  conf_data_elemental.set('HAS_EXECINFO_H', false)
endif

build_conf_elemental = configure_file(input: 'src/build.h', output: 'neutron-elemental-build.h',
  configuration: conf_data_elemental)

elemental_sources = [
  'src/argument.c', 'src/backtrace.c', 'src/error.c',
  'src/list.c', 'src/signal.c', 'src/type.c'
]

elemental_inc = include_directories('include')
elemental_deps = [thread]

install_subdir('include', strip_directory: true, install_dir: includedir)

libelemental = library('neutron-elemental', elemental_sources,
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

  elemental_pub = run_command([dart, 'pub', 'get', '-C', meson.current_source_dir()], check: false)

  if elemental_pub.returncode() != 0
    warning('Elemental ffi generation is disabled due to: @0@'.format(elemental_pub.stderr()))
  endif

  install_data('pubspec.yaml', install_dir: dartdir / 'elemental')
  install_data('README.md', install_dir: dartdir / 'elemental')

  if fs.exists(meson.current_source_dir() / 'pubspec.lock')
    install_data('.dart_tool/package_config.json', install_dir: dartdir / 'elemental' / '.dart_tool')
    install_data('pubspec.lock', install_dir: dartdir / 'elemental')
  endif
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
