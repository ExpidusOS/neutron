project('neutron', 'c', license: 'GPL-3.0-only', version: '0.1.0-prealpha')

pkg = import('pkgconfig')

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
conf_data.set('BUILD_USER', get_option('build-user'))

if git.found()
  git_commit = run_command(git, 'rev-parse', '--short', 'HEAD', check: true)
  git_branch = run_command(git, 'rev-parse', '--abbrev-ref', 'HEAD', check: true)
  git_config_username = run_command(git, 'config', '--get', 'user.name', check: true)

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

  if git_config_username.returncode() == 0
    git_username = git_config_username.stdout().strip()
    conf_data.set('BUILD_USER', git_username)
  endif
else
  git_commit = get_option('git-commit')
  git_branch = get_option('git-branch')
endif

shortver = '@0@-@1@'.format(meson.project_version(), git_commit)
longver = '@0@ (branch \'@1@\')'.format(shortver, git_branch)
version = shortver.split('-')[0]

conf_data.set('GIT_COMMIT', git_commit)
conf_data.set('GIT_BRANCH', git_branch)

conf_data.set('VERSION', version)
conf_data.set('VERSION_LONG', longver)
conf_data.set('VERSION_SHORT', shortver)

cc = meson.get_compiler('c')
pthread = cc.find_library('pthread')

check = dependency('check', required: get_option('tests'), native: true)

subdir('elemental')
