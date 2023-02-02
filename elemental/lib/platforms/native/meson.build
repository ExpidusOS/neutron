if fs.exists(meson.project_source_root() / 'pubspec.lock')
  if ffigen.found()
    elemental_ffi = custom_target('elemental-ffigen',
      command: [
        ffigen, '--flutter',
        '--directory=@0@'.format(meson.project_source_root() / 'elemental'),
        '--file=@0@'.format(meson.project_source_root() / 'elemental' / 'ffigen.yaml')
      ],
      output: 'bindings.dart',
      input: '../../../ffigen.yaml')
  elif flutter.found()
    elemental_ffi = custom_target('elemental-ffigen',
      command: [
        flutter, 'pub', 'run', '-C', meson.project_source_root() / 'elemental', 'ffigen'
      ],
      output: 'bindings.dart',
      input: '../../../ffigen.yaml')
  endif
endif

conf_data_elemental_ffi = configuration_data()
conf_data_elemental_ffi.merge_from(conf_data_elemental)
conf_data_elemental_ffi.set('LIBNAME', libelemental_name)

configure_file(input: 'path.dart.in', output: 'path.dart',
  configuration: conf_data_elemental_ffi,
  install: true,
  install_dir: dartdir / 'elemental' / 'lib' / 'platforms' / 'native')
