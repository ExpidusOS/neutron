if fs.exists(meson.project_source_root() / 'platform' / 'pubspec.lock') and platform_pub.returncode() == 0
  if ffigen.found()
    platform_ffi = custom_target('platform-ffigen',
      command: [
        ffigen,
        '--directory=@0@'.format(meson.project_source_root() / 'platform'),
        '--file=@0@'.format(meson.project_source_root() / 'platform' / 'ffigen.yaml')
      ],
      depends: [elemental_ffi],
      output: 'bindings.dart',
      input: '../ffigen.yaml',
      build_by_default: true)
  elif dart.found()
    platform_ffi = custom_target('platform-ffigen',
      command: [
        'dart', 'pub', 'run', '-C', meson.project_source_root() / 'platform', 'ffigen'
      ],
      depends: [elemental_ffi],
      output: 'bindings.dart',
      input: '../ffigen.yaml',
      build_by_default: true)
  endif
endif

conf_data_platform_ffi = configuration_data()
conf_data_platform_ffi.merge_from(conf_data_platform)
conf_data_platform_ffi.set('LIBNAME', libplatform_name)

configure_file(input: 'path.dart.in', output: 'path.dart',
  configuration: conf_data_platform_ffi,
  install: true,
  install_dir: dartdir / 'platform' / 'lib')
