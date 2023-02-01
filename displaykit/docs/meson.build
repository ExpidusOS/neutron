gnome.gtkdoc('neutron-displaykit',
  main_xml: join_paths(meson.current_build_dir(), 'manual.xml'),
  content_files: [
    configure_file(input: 'manual.xml.in', output: 'manual.xml', configuration: conf_data_displaykit),
    configure_file(input: 'version.xml.in', output: 'version.xml', configuration: conf_data_displaykit)
  ],
  src_dir: [
    join_paths(meson.project_source_root(), 'displaykit', 'include'),
    join_paths(meson.project_build_root(), 'displaykit', 'include'),
    displaykit_docs_inc_paths
  ],
  scan_args: ['--rebuild-sections'],
  dependencies: [displaykit],
  install: true)
