gnome.gtkdoc('neutron-platform',
  main_xml: 'manual.xml',
  content_files: configure_file(input: 'version.xml.in', output: 'version.xml', configuration: conf_data),
  src_dir: [
    join_paths(meson.project_source_root(), 'platform', 'include'),
  ],
  dependencies: [platform],
  install: true)
