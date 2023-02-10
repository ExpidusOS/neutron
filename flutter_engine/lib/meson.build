flutter_engine_ffigen_compiler_opts = [
  '-I@0@'.format(get_option('flutter-engine'))
]

if fs.exists(meson.project_source_root() / 'flutter_engine' / 'pubspec.lock') and flutter_engine_pub.returncode() == 0
  if ffigen.found()
    flutter_engine_ffi = custom_target('flutter-engine-ffigen',
      command: [
        ffigen,
        '--directory=@0@'.format(meson.project_source_root() / 'flutter_engine'),
        '--file=@0@'.format(flutter_engine_ffi_config),
        '--compiler-opts="@0@"'.format(' '.join(flutter_engine_ffigen_compiler_opts))
      ],
      output: 'bindings.dart',
      input: flutter_engine_ffi_config,
      build_by_default: true)
  elif dart.found()
    flutter_engine_ffi = custom_target('flutter-engine-ffigen',
      command: [
        'dart', 'pub', 'run', '-C', meson.project_source_root() / 'flutter_engine', 'ffigen',
        '--config', flutter_engine_ffi_config,
        '--compiler-opts', ' '.join(flutter_engine_ffigen_compiler_opts)
      ],
      output: 'bindings.dart',
      input: flutter_engine_ffi_config,
      build_by_default: true)
  endif
else
  flutter_engine_ffi = disabler()
endif

conf_data_flutter_engine_ffi = configuration_data()
conf_data_flutter_engine_ffi.merge_from(conf_data_flutter_engine)
conf_data_flutter_engine_ffi.set('LIBNAME', libflutter_engine_name)

configure_file(input: 'path.dart.in', output: 'path.dart',
  configuration: conf_data_flutter_engine_ffi,
  install: true,
  install_dir: dartdir / 'flutter_engine' / 'lib')
