conf_data_elemental = configuration_data()
conf_data_elemental.merge_from(conf_data)

build_conf_elemental = configure_file(input: 'src/build.h', output: 'neutron-elemental-build.h',
  configuration: conf_data_elemental)

elemental_sources = [
  'src/argument.c', 'src/backtrace.c', 'src/error.c',
  'src/list.c', 'src/signal.c', 'src/type.c'
]

elemental_inc = include_directories('include')
elemental_deps = [pthread]
elemental_extras = []

install_subdir('include', strip_directory: true, install_dir: includedir)

if flutter.found()
  elemental_pub = run_command([flutter, 'pub', 'get', meson.current_source_dir()], check: false)

  if elemental_pub.returncode() == 0
    subdir('lib/platforms/native')
  else
    warning('Elemental ffi generation is disabled due to: @0@'.format(elemental_pub.stderr()))
  endif

  install_data('pubspec.yaml', install_dir: dartdir / 'elemental')
  install_data('README.md', install_dir: dartdir / 'elemental')

  if fs.exists(meson.current_source_dir() / 'pubspec.lock')
    install_data('.dart_tool/package_config.json', install_dir: dartdir / 'elemental' / '.dart_tool')
    install_data('pubspec.lock', install_dir: dartdir / 'elemental')
  endif
endif

install_subdir('lib', strip_directory: true,
  install_dir: dartdir / 'elemental' / 'lib',
  exclude_files: [
    'platforms/native/meson.build'
  ])

libelemental = both_libraries('neutron-elemental', elemental_sources,
  include_directories: elemental_inc,
  dependencies: elemental_deps,
  version: version,
  gnu_symbol_visibility: 'hidden',
  install: true)
elemental = declare_dependency(link_with: libelemental,
  include_directories: elemental_inc,
  dependencies: elemental_deps)
libs += [libelemental]

pkg.generate(libelemental,
  name: 'neutron-elemental',
  description: 'A minimal resource usage type system for C',
  url: 'https://github.com/ExpidusOS/neutron',
  version: shortver)

subdir('tests', if_found: [check])
subdir('docs', if_found: [gtkdoc])
