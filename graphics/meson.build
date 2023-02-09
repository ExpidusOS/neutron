conf_data_graphics = configuration_data()
conf_data_graphics.merge_from(conf_data)

graphics_renderers_xml = ''

if egl.found()
  graphics_renderers_xml += '<xi:include href="xml/egl.xml" />'
  conf_data_graphics.set('NT_GRAPHICS_HAS_EGL', true)
endif

if pixman.found()
  graphics_renderers_xml += '<xi:include href="xml/pixman.xml" />'
  conf_data_graphics.set('NT_GRAPHICS_HAS_PIXMAN', true)
endif

conf_data_graphics.set('GRAPHICS_RENDERERS_XML', graphics_renderers_xml)

build_conf_graphics = configure_file(input: 'src/build.h', output: 'neutron-graphics-build.h',
  configuration: conf_data_graphics)

graphics_sources = [
  'src/renderer.c', 'src/scene-layer.c', 'src/scene.c'
]

graphics_cflags = []

graphics_inc = [include_directories('include')]
graphics_docs_inc_paths = []
graphics_dart_inc_paths = []
graphics_deps = [elemental, flutter_engine, thread]
graphics_renderers = []

subdir('renderers')

subdir('include/neutron/graphics')
install_subdir('include', strip_directory: true,
  install_dir: includedir,
  exclude_files: [
    'neutron/graphics/build.h.in',
    'neutron/graphics/meson.build'
  ])

libgraphics = library('neutron-graphics', graphics_sources,
  c_args: graphics_cflags,
  include_directories: graphics_inc,
  dependencies: graphics_deps,
  version: version,
  gnu_symbol_visibility: 'hidden',
  install: true)
graphics = declare_dependency(link_with: libgraphics,
  include_directories: graphics_inc,
  dependencies: graphics_deps)
libgraphics_name = fs.name(libgraphics.full_path())
libs += [libgraphics]
neutron_inc += graphics_inc
neutron_deps += graphics_deps

foreach src : graphics_sources
  neutron_sources += ['graphics' / src]
endforeach

pkg.generate(libgraphics,
  name: 'neutron-graphics',
  description: 'Graphical API for ExpidusOS\'s Neutron',
  url: 'https://github.com/ExpidusOS/neutron',
  version: shortver)

if dart.found()
  graphics_cmake = configure_file(input: 'CMakeLists.txt.in', output: 'CMakeLists.txt',
    configuration: conf_data_graphics,
    install: true,
    install_dir: dartdir / 'graphics')
  install_data(graphics_cmake, install_dir: dartdir / 'graphics' / flutter_os)

  graphics_pub = run_command([dart, 'pub', 'get', '-C', meson.current_source_dir()], check: false)

  if graphics_pub.returncode() != 0
    warning('Graphics ffi generation is disabled due to: @0@'.format(graphics_pub.stderr()))
  endif

  install_data('pubspec.yaml', install_dir: dartdir / 'graphics')

  if fs.exists(meson.current_source_dir() / 'pubspec.lock')
    install_data('.dart_tool/package_config.json', install_dir: dartdir / 'graphics' / '.dart_tool')
    install_data('pubspec.lock', install_dir: dartdir / 'graphics')
  endif
endif

subdir('lib')
install_subdir('lib', strip_directory: true,
  install_dir: dartdir / 'graphics' / 'lib',
  exclude_files: [
    'path.dart.in',
    'meson.build'
  ])

subdir('docs', if_found: [gtkdoc])

summary({
    'Renderers': graphics_renderers
  }, section: 'Graphics')
