core_docs_devhelp = custom_target('core-docs-devhelp',
  input: core_sources,
  depends: core_shlib,
  output: 'devhelp',
  command: [valadoc, '-o', join_paths(meson.current_build_dir(), 'devhelp'),
      '--doclet', 'devhelp', '@INPUT@', '--force',
      '--pkg', 'vadi-0.0', '--pkg', 'gio-2.0',
      '--vapidir', join_paths(meson.project_source_root(), 'vapi'),
      core_docs_args],
  build_by_default: true)

install_subdir(join_paths(meson.current_build_dir(), 'devhelp', 'neutron'), install_dir: join_paths(datadir, 'devhelp', 'books'))
