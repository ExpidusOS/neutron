conf_data_flutter_engine = configuration_data()
conf_data_flutter_engine.merge_from(conf_data)
conf_data_flutter_engine.set('FLUTTER_ENGINE_DIR', get_option('flutter-engine'))

libflutter_engine_name = fs.name(flutter_engine.name())

flutter_engine_ffi_config = configure_file(input: 'ffigen.yaml.in', output: 'ffigen.yaml',
  configuration: conf_data_flutter_engine)

if dart.found()
  flutter_engine_cmake = configure_file(input: 'CMakeLists.txt.in', output: 'CMakeLists.txt',
    configuration: conf_data_flutter_engine,
    install: true,
    install_dir: dartdir / 'elemental')
  install_data(flutter_engine_cmake, install_dir: dartdir / 'flutter_engine' / flutter_os)

  flutter_engine_pub = run_command([dart, 'pub', 'get', '-C', meson.current_source_dir(), dart_pub_flags], check: false)

  if flutter_engine_pub.returncode() != 0
    warning('Flutter Engine ffi generation is disabled due to: @0@'.format(flutter_engine_pub.stderr()))
  endif

  install_data('pubspec.yaml', install_dir: dartdir / 'flutter_engine')
endif

subdir('lib')

install_subdir('lib', strip_directory: true,
  install_dir: dartdir / 'flutter_engine' / 'lib',
  exclude_files: [
    'path.dart.in',
    'meson.build'
  ])
