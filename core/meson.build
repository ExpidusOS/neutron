conf_data_core = configuration_data()
conf_data_core.merge_from(conf_data)

core_flags = []
core_reqs = []
core_extra_deps = ''
core_rel_sources = ['lib/context.vala', 'lib/provider.vala']
core_sources = []
core_vala_args = []
core_deps = [gio, vadi]
core_docs_args = ['--package-name=neutron', '--package-version=@0@'.format(shortver)]

if libpeas.found()
  conf_data_core.set('HAS_LIBPEAS', 'true')
  core_reqs += ['libpeas-1.0']
  core_extra_deps += 'libpeas-1.0\n'
  core_vala_args += ['--define=HAS_LIBPEAS=1']
  core_deps += [libpeas]
  core_docs_args += ['--pkg', 'libpeas-1.0']
  core_rel_sources += ['lib/context/libpeas.vala']
else
  conf_data_core.set('HAS_LIBPEAS', 'false')
endif

if gmodule.found()
  conf_data_core.set('HAS_GMODULE', 'true')
  core_reqs += ['gmodule-2.0']
  core_extra_deps += 'gmodule-2.0\n'
  core_vala_args += ['--define=HAS_GMODULE=1']
  core_deps += [gmodule]
  core_docs_args += ['--pkg', 'gmodule-2.0']
  core_rel_sources += ['lib/context/gmodule.vala']
else
  conf_data_core.set('HAS_GMODULE', 'false')
endif

conf_data_core.set('EXTRA_DEPS', core_extra_deps)
build_conf_core = configure_file(input: 'lib/build.vala.in', output: 'build.vala',
  configuration: conf_data_core)

foreach src : core_rel_sources
  core_sources += [join_paths(meson.current_source_dir(), src)]
endforeach

if uncrustify.found()
  run_target('core-prettier',
    command: [uncrustify, '--no-backup', core_sources])
endif

core_rel_sources += [build_conf_core]
core_sources += [build_conf_core]
core_shlib = shared_library('neutron', core_rel_sources,
  c_args: ['-DG_LOG_DOMAIN="Neutron"'],
  vala_args: core_vala_args,
  vala_gir: 'Neutron-@0@.gir'.format(shortver.split('-')[0]),
  dependencies: core_deps,
  version: shortver.split('-')[0],
  install: true,
  install_dir: [true, true, true, true])
core = declare_dependency(link_with: core_shlib, dependencies: core_deps,
  compile_args: ['-I' + meson.current_build_dir()])
pkg.generate(core_shlib,
  name: 'neutron',
  requires: ['gio-2.0', 'vadi-0.0', core_reqs],
  description: 'A common system library for handling things such as rotation, calls, networking, etc.',
  url: 'https://github.com/ExpidusOS/neutron',
  version: longver)

subdir('docs', if_found: [valadoc])
