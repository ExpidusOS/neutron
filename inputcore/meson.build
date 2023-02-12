conf_data_inputcore = configuration_data()
conf_data_inputcore.merge_from(conf_data)

build_config_inputcore = configure_file(input: 'src/build.h', output: 'neutron-inputcore-build.h',
  configuration: conf_data_inputcore)

inputcore_sources = [
  'src/device.c', 'src/keyboard.c', 'src/mouse.c', 'src/touch.c'
]

inputcore_cflags = []

inputcore_inc = include_directories('include')
inputcore_deps = [elemental]

install_subdir('include', strip_directory: true, install_dir: includedir)

libinputcore = library('neutron-inputcore', inputcore_sources,
  c_args: inputcore_cflags,
  include_directories: inputcore_inc,
  dependencies: inputcore_deps,
  version: version,
  gnu_symbol_visibility: 'hidden',
  install: true)
inputcore = declare_dependency(link_with: libinputcore,
  include_directories: inputcore_inc,
  dependencies: inputcore_deps)
libinputcore_name = fs.name(libinputcore.full_path())
libs += [libinputcore]
neutron_inc += inputcore_inc
neutron_deps += inputcore_deps

foreach src : inputcore_sources
  neutron_sources += ['inputcore' / src]
endforeach

pkg.generate(libinputcore,
  name: 'neutron-inputcore',
  description: 'Input device handling for Neutron',
  url: 'https://github.com/ExpidusOS/neutron',
  version: shortver)

if dart.found()
  inputcore_cmake = configure_file(input: 'CMakeLists.txt.in', output: 'CMakeLists.txt',
    configuration: conf_data_inputcore,
    install: true,
    install_dir: dartdir / 'inputcore')
  install_data(inputcore_cmake, install_dir: dartdir / 'inputcore' / flutter_os)

  inputcore_pub = run_command([dart, 'pub', 'get', '-C', meson.current_source_dir(), dart_pub_flags], check: false)

  if inputcore_pub.returncode() != 0
    warning('InputCore ffi generation is disabled due to: @0@'.format(inputcore_pub.stderr()))
  endif

  install_data('pubspec.yaml', install_dir: dartdir / 'inputcore')
endif

subdir('lib')
install_subdir('lib', strip_directory: true,
  install_dir: dartdir / 'inputcore' / 'lib',
  exclude_files: [
    'path.dart.in',
    'meson.build'
  ])

subdir('docs', if_found: [gtkdoc])
