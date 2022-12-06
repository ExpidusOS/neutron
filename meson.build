project('neutron', 'vala', 'c', license: 'GPL-3.0-only', version: '0.1.0-alpha')

add_project_arguments([
  '--hide-internal',
  '--vapidir', join_paths(meson.project_source_root(), 'vapi'),
  '--define=GETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
  '--define=TARGET_SYSTEM_@0@'.format(target_machine.system().to_upper())
], language: 'vala')

add_project_arguments([
  '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name())
], language: 'c')

gnome = import('gnome')
i18n = import('i18n')
pkg = import('pkgconfig')
fs = import('fs')

prefix = get_option('prefix')
bindir = prefix / get_option('bindir')
datadir = prefix / get_option('datadir')
libdir = prefix / get_option('libdir')
libexecdir = prefix / get_option('libexecdir')
localstatedir = get_option('localstatedir')

longver = '@0@'.format(meson.project_version())
shortver = longver
git = find_program('git', native: true, required: false)
i18n_args = ['--package-version=@0@'.format(longver), '--copyright-holder=Midstall Software']

conf_data = configuration_data()

if git.found()
  git_commit = run_command([git, 'rev-parse', '--short', 'HEAD'])
  git_branch = run_command([git, 'rev-parse', '--abbrev-ref', 'HEAD'])
  git_config_username = run_command([git, 'config', '--get', 'user.name'])

  if git_commit.returncode() == 0 and git_branch.returncode() == 0
    shortver = '@0@-@1@'.format(meson.project_version(), git_commit.stdout().strip())
    longver = '@0@ (branch \'@1@\')'.format(shortver, git_branch.stdout().strip())
  endif

  if git_config_username.returncode() == 0
    git_username = git_config_username.stdout().strip()
    conf_data.set('BUILD_USER', git_username)
  else
    conf_data.set('BUILD_USER', 'nobody')
  endif
else
  conf_data.set('BUILD_USER', 'nobody')
endif

conf_data.set('PREFIX', prefix)
conf_data.set('BINDIR', bindir)
conf_data.set('DATADIR', datadir)
conf_data.set('LIBDIR', libdir)
conf_data.set('LIBEXECDIR', libexecdir)
conf_data.set('VERSION', longver)
conf_data.set('TARGET_SYSTEM', target_machine.system())
conf_data.set('LOCALDIR', join_paths(datadir, 'locale'))
conf_data.set('BUILDDIR', meson.current_build_dir())
conf_data.set('SOURCEDIR', meson.current_source_dir())

sdk = dependency('expidus-sdk', native: false, required: false, include_type: 'system', method: 'pkg-config')
if sdk.found()
  uncrustify = find_program('uncrustify', sdk.get_variable('bindir'))
else
  uncrustify = disabler()
endif

valadoc = find_program('valadoc', required: get_option('docs'), native: true)

libintl = meson.get_compiler('c').find_library('intl', required: false)
gio = dependency('gio-2.0', required: true)
libpeas = dependency('libpeas-1.0', required: false)
gmodule = dependency('gmodule-2.0', required: false)
vadi = dependency('vadi-0.0', required: true)

subdir('po')
subdir('core')
subdir('plugins')
