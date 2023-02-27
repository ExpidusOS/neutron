if fs.exists(meson.project_source_root() / 'packages' / 'pubspec.lock') and packages_pub.returncode() == 0
  if ffigen.found()
    packages_ffi = custom_target('packages-ffigen',
      command: [
        ffigen,
        '--directory=@0@'.format(meson.project_source_root() / 'packages'),
        '--file=@0@'.format(meson.project_source_root() / 'packages' / 'ffigen.yaml')
      ],
      depends: [elemental_ffi],
      output: 'bindings.dart',
      input: '../ffigen.yaml',
      build_by_default: true)
  elif dart.found()
    packages_ffi = custom_target('packages-ffigen',
      command: [
        'dart', 'pub', 'run', '-C', meson.project_source_root() / 'packages', 'ffigen'
      ],
      depends: [elemental_ffi],
      output: 'bindings.dart',
      input: '../ffigen.yaml',
      build_by_default: true)
  endif
endif

conf_data_packages_ffi = configuration_data()
conf_data_packages_ffi.merge_from(conf_data_packages)
conf_data_packages_ffi.set('LIBNAME', libpackages_name)

configure_file(input: 'path.dart.in', output: 'path.dart',
  configuration: conf_data_packages_ffi,
  install: true,
  install_dir: dartdir / 'packages' / 'lib')
