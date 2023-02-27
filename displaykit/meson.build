conf_data_displaykit = configuration_data()
conf_data_displaykit.merge_from(conf_data)

displaykit_compositors_xml = ''

if wlroots.found()
  displaykit_compositors_xml += '<xi:include href="xml/wlroots-compositor.xml" />'
  conf_data_displaykit.set('NT_DISPLAYKIT_HAS_WLROOTS', true)
endif

conf_data_displaykit.set('DISPLAYKIT_COMPOSITORS_XML', displaykit_compositors_xml)

build_config_displaykit = configure_file(input: 'src/build.h', output: 'neutron-displaykit-build.h',
  configuration: conf_data_displaykit)

displaykit_sources = [
  'src/client.c', 'src/compositor.c', 'src/context.c',
  'src/output.c', 'src/view.c'
]
displaykit_cflags = []

displaykit_inc = [include_directories('include')]
displaykit_docs_inc_paths = []
displaykit_deps = [elemental, graphics]

displaykit_compositors = []
displaykit_clients = []

subdir('compositors')
subdir('clients')

subdir('include/neutron/displaykit')
install_subdir('include', strip_directory: true,
  install_dir: includedir,
  exclude_files: [
    'neutron/displaykit/build.h.in',
    'neutron/displaykit/meson.build'
  ])

libdisplaykit = library('neutron-displaykit', displaykit_sources,
  c_args: displaykit_cflags,
  include_directories: displaykit_inc,
  dependencies: displaykit_deps,
  version: version,
  gnu_symbol_visibility: 'hidden',
  install: true)
displaykit = declare_dependency(link_with: libdisplaykit,
  include_directories: displaykit_inc,
  dependencies: displaykit_deps)
libdisplaykit_name = fs.name(libdisplaykit.full_path())
libs += [libdisplaykit]
neutron_inc += displaykit_inc
neutron_cflags += displaykit_cflags
neutron_deps += displaykit_deps

foreach src : displaykit_sources
  neutron_sources += ['displaykit' / src]
endforeach

pkg.generate(libdisplaykit,
  name: 'neutron-displaykit',
  description: 'Display server API for compositors and clients for ExpidusOS\'s Neutron',
  url: 'https://github.com/ExpidusOS/neutron',
  libraries: displaykit_deps,
  version: shortver)

if dart.found()
  displaykit_cmake = configure_file(input: 'CMakeLists.txt.in', output: 'CMakeLists.txt',
    configuration: conf_data_displaykit,
    install: true,
    install_dir: dartdir / 'displaykit')
  install_data(elemental_cmake, install_dir: dartdir / 'displaykit' / flutter_os)

  displaykit_pub = run_command([dart, 'pub', 'get', '-C', meson.current_source_dir(), dart_pub_flags], check: false)

  if displaykit_pub.returncode() != 0
    error('DisplayKit ffi generation is disabled due to: @0@'.format(displaykit_pub.stderr()))
  endif

  install_data('pubspec.yaml', install_dir: dartdir / 'displaykit')
  install_data('README.md', install_dir: dartdir / 'displaykit')
endif

subdir('lib')
install_subdir('lib', strip_directory: true,
  install_dir: dartdir / 'displaykit' / 'lib',
  exclude_files: [
    'path.dart.in',
    'meson.build'
  ])

subdir('docs', if_found: [gtkdoc])

summary({
    'Clients': displaykit_clients,
    'Compositors': displaykit_compositors
  }, section: 'DisplayKit')
