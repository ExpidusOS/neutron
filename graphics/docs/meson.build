gnome.gtkdoc('neutron-graphics',
  main_xml: join_paths(meson.current_build_dir(), 'manual.xml'),
  content_files: [
    configure_file(input: 'manual.xml.in', output: 'manual.xml', configuration: conf_data_graphics),
    configure_file(input: 'version.xml.in', output: 'version.xml', configuration: conf_data_graphics)
  ],
  src_dir: [
    join_paths(meson.project_source_root(), 'graphics', 'include'),
    join_paths(meson.project_build_root(), 'graphics', 'include'),
    graphics_docs_inc_paths
  ],
  scan_args: ['--rebuild-sections'],
  dependencies: [graphics],
  install: true)
