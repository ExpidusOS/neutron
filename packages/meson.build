conf_data_packages = configuration_data()
conf_data_packages.merge_from(conf_data)

build_conf_packages = configure_file(input: 'src/build.h', output: 'neutron-packages-build.h',
  configuration: conf_data_packages)

packages_sources = [
  'src/manager.c', 'src/metadata.c', 'src/package.c'
]

packages_cflags = []
packages_inc = include_directories('include')
packages_deps = [elemental, libxml2]

install_subdir('include', strip_directory: true, install_dir: includedir)

libpackages = library('neutron-packages', packages_sources,
  c_args: packages_cflags,
  include_directories: packages_inc,
  dependencies: packages_deps,
  version: version,
  gnu_symbol_visibility: 'hidden',
  install: true)
packages = declare_dependency(link_with: libpackages,
  include_directories: packages_inc,
  dependencies: packages_deps)
libpackages_name = fs.name(libpackages.full_path())
libs += [libpackages]
neutron_inc += packages_inc
neutron_deps += packages_deps

foreach src : packages_sources
  neutron_sources += ['packages' / src]
endforeach

pkg.generate(libpackages,
  name: 'neutron-packages',
  description: 'Packages API for Neutron',
  url: 'https://github.com/ExpidusOS/neutron',
  libraries: packages_deps,
  version: shortver)

if dart.found()
  packages_cmake = configure_file(input: 'CMakeLists.txt.in', output: 'CMakeLists.txt',
    configuration: conf_data_packages,
    install: true,
    install_dir: dartdir / 'packages')
  install_data(elemental_cmake, install_dir: dartdir / 'packages' / flutter_os)

  packages_pub = run_command([dart, 'pub', 'get', '-C', meson.current_source_dir(), dart_pub_flags], check: false)

  if packages_pub.returncode() != 0
    error('Packages ffi generation is disabled due to: @0@'.format(packages_pub.stderr()))
  endif

  install_data('pubspec.yaml', install_dir: dartdir / 'packages')
  install_data('README.md', install_dir: dartdir / 'packages')
endif

subdir('lib')
install_subdir('lib', strip_directory: true,
  install_dir: dartdir / 'packages' / 'lib',
  exclude_files: [
    'path.dart.in',
    'meson.build'
  ])

subdir('docs', if_found: [gtkdoc])
