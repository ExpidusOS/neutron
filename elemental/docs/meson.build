gnome.gtkdoc('neutron-elemental',
  main_xml: 'manual.xml',
  content_files: configure_file(input: 'version.xml.in', output: 'version.xml', configuration: conf_data),
  src_dir: [
    join_paths(meson.project_source_root(), 'elemental', 'include'),
    join_paths(meson.project_build_root(), 'elemental', 'include'),
  ],
  scan_args: ['--rebuild-sections'],
  dependencies: [elemental],
  install: true)
