gnome.gtkdoc('neutron-inputcore',
  main_xml: 'manual.xml',
  content_files: configure_file(input: 'version.xml.in', output: 'version.xml', configuration: conf_data),
  src_dir: [
    join_paths(meson.project_source_root(), 'inputcore', 'include'),
  ],
  scan_args: ['--rebuild-sections'],
  dependencies: [elemental],
  install: true)
