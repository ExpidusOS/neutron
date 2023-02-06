project('neutron', 'c', license: 'GPL-3.0-only', version: '0.1.0-prealpha', default_options: [
  'default_library=both'
])

pkg = import('pkgconfig')
fs = import('fs')

prefix = get_option('prefix')
bindir = prefix / get_option('bindir')
datadir = prefix / get_option('datadir')
libdir = prefix / get_option('libdir')
libexecdir = prefix / get_option('libexecdir')
includedir = prefix / get_option('includedir')

longver = '@0@'.format(meson.project_version())
shortver = longver
git = find_program('git', native: true, required: false)
conf_data = configuration_data()
build_user = get_option('build-user')

if git.found()
  git_commit = run_command(git, 'rev-parse', '--short', 'HEAD', check: false)
  git_branch = run_command(git, 'rev-parse', '--abbrev-ref', 'HEAD', check: false)
  git_config_username = run_command(git, 'config', '--get', 'user.name', check: false)
  git_config_email = run_command(git, 'config', '--get', 'user.email', check: false)

  if git_commit.returncode() == 0
    git_commit = git_commit.stdout().strip()
  else
    git_commit = get_option('git-commit')
  endif

  if git_branch.returncode() == 0
    git_branch = git_branch.stdout().strip()
  else
    git_branch = get_option('git-branch')
  endif

  if git_config_username.returncode() == 0 and git_config_email.returncode() == 0
    git_config_username = git_config_username.stdout().strip()
    git_config_email = git_config_email.stdout().strip()
    build_user = '@0@ (@1@)'.format(git_config_username, git_config_email)
  endif
else
  git_commit = get_option('git-commit')
  git_branch = get_option('git-branch')
endif

shortver = '@0@-@1@'.format(meson.project_version(), git_commit)
longver = '@0@ (branch \'@1@\')'.format(shortver, git_branch)
version = shortver.split('-')[0]

if get_option('buildtype') == 'release'
  shortver = meson.project_version()
endif

flutter_os = target_machine.system()
if target_machine.system() == 'darwin'
  flutter_os = 'macos'
elif target_machine.system() == 'cygwin'
  flutter_os = 'windows'
endif

libdir_neutron = libdir / 'neutron' / version
dartdir = libdir_neutron / 'dart'
shimdir = libdir_neutron / 'shims'

conf_data.set('BUILD_USER', build_user)
conf_data.set('LIBDIR', libdir)

conf_data.set('GIT_COMMIT', git_commit)
conf_data.set('GIT_BRANCH', git_branch)

conf_data.set('VERSION', version)
conf_data.set('VERSION_LONG', longver)
conf_data.set('VERSION_SHORT', shortver)

is_bootstrap = get_option('bootstrap')

tests = get_option('tests').disable_auto_if(not dependency('check', native: true, required: false).found())
docs = get_option('docs').disable_auto_if(not dependency('gtk-doc', native: true, required: false).found())

cc = meson.get_compiler('c')
has_execinfo_h = cc.check_header('execinfo.h', required: false)

pthread = dependency('threads', required: true)
check = dependency('check', required: get_option('tests'), native: true)

gnome = import('gnome')
gtkdoc = dependency('gtk-doc', native: true, required: docs)

if not is_bootstrap
  ffigen = find_program('ffigen', native: true, required: false)
  dart = find_program('dart', native: true, required: true)
  flutter = find_program('flutter', native: true, required: true)

  if get_option('flutter-engine') == ''
    error('Must set the flutter-engine option')
  endif

  flutter_engine = declare_dependency(dependencies: [
    cc.find_library('flutter_engine',
      dirs: get_option('flutter-engine'),
      header_include_directories: include_directories(get_option('flutter-engine')),
      has_headers: ['flutter_embedder.h'])
  ],
  include_directories: include_directories(get_option('flutter-engine')))

  egl = dependency('egl', native: false,
    required: get_option('graphics-renderer-egl').disable_auto_if(not dependency('egl', native: false, required: false).found()))
  pixman = dependency('pixman-1', native: false,
    required: get_option('graphics-renderer-pixman').disable_auto_if(not dependency('pixman-1', native: false, required: false).found()))

  has_xcb = dependency('xcb', native: false, required: false).found()
  xcb = dependency('xcb', native: false,
    required: not get_option('displaykit-compositor-xcb').disable_auto_if(not has_xcb).disabled()
      or not get_option('displaykit-client-xcb').disable_auto_if(not has_xcb).disabled())

  wlroots = dependency('wlroots', native: false,
    required: get_option('displaykit-compositor-wlroots').disable_auto_if(not dependency('wlroots', native: false, required: false).found()))
  wayland_server = dependency('wayland-server', native: false, required: wlroots.found())

  xkbcommon = dependency('xkbcommon', native: false, required: xcb.found() or wlroots.found())
else
  ffigen = disabler()
  flutter = disabler()
endif

add_global_arguments([
  '-Werror=unused-variable'
], language: 'c')

libs = []
neutron_sources = []
neutron_cflags = []
neutron_inc = [include_directories('elemental')]
neutron_deps = []

subdir('elemental')

if not is_bootstrap
  foreach name : [ 'shimmy', 'platform', 'graphics', 'inputcore', 'displaykit', 'runtime' ]
    subdir(name)
    neutron_inc += [include_directories(name)]
  endforeach
endif

lib_names = []

foreach lib : libs
  lib_names += [lib.name()]
endforeach

sum_args = {
  'Built Libraries': lib_names,
  'Built by': build_user,
  'Version': version,
  'Version (long)': longver,
  'Version (short)': shortver
}

if not is_bootstrap
  libneutron = library('neutron', neutron_sources,
    c_args: neutron_cflags,
    include_directories: neutron_inc,
    dependencies: neutron_deps,
    version: version,
    gnu_symbol_visibility: 'hidden',
    install: true)
  neutron = declare_dependency(link_with: libneutron,
    dependencies: neutron_deps,
    include_directories: neutron_inc)

  pkg.generate(libneutron,
    name: 'neutron',
    description: 'API and runtime for ExpidusOS applications and compositors',
    url: 'https://github.com/ExpidusOS/neutron',
    version: shortver)

  subdir('docs', if_found: [gtkdoc])
endif

summary(sum_args, section: 'Neutron')
