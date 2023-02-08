conf_data_platform = configuration_data()
conf_data_platform.merge_from(conf_data)

platform_xml = ''

if target_machine.system() == 'linux'
  platform_xml += '<xi:include href="xml/linux-platform.xml" />'
  platform_xml += '<xi:include href="xml/linux-process.xml" />'
  platform_xml += '<xi:include href="xml/systemd-device-enum.xml" />'
  platform_xml += '<xi:include href="xml/systemd-device.xml" />'
endif

conf_data_platform.set('PLATFORM_XML', platform_xml)

build_conf_platform = configure_file(input: 'src/build.h', output: 'neutron-platform-build.h',
  configuration: conf_data_platform)

platform_sources = [
  'src/device-enum.c', 'src/device.c', 'src/platform.c', 'src/process.c', 'src/thread.c'
]

platform_cflags = [
  '-D@0@=1'.format(target_machine.system().to_upper()),
  '-D@0@=1'.format(target_machine.cpu_family().to_upper())
]

platform_inc = [include_directories('include')]
platform_deps = [elemental]
platform_docs_inc_paths = []

install_subdir('include', strip_directory: true, install_dir: includedir)

subdir('targets')

libplatform = library('neutron-platform', platform_sources,
  c_args: platform_cflags,
  include_directories: platform_inc,
  dependencies: platform_deps,
  version: version,
  gnu_symbol_visibility: 'hidden',
  install: true)
platform = declare_dependency(link_with: libplatform,
  include_directories: platform_inc,
  dependencies: platform_deps)
libs += [libplatform]
neutron_inc += platform_inc
neutron_deps += platform_deps
neutron_cflags += platform_cflags

foreach src : platform_sources
  neutron_sources += ['platform' / src]
endforeach

pkg.generate(libplatform,
  name: 'neutron-platform',
  description: 'Platform specific API bindings',
  url: 'https://github.com/ExpidusOS/neutron',
  version: shortver)

subdir('tests', if_found: [check])
subdir('docs', if_found: [gtkdoc])

summary({
    'Target': platform_target
  }, section: 'Platform')
