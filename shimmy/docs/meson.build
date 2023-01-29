gnome.gtkdoc('neutron-shimmy',
  main_xml: 'manual.xml',
  content_files: configure_file(input: 'version.xml.in', output: 'version.xml', configuration: conf_data),
  src_dir: [
    join_paths(meson.project_source_root(), 'shimmy', 'include'),
  ],
  scan_args: ['--rebuild-sections'],
  dependencies: [shimmy],
  install: true)
