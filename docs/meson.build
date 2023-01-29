conf_data_docs = configuration_data()
conf_data_docs.merge_from(conf_data)

conf_data_docs.set('GRAPHICS_RENDERERS_XML', graphics_renderers_xml)

gnome.gtkdoc('neutron',
  main_xml: join_paths(meson.current_build_dir(), 'manual.xml'),
  content_files: [
    configure_file(input: 'manual.xml.in', output: 'manual.xml', configuration: conf_data_docs),
    configure_file(input: 'version.xml.in', output: 'version.xml', configuration: conf_data_docs)
  ],
  src_dir: [
    join_paths(meson.project_source_root(), 'elemental', 'include'),
    join_paths(meson.project_source_root(), 'platform', 'include'),
    join_paths(meson.project_source_root(), 'graphics', 'include'),
    join_paths(meson.project_build_root(), 'graphics', 'include'),
    graphics_docs_inc_paths
  ],
  scan_args: ['--rebuild-sections'],
  install: true)
