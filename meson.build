project('neutron', 'c', license: 'GPL-3.0-only', version: '0.1.0-prealpha')

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

dartdir = libdir / 'neutron' / version / 'dart'

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

pthread = dependency('threads', required: true)
check = dependency('check', required: get_option('tests'), native: true)

gnome = import('gnome')
gtkdoc = dependency('gtk-doc', native: true, required: docs)

if not is_bootstrap
  ffigen = find_program('ffigen', native: true, required: false)
  flutter = find_program('flutter', native: true, required: true)

  flutter_engine = dependency('flutter-engine-@0@'.format(get_option('flutter-runtime-mode')), required: true)
  egl = dependency('egl', native: false,
    required: get_option('graphics-renderer-egl').disable_auto_if(not dependency('egl', native: false, required: false).found()))
  pixman = dependency('pixman-1', native: false,
    required: get_option('graphics-renderer-pixman').disable_auto_if(not dependency('pixman-1', native: false, required: false).found()))
else
  ffigen = disabler()
  flutter = disabler()
endif

add_global_arguments([
  '-Werror=unused-variable'
], language: 'c')

libs = []

subdir('elemental')

if not is_bootstrap
  subdir('shimmy')
  subdir('platform')
  subdir('graphics')
  subdir('displaykit')
  subdir('runtime')
endif

static_libs = []
lib_names = []

foreach lib : libs
  lib_names += [lib.name()]
  static_libs += [lib.get_static_lib()]
endforeach

sum_args = {
  'Built Libraries': lib_names,
  'Built by': build_user,
  'Version': version,
  'Version (long)': longver,
  'Version (short)': shortver
}

if not is_bootstrap
  sum_args += {
    'Flutter Engine Runtime Mode': get_option('flutter-runtime-mode')
  }

  libneutron = both_libraries('neutron',
    link_whole: static_libs,
    version: version,
    gnu_symbol_visibility: 'hidden',
    install: true)
  neutron = declare_dependency(link_with: libneutron,
    dependencies: [elemental_deps, platform_deps, graphics_deps])

  pkg.generate(libneutron,
    name: 'neutron',
    description: 'Core API for ExpidusOS',
    url: 'https://github.com/ExpidusOS/neutron',
    version: shortver)

  subdir('docs', if_found: [gtkdoc])
endif

summary(sum_args, section: 'Neutron')
