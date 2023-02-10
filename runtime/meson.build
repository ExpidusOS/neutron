conf_data_runtime = configuration_data()
conf_data_runtime.merge_from(conf_data)

build_conf_runtime = configure_file(input: 'src/build.h', output: 'neutron-runtime-build.h',
  configuration: conf_data_runtime)

runtime_sources = []

runtime_cflags = []
runtime_inc = include_directories('include')
runtime_deps = [elemental, graphics]

install_subdir('include', strip_directory: true, install_dir: includedir)

libruntime = library('neutron-runtime', runtime_sources,
  c_args: runtime_cflags,
  include_directories: runtime_inc,
  dependencies: runtime_deps,
  version: version,
  gnu_symbol_visibility: 'hidden',
  install: true)
runtime = declare_dependency(link_with: libruntime,
  include_directories: runtime_inc,
  dependencies: runtime_deps)
libruntime_name = fs.name(libruntime.full_path())
libs += [libruntime]
neutron_inc += runtime_inc
neutron_deps += runtime_deps

foreach src : runtime_sources
  neutron_sources += ['runtime' / src]
endforeach

pkg.generate(libruntime,
  name: 'neutron-runtime',
  description: 'Runtime API for Neutron',
  url: 'https://github.com/ExpidusOS/neutron',
  version: shortver)

if dart.found()
  runtime_cmake = configure_file(input: 'CMakeLists.txt.in', output: 'CMakeLists.txt',
    configuration: conf_data_runtime,
    install: true,
    install_dir: dartdir / 'runtime')
  install_data(elemental_cmake, install_dir: dartdir / 'runtime' / flutter_os)

  runtime_pub = run_command([dart, 'pub', 'get', '-C', meson.current_source_dir()], check: false)

  if runtime_pub.returncode() != 0
    warning('Runtime ffi generation is disabled due to: @0@'.format(runtime_pub.stderr()))
  endif

  install_data('pubspec.yaml', install_dir: dartdir / 'runtime')
  install_data('README.md', install_dir: dartdir / 'runtime')
endif

subdir('lib')
install_subdir('lib', strip_directory: true,
  install_dir: dartdir / 'runtime' / 'lib',
  exclude_files: [
    'path.dart.in',
    'meson.build'
  ])

subdir('docs', if_found: [gtkdoc])
