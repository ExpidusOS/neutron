gnome.gtkdoc('neutron-graphics',
  main_xml: 'manual.xml',
  content_files: configure_file(input: 'version.xml.in', output: 'version.xml', configuration: conf_data),
  src_dir: [
    join_paths(meson.project_source_root(), 'graphics', 'include'),
  ],
  dependencies: [graphics],
  install: true)
