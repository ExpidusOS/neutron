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

subdir('docs', if_found: [gtkdoc])

summary({
    'Renderers': graphics_renderers
  }, section: 'Graphics')
