graphics_ffigen_compiler_opts = [
  '-I@0@'.format(join_paths(meson.project_build_root(), 'graphics', 'include')),
  '-I@0@'.format(get_option('flutter-engine'))
]

foreach inc : graphics_dart_inc_paths
  graphics_ffigen_compiler_opts += '-I@0@'.format(inc)
endforeach

if fs.exists(meson.project_source_root() / 'graphics' / 'pubspec.lock')
  if ffigen.found()
    graphics_ffi = custom_target('graphics-ffigen',
      command: [
        ffigen,
        '--directory=@0@'.format(meson.project_source_root() / 'graphics'),
        '--file=@0@'.format(meson.project_source_root() / 'graphics' / 'ffigen.yaml'),
        '--compiler-opts="@0@"'.format(' '.join(graphics_ffigen_compiler_opts))
      ],
      depends: [elemental_ffi, platform_ffi, flutter_engine_ffi],
      output: 'bindings.dart',
      input: '../ffigen.yaml',
      build_by_default: true)
  elif dart.found()
    graphics_ffi = custom_target('graphics-ffigen',
      command: [
        'dart', 'pub', 'run', '-C', meson.project_source_root() / 'graphics', 'ffigen',
        '--compiler-opts="@0@"'.format(' '.join(graphics_ffigen_compiler_opts))
      ],
      depends: [elemental_ffi, platform_ffi, flutter_engine_ffi],
      output: 'bindings.dart',
      input: '../ffigen.yaml',
      build_by_default: true)
  endif
endif

conf_data_graphics_ffi = configuration_data()
conf_data_graphics_ffi.merge_from(conf_data_graphics)
conf_data_graphics_ffi.set('LIBNAME', libgraphics_name)

configure_file(input: 'path.dart.in', output: 'path.dart',
  configuration: conf_data_graphics_ffi,
  install: true,
  install_dir: dartdir / 'graphics' / 'lib')
