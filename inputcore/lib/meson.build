if fs.exists(meson.project_source_root() / 'inputcore' / 'pubspec.lock') and inputcore_pub.returncode() == 0
  if ffigen.found()
    inputcore_ffi = custom_target('inputcore-ffigen',
      command: [
        ffigen,
        '--directory=@0@'.format(meson.project_source_root() / 'inputcore'),
        '--file=@0@'.format(meson.project_source_root() / 'inputcore' / 'ffigen.yaml')
      ],
      depends: [elemental_ffi],
      output: 'bindings.dart',
      input: '../ffigen.yaml',
      build_by_default: true)
  elif dart.found()
    inputcore_ffi = custom_target('inputcore-ffigen',
      command: [
        'dart', 'pub', 'run', '-C', meson.project_source_root() / 'inputcore', 'ffigen'
      ],
      depends: [elemental_ffi],
      output: 'bindings.dart',
      input: '../ffigen.yaml',
      build_by_default: true)
  endif
endif

conf_data_inputcore_ffi = configuration_data()
conf_data_inputcore_ffi.merge_from(conf_data_inputcore)
conf_data_inputcore_ffi.set('LIBNAME', libinputcore_name)

configure_file(input: 'path.dart.in', output: 'path.dart',
  configuration: conf_data_inputcore_ffi,
  install: true,
  install_dir: dartdir / 'inputcore' / 'lib')
