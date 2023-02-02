if ffigen.found()
  elemental_ffi = custom_target('elemental-ffigen',
    command: [
      ffigen, '--flutter',
      '--directory=@0@'.format(meson.project_source_root() / 'elemental'),
      '--file=@0@'.format(meson.project_source_root() / 'elemental' / 'ffigen.yaml')
    ],
    output: 'bindings-gen.dart',
    input: '../../../ffigen.yaml')
elif flutter.found()
  elemental_ffi = custom_target('elemental-ffigen',
    command: [
      flutter, 'pub', 'run', '-C', meson.project_source_root() / 'elemental', 'ffigen'
    ],
    output: 'bindings-gen.dart',
    input: '../../../ffigen.yaml')
endif
