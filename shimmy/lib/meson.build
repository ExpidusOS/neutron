if fs.exists(meson.project_source_root() / 'shimmy' / 'pubspec.lock') and shimmy_pub.returncode() == 0
  if ffigen.found()
    shimmy_ffi = custom_target('shimmy-ffigen',
      command: [
        ffigen,
        '--directory=@0@'.format(meson.project_source_root() / 'shimmy'),
        '--file=@0@'.format(meson.project_source_root() / 'shimmy' / 'ffigen.yaml')
      ],
      depends: [elemental_ffi, platform_ffi],
      output: 'bindings.dart',
      input: '../ffigen.yaml',
      build_by_default: true)
  elif dart.found()
    shimmy_ffi = custom_target('shimmy-ffigen',
      command: [
        'dart', 'pub', 'run', '-C', meson.project_source_root() / 'shimmy', 'ffigen'
      ],
      depends: [elemental_ffi, platform_ffi],
      output: 'bindings.dart',
      input: '../ffigen.yaml',
      build_by_default: true)
  endif
endif

conf_data_shimmy_ffi = configuration_data()
conf_data_shimmy_ffi.merge_from(conf_data_shimmy)
conf_data_shimmy_ffi.set('LIBNAME', libshimmy_name)

configure_file(input: 'path.dart.in', output: 'path.dart',
  configuration: conf_data_shimmy_ffi,
  install: true,
  install_dir: dartdir / 'shimmy' / 'lib')
