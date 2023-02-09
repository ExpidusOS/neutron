if fs.exists(meson.project_source_root() / 'runtime' / 'pubspec.lock')
  if ffigen.found()
    runtime_ffi = custom_target('runtime-ffigen',
      command: [
        ffigen,
        '--directory=@0@'.format(meson.project_source_root() / 'runtime'),
        '--file=@0@'.format(meson.project_source_root() / 'runtime' / 'ffigen.yaml')
      ],
      depends: [elemental_ffi],
      output: 'bindings.dart',
      input: '../ffigen.yaml',
      build_by_default: true)
  elif dart.found()
    runtime_ffi = custom_target('runtime-ffigen',
      command: [
        'dart', 'pub', 'run', '-C', meson.project_source_root() / 'runtime', 'ffigen'
      ],
      depends: [elemental_ffi],
      output: 'bindings.dart',
      input: '../ffigen.yaml',
      build_by_default: true)
  endif
endif

conf_data_runtime_ffi = configuration_data()
conf_data_runtime_ffi.merge_from(conf_data_runtime)
conf_data_runtime_ffi.set('LIBNAME', libruntime_name)

configure_file(input: 'path.dart.in', output: 'path.dart',
  configuration: conf_data_runtime_ffi,
  install: true,
  install_dir: dartdir / 'runtime' / 'lib')
