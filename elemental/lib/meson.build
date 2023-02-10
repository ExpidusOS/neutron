elemental_ffigen_compiler_opts = [
  '-I @0@'.format(join_paths(meson.project_build_root(), 'elemental', 'include'))
]

if fs.exists(meson.project_source_root() / 'elemental' / 'pubspec.lock') and elemental_pub.returncode() == 0
  if ffigen.found()
    elemental_ffi = custom_target('elemental-ffigen',
      command: [
        ffigen,
        '--directory=@0@'.format(meson.project_source_root() / 'elemental'),
        '--file=@0@'.format(meson.project_source_root() / 'elemental' / 'ffigen.yaml'),
        '--compiler-opts="@0@"'.format(' '.join(elemental_ffigen_compiler_opts))
      ],
      output: 'bindings.dart',
      input: '../ffigen.yaml',
      build_by_default: true)
  elif dart.found()
    elemental_ffi = custom_target('elemental-ffigen',
      command: [
        'dart', 'pub', 'run', '-C', meson.project_source_root() / 'elemental', 'ffigen',
        '--compiler-opts="@0@"'.format(' '.join(elemental_ffigen_compiler_opts))
      ],
      output: 'bindings.dart',
      input: '../ffigen.yaml',
      build_by_default: true)
  endif
endif

conf_data_elemental_ffi = configuration_data()
conf_data_elemental_ffi.merge_from(conf_data_elemental)
conf_data_elemental_ffi.set('LIBNAME', libelemental_name)

configure_file(input: 'path.dart.in', output: 'path.dart',
  configuration: conf_data_elemental_ffi,
  install: true,
  install_dir: dartdir / 'elemental' / 'lib')
