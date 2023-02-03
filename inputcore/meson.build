conf_data_inputcore = configuration_data()
conf_data_inputcore.merge_from(conf_data)

build_config_inputcore = configure_file(input: 'src/build.h', output: 'neutron-inputcore-build.h',
  configuration: conf_data_inputcore)

inputcore_sources = [
  'src/device.c', 'src/keyboard.c', 'src/mouse.c', 'src/touch.c'
]

inputcore_cflags = []

inputcore_inc = include_directories('include')
inputcore_deps = [elemental]

install_subdir('include', strip_directory: true, install_dir: includedir)

libinputcore = library('neutron-inputcore', inputcore_sources,
  c_args: inputcore_cflags,
  include_directories: inputcore_inc,
  dependencies: inputcore_deps,
  version: version,
  gnu_symbol_visibility: 'hidden',
  install: true)
inputcore = declare_dependency(link_with: libinputcore,
  include_directories: inputcore_inc,
  dependencies: inputcore_deps)
libs += [libinputcore]
neutron_inc += inputcore_inc
neutron_deps += inputcore_deps

foreach src : inputcore_sources
  neutron_sources += ['inputcore' / src]
endforeach

pkg.generate(libinputcore,
  name: 'neutron-inputcore',
  description: 'Input device handling for Neutron',
  url: 'https://github.com/ExpidusOS/neutron',
  version: shortver)

subdir('docs', if_found: [gtkdoc])
