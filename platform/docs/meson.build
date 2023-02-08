gnome.gtkdoc('neutron-platform',
  main_xml: join_paths(meson.current_build_dir(), 'manual.xml'),
  content_files: [
    configure_file(input: 'manual.xml.in', output: 'manual.xml', configuration: conf_data_platform),
    configure_file(input: 'version.xml.in', output: 'version.xml', configuration: conf_data)
  ],
  src_dir: [
    join_paths(meson.project_source_root(), 'platform', 'include'),
    platform_docs_inc_paths
  ],
  scan_args: ['--rebuild-sections'],
  dependencies: [platform],
  install: true)
