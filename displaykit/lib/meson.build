if fs.exists(meson.project_source_root() / 'displaykit' / 'pubspec.lock') and displaykit_pub.returncode() == 0
  if ffigen.found()
    displaykit_ffi = custom_target('displaykit-ffigen',
      command: [
        ffigen,
        '--directory=@0@'.format(meson.project_source_root() / 'displaykit'),
        '--file=@0@'.format(meson.project_source_root() / 'displaykit' / 'ffigen.yaml')
      ],
      depends: [elemental_ffi],
      output: 'bindings.dart',
      input: '../ffigen.yaml',
      build_by_default: true)
  elif dart.found()
    displaykit_ffi = custom_target('displaykit-ffigen',
      command: [
        'dart', 'pub', 'run', '-C', meson.project_source_root() / 'displaykit', 'ffigen'
      ],
      depends: [elemental_ffi],
      output: 'bindings.dart',
      input: '../ffigen.yaml',
      build_by_default: true)
  endif
endif

conf_data_displaykit_ffi = configuration_data()
conf_data_displaykit_ffi.merge_from(conf_data_displaykit)
conf_data_displaykit_ffi.set('LIBNAME', libdisplaykit_name)

configure_file(input: 'path.dart.in', output: 'path.dart',
  configuration: conf_data_displaykit_ffi,
  install: true,
  install_dir: dartdir / 'displaykit' / 'lib')
