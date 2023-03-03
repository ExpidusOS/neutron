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
  'src/device-enum.c', 'src/device.c', 'src/platform.c',
  'src/process.c', 'src/thread.c', 'src/user.c'
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
libplatform_name = fs.name(libplatform.full_path())
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
  libraries: platform_deps,
  version: shortver)

if dart.found()
  platform_cmake = configure_file(input: 'CMakeLists.txt.in', output: 'CMakeLists.txt',
    configuration: conf_data_platform,
    install: true,
    install_dir: dartdir / 'platform')
  install_data(elemental_cmake, install_dir: dartdir / 'platform' / flutter_os)

  platform_pub = run_command([dart, 'pub', 'get', '-C', meson.current_source_dir(), dart_pub_flags], check: false)

  if platform_pub.returncode() != 0
    error('Platform ffi generation is disabled due to: @0@'.format(platform_pub.stderr()))
  endif

  install_data('pubspec.yaml', install_dir: dartdir / 'platform')
endif

subdir('lib')
install_subdir('lib', strip_directory: true,
  install_dir: dartdir / 'platform' / 'lib',
  exclude_files: [
    'path.dart.in',
    'meson.build'
  ])

subdir('tests', if_found: [check])
subdir('docs', if_found: [gtkdoc])

summary({
    'Target': platform_target
  }, section: 'Platform')
